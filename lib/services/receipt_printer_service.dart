import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import '../model/receipt_model.dart';
import '../widgets/receipt_widget.dart';
import '../widgets/service_receipt_widget.dart';

class ReceiptPrinter {
  static final _printer = FlutterThermalPrinter.instance;
  static final _screenshotController = ScreenshotController();

  /// 🖨️ طباعة الفاتورة الرئيسية والخدمات
  static Future<void> printReceipt(
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      print("🟢 بدء عملية الطباعة الكاملة");
      final receiptModel = ReceiptModel(data: data);

      // 1. أولاً: طباعة فاتورة الكاشير الرئيسية
      await _printCashierReceipt(receiptModel, context);

      // 2. ثانياً: طباعة فواتير الخدمات لكل printerIp
      await _printServiceReceipts(receiptModel, context);

      print("✅ اكتملت عملية الطباعة بنجاح");

    } catch (e) {
      print("❌ خطأ عام في الطباعة: $e");
      rethrow;
    }
  }

  /// 💰 طباعة فاتورة الكاشير الرئيسية
  static Future<void> _printCashierReceipt(ReceiptModel receiptModel, BuildContext context) async {
    try {
      final mainPrinterIp = receiptModel.printerIp;

      if (mainPrinterIp == null || mainPrinterIp.isEmpty) {
        print("⚠️ لا يوجد طابعة رئيسية للفاتورة");
        return;
      }

      print("💰 بدء طباعة فاتورة الكاشير على: $mainPrinterIp");

      // استخدام الطباعة مع حفظ الصورة أولاً
      await _printWithImageSave(mainPrinterIp, receiptModel.data, context, isService: false);

      print("✅ تمت طباعة فاتورة الكاشير بنجاح على: $mainPrinterIp");

    } catch (e) {
      print("❌ خطأ في طباعة فاتورة الكاشير: $e");
      print("🔍 تفاصيل الخطأ: ${e.toString()}");
    }
  }

  /// 🔧 طباعة فواتير الخدمات
  static Future<void> _printServiceReceipts(ReceiptModel receiptModel, BuildContext context) async {
    try {
      final orderDetails = receiptModel.orderDetails;

      if (orderDetails.isEmpty) {
        print("ℹ️ لا توجد خدمات للطباعة");
        return;
      }

      print("🛠️ بدء طباعة ${orderDetails.length} فاتورة خدمة");

      // طباعة فاتورة خدمة لكل printerIp
      for (final entry in orderDetails.entries) {
        final printerIp = entry.key;
        final services = entry.value;

        print("🖨️ معالجة طابعة الخدمة: $printerIp بها ${services.length} خدمة");

        for (final service in services) {
          await _printSingleServiceReceipt(receiptModel, printerIp, service, context);
        }
      }

      print("✅ اكتملت طباعة فواتير الخدمات");

    } catch (e) {
      print("❌ خطأ في طباعة فواتير الخدمات: $e");
    }
  }

  /// 🛠️ طباعة فاتورة خدمة واحدة
  static Future<void> _printSingleServiceReceipt(
      ReceiptModel receiptModel,
      String printerIp,
      ProductItem service,
      BuildContext context,
      ) async {
    try {
      print("🛠️ بدء طباعة فاتورة الخدمة على: $printerIp - ${service.name}");

      // إنشاء فاتورة الخدمة
      final serviceWidget = ServiceReceiptWidget(
        receiptModel: receiptModel,
        printerIp: printerIp,
        serviceItem: service,
      );

      // استخدام الطباعة مع حفظ الصورة أولاً
      await _printServiceWithImageSave(printerIp, serviceWidget, context);

      print("✅ تمت طباعة فاتورة الخدمة: ${service.name} على $printerIp");

    } catch (e) {
      print("❌ خطأ في طباعة فاتورة الخدمة $printerIp: $e");
      print("🔍 تفاصيل الخطأ: ${e.toString()}");
    }
  }

  /// 💾 حفظ الصورة ثم الطباعة للفاتورة الرئيسية
  static Future<void> _printWithImageSave(
      String printerIp,
      Map<String, dynamic> data,
      BuildContext context, {
        bool isService = false,
      }) async {
    try {
      final receiptModel = ReceiptModel(data: data);
      final widget = ReceiptWidget(receiptModel: receiptModel);

      // 1. حفظ الصورة أولاً
      final String imagePath = await _saveReceiptImage(widget, context, 'main_receipt');
      print("💾 تم حفظ صورة الفاتورة في: $imagePath");

      // 2. ثم الطباعة من الصورة المحفوظة
      await _printFromSavedImage(printerIp, imagePath, context);

    } catch (e) {
      print("❌ خطأ في حفظ الصورة أو الطباعة: $e");
      // محاولة الطريقة البديلة
      await _printViaWidget(printerIp, data, context);
    }
  }

  /// 💾 حفظ الصورة ثم الطباعة للخدمات
  static Future<void> _printServiceWithImageSave(
      String printerIp,
      ServiceReceiptWidget serviceWidget,
      BuildContext context,
      ) async {
    try {
      // 1. حفظ الصورة أولاً
      final String imagePath = await _saveServiceReceiptImage(serviceWidget, context, 'service_receipt');
      print("💾 تم حفظ صورة الخدمة في: $imagePath");

      // 2. ثم الطباعة من الصورة المحفوظة
      await _printFromSavedImage(printerIp, imagePath, context);

    } catch (e) {
      print("❌ خطأ في حفظ صورة الخدمة أو الطباعة: $e");
      // محاولة الطريقة البديلة
      await _printServiceViaWidget(printerIp, serviceWidget, context);
    }
  }

  /// 📸 حفظ صورة الفاتورة الرئيسية
  static Future<String> _saveReceiptImage(Widget widget, BuildContext context, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${directory.path}/$fileName\_$timestamp.png';

      // استخدام ScreenshotController لالتقاط الصورة
      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        Material(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: widget,
          ),
        ),
        context: context,
        pixelRatio: 3.0, // دقة عالية
      );

      if (imageBytes != null) {
        final File imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);
        print("✅ تم حفظ الصورة بنجاح: $imagePath (${imageBytes.length} bytes)");
        return imagePath;
      } else {
        throw Exception("فشل في التقاط الصورة");
      }
    } catch (e) {
      print("❌ خطأ في حفظ صورة الفاتورة: $e");
      rethrow;
    }
  }

  /// 📸 حفظ صورة الخدمة
  static Future<String> _saveServiceReceiptImage(ServiceReceiptWidget widget, BuildContext context, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${directory.path}/$fileName\_$timestamp.png';

      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        Material(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: widget,
          ),
        ),
        context: context,
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        final File imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);
        print("✅ تم حفظ صورة الخدمة بنجاح: $imagePath (${imageBytes.length} bytes)");
        return imagePath;
      } else {
        throw Exception("فشل في التقاط صورة الخدمة");
      }
    } catch (e) {
      print("❌ خطأ في حفظ صورة الخدمة: $e");
      rethrow;
    }
  }

  /// 🖨️ الطباعة من الصورة المحفوظة - الطريقة المصححة
  static Future<void> _printFromSavedImage(String printerIp, String imagePath, BuildContext context) async {
    try {
      final port = 9100;
      print("🌐 الطباعة من الصورة المحفوظة على: $printerIp:$port");

      // قراءة الصورة المحفوظة
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception("الصورة المحفوظة غير موجودة: $imagePath");
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      print("📦 جاري طباعة الصورة بحجم: ${imageBytes.length} bytes");

      // استخدام FlutterThermalPrinterNetwork للطباعة المباشرة
      final networkPrinter = FlutterThermalPrinterNetwork(printerIp, port: port);

      print("🔌 محاولة الاتصال بالطابعة...");
      await networkPrinter.connect();
      print("✅ تم الاتصال بالطابعة");

      // ✅ التصحيح: استخدام screenShotWidget لإنشاء bytes الصورة
      print("🖨️ بدء إنشاء بيانات الطباعة من الصورة...");

      // إعادة إنشاء الـ widget من الصورة المحفوظة
      final imageWidget = Image.file(imageFile);

      // استخدام screenShotWidget لتحويل الصورة إلى bytes مناسبة للطابعة
      final List<int> receiptBytes = await _printer.screenShotWidget(
        context,
        widget: imageWidget,
      );

      // إضافة أوامر قطع الورق
      final List<int> finalBytes = [];
      finalBytes.addAll(receiptBytes);
      finalBytes.addAll([0x0A, 0x0A, 0x0A]); // أسطر فارغة
      finalBytes.addAll([0x1B, 0x69]); // أمر قطع الورق

      print("🖨️ إرسال البيانات للطباعة...");
      await networkPrinter.printTicket(finalBytes);
      print("✅ تم إرسال البيانات بنجاح");

      print("🔌 قطع الاتصال...");
      await networkPrinter.disconnect();
      print("✅ تم قطع الاتصال");

    } catch (e) {
      print("❌ خطأ في الطباعة من الصورة المحفوظة: $e");
      // محاولة بديلة
      await _printFromSavedImageAlternative(printerIp, imagePath, context);
    }
  }

  /// 🖨️ طريقة بديلة للطباعة من الصورة المحفوظة - مصححة
  static Future<void> _printFromSavedImageAlternative(String printerIp, String imagePath, BuildContext context) async {
    try {
      print("🔄 تجربة الطريقة البديلة للطباعة من الصورة...");

      final printer = Printer(
        name: 'Image Printer - $printerIp',
        address: '$printerIp:9100',
        connectionType: ConnectionType.NETWORK,
      );

      print("🔌 محاولة الاتصال بالطريقة البديلة...");
      final connected = await _printer.connect(printer);

      if (connected) {
        print("✅ تم الاتصال بالطريقة البديلة");

        // استخدام printWidget مباشرة مع الصورة
        final imageFile = File(imagePath);
        final imageWidget = Image.file(imageFile);

        await _printer.printWidget(
          context,
          printer: printer,
          cutAfterPrinted: true,
          widget: imageWidget,
        );

        await _printer.disconnect(printer);
        print("✅ تمت الطباعة بالطريقة البديلة من الصورة");
      } else {
        print("❌ فشل الاتصال بالطريقة البديلة");
        throw Exception("فشل الاتصال بالطابعة $printerIp");
      }

    } catch (e) {
      print("❌ خطأ في الطريقة البديلة: $e");
      rethrow;
    }
  }

  /// 🖨️ طريقة بديلة للطباعة باستخدام Widget مباشرة
  static Future<void> _printViaWidget(
      String printerIp,
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      print("🖨️ استخدام طريقة الطباعة المباشرة بالويدجت...");

      final receiptModel = ReceiptModel(data: data);
      final widget = ReceiptWidget(receiptModel: receiptModel);

      final printer = Printer(
        name: 'Widget Printer - $printerIp',
        address: '$printerIp:9100',
        connectionType: ConnectionType.NETWORK,
      );

      print("🔌 محاولة الاتصال...");
      final connected = await _printer.connect(printer);

      if (!connected) {
        throw Exception("فشل في الاتصال بالطابعة $printerIp");
      }

      print("✅ تم الاتصال بالطابعة");

      // استخدام printWidget للطباعة المباشرة
      await _printer.printWidget(
        context,
        printer: printer,
        cutAfterPrinted: true,
        widget: widget,
      );

      await _printer.disconnect(printer);
      print("✅ تمت الطباعة بنجاح");

    } catch (e) {
      print("❌ خطأ في طريقة الطباعة بالويدجت: $e");
      rethrow;
    }
  }

  /// 🖨️ طريقة بديلة لطباعة الخدمات باستخدام Widget مباشرة
  static Future<void> _printServiceViaWidget(
      String printerIp,
      ServiceReceiptWidget serviceWidget,
      BuildContext context,
      ) async {
    try {
      print("🖨️ استخدام طريقة الطباعة المباشرة لخدمة بالويدجت...");

      final printer = Printer(
        name: 'Service Widget Printer - $printerIp',
        address: '$printerIp:9100',
        connectionType: ConnectionType.NETWORK,
      );

      print("🔌 محاولة الاتصال...");
      final connected = await _printer.connect(printer);

      if (!connected) {
        throw Exception("فشل في الاتصال بطابعة الخدمة $printerIp");
      }

      print("✅ تم الاتصال بطابعة الخدمة");

      // استخدام printWidget للطباعة المباشرة
      await _printer.printWidget(
        context,
        printer: printer,
        cutAfterPrinted: true,
        widget: serviceWidget,
      );

      await _printer.disconnect(printer);
      print("✅ تمت طباعة الخدمة بنجاح");

    } catch (e) {
      print("❌ خطأ في طريقة الطباعة بالويدجت للخدمة: $e");
      rethrow;
    }
  }

  // ========== الطرق القديمة ==========

  /// 🌐 الطباعة المباشرة عبر الشبكة للفاتورة الرئيسية
  static Future<void> _printDirectViaNetworkOld(
      String printerIp,
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      final port = 9100;

      print("🌐 استخدام الطريقة القديمة المباشرة...");

      final bytes = await _generateReceiptBytesOld(data, context);
      final networkPrinter = FlutterThermalPrinterNetwork(printerIp, port: port);

      await networkPrinter.connect();
      await networkPrinter.printTicket(bytes);
      await networkPrinter.disconnect();

    } catch (e) {
      print("❌ خطأ في الطريقة القديمة: $e");
      rethrow;
    }
  }

  /// 🌐 الطباعة المباشرة عبر الشبكة للخدمات
  static Future<void> _printServiceDirectViaNetworkOld(
      String printerIp,
      ServiceReceiptWidget serviceWidget,
      BuildContext context,
      ) async {
    try {
      final port = 9100;

      print("🌐 استخدام الطريقة القديمة للخدمات...");

      final bytes = await _generateServiceReceiptBytesOld(serviceWidget, context);
      final networkPrinter = FlutterThermalPrinterNetwork(printerIp, port: port);

      await networkPrinter.connect();
      await networkPrinter.printTicket(bytes);
      await networkPrinter.disconnect();

    } catch (e) {
      print("❌ خطأ في الطريقة القديمة للخدمات: $e");
      rethrow;
    }
  }

  static Future<List<int>> _generateReceiptBytesOld(
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    try {
      print("📸 [OLD METHOD] جاري إنشاء صورة الفاتورة...");
      final receiptModel = ReceiptModel(data: data);
      final widget = ReceiptWidget(receiptModel: receiptModel);

      List<int> screenshotBytes = await FlutterThermalPrinter.instance.screenShotWidget(
        context,
        widget: widget,
      );

      print("📸 [OLD METHOD] تم إنشاء الصورة بحجم: ${screenshotBytes.length} bytes");

      List<int> finalBytes = [];
      finalBytes.addAll(screenshotBytes);
      finalBytes.addAll([0x0A, 0x0A, 0x0A]); // إضافة أسطر فارغة
      finalBytes.addAll([0x1B, 0x69]); // أمر قطع الورق

      print("📦 [OLD METHOD] الحجم النهائي للبيانات: ${finalBytes.length} bytes");

      return finalBytes;
    } catch (e) {
      print("❌ [OLD METHOD] خطأ في _generateReceiptBytes: $e");
      rethrow;
    }
  }

  static Future<List<int>> _generateServiceReceiptBytesOld(
      ServiceReceiptWidget serviceWidget,
      BuildContext context,
      ) async {
    try {
      print("📸 [OLD METHOD] جاري إنشاء صورة فاتورة الخدمة...");

      List<int> screenshotBytes = await FlutterThermalPrinter.instance.screenShotWidget(
        context,
        widget: serviceWidget,
      );

      print("📸 [OLD METHOD] تم إنشاء صورة الخدمة بحجم: ${screenshotBytes.length} bytes");

      List<int> finalBytes = [];
      finalBytes.addAll(screenshotBytes);
      finalBytes.addAll([0x0A, 0x0A, 0x0A]);
      finalBytes.addAll([0x1B, 0x69]);

      print("📦 [OLD METHOD] الحجم النهائي لبيانات الخدمة: ${finalBytes.length} bytes");

      return finalBytes;
    } catch (e) {
      print("❌ [OLD METHOD] خطأ في _generateServiceReceiptBytes: $e");
      rethrow;
    }
  }
}