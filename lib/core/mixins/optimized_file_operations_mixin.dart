import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../services/file_operations_service.dart';
import '../services/file_cache_service.dart';
import '../../utils/data/file_storage_provider.dart';

mixin OptimizedFileOperationsMixin<T> on State<StatefulWidget> {
  bool isSelectionMode = false;
  Set<T> selectedItems = {};
  bool isOperationInProgress = false;
  
  final FileOperationsService _fileOps = FileOperationsService();
  final FileCacheService _cache = FileCacheService();

  void toggleSelection(T item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
        if (selectedItems.isEmpty) isSelectionMode = false;
      } else {
        selectedItems.add(item);
        isSelectionMode = true;
      }
    });
  }

  void clearSelection() {
    setState(() {
      isSelectionMode = false;
      selectedItems.clear();
    });
  }

  void selectAll(List<T> items) {
    setState(() {
      selectedItems = Set.from(items);
      isSelectionMode = true;
    });
  }

  Future<void> handleShare(List<File> files) async {
    if (files.isEmpty) return;
    
    try {
      await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sharing files: $e")),
        );
      }
    }
  }

  Future<void> handleCopy(List<FileSystemEntity> entities) async {
    if (entities.isEmpty) return;

    final files = entities.whereType<File>().toList();
    if (files.isEmpty) {
      _showMessage("No files to copy");
      return;
    }

    String? destination = await FilePicker.platform.getDirectoryPath();
    if (destination == null) return;

    _setOperationInProgress(true);
    
    try {
      await _fileOps.copyFiles(files, destination, onProgress: (current, total) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Copying $current/$total files..."),
              duration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
      
      _invalidateCache(destination);
      _showMessage("Files copied successfully");
      clearSelection();
    } catch (e) {
      _showMessage("Error copying files: $e");
    } finally {
      _setOperationInProgress(false);
    }
  }

  Future<void> handleMove(List<FileSystemEntity> entities) async {
    if (entities.isEmpty) return;

    String? destination = await FilePicker.platform.getDirectoryPath();
    if (destination == null) return;

    _setOperationInProgress(true);
    
    try {
      await _fileOps.moveFiles(entities, destination, onProgress: (current, total) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Moving $current/$total files..."),
              duration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
      
      _invalidateCache(destination);
      _showMessage("Files moved successfully");
      clearSelection();
      
      // Refresh current view if needed
      if (mounted) _refreshCurrentView();
    } catch (e) {
      _showMessage("Error moving files: $e");
    } finally {
      _setOperationInProgress(false);
    }
  }

  Future<void> handleRename(FileSystemEntity entity) async {
    final oldName = p.basename(entity.path);
    final controller = TextEditingController(text: oldName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Rename"),
          ),
        ],
      ),
    );
    
    if (newName == null || newName.isEmpty || newName == oldName) return;
    
    try {
      final dir = entity.parent.path;
      final newPath = p.join(dir, newName);
      await entity.rename(newPath);
      
      _invalidateCache(dir);
      _showMessage("Renamed successfully");
      clearSelection();
      
      if (mounted) _refreshCurrentView();
    } catch (e) {
      _showMessage("Error renaming: $e");
    }
  }

  Future<void> handleDelete(List<FileSystemEntity> entities) async {
    if (entities.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Items?"),
        content: Text("Delete ${entities.length} items permanently?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    _setOperationInProgress(true);
    
    try {
      await _fileOps.deleteFiles(entities, onProgress: (current, total) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Deleting $current/$total files..."),
              duration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
      
      // Invalidate cache for parent directories
      for (final entity in entities) {
        _invalidateCache(entity.parent.path);
      }
      
      _showMessage("Deleted successfully");
      clearSelection();
      
      if (mounted) _refreshCurrentView();
    } catch (e) {
      _showMessage("Error deleting: $e");
    } finally {
      _setOperationInProgress(false);
    }
  }

  void _setOperationInProgress(bool inProgress) {
    setState(() {
      isOperationInProgress = inProgress;
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _invalidateCache(String path) {
    _cache.invalidateDirectory(path);
  }

  void _refreshCurrentView() {
    // Override this in implementing classes
  }

  List<File> getSelectedFiles(Set<T> selectedItems) {
    return selectedItems.whereType<File>().toList();
  }

  List<FileSystemEntity> getSelectedEntities(Set<T> selectedItems) {
    return selectedItems.whereType<FileSystemEntity>().toList();
  }
}
