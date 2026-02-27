import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_storage_info/flutter_storage_info.dart';

class StorageProvider extends ChangeNotifier {

  static const MethodChannel _channel =
  MethodChannel('storage_channel');


  List<FileSystemEntity> allFiles = [];
  List<FileSystemEntity> filteredFiles = [];

  String searchQuery = "";

// Internal Storage
  double marketedTotalGB = 0.0;
  double usableTotalGB = 0.0;
  double usedGB = 0.0;
  double freeGB = 0.0;
  double systemGB = 0.0;
  double usedMarketedGB = 0.0;
  // SD Card
  double marketedSDGB = 0.0;
  double sdTotalGB = 0.0;
  double sdUsedGB = 0.0;
  double sdFreeGB = 0.0;

  String? sdCardPath;

  bool isLoading = true;
  bool hasSDCard = false;

  StorageProvider() {
    initStorage();
  }

  Future<void> initStorage() async {
    await updateStorage();
    await detectSDCardNative();   // ✅ correct call
  }

  double detectMarketedSize(double usable) {
    if (usable <= 30) return 32;
    if (usable <= 60) return 64;
    if (usable <= 120) return 128;
    if (usable <= 250) return 256;
    if (usable <= 500) return 512;
    if (usable <= 1000) return 1024;
    return usable;
  }
  double detectMarketedSdSize(double usable) {
    if (usable <= 16.5) return 16;
    if (usable <= 30) return 32;
    if (usable <= 60) return 64;
    if (usable <= 120) return 128;
    if (usable <= 250) return 256;
    if (usable <= 500) return 512;
    if (usable <= 1000) return 1024;
    return usable;
  }

  Future<void> updateStorage() async {
    isLoading = true;
    notifyListeners();

    try {
      const gb = 1024 * 1024 * 1024;

      final totalBytes = await FlutterStorageInfo.storageTotalSpace;
      final usedBytes = await FlutterStorageInfo.storageUsedSpace;

      usableTotalGB = totalBytes / gb;
      usedGB = usedBytes / gb;
      freeGB = usableTotalGB - usedGB;

      marketedTotalGB = detectMarketedSize(usableTotalGB);

      systemGB = marketedTotalGB - usableTotalGB;
      usedMarketedGB = systemGB + usedGB;

      usableTotalGB = double.parse(usableTotalGB.toStringAsFixed(2));
      usedGB = double.parse(usedGB.toStringAsFixed(2));
      freeGB = double.parse(freeGB.toStringAsFixed(2));
      systemGB = double.parse(systemGB.toStringAsFixed(2));

      print("Usable Total: $usableTotalGB GB");
      print("Used: $usedGB GB");
      print("Free: $freeGB GB");
      print("System: $systemGB GB");
      print("Marketed Total: $marketedTotalGB GB");
      print("Used Marketed: $usedMarketedGB GB");

    } catch (e) {
      debugPrint("Storage Error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // ✅ Native Android SD detection
  Future<void> detectSDCardNative() async {
    try {
      final Map? result =
      await _channel.invokeMethod('getSDCard');

      if (result != null) {
        hasSDCard = true;
        sdCardPath = result['path'];

        const gb = 1024 * 1024 * 1024;

        double realTotal =
            (result['total'] as int) / gb;
        double realFree =
            (result['free'] as int) / gb;
        double realUsed =
            (result['used'] as int) / gb;

        // Round real values
        realTotal = double.parse(realTotal.toStringAsFixed(2));
        realUsed = double.parse(realUsed.toStringAsFixed(2));
        realFree = double.parse(realFree.toStringAsFixed(2));

        print("Real Total: $realTotal GB");
        print("Real Used: $realUsed GB");
        print("Real Free: $realFree GB");

        // Set actual usable values
        sdTotalGB = realTotal;
        sdUsedGB = realUsed;
        sdFreeGB = realFree;

        marketedSDGB = detectMarketedSdSize(realTotal);

        print("Marketed SD: $marketedSDGB GB");


        print("SD Real Total: $sdTotalGB GB");
        print("SD Used: $sdUsedGB GB");
        print("SD Free: $sdFreeGB GB");
      } else {
        hasSDCard = false;
        sdCardPath = null;
      }

    } catch (e) {
      print("Native SD Error: $e");
      hasSDCard = false;
    }

    notifyListeners();
  }

  /// search bar
  Future<void> fullDeviceSearch() async {
    filteredFiles.clear();
    notifyListeners();

    List<String> roots = [];

    // Internal storage
    roots.add("/storage/emulated/0");

    // SD card
    if (hasSDCard && sdCardPath != null) {
      roots.add(sdCardPath!);
    }

    for (String rootPath in roots) {
      final rootDir = Directory(rootPath);

      if (await rootDir.exists()) {
        await _searchDirectory(rootDir);
      }
    }

    notifyListeners();
  }

  Future<void> _searchDirectory(Directory dir) async {
    try {
      await for (FileSystemEntity entity
      in dir.list(followLinks: false)) {

        final path = entity.path.toLowerCase();

        // 🔒 Skip restricted folders
        if (path.contains("/android/data") ||
            path.contains("/android/obb")) {
          continue;
        }

        final name = path.split('/').last;

        if (searchQuery.isNotEmpty &&
            name.contains(searchQuery.toLowerCase())) {
          filteredFiles.add(entity);
        }

        // Recursive call for directories
        if (entity is Directory) {
          await _searchDirectory(entity);
        }
      }
    } catch (e) {
      // 👇 Permission denied folders automatically skip
      print("Skipped folder: ${dir.path}");
    }
  }

  void searchFiles(String query) {
    searchQuery = query;

    if (query.isEmpty) {
      filteredFiles.clear();
      notifyListeners();
      return;
    }

    fullDeviceSearch();
  }


}