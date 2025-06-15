import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

class InventoryTile extends StatelessWidget {
  final String imageUrl;
  final String itemName;
  final String quantity;
  final String unit;
  final String category;
  final bool isSelected;
  final bool isOffline;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const InventoryTile({
    super.key,
    required this.imageUrl,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isSelected = false,
    this.isOffline = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? Colors.redAccent : Colors.black26,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported)),
                        )
                      : Icon(Icons.image, size: 38, color: Colors.grey[400]),
                ),
                const SizedBox(height: 10),
                Text(
                  itemName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$quantity $unit',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ).asGlass(
            tintColor: Colors.white.withOpacity(0.18),
            blurX: 7,
            blurY: 7,
            frosted: true,
            clipBorderRadius: BorderRadius.circular(18),
          ),
          if (isOffline)
            Positioned(
              top: 7,
              right: 9,
              child: Tooltip(
                message: "Not synced",
                child: Icon(Icons.cloud_off, color: Colors.redAccent, size: 21),
              ),
            ),
          if (isSelected)
            Positioned(
              top: 7,
              left: 9,
              child: Icon(Icons.check_circle, color: Colors.redAccent, size: 21),
            ),
        ],
      ),
    );
  }
}
