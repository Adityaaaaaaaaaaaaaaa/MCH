class ScannedItem {
  final String itemName;
  final double quantity;
  final String? unit;
  final String source; // "food_scan" or "receipt_scan" or "manual_entry"
  final String? category; // Optional
  final String? nutritionId; // Optional, for future
  final String? imageUrl; // Optional, for future, maybe we will not have it or use it
  bool isReviewed;
  bool isEdited;

  ScannedItem({
    required this.itemName,
    required this.quantity,
    this.unit,
    required this.source,
    this.category,
    this.nutritionId,
    this.imageUrl,
    this.isReviewed = false,
    this.isEdited = false,
  });

  ScannedItem copyWith({
    String? itemName,
    double? quantity,
    String? unit,
    String? source,
    String? category,
    String? nutritionId,
    String? imageUrl,
    DateTime? expiryDate,
    bool? isReviewed,
    bool? isEdited,
  }) {
    return ScannedItem(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      category: category ?? this.category,
      nutritionId: nutritionId ?? this.nutritionId,
      imageUrl: imageUrl ?? this.imageUrl,
      isReviewed: isReviewed ?? this.isReviewed,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      itemName: json['itemName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String?,
      source: json['source'] as String,
      category: json['category'] as String?,
      nutritionId: json['nutritionId'] as String?,
      imageUrl: json['imageUrl'] as String?,
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
      'category': category,
      'nutritionId': nutritionId,
      'imageUrl': imageUrl,
      'isReviewed': isReviewed,
      'isEdited': isEdited,
    };
  }
}
