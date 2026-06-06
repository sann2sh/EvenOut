class ParsedItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  ParsedItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory ParsedItem.fromJson(Map<String, dynamic> json) {
    return ParsedItem(
      name: json['name'] as String? ?? 'Unknown Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ParsedReceipt {
  final String? receiptType;
  final String? merchant;
  final String? date;
  final double total;
  final List<ParsedItem> items;
  final String? paymentMethod;
  final String? billNumber;
  final String? confidence;

  ParsedReceipt({
    this.receiptType,
    this.merchant,
    this.date,
    required this.total,
    required this.items,
    this.paymentMethod,
    this.billNumber,
    this.confidence,
  });

  factory ParsedReceipt.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;
    final itemsList = itemsJson != null
        ? itemsJson.map((item) => ParsedItem.fromJson(item as Map<String, dynamic>)).toList()
        : <ParsedItem>[];

    return ParsedReceipt(
      receiptType: json['receipt_type'] as String?,
      merchant: json['merchant'] as String?,
      date: json['date'] as String?,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      items: itemsList,
      paymentMethod: json['payment_method'] as String?,
      billNumber: json['bill_number'] as String?,
      confidence: json['confidence'] as String?,
    );
  }
}
