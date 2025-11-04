import 'package:bellezza_pos/model/receipt_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import 'package:bellezza_pos/services/shared_preferences_service.dart';
import 'package:bellezza_pos/pages/base_url_settings_page.dart';
import '../services/receipt_printer_service.dart';
import '../widgets/receipt_widget.dart';

class MainWebViewPage extends StatefulWidget {
  const MainWebViewPage({super.key});

  @override
  State<MainWebViewPage> createState() => _MainWebViewPageState();
}

class _MainWebViewPageState extends State<MainWebViewPage> {
  InAppWebViewController? controller;
  Map<String, dynamic>? receivedData;
  double _progress = 0;
  bool _isLoading = true;
  bool _hasError = false;

  String get _baseUrl {
    final url = SharedPreferencesService.getBaseUrl();
    print("🌐 استخدام الـ URL: $url");
    return url;
  }

  @override
  void initState() {
    super.initState();
    print("🚀 بدء MainWebViewPage مع الـ URL: $_baseUrl");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onLongPress: _showBottomOptionsMenu,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_baseUrl)),

              onWebViewCreated: (c) {
                controller = c;

                c.addJavaScriptHandler(
                  handlerName: "printApp",
                  callback: (args) {
                    _handleReceivedData(args);
                    return {"status": "تم الاستقبال بنجاح"};
                  },
                );
              },

              onLoadStart: (c, url) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _progress = 0;
                });
              },

              onLoadStop: (c, url) async {
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
                await _setupPrintAppHandler(c);
              },

              onProgressChanged: (c, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },

              onLoadError: (c, url, code, message) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              },

              onReceivedError: (c, request, error) {
                setState(() {
                  _hasError = true;
                });
              },
            ),
          ),

          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),

          if (_hasError)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذر تحميل الصفحة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الرابط: $_baseUrl',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _refreshPage,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BaseUrlSettingsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('تغيير الرابط'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoading && _progress == 0)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل التطبيق...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showBottomOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'خيارات التطبيق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildBottomMenuItem(
                    icon: Icons.refresh,
                    title: 'تحديث الصفحة',
                    onTap: () {
                      Navigator.pop(context);
                      _refreshPage();
                    },
                  ),
                  _buildBottomMenuItem(
                    icon: Icons.settings,
                    title: 'إعدادات الخادم',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BaseUrlSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildBottomMenuItem(
                    icon: Icons.close,
                    title: 'إغلاق',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Center(child: Text(title, style: const TextStyle(fontSize: 16))),
      onTap: onTap,
    );
  }

  void _refreshPage() {
    if (controller != null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      controller!.reload();
    }
  }

  void _handleReceivedData(List<dynamic> args) {
    try {
      if (args.isNotEmpty && args[0] is Map) {
        final data = args[0] as Map;
        print("🔍 البيانات الخام من JavaScript: $data");

        // دمج بيانات الفاتورة والشركة معاً
        final Map<String, dynamic> mergedData = {};

        // إضافة بيانات الفاتورة من Reciept
        if (data.containsKey('Reciept') && data['Reciept'] is Map) {
          final receiptData = Map<String, dynamic>.from(data['Reciept']);
          if (receiptData.isNotEmpty) {
            mergedData.addAll(receiptData);
            print("✅ تم إضافة بيانات الفاتورة");
          }
        }

        // إضافة بيانات الشركة
        if (data.containsKey('Company') && data['Company'] is Map) {
          final companyData = Map<String, dynamic>.from(data['Company']);
          if (companyData.isNotEmpty) {
            mergedData['Company'] = companyData;
            print("✅ تم إضافة بيانات الشركة");
          }
        }

        print("📦 البيانات المدمجة النهائية: $mergedData");

        if (mergedData.isNotEmpty) {
          setState(() {
            receivedData = mergedData;
          });

          // ✅ الطباعة المباشرة باستخدام printerIp من البيانات
          _printReceivedData(mergedData);
        } else {
          print("❌ لا توجد بيانات للطباعة");
        }
      }
    } catch (e) {
      _showErrorSnackbar("خطأ في معالجة البيانات: $e");
    }
  }

  void _printDetailedData(Map<String, dynamic> data) {
    print("📊 تفاصيل البيانات المستلمة:");

    // طباعة بيانات الفاتورة الأساسية
    print("📄 بيانات الفاتورة:");
    print("   - رقم الفاتورة: ${data['code'] ?? 'N/A'}");
    print("   - الإجمالي: ${data['total'] ?? 'N/A'}");
    print("   - الضريبة: ${data['tax'] ?? 'N/A'}");
    print("   - العميل: ${data['clientName'] ?? 'N/A'}");
    print("   - الكاشير: ${data['cashierName'] ?? 'N/A'}");
    print("   - الفرع: ${data['vendorBranchName'] ?? 'N/A'}");
    print("   - طريقة الدفع: ${data['paymethodName'] ?? 'N/A'}");

    // طباعة بيانات الشركة إذا موجودة
    if (data.containsKey('Company') && data['Company'] is Map) {
      final company = data['Company'] as Map;
      print("🏢 بيانات الشركة:");
      print("   - الاسم: ${company['ar'] ?? 'N/A'}");
      print("   - الهاتف: ${company['phoneNumber'] ?? 'N/A'}");
      print("   - العنوان: ${company['location'] ?? 'N/A'}");
      print("   - اللوجو: ${company['imageUrl'] ?? 'N/A'}");
      print("   - سياسة الاسترجاع: ${company['cancellationPolicy'] ?? 'N/A'}");
    }

    // طباعة تفاصيل الطلبات
    if (data.containsKey('orderDetails') && data['orderDetails'] is Map) {
      final orderDetails = data['orderDetails'] as Map;
      print("🛒 تفاصيل الطلبات:");
      orderDetails.forEach((printerIp, items) {
        print("   - طابعة: $printerIp");
        if (items is List) {
          for (var item in items) {
            print("     * ${item['itemName']} - الكمية: ${item['quantity']} - السعر: ${item['itemPrice']} - الإجمالي: ${item['total']}");
          }
        }
      });
    }

    // طباعة QR Code إذا موجود
    if (data['qrCodeData'] != null) {
      print("🔗 رمز QR: ${data['qrCodeData']}");
    }
  }


  Future<void> _setupPrintAppHandler(InAppWebViewController c) async {
    try {
      await c.evaluateJavascript(
        source: """
        console.log("🟢 [Injected JS] بدأ إعداد PrintApp...");
        
        if (window.originalPrintApp) {
          window.printApp = window.originalPrintApp;
        }
        
        window.originalPrintApp = window.printApp;
        window.printApp = function(data) {
          console.log("🟢 [PrintApp Override] تم استدعاء printApp");
          console.log("📊 بيانات الفاتورة:", data);
          
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('printApp', data);
          } else {
            console.log("❌ flutter_inappwebview غير متاح");
          }
          
          if (window.originalPrintApp) {
            return window.originalPrintApp(data);
          }
          
          return true;
        };
        
        localStorage.setItem('PrintApp', 'true');
        console.log("✅ [Injected JS] تم تعيين PrintApp = true و override الدالة");
      """,
      );

      // التحقق من نجاح الإعداد
      await Future.delayed(const Duration(seconds: 1));
      final result = await c.evaluateJavascript(
        source: "localStorage.getItem('PrintApp');",
      );
      print("🔍 نتيجة التحقق من PrintApp: $result");
    } catch (e) {
      print("Erorr : $e");
    }
  }

  void _showReceiptPreview(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text("معاينة الفاتورة"),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () {
                      Navigator.pop(context);
                      _printReceivedData(data);
                    },
                    tooltip: "طباعة",
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: "إغلاق",
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(child: ReceiptWidget(receiptModel: ReceiptModel(data: data))),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("إغلاق"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _printReceivedData(data);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                        child: const Text(
                          "طباعة",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printReceivedData(Map<String, dynamic> data) async {
    try {
      // التحقق من وجود printerIp في البيانات
      final printerIp = data['printerIp']?.toString();

      if (printerIp == null || printerIp.isEmpty) {
        _showErrorSnackbar("❌ لم يتم تحديد عنوان الطابعة في البيانات");
        return;
      }

      print("🖨️ بدء الطباعة على الطابعة: $printerIp");

      await ReceiptPrinter.printReceipt(data, context);

      // إشعار نجاح الطباعة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم إرسال الفاتورة للطابعة $printerIp بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar("خطأ في الطباعة: $e");
    }
  }


  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'إخفاء',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    controller?.removeJavaScriptHandler(handlerName: "printApp");
    super.dispose();
  }
}
