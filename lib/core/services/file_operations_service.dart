import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class FileOperationsService {
  static final FileOperationsService _instance = FileOperationsService._internal();
  factory FileOperationsService() => _instance;
  FileOperationsService._internal();

  /// Perform file operations in isolate to avoid blocking UI
  Future<List<FileSystemEntity>> listDirectoryFiles(String path, {bool recursive = false}) async {
    return await compute(_listDirectoryIsolate, {
      'path': path,
      'recursive': recursive,
    });
  }

  /// Copy files asynchronously with progress callback
  Future<void> copyFiles(List<File> files, String destination, {Function(int, int)? onProgress}) async {
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final newPath = p.join(destination, p.basename(file.path));
      
      try {
        await file.copy(newPath);
      } catch (e) {
        debugPrint('Error copying ${file.path}: $e');
      }
      
      onProgress?.call(i + 1, files.length);
    }
  }

  /// Move files asynchronously with progress callback
  Future<void> moveFiles(List<FileSystemEntity> files, String destination, {Function(int, int)? onProgress}) async {
    for (int i = 0; i < files.length; i++) {
      final entity = files[i];
      final newPath = p.join(destination, p.basename(entity.path));
      
      try {
        if (entity is File) {
          await entity.rename(newPath);
        } else if (entity is Directory) {
          await _copyDirectory(entity, Directory(newPath));
          await entity.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('Error moving ${entity.path}: $e');
      }
      
      onProgress?.call(i + 1, files.length);
    }
  }

  /// Delete files asynchronously with progress callback
  Future<void> deleteFiles(List<FileSystemEntity> files, {Function(int, int)? onProgress}) async {
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      
      try {
        if (await file.exists()) {
          await file.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('Error deleting ${file.path}: $e');
      }
      
      onProgress?.call(i + 1, files.length);
    }
  }

  /// Get directory size asynchronously
  Future<int> getDirectorySize(String path) async {
    return await compute(_getDirectorySizeIsolate, path);
  }

  /// Search files with pattern matching
  Future<List<FileSystemEntity>> searchFiles(String rootPath, String query) async {
    return await compute(_searchFilesIsolate, {
      'rootPath': rootPath,
      'query': query.toLowerCase(),
    });
  }

  // Isolate functions
  static Future<List<FileSystemEntity>> _listDirectoryIsolate(Map<String, dynamic> params) async {
    final path = params['path'] as String;
    final recursive = params['recursive'] as bool;
    
    try {
      final directory = Directory(path);
      if (!await directory.exists()) return [];
      
      final files = <FileSystemEntity>[];
      await for (final entity in directory.list(recursive: recursive, followLinks: false)) {
        files.add(entity);
      }
      
      // Sort: directories first, then by name
      files.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      
      return files;
    } catch (e) {
      return [];
    }
  }

  static Future<int> _getDirectorySizeIsolate(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // Skip files that can't be accessed
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<FileSystemEntity>> _searchFilesIsolate(Map<String, dynamic> params) async {
    final rootPath = params['rootPath'] as String;
    final query = params['query'] as String;
    
    try {
      final directory = Directory(rootPath);
      if (!await directory.exists()) return [];
      
      final results = <FileSystemEntity>[];
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        final name = p.basename(entity.path).toLowerCase();
        if (name.contains(query)) {
          results.add(entity);
        }
      }
      
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false, followLinks: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }
}
