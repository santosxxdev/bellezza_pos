import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/receipt_model.dart';
import '../services/shared_preferences_service.dart';

class ReceiptWidget extends StatelessWidget {
  final ReceiptModel receiptModel;

  const ReceiptWidget({super.key, required this.receiptModel});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: 192,
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderWithLogo(),
                const SizedBox(height: 12),
                const Divider(thickness: 3, color: Colors.black),
                _buildInvoiceInfo(),
                const SizedBox(height: 12),
                const Divider(thickness: 2, color: Colors.black),
                _buildProductsTable(),
                const SizedBox(height: 12),
                const Divider(thickness: 3, color: Colors.black),
                _buildTotalsSection(),
                const SizedBox(height: 12),
                _buildQrCodeSection(),
                const SizedBox(height: 12),
                const Divider(thickness: 3, color: Colors.black),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeaderWithLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_getCompanyData()['imageUrl'] != null && _getCompanyData()['imageUrl'].toString().isNotEmpty)
          Container(
            height: 60, // تم تصغير حجم اللوجو
            child: Center(
              child: _buildCompanyLogo(
                  _getFullImageUrl(_getCompanyData()['imageUrl']),
                  _getCompanyData()['ar'] ?? receiptModel.vendorBranchName ?? 'المتجر'
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          _getCompanyData()['ar'] ?? receiptModel.vendorBranchName ?? 'المتجر',
          style: const TextStyle(
            fontSize: 18, // تم تصغير الخط
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (_getCompanyData()['location'] != null)
          Text(
            'العنوان: ${_getCompanyData()['location']}',
            style: const TextStyle(
              fontSize: 14, // تم تصغير الخط
              height: 1.2,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: const Text(
            'فاتورة ضريبية مبسطة',
            style: TextStyle(
              fontSize: 16, // تم تصغير الخط
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
      width: 100, // تم تصغير الحجم
      height: 40,
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
        final filePath = '${directory.path}/company_logo_${companyName.hashCode}.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_logo_path', filePath);
        await prefs.setString('cached_logo_url', imageUrl);
        return filePath;
      }
    } catch (e) {
      print("خطأ في تحميل الصورة: $e");
    }
    return null;
  }

  Widget _buildLogoImage(File imageFile, String companyName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100, // تم تصغير الحجم
          height: 40,
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
        ),
      ],
    );
  }

  Widget _buildNetworkLogoWithCache(String imageUrl, String companyName) {
    _downloadAndCacheLogo(imageUrl, companyName);
    return Container(
      width: 100, // تم تصغير الحجم
      height: 40,
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
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          companyName.split(' ').take(2).join(' '),
          style: const TextStyle(
            fontSize: 12, // تم تصغير الخط
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


  Widget _buildInvoiceInfo() {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'معلومات الفاتورة',
              style: TextStyle(
                fontSize: 18, // حجم أصغر للمعلومات
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 8),
            _buildInfoRow('رقم الفاتورة', '${receiptModel.receiptCode ?? "N/A"}'),
            _buildInfoRow('التاريخ', _formatDate(receiptModel.receiveDate ?? receiptModel.openDay)),
            const SizedBox(height: 6),
            _buildDualInfoRow(
              label1: 'الكاشير',
              value1: receiptModel.cashierName ?? 'N/A',
              label2: 'المتخصص',
              value2: receiptModel.specialistName ?? 'N/A',
            ),
            _buildInfoRow('العميل', _getClientName()),
            if (receiptModel.clientPhone != null && receiptModel.clientPhone!.isNotEmpty)
              _buildInfoRow('هاتف العميل', receiptModel.clientPhone!),
            _buildDualInfoRow(
              label1: 'الفرع',
              value1: receiptModel.vendorBranchName ?? '',
              label2: 'طريقة الدفع',
              value2: receiptModel.paymethodName ?? 'نقدي',
            ),
            // تم إزالة حالة الطلب كما طلبت
            if (receiptModel.orderTypeName != null)
              _buildInfoRow('نوع الطلب', receiptModel.orderTypeName!),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable() {
    final allProducts = receiptModel.orderDetails.values.expand((e) => e).toList();

    if (allProducts.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد عناصر',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'الخدمات',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.black, width: 1)),
                  ),
                  child: const Text(
                    'المنتج / الخدمة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.black, width: 1)),
                  ),
                  child: const Text(
                    'الكمية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.black, width: 1)),
                  ),
                  child: const Text(
                    'السعر',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: const Text(
                    'الإجمالي',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < allProducts.length; i++)
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: const BorderSide(color: Colors.black, width: 1),
                right: const BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(
                  color: i == allProducts.length - 1 ? Colors.black : Colors.grey.shade400,
                  width: i == allProducts.length - 1 ? 2 : 1,
                ),
              ),
              color: i.isEven ? Colors.white : Colors.grey[50],
            ),
            child: _buildProductRow(allProducts[i]),
          ),
      ],
    );
  }

  Widget _buildProductRow(ProductItem product) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.black, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.hallName != null && product.hallName!.isNotEmpty)
                  Text(
                    'الصالة: ${product.hallName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                  ),
                if (product.reservationDate != null)
                  Text(
                    'موعد: ${_formatDate(product.reservationDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                  ),
                if (product.reservationFee > 0)
                  Text(
                    'حجز: ${_formatCurrency(product.reservationFee)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.black, width: 1)),
            ),
            child: Text(
              '${product.quantity}',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.black, width: 1)),
            ),
            child: Text(
              _formatCurrency(product.price),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(
              _formatCurrency(product.total),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          _buildTotalRow('المجموع', _formatCurrency(receiptModel.subtotal)),
          if (receiptModel.discountPercent > 0)
            _buildTotalRow('نسبة الخصم', '${receiptModel.discountPercent}%'),
          if (receiptModel.discountTotal > 0)
            _buildTotalRow('قيمة الخصم', _formatCurrency(receiptModel.discountTotal)),
          if (receiptModel.deliveryFee > 0)
            _buildTotalRow('رسوم التوصيل', _formatCurrency(receiptModel.deliveryFee)),
          _buildTotalRow('الضريبة', _formatCurrency(receiptModel.tax)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _buildTotalRow(
              'المبلغ المستحق',
              _formatCurrency(receiptModel.totalAfterDiscount),
              isTotal: true,
            ),
          ),
          const SizedBox(height: 8),
          _buildTotalRow('طريقة الدفع', receiptModel.paymethodName ?? 'نقدي'),
          if (receiptModel.cash > 0) _buildTotalRow('المبلغ النقدي', _formatCurrency(receiptModel.cash)),
          if (receiptModel.card > 0) _buildTotalRow('المبلغ بالبطاقة', _formatCurrency(receiptModel.card)),
          if (receiptModel.giftPhoneNumber != null && receiptModel.giftPhoneNumber!.isNotEmpty)
            _buildTotalRow('رقم الهدية', receiptModel.giftPhoneNumber!),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection() {
    if (receiptModel.qrCodeData == null || receiptModel.qrCodeData!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'رمز الاستعلام',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          QrImageView(
            data: receiptModel.qrCodeData!,
            version: QrVersions.auto,
            size: 90.0, // تم تصغير حجم الـ QR
            foregroundColor: Colors.black,
          ),
          const SizedBox(height: 8),
          Text(
            receiptModel.qrCodeData!,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final companyData = _getCompanyData();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // معلومات الاتصال
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (companyData['phoneNumber'] != null)
                Text(
                  'هاتف: ${companyData['phoneNumber']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              if (companyData['location'] != null)
                Text(
                  'العنوان: ${companyData['location']}',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (companyData['taxnumber'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'الرقم الضريبي: ${companyData['taxnumber']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // سياسة الاسترجاع والاستبدال
        if (companyData['description'] != null || companyData['cancellationPolicy'] != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'سياسة الاسترجاع والاستبدال',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (companyData['description'] != null)
                  Text(
                    companyData['description']!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (companyData['cancellationPolicy'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    companyData['cancellationPolicy']!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 10),

        // رسالة شكر
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(6),
            color: Colors.green[50],
          ),
          child: const Column(
            children: [
              Text(
                'شكراً لثقتكم بنا',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2),
              Text(
                'نرحب بزيارتكم دائماً',
                style: TextStyle(fontSize: 14, color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // معلومات إضافية
        Text(
          'رقم السيريال: ${receiptModel.daySerialNumber}',
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Map<String, dynamic> _getCompanyData() {
    if (receiptModel.data.containsKey('Company') && receiptModel.data['Company'] is Map) {
      return Map<String, dynamic>.from(receiptModel.data['Company']);
    }
    return {};
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualInfoRow({
    required String label1,
    required String value1,
    required String label2,
    required String value2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$label1: ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: value1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$label2: ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: value2,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? Colors.black : Colors.grey[800],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? Colors.black : Colors.grey[800],
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
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