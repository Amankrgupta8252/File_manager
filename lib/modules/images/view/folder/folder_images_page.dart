import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:open_file/open_file.dart';

class FolderImagesPage extends StatefulWidget {
  final AssetPathEntity folder;
  const FolderImagesPage({super.key, required this.folder});

  @override
  State<FolderImagesPage> createState() => _FolderImagesPageState();
}

class _FolderImagesPageState extends State<FolderImagesPage> {
  List<AssetEntity> assets = [];
  Set<AssetEntity> selectedAssets = {}; // Selected images store karne ke liye
  bool isLoading = true;
  bool isSelectionMode = false; // Kya user select kar raha hai?

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() => isLoading = true);
    try {
      final list = await widget.folder.getAssetListPaged(page: 0, size: 100);
      setState(() {
        assets = list;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching images: $e");
      setState(() => isLoading = false);
    }
  }

  // --- DELETE SELECTED LOGIC ---
  Future<void> _deleteSelectedPhotos() async {
    if (selectedAssets.isEmpty) return;

    try {
      final ids = selectedAssets.map((e) => e.id).toList();
      final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

      if (result.isNotEmpty) {
        setState(() {
          assets.removeWhere((element) => selectedAssets.contains(element));
          selectedAssets.clear();
          isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selected images deleted successfully")),
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
        title: Text(
          isSelectionMode ? "${selectedAssets.length} Selected" : widget.folder.name,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: _deleteSelectedPhotos, // Right side delete button
            ),

          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          }, icon: const Icon(Icons.search, )),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, )),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          final isSelected = selectedAssets.contains(asset);

          return GestureDetector(
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(asset);
              } else {
                _openImageFile(asset);
              }
            },
            onLongPress: () => _toggleSelection(asset),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                      ),
                      child: AssetEntityImage(
                        asset,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(250),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(Icons.check_circle, color: Colors.blue[700]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openImageFile(AssetEntity asset) async {
    final File? file = await asset.file;
    if (file != null) OpenFile.open(file.path);
  }
}