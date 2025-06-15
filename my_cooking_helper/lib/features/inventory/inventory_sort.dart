import 'package:flutter/material.dart';

class InventorySortBar extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onSort;
  const InventorySortBar({super.key, required this.sortBy, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text("Sort by:", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: sortBy,
          onChanged: (value) {
            if (value != null) {
              onSort(value);
            }
          },
          items: const [
            DropdownMenuItem(value: "default", child: Text("Default")),
            DropdownMenuItem(value: "name", child: Text("Name")),
            DropdownMenuItem(value: "quantity", child: Text("Quantity")),
            DropdownMenuItem(value: "category", child: Text("Category")),
          ],
        ),
      ],
    );
  }
}
