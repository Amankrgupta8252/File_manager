import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class FileCacheService {
  static final FileCacheService _instance = FileCacheService._internal();
  factory FileCacheService() => _instance;
  FileCacheService._internal();

  final Map<String, CachedData> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const int _maxCacheSize = 1000;

  /// Cache file metadata to avoid repeated system calls
  void cacheFiles(String directory, List<FileSystemEntity> files) {
    final key = _normalizePath(directory);
    _cache[key] = CachedData(
      files: files,
      timestamp: DateTime.now(),
      size: files.length,
    );
    
    _cleanupCache();
  }

  /// Get cached files if still valid
  List<FileSystemEntity>? getCachedFiles(String directory) {
    final key = _normalizePath(directory);
    final cached = _cache[key];
    
    if (cached == null) return null;
    
    if (DateTime.now().difference(cached.timestamp) > _cacheExpiry) {
      _cache.remove(key);
      return null;
    }
    
    return cached.files;
  }

  /// Cache file size to avoid repeated length() calls
  void cacheFileSize(String filePath, int size) {
    final key = _normalizePath(filePath);
    _cache['size:$key'] = CachedData(
      size: size,
      timestamp: DateTime.now(),
    );
  }

  int? getCachedFileSize(String filePath) {
    final key = _normalizePath(filePath);
    final cached = _cache['size:$key'];
    
    if (cached == null) return null;
    if (DateTime.now().difference(cached.timestamp) > _cacheExpiry) {
      _cache.remove('size:$key');
      return null;
    }
    
    return cached.size;
  }

  /// Clear cache for specific directory
  void invalidateDirectory(String directory) {
    final key = _normalizePath(directory);
    _cache.remove(key);
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
  }

  String _normalizePath(String path) {
    return p.normalize(path);
  }

  void _cleanupCache() {
    if (_cache.length <= _maxCacheSize) return;
    
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
    
    final toRemove = sortedEntries.take(_cache.length - _maxCacheSize);
    for (final entry in toRemove) {
      _cache.remove(entry.key);
    }
  }
}

class CachedData {
  final List<FileSystemEntity>? files;
  final DateTime timestamp;
  final int size;

  CachedData({
    this.files,
    required this.timestamp,
    required this.size,
  });
}
