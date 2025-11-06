import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import '../model/receipt_model.dart';
import '../widgets/receipt_widget.dart';
import '../widgets/service_receipt_widget.dart';

class ReceiptPrinter {
  static int imageHeight = 0;
  static final ScreenshotController _screenshotController = ScreenshotController();

  static Future<void> printReceipt(
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      final receiptModel = ReceiptModel(data: data);
      final mainPrinterIp =
          receiptModel.printerIp ?? data['printerIp']?.toString();

      if (mainPrinterIp == null || mainPrinterIp.isEmpty) {
        _showMessage(context, "⚠️ لا يوجد IP للطابعة في البيانات");
        return;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      await _printToPrinter(
        ip: mainPrinterIp,
        context: context,
        bytesBuilder: () async {
          log("🖨️ طباعة الفاتورة الأساسية على $mainPrinterIp");
          final receiptBytes = await screenShotWidget(
            context,
            generator: generator,
            widget: ReceiptWidget(receiptModel: receiptModel),
          );
          return [...receiptBytes, ...generator.cut()];
        },
      );

      // 🧾 2️⃣ طباعة فواتير الخدمات
      for (final entry in receiptModel.orderDetails.entries) {
        final printerIp = entry.key;
        final serviceItems = entry.value;

        if (printerIp == mainPrinterIp) continue;

        // تجهيز موديل جديد بخدمات هذا الـ IP فقط
        final serviceData = Map<String, dynamic>.from(data);
        serviceData['orderDetails'] = {
          printerIp: serviceItems.map((item) => item.toMap()).toList()
        };
        final serviceModel = ReceiptModel(data: serviceData);

        await Future.delayed(const Duration(milliseconds: 400));

        await _printToPrinter(
          ip: printerIp,
          context: context,
          bytesBuilder: () async {
            log("🧾 طباعة فاتورة الخدمة على $printerIp");
            final serviceBytes = await screenShotWidget(
              context,
              generator: generator,
              widget: ServiceReceiptWidget(
                receiptModel: serviceModel,
                printerIp: printerIp,
              ),
            );
            return [...serviceBytes, ...generator.cut()];
          },
        );
      }

      _showMessage(context, "✅ تم إرسال جميع الفواتير للطابعات بنجاح");
    } catch (e) {
      log("❌ خطأ أثناء الطباعة: $e");
      _showMessage(context, "حدث خطأ أثناء الطباعة: $e");
    }
  }

  // 🔧 دالة الطباعة على IP محدد
  static Future<void> _printToPrinter({
    required String ip,
    required BuildContext context,
    required Future<List<int>> Function() bytesBuilder,
  }) async {
    const port = 9100;
    final service = FlutterThermalPrinterNetwork(ip, port: port);

    try {
      await service.connect();
      final bytes = await bytesBuilder();
      await service.printTicket(bytes);
    } catch (e) {
      log("⚠️ فشل الاتصال بالطابعة $ip: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ فشل الاتصال بالطابعة $ip")),
        );
      }
    } finally {
      await service.disconnect();
    }
  }

  static void _showMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // 📸 Method to capture widget as thermal printer bytes
  static Future<Uint8List> screenShotWidget(
      BuildContext context, {
        required Widget widget,
        Duration delay = const Duration(milliseconds: 100),
        int? customWidth,
        PaperSize paperSize = PaperSize.mm80,
        Generator? generator,
      }) async {
    // انتظر قليلاً لضمان render الـ widget
    await Future.delayed(delay);

    // capture الصورة باستخدام الإصدار 3.0.0
    final Uint8List? image = await _screenshotController.captureFromWidget(
      Material(
        color: Colors.white,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: widget,
        ),
      ),
      pixelRatio: 3.0,
      context: context, // إضافة context في الإصدار 3.0.0
    );

    if (image == null) {
      throw Exception("فشل في capture الصورة");
    }

    Generator? generator0;
    if (generator == null) {
      final profile = await CapabilityProfile.load();
      generator0 = Generator(paperSize, profile);
    } else {
      generator0 = generator;
    }

    img.Image? imagebytes = img.decodeImage(image);

    if (customWidth != null) {
      final width = _makeDivisibleBy8(customWidth);
      imagebytes = img.copyResize(imagebytes!, width: width);
    }

    imagebytes = _buildImageRasterAvaliable(imagebytes!);

    imagebytes = img.grayscale(imagebytes);
    imageHeight = imagebytes.height;
    final totalheight = imagebytes.height;
    final totalwidth = imagebytes.width;

    int imageChunkHeight = 150;
    double exactChunks = totalheight / imageChunkHeight;
    final timestoCut =
        exactChunks.floor() + (exactChunks - exactChunks.floor() > 0.1 ? 1 : 0);
    List<int> bytes = [];

    for (var i = 0; i < timestoCut; i++) {
      final croppedImage = img.copyCrop(
        imagebytes,
        x: 0,
        y: i * imageChunkHeight,
        width: totalwidth,
        height: imageChunkHeight,
      );
      final raster = generator0.imageRaster(
        croppedImage,
        imageFn: PosImageFn.bitImageRaster,
      );
      bytes += raster;
    }

    return Uint8List.fromList(bytes);
  }

  static int _makeDivisibleBy8(int number) {
    if (number % 8 == 0) {
      return number;
    }
    return number + (8 - (number % 8));
  }

  static img.Image _buildImageRasterAvaliable(img.Image image) {
    final avaliable = image.width % 8 == 0;
    if (avaliable) {
      return image;
    }
    final newWidth = _makeDivisibleBy8(image.width);
    return img.copyResize(image, width: newWidth);
  }
}