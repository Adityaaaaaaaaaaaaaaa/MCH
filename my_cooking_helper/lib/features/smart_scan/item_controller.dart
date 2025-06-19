import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/models/item.dart';

class SmartScanController extends StateNotifier<List<ScannedItem>> {
  SmartScanController() : super([]);

  void addItem(ScannedItem item) {
    state = [...state, item];
  }

  // Add multiple scanned items at once 
  void addItems(List<ScannedItem> items) {
    state = [...state, ...items];
  }

  void editItem(int index, ScannedItem newItem) {
    final updatedList = [...state];
    updatedList[index] = newItem;
    state = updatedList;
  }

  void removeItem(int index) {
    final updatedList = [...state]..removeAt(index);
    state = updatedList;
  }

  // Clear all items 
  void clearItems() {
    state = [];
  }
}

// Provider for accessing the controller 
final smartScanControllerProvider =
    StateNotifierProvider<SmartScanController, List<ScannedItem>>(
  (ref) => SmartScanController(),
);
