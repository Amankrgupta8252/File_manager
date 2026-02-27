import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:open_file/open_file.dart';

class RecentFilesPage extends StatefulWidget {
  const RecentFilesPage({super.key});

  @override
  State<RecentFilesPage> createState() => _RecentFilesPageState();
}

class _RecentFilesPageState extends State<RecentFilesPage> {
  List<AssetEntity> recentAssets = [];
  Set<AssetEntity> selectedAssets = {}; // Selected files ke liye
  bool isLoading = true;
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchRecentMedia();
  }

  Future<void> _fetchRecentMedia() async {
    setState(() => isLoading = true);
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (paths.isNotEmpty) {
      final List<AssetEntity> list = await paths[0].getAssetListPaged(page: 0, size: 50);
      setState(() {
        recentAssets = list;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteSelectedAssets() async {
    if (selectedAssets.isEmpty) return;

    try {
      final ids = selectedAssets.map((e) => e.id).toList();
      final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

      if (result.isNotEmpty) {
        setState(() {
          recentAssets.removeWhere((element) => selectedAssets.contains(element));
          selectedAssets.clear();
          isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recent files deleted successfully")),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (selectedAssets.contains(asset)) {
        selectedAssets.remove(asset);
        if (selectedAssets.isEmpty) isSelectionMode = false;
      } else {
        selectedAssets.add(asset);
        isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          isSelectionMode ? "${selectedAssets.length} Selected" : "Recent Files",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: _deleteSelectedAssets, // Top Right Delete Button
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentAssets.isEmpty
          ? const Center(child: Text("No recent files found"))
          : ListView.builder(
        itemCount: recentAssets.length,
        itemBuilder: (context, index) {
          final asset = recentAssets[index];
          final isSelected = selectedAssets.contains(asset);

          return ListTile(
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(asset);
              } else {
                _openFile(asset);
              }
            },
            onLongPress: () => _toggleSelection(asset),
            selected: isSelected,
            selectedTileColor: Colors.blue.withOpacity(0.05),
            leading: Stack(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: asset.type == AssetType.audio
                        ? Container(
                      color: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.music_note, color: Colors.orange),
                    )
                        : AssetEntityImage(asset, isOriginal: false, fit: BoxFit.cover),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, size: 18, color: Colors.blue),
                  ),
              ],
            ),
            title: Text(
              asset.title ?? "Unknown",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(asset.type.toString().split('.').last.toUpperCase()),
            trailing: isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(asset),
              activeColor: Colors.blue,
            )
                : const Icon(Icons.history, size: 18, color: Colors.grey),
          );
        },
      ),
    );
  }

  Future<void> _openFile(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) OpenFile.open(file.path);
  }
}