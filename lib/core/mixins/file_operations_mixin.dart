import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/file_storage_provider.dart';

// Mixin on State<StatefulWidget> sabse best hai compatibility ke liye
mixin FileOperationsMixin<T> on State<StatefulWidget> {
  bool isSelectionMode = false;
  Set<T> selectedItems = {};

  void toggleSelection(T item) {
    // Directly use setState because we are 'on State'
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

  void handleBaseShare(List<File> files) async {
    if (files.isNotEmpty) {
      await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
    }
  }

  void handleBaseCopyMove(List<File> files, {required bool isMove}) {
    if (files.isEmpty) return;

    // context is already available because we are 'on State'
    context.read<FileStorageProvider>().copyToClipboard(files, isMove: isMove);

    String action = isMove ? "Move" : "Copy";
    clearSelection();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Files ready to $action. Go to destination and paste.")),
    );
  }
}