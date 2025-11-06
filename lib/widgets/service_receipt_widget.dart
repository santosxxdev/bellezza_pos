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

  const ServiceReceiptWidget({
    super.key,
    required this.receiptModel,
    required this.printerIp,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 384,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              const Divider(thickness: 3),
              _buildInfoSection(),
              const SizedBox(height: 12),
              const Divider(thickness: 3),
              _buildServiceSection(),
              const SizedBox(height: 12),
              const Divider(thickness: 3),
              _buildSpecialistSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final companyData = _getCompanyData();
    final companyName = companyData['ar'] ?? receiptModel.vendorBranchName ?? 'المتجر';
    final companyLocation = companyData['location'];
    final imageUrl = companyData['imageUrl'];

    return Column(
      children: [
        if (imageUrl != null && imageUrl.toString().isNotEmpty)
          SizedBox(
            height: 80,
            child: Center(
              child: _buildCompanyLogo(_getFullImageUrl(imageUrl), companyName),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          companyName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (companyLocation != null)
          Text(
            'العنوان: $companyLocation',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue[50],
          ),
          child: const Text(
            'فاتورة خدمة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final receiptCode = receiptModel.receiptCode ?? 'N/A';
    final date = _formatDate(receiptModel.receiveDate);
    final cashier = receiptModel.cashierName ?? 'غير محدد';
    final client = receiptModel.clientName ?? 'عميل';
    final phone = receiptModel.clientPhone ?? 'غير متوفر';
    final branch = receiptModel.vendorBranchName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('معلومات الخدمة', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildRow('رقم الفاتورة', receiptCode),
        _buildRow('التاريخ', date),
        _buildRow('الكاشير', cashier),
        _buildRow('العميل', client),
        _buildRow('هاتف العميل', phone),
        _buildRow('الفرع', branch),
      ],
    );
  }

  Widget _buildServiceSection() {
    // هنا نعرض أول منتج من orderDetails كمثال للخدمة
    final items = receiptModel.orderDetails[printerIp] ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;

    if (firstItem == null) {
      return const Text(
        'لا توجد بيانات خدمة متاحة.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('تفاصيل الخدمة', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildRow('اسم الخدمة', firstItem.name),
        _buildRow('الكمية', '${firstItem.quantity}'),
        _buildRow('سعر الخدمة', _formatCurrency(firstItem.price)),
        _buildRow('رسوم الحجز', _formatCurrency(firstItem.reservationFee)),
        _buildRow('الإجمالي', _formatCurrency(firstItem.total)),
      ],
    );
  }

  Widget _buildSpecialistSection() {
    final items = receiptModel.orderDetails[printerIp] ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final specialist = firstItem?.specialistName ?? receiptModel.specialistName ?? 'غير محدد';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('المتخصص المسؤول', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(specialist, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.green)),
      ],
    );
  }

  // ===== دوال مساعدة =====

  Widget _buildRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(value, style: const TextStyle(fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Map<String, dynamic> _getCompanyData() {
    if (receiptModel.data.containsKey('Company') && receiptModel.data['Company'] is Map) {
      return Map<String, dynamic>.from(receiptModel.data['Company']);
    }
    return {};
  }

  String _formatCurrency(double amount) => '${amount.toStringAsFixed(2)} ر.س';

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  String _getFullImageUrl(String imagePath) {
    final baseUrl = SharedPreferencesService.getBaseUrl();
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/')) return '$baseUrl${imagePath.substring(1)}';
    return '$baseUrl$imagePath';
  }

  Widget _buildCompanyLogo(String url, String name) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) => Text(name, style: const TextStyle(fontSize: 14)),
    );
  }
}
