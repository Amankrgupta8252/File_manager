// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../models/quick_access_model.dart';
//
// class QuickAccessProvider extends ChangeNotifier {
//   List<QuickAccessFolder> folders = [];
//   List<QuickAccessFolder> history = [];
//
//   static const String _folderKey = "quick_access";
//   static const String _historyKey = "quick_access_history";
//
//   // --- LOAD FOLDERS ---
//   Future<void> loadFolders() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final data = prefs.getString(_folderKey);
//
//       if (data != null && data.isNotEmpty) {
//         List decoded = jsonDecode(data);
//         // Map karte waqt safety check
//         folders = decoded.map((e) => QuickAccessFolder.fromJson(e)).toList();
//       } else {
//         folders = [];
//       }
//     } catch (e) {
//       debugPrint("Error loading folders: $e");
//       folders = [];
//     }
//     notifyListeners();
//   }
//
//   // --- REMOVE FOLDER (With Safety Check) ---
//   Future<void> removeFolder(int index) async {
//     try {
//       // Check index range taaki "RangeError" na aaye
//       if (index >= 0 && index < folders.length) {
//         folders.removeAt(index);
//
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString(
//           _folderKey,
//           jsonEncode(folders.map((e) => e.toJson()).toList()),
//         );
//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint("Error removing folder: $e");
//     }
//   }
//
//   // --- ADD FOLDER ---
//   Future<void> addFolder(String name, String path) async {
//     bool exists = folders.any((f) => f.path == path);
//     if (!exists) {
//       folders.add(QuickAccessFolder(name: name, path: path));
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_folderKey, jsonEncode(folders.map((e) => e.toJson()).toList()));
//       notifyListeners();
//     }
//   }
//
//   // --- HISTORY LOGIC (Load & Add) ---
//   Future<void> loadHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     final data = prefs.getString(_historyKey);
//     if (data != null) {
//       List decoded = jsonDecode(data);
//       history = decoded.map((e) => QuickAccessFolder.fromJson(e)).toList();
//       notifyListeners();
//     }
//   }
//
//   Future<void> addToHistory(QuickAccessFolder folder) async {
//     history.removeWhere((f) => f.path == folder.path);
//     history.insert(0, folder);
//     if (history.length > 10) history.removeLast();
//
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_historyKey, jsonEncode(history.map((e) => e.toJson()).toList()));
//     notifyListeners();
//   }
// }