import 'package:flutter/material.dart';
import 'package:bellezza_pos/services/shared_preferences_service.dart';
import 'package:bellezza_pos/config/app_config.dart';
import 'package:bellezza_pos/pages/main_webview_page.dart';

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final TextEditingController _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedProtocol = 'https://';
  bool _isLoading = false;
  bool _checkingConfig = true;
  bool _showGuestOption = false;
  final List<String> _protocols = ['https://', 'http://'];

  @override
  void initState() {
    super.initState();
    _checkExistingConfiguration();
  }

  void _checkExistingConfiguration() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final currentUrl = SharedPreferencesService.getBaseUrl();
    final bool isConfigured = SharedPreferencesService.isConfigured;

    if (mounted) {
      setState(() {
        _checkingConfig = false;
        _showGuestOption = !isConfigured || currentUrl == AppConfig.defaultBaseUrl;
      });
    }

    // الانتقال التلقائي إذا كان التطبيق مهيأ
    if (isConfigured && currentUrl != AppConfig.defaultBaseUrl) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWebViewPage()),
        );
      }
    }
  }

  Future<void> _saveBaseUrl() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final fullUrl = _selectedProtocol + _urlController.text.trim();
        await SharedPreferencesService.setBaseUrl(fullUrl);

        if (mounted) {
          // إظهار رسالة نجاح قبل الانتقال
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('تم حفظ الإعدادات بنجاح'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 1200));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainWebViewPage()),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('خطأ في حفظ الإعدادات: $e');
      }
    }
  }

  void _enterAsGuest() {
    // استخدام الإعدادات الافتراضية للدخول كزائر
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainWebViewPage()),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('معلومات الإعداد'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أدخل عنوان الخادم الخاص بنظام Bellezza:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoItem('مثال:', 'mydomain.com'),
            _buildInfoItem('أو:', '192.168.1.100'),
            _buildInfoItem('أو:', 'server.bellezza.com'),
            SizedBox(height: 16),
            Text(
              'تأكد من:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildInfoItem('•', 'اتصال الإنترنت نشط'),
            _buildInfoItem('•', 'الخادم يعمل بشكل صحيح'),
            _buildInfoItem('•', 'البورتات مفتوحة (80, 443)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingConfig) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'جاري التحقق من الإعدادات...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى الانتظار',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Section
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.dashboard,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'تهيئة التطبيق',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل عنوان الخادم لبدء استخدام النظام',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Form Section
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Protocol and URL Input
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  // Protocol Dropdown
                                  Container(
                                    width: 100,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(12),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedProtocol,
                                        isExpanded: true,
                                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        items: _protocols.map((protocol) {
                                          return DropdownMenuItem<String>(
                                            value: protocol,
                                            child: Text(protocol),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedProtocol = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey.shade300,
                                  ),
                                  // URL Input
                                  Expanded(
                                    child: TextFormField(
                                      controller: _urlController,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                        hintText: 'اسم النطاق أو عنوان IP',
                                        hintStyle: TextStyle(color: Colors.grey[500]),
                                        errorStyle: TextStyle(color: Colors.red.shade600),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'يرجى إدخال عنوان الخادم';
                                        }
                                        if (value.contains(' ')) {
                                          return 'العنوان لا يمكن أن يحتوي على مسافات';
                                        }
                                        if (value.contains('/')) {
                                          return 'أدخل العنوان فقط بدون مسارات إضافية';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  // Help Icon
                                  IconButton(
                                    icon: Icon(Icons.help_outline, color: Colors.grey[500], size: 20),
                                    onPressed: _showInfoDialog,
                                    tooltip: 'معلومات المساعدة',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Help Text
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'أدخل اسم النطاق أو عنوان IP بدون http://',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Save Button
                            if (_isLoading)
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'جاري الحفظ...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _saveBaseUrl,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'حفظ والدخول',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Guest Option (Only shown when needed)
                      if (_showGuestOption) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'أو',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _enterAsGuest,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.blue.shade400),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_outline, size: 20, color: Colors.blue.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'الدخول كزائر',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'باستخدام الإعدادات الافتراضية',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}