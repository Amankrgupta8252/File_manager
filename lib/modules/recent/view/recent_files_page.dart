import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../file_explorer/view/file_action_bar.dart';
import '../../search/view/search_page.dart';

class RecentFilesPage extends StatefulWidget {
  const RecentFilesPage({super.key});

  @override
  State<RecentFilesPage> createState() => _RecentFilesPageState();
}

class _RecentFilesPageState extends State<RecentFilesPage> {
  List<AssetEntity> recentAssets = [];
  Set<AssetEntity> selectedAssets = {};
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

  Future<List<File>> getSelectedFiles() async {
    List<File> files = [];

    for (var asset in selectedAssets) {
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }

    return files;
  }

  // --- ACTION BAR FUNCTIONS ---

  Future<void> _handleShare() async {

    final files = await getSelectedFiles();

    if (files.isNotEmpty) {

      await Share.shareXFiles(
        files.map((f) => XFile(f.path)).toList(),
      );
    }
  }

  Future<void> _handleCopy() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination =
    await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {

      final newPath =
          "$destination/${p.basename(file.path)}";

      await file.copy(newPath);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Files copied")),
    );
  }

  Future<void> _handleMove() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination =
    await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {

      final newPath =
          "$destination/${p.basename(file.path)}";

      await file.copy(newPath);
      await file.delete();
    }

    setState(() {
      selectedAssets.clear();
      isSelectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Files moved")),
    );
  }

  void _handleRename() {
    if (selectedAssets.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select only one file to rename")),
      );
      return;
    }

    final asset = selectedAssets.first;
    final controller = TextEditingController(text: asset.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename File"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              debugPrint("Renaming to: ${controller.text}");
              Navigator.pop(context);
              // Note: PhotoManager assets ka rename system level par restricted ho sakta hai
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    if (selectedAssets.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Recent Files?"),
        content: Text("${selectedAssets.length} items will be deleted permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final ids = selectedAssets.map((e) => e.id).toList();
        final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

        if (result.isNotEmpty) {
          setState(() {
            recentAssets.removeWhere((element) => selectedAssets.contains(element));
            selectedAssets.clear();
            isSelectionMode = false;
          });
        }
      } catch (e) {
        debugPrint("Delete Error: $e");
      }
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
      // backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: () {
          setState(() {
            isSelectionMode = false;
            selectedAssets.clear();
          });
        })
            : const BackButton(),
        title: Text(
          isSelectionMode ? "${selectedAssets.length} Selected" : "Recent Files",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // backgroundColor: Colors.white,
        elevation: 0.5,
        // iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!isSelectionMode)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              icon: const Icon(Icons.search),
            ),

          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentAssets.isEmpty
          ? const Center(child: Text("No recent files found"))
          : ListView.separated(
        itemCount: recentAssets.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 75),
        itemBuilder: (context, index) {
          final asset = recentAssets[index];
          final isSelected = selectedAssets.contains(asset);

          return ListTile(
            onTap: () => isSelectionMode ? _toggleSelection(asset) : _openFile(asset),
            onLongPress: () => _toggleSelection(asset),
            selected: isSelected,
            selectedTileColor: Colors.blue.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
              style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
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

      // --- UNIVERSAL BOTTOM ACTION BAR ---
      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedAssets.length,
        onShare: _handleShare,
        onCopy: _handleCopy,
        onMove: _handleMove,
        onRename: _handleRename,
        onDelete: _handleDelete,
      )
          : null,
    );
  }

  Future<void> _openFile(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) OpenFile.open(file.path);
  }
}