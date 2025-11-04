class ReceiptModel {
  final Map<String, dynamic> data;

  ReceiptModel({required this.data});

  // الحقول الرئيسية للفاتورة
  String? get printerIp => data['printerIp']?.toString();
  int get daySerialNumber => (data['daySerialNumber'] ?? 0).toInt();
  double get totalReturn => (data['totalReturn'] ?? 0).toDouble();
  double get tax => (data['tax'] ?? 0).toDouble();
  double get deliveryFee => (data['deliveryFee'] ?? 0).toDouble();
  double get discountPercent => (data['discountPercent'] ?? 0).toDouble();
  double get discountTotal => (data['discountTotal'] ?? 0).toDouble();
  double get subtotal => (data['subtotal'] ?? 0).toDouble();
  double get total => (data['total'] ?? 0).toDouble();
  double get totalItemsPrice => (data['totalItemsPrice'] ?? 0).toDouble();
  double get totalItemsBuyPrice => (data['totalItemsBuyPrice'] ?? 0).toDouble();
  double get finalTotalItemsPrice => (data['finalTotalItemsPrice'] ?? 0).toDouble();

  String? get openDay => data['openDay']?.toString();
  String? get receiptCode => data['code']?.toString();
  double get totalAfterDiscount => (data['totalAfterDiscount'] ?? total).toDouble();
  double get cash => (data['cash'] ?? 0).toDouble();
  double get card => (data['card'] ?? 0).toDouble();
  String? get receiveDate => data['recieveDate']?.toString();
  String? get orderStatusName => data['orderStatusName']?.toString();
  String? get clientName => data['clientName']?.toString();
  String? get clientPhone => data['clientPhoneNumber']?.toString();
  String? get cashierName => data['cashierName']?.toString();
  String? get specialistName => data['specialistName']?.toString();
  String? get vendorBranchName => data['vendorBranchName']?.toString();
  String? get vendorName => data['vendorName']?.toString();
  String? get paymethodName => data['paymethodName']?.toString();
  String? get orderTypeName => data['orderTypeName']?.toString();
  String? get giftPhoneNumber => data['giftPhoneNumber']?.toString();
  String? get location => data['location']?.toString();
  String? get qrCodeData => data['qrCodeData']?.toString();

  // التفاصيل حسب كل طابعة
  Map<String, List<ProductItem>> get orderDetails {
    final Map<String, List<ProductItem>> result = {};
    final details = data['orderDetails'] as Map<String, dynamic>?;

    if (details != null) {
      details.forEach((printerIp, items) {
        if (items is List) {
          result[printerIp] = items
              .map((item) => ProductItem.fromMap(item as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return result;
  }
}

class ProductItem {
  final String name;
  final int quantity;
  final double price;
  final double total;
  final double reservationFee;
  final String? reservationDate;
  final String? specialistName;
  final String? printerName;
  final String? printerIp;
  final String? hallName;
  final String? itemColor;
  final int? id;

  ProductItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.reservationFee = 0,
    this.reservationDate,
    this.specialistName,
    this.printerName,
    this.printerIp,
    this.hallName,
    this.itemColor,
    this.id,
  });

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      name: map['itemName']?.toString() ?? 'منتج',
      quantity: (map['quantity'] ?? 0).toInt(),
      price: (map['itemPrice'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      reservationFee: (map['reservationFee'] ?? 0).toDouble(),
      reservationDate: map['reservationDate']?.toString(),
      specialistName: map['specialistName']?.toString(),
      printerName: map['printerName']?.toString(),
      printerIp: map['printerIp']?.toString(),
      hallName: map['hallName']?.toString(),
      itemColor: map['itemColor']?.toString(),
      id: (map['id'] ?? 0).toInt(),
    );
  }
}
