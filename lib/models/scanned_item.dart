class ScannedItem {
  final String itemName;
  final double quantity;
  final String? unit;
  final String source; // "food_scan" or "receipt_scan"
  bool isReviewed;
  bool isEdited;

  ScannedItem({
    required this.itemName,
    required this.quantity,
    this.unit,
    required this.source,
    this.isReviewed = false,
    this.isEdited = false,
  });

  ScannedItem copyWith({
    String? itemName,
    double? quantity,
    String? unit,
    String? source,
    bool? isReviewed,
    bool? isEdited,
  }) {
    return ScannedItem(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      isReviewed: isReviewed ?? this.isReviewed,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  // For Firebase integration and easier UI display
  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      itemName: json['itemName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String?,
      source: json['source'] as String,
      isReviewed: json['isReviewed'] ?? false,
      isEdited: json['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'source': source,
      'isReviewed': isReviewed,
      'isEdited': isEdited,
    };
  }
}
