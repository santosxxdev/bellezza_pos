import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import '../model/receipt_model.dart';
import '../widgets/receipt_widget.dart';
import '../widgets/service_receipt_widget.dart';

class ReceiptPrinter {
  static Future<void> printReceipt(
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    final flutterPrinter = FlutterThermalPrinter.instance;

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
          final receiptBytes = await flutterPrinter.screenShotWidget(
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
            final serviceBytes = await flutterPrinter.screenShotWidget(
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
}
