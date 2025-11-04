import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../model/receipt_model.dart';
import '../services/shared_preferences_service.dart';

class ServiceReceiptWidget extends StatelessWidget {
  final ReceiptModel receiptModel;
  final String printerIp;
  final ProductItem serviceItem;

  const ServiceReceiptWidget({
    super.key,
    required this.receiptModel,
    required this.printerIp,
    required this.serviceItem,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 400, // زيادة العرض
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // زيادة البادنج
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildServiceHeader(),
                const SizedBox(height: 12),
                const Divider(thickness: 3, color: Colors.black),
                _buildServiceInfo(),
                const SizedBox(height: 12),
                const Divider(thickness: 3, color: Colors.black),
                _buildServiceDetails(),
                const SizedBox(height: 12),
                const Divider(thickness: 3, color: Colors.black),
                _buildSpecialistSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader() {
    final companyData = _getCompanyData();
    final companyName = companyData['ar'] ?? receiptModel.vendorBranchName ?? 'المتجر';
    final companyLocation = companyData['location'];
    final imageUrl = companyData['imageUrl'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // اللوجو
        if (imageUrl != null && imageUrl.toString().isNotEmpty)
          Container(
            height: 80, // زيادة الارتفاع
            child: Center(
              child: _buildCompanyLogo(
                  _getFullImageUrl(imageUrl),
                  companyName
              ),
            ),
          ),

        const SizedBox(height: 8),

        // اسم الشركة
        Text(
          companyName,
          style: const TextStyle(
            fontSize: 22, // زيادة حجم الخط
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        // عنوان الشركة
        if (companyLocation != null)
          Text(
            'العنوان: $companyLocation',
            style: const TextStyle(
              fontSize: 16, // زيادة حجم الخط
              height: 1.2,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 8),

        // نوع الفاتورة
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // زيادة البادنج
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2), // زيادة السماكة
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue[50],
          ),
          child: const Text(
            'فاتورة خدمة',
            style: TextStyle(
              fontSize: 20, // زيادة حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceInfo() {
    final clientName = _getClientName();
    final receiptCode = receiptModel.receiptCode ?? "N/A";
    final date = _formatDate(receiptModel.receiveDate);
    final cashierName = receiptModel.cashierName ?? 'N/A';
    final branchName = receiptModel.vendorBranchName ?? '';
    final clientPhone = receiptModel.clientPhone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // زيادة البادنج
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'معلومات الخدمة',
            style: TextStyle(
              fontSize: 20, // زيادة حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Divider(height: 2, color: Colors.grey), // زيادة السماكة
          const SizedBox(height: 8),
          _buildInfoRow('رقم الفاتورة', receiptCode),
          _buildInfoRow('التاريخ', date),
          _buildInfoRow('الكاشير', cashierName),
          _buildInfoRow('العميل', clientName),
          if (clientPhone != null && clientPhone.isNotEmpty)
            _buildInfoRow('هاتف العميل', clientPhone),
          _buildInfoRow('الفرع', branchName),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Container(
      padding: const EdgeInsets.all(12), // زيادة البادنج
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تفاصيل الخدمة',
            style: TextStyle(
              fontSize: 20, // زيادة حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // اسم الخدمة
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // زيادة البادنج
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              serviceItem.name,
              style: const TextStyle(
                fontSize: 18, // زيادة حجم الخط
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          // جدول تفاصيل الخدمة
          _buildDetailRow('الصالة', serviceItem.hallName ?? 'غير محدد'),
          _buildDetailRow('الكمية', '${serviceItem.quantity}'),
          _buildDetailRow('سعر الخدمة', _formatCurrency(serviceItem.price)),
          _buildDetailRow('رسوم الحجز', _formatCurrency(serviceItem.reservationFee)),
          _buildDetailRow('الإجمالي', _formatCurrency(serviceItem.total)),

          if (serviceItem.reservationDate != null)
            _buildDetailRow('موعد الحجز', _formatDate(serviceItem.reservationDate)),
        ],
      ),
    );
  }

  Widget _buildSpecialistSection() {
    final specialistName = serviceItem.specialistName ?? 'غير محدد';
    final printerName = serviceItem.printerName ?? printerIp;

    return Container(
      padding: const EdgeInsets.all(12), // زيادة البادنج
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green[50],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'المتخصص المسؤول',
            style: TextStyle(
              fontSize: 20, // زيادة حجم الخط
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // زيادة البادنج
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              specialistName,
              style: const TextStyle(
                fontSize: 18, // زيادة حجم الخط
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'طابعة الخدمة: $printerName',
            style: const TextStyle(
              fontSize: 14, // زيادة حجم الخط
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== الدوال المساعدة ==========

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // زيادة البادنج
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 16, // زيادة حجم الخط
                  fontWeight: FontWeight.w500
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 16, // زيادة حجم الخط
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5), // زيادة البادنج
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 16, // زيادة حجم الخط
                    fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 16, // زيادة حجم الخط
                  fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  String get _baseUrl {
    final url = SharedPreferencesService.getBaseUrl();
    return url;
  }

  String _getFullImageUrl(String imagePath) {
    final baseUrl = _baseUrl;

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    if (imagePath.startsWith('/')) {
      return '$baseUrl${imagePath.substring(1)}';
    }

    return '$baseUrl$imagePath';
  }

  Widget _buildCompanyLogo(String imageUrl, String companyName) {
    return SizedBox(
      width: 120, // زيادة العرض
      height: 60, // زيادة الارتفاع
      child: FutureBuilder<String?>(
        future: _getCachedLogoPath(imageUrl, companyName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLogoPlaceholder(companyName);
          }

          if (snapshot.hasData && snapshot.data != null) {
            return _buildLogoImage(File(snapshot.data!), companyName);
          }

          return _buildNetworkLogoWithCache(imageUrl, companyName);
        },
      ),
    );
  }

  Future<String?> _getCachedLogoPath(String imageUrl, String companyName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString('cached_logo_path');
      final cachedUrl = prefs.getString('cached_logo_url');

      if (cachedPath != null && cachedUrl == imageUrl) {
        final file = File(cachedPath);
        if (await file.exists()) {
          return cachedPath;
        }
      }

      return await _downloadAndCacheLogo(imageUrl, companyName);
    } catch (e) {
      return null;
    }
  }

  Future<String?> _downloadAndCacheLogo(String imageUrl, String companyName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/service_logo_${companyName.hashCode}.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_logo_path', filePath);
        await prefs.setString('cached_logo_url', imageUrl);
        return filePath;
      }
    } catch (e) {
      print("خطأ في تحميل صورة الخدمة: $e");
    }
    return null;
  }

  Widget _buildLogoImage(File imageFile, String companyName) {
    return Container(
      width: 100, // زيادة العرض
      height: 50, // زيادة الارتفاع
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildLogoPlaceholder(companyName);
          },
        ),
      ),
    );
  }

  Widget _buildNetworkLogoWithCache(String imageUrl, String companyName) {
    _downloadAndCacheLogo(imageUrl, companyName);
    return Container(
      width: 100, // زيادة العرض
      height: 50, // زيادة الارتفاع
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => _buildLogoPlaceholder(companyName),
          errorWidget: (context, url, error) => _buildLogoPlaceholder(companyName),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(String companyName) {
    return Container(
      width: 100, // زيادة العرض
      height: 50, // زيادة الارتفاع
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          companyName.split(' ').take(1).join(' '),
          style: const TextStyle(
            fontSize: 14, // زيادة حجم الخط
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Map<String, dynamic> _getCompanyData() {
    if (receiptModel.data.containsKey('Company') && receiptModel.data['Company'] is Map) {
      return Map<String, dynamic>.from(receiptModel.data['Company']);
    }
    return {};
  }

  String _getClientName() {
    final clientName = receiptModel.clientName;
    return (clientName?.isEmpty == true) ? 'عميل' : (clientName ?? 'عميل');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ر.س';
  }
}