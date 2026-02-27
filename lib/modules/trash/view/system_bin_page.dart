import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class SystemBinPage extends StatefulWidget {
  const SystemBinPage({super.key});

  @override
  State<SystemBinPage> createState() => _SystemBinPageState();
}

class _SystemBinPageState extends State<SystemBinPage> {
  List<AssetEntity> trashedAssets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSystemTrash();
  }

  Future<void> _fetchSystemTrash() async {
    setState(() => isLoading = true);

    try {
      // 1. Correct Permission Method
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
        setState(() => isLoading = false);
        return;
      }

      // 2. Filter setup (Isse simple rakhein)
      final filter = FilterOptionGroup();

      // 3. getAssetPathList mein 'containsPathEntity' ko yahan pass karein
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: filter,
        onlyAll: false, // Saare folders check karne ke liye false rakhein
      );

      List<AssetEntity> allTrashed = [];

      for (var path in paths) {
        // Android system mein aksar '.trash' ya 'Trash' folder hota hai
        String folderName = path.name.toLowerCase();

        if (folderName.contains('trash') || folderName.contains('bin')) {
          final list = await path.getAssetListPaged(page: 0, size: 100);
          allTrashed.addAll(list);
        }
      }

      setState(() {
        trashedAssets = allTrashed;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trash")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trashedAssets.isEmpty
          ? const Center(child: Text("No files found in System Bin"))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 5, mainAxisSpacing: 5
        ),
        itemCount: trashedAssets.length,
        itemBuilder: (context, index) {
          return AssetEntityImage(
            trashedAssets[index],
            isOriginal: false,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}