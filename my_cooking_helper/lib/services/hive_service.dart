import 'package:hive/hive.dart';

class HiveService {
  static Future<Box> openInventoryBox() async => await Hive.openBox('inventoryBox');

  static Future<void> saveItem(Map<String, dynamic> item) async {
    final box = await openInventoryBox();
    await box.put(item['id'], item);
  }

  static Future<void> deleteItem(String id) async {
    final box = await openInventoryBox();
    await box.delete(id);
  }

  static List<Map<String, dynamic>> getAll() {
    final box = Hive.box('inventoryBox');
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
