import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/models/item.dart';

// State: List of ScannedItems (mutable during a session)
class SmartScanController extends StateNotifier<List<ScannedItem>> {
  SmartScanController() : super([]);

  // Add a scanned item
  void addItem(ScannedItem item) {
    state = [...state, item];
  }

  // Add multiple scanned items at once 
  void addItems(List<ScannedItem> items) {
    state = [...state, ...items];
  }

  // Edit (replace) an item at index
  void editItem(int index, ScannedItem newItem) {
    final updatedList = [...state];
    updatedList[index] = newItem;
    state = updatedList;
  }

  // Remove item at index
  void removeItem(int index) {
    final updatedList = [...state]..removeAt(index);
    state = updatedList;
  }

  // Clear all items (e.g., on new scan session)
  void clearItems() {
    state = [];
  }
}

// Provider for accessing the controller in your widgets/screens
final smartScanControllerProvider =
    StateNotifierProvider<SmartScanController, List<ScannedItem>>(
  (ref) => SmartScanController(),
);
