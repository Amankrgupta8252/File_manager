import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_storage_info/flutter_storage_info.dart';
import '../services/file_cache_service.dart';
import '../services/file_operations_service.dart';

class OptimizedStorageProvider extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('storage_channel');
  
  final FileCacheService _cache = FileCacheService();
  final FileOperationsService _fileOps = FileOperationsService();

  List<FileSystemEntity> allFiles = [];
  List<FileSystemEntity> filteredFiles = [];
  String searchQuery = "";
  bool isSearching = false;

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

  List<FileSystemEntity> sdFiles = [];

  OptimizedStorageProvider() {
    Future.delayed(const Duration(seconds: 1), () {
      initStorage();
    });
  }

  Future<void> initStorage() async {
    await updateStorage();
    await detectSDCardNative();

    isLoading = false;
    notifyListeners();
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
    } catch (e) {
      debugPrint("Storage Error: $e");
    }
  }

  Future<void> fetchSdCardFiles() async {
    if (!hasSDCard || sdCardPath == null) return;
    
    try {
      // Check cache first
      final cachedFiles = _cache.getCachedFiles(sdCardPath!);
      if (cachedFiles != null) {
        sdFiles = cachedFiles;
        notifyListeners();
        return;
      }
      
      sdFiles = await _fileOps.listDirectoryFiles(sdCardPath!);
      
      // Cache the results
      _cache.cacheFiles(sdCardPath!, sdFiles);
    } catch (e) {
      debugPrint("SD Card Files Error: $e");
    }
    notifyListeners();
  }

  Future<void> detectSDCardNative() async {
    try {
      final Map? result = await _channel.invokeMethod('getSDCard');
      if (result != null) {
        hasSDCard = true;
        sdCardPath = result['path'];
        const gb = 1024 * 1024 * 1024;

        double realTotal = (result['total'] as int) / gb;
        double realFree = (result['free'] as int) / gb;
        double realUsed = (result['used'] as int) / gb;

        sdTotalGB = double.parse(realTotal.toStringAsFixed(2));
        sdUsedGB = double.parse(realUsed.toStringAsFixed(2));
        sdFreeGB = double.parse(realFree.toStringAsFixed(2));
        marketedSDGB = detectMarketedSdSize(realTotal);
      } else {
        hasSDCard = false;
        sdCardPath = null;
      }
    } catch (e) {
      debugPrint("Native SD Error: $e");
      hasSDCard = false;
    }
  }

  Future<void> fullDeviceSearch() async {
    isSearching = true;
    notifyListeners();
    
    filteredFiles.clear();
    List<String> roots = ["/storage/emulated/0"];
    if (hasSDCard && sdCardPath != null) roots.add(sdCardPath!);

    try {
      final results = <FileSystemEntity>[];
      
      for (String rootPath in roots) {
        final searchResults = await _fileOps.searchFiles(rootPath, searchQuery);
        results.addAll(searchResults);
      }
      
      filteredFiles = results;
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void searchFiles(String query) {
    searchQuery = query;
    if (query.isEmpty) {
      filteredFiles.clear();
      isSearching = false;
      notifyListeners();
      return;
    }
    fullDeviceSearch();
  }
  
  /// Get cached directory files or fetch them
  Future<List<FileSystemEntity>> getDirectoryFiles(String path) async {
    final cachedFiles = _cache.getCachedFiles(path);
    if (cachedFiles != null) {
      return cachedFiles;
    }
    
    final files = await _fileOps.listDirectoryFiles(path);
    _cache.cacheFiles(path, files);
    return files;
  }
  
  /// Invalidate cache for directory
  void invalidateDirectoryCache(String path) {
    _cache.invalidateDirectory(path);
  }
  
  /// Get directory size with caching
  Future<int> getDirectorySize(String path) async {
    return await _fileOps.getDirectorySize(path);
  }
}
