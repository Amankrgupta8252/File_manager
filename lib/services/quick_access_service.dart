import 'package:shared_preferences/shared_preferences.dart';

class QuickAccessService {
  static const String _key = 'quick_access_paths';

  // Folder history save karega
  static Future<void> trackFolder(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    history.remove(path); // duplicate remove
    history.insert(0, path); // top par add

    if (history.length > 6) {
      history = history.sublist(0, 6); // max 6 folders
    }

    await prefs.setStringList(_key, history);
  }

  // UI me folders lane ke liye
  static Future<List<String>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}