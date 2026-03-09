import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quick_access_model.dart';

class QuickAccessProvider extends ChangeNotifier {
  List<QuickAccessFolder> folders = [];
  List<QuickAccessFolder> history = []; // 👈 History ke liye

  static const String _key = "quick_access";
  static const String _historyKey = "quick_access_history";

  // ... (Baaki loadFolders, addFolder, removeFolder wahi rahenge)

  // 1. History load karne ka logic
  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    if (data != null) {
      List decoded = jsonDecode(data);
      history = decoded.map((e) => QuickAccessFolder.fromJson(e)).toList();
      notifyListeners();
    }
  }

  // 2. Folder open karte hi history mein add karna
  Future<void> addToHistory(QuickAccessFolder folder) async {
    // Purani history mein agar ye folder hai to pehle hatao (taaki top par aaye)
    history.removeWhere((f) => f.path == folder.path);

    // Naya folder top par add karo
    history.insert(0, folder);

    // Sirf top 5 ya 10 folders hi rakhein history mein
    if (history.length > 10) history.removeLast();
    print("Add history ${history.length}");

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(history.map((e) => e.toJson()).toList()));
    notifyListeners();

  }
  // QuickAccessProvider.dart ke andar

  Future<void> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('quick_access');

    if (data != null && data.isNotEmpty) {
      try {
        final List decoded = jsonDecode(data);
        folders = decoded.map((item) => QuickAccessFolder.fromJson(item)).toList();
      } catch (e) {
        debugPrint("Error decoding: $e");
        folders = [];
      }
    } else {
      folders = [];
    }
    notifyListeners();
  }

  Future<void> removeFolder(int index) async {
    // Safety check: index valid hai ya nahi
    if (index >= 0 && index < folders.length) {
      folders.removeAt(index);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quick_access', jsonEncode(folders.map((e) => e.toJson()).toList()));

      notifyListeners(); // UI ko batana zaroori hai
    }
  }
}