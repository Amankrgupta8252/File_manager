import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../../file_explorer/view/file_action_bar.dart';

class AudioListPage extends StatefulWidget {
  final AssetPathEntity folder;
  const AudioListPage({super.key, required this.folder});

  @override
  State<AudioListPage> createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage> {
  List<AssetEntity> audioList = [];
  Set<AssetEntity> selectedAudios = {};
  bool isLoading = true;
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }

  Future<void> _fetchAudios() async {
    setState(() => isLoading = true);
    try {
      final count = await widget.folder.assetCountAsync;
      final list = await widget.folder.getAssetListPaged(page: 0, size: count);
      setState(() {
        audioList = list;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  // --- ACTION BAR FUNCTIONS ---

  // ---------------- SHARE ----------------

  Future<void> _handleShare() async {
    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
  }

  // ---------------- COPY ----------------

  Future<void> _handleCopy() async {
    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination = await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {
      final newPath = "$destination/${file.uri.pathSegments.last}";

      await file.copy(newPath);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Files copied successfully")),
      );
    }
  }

  // ---------------- MOVE ----------------

  Future<void> _handleMove() async {
    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    String? destination = await FilePicker.platform.getDirectoryPath();

    if (destination == null) return;

    for (var file in files) {
      final newPath = "$destination/${file.uri.pathSegments.last}";

      await file.rename(newPath);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Files moved successfully")));
    }
  }

  // ---------------- RENAME ----------------

  Future<void> _handleRename() async {

    final files = await getSelectedFiles();

    if (files.isEmpty) return;

    if (files.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rename supports only one file")),
      );
      return;
    }

    final file = files.first;

    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController controller =
        TextEditingController(text: file.uri.pathSegments.last);

        return AlertDialog(
          title: const Text("Rename File"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter new file name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    final dir = file.parent.path;

    final newPath = "$dir/$newName";

    await file.rename(newPath);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File renamed successfully")),
      );
    }

    setState(() {});
  }

  // ---------------- DELETE ----------------

  Future<void> _handleDelete() async {
    if (selectedAudios.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Audio?"),
        content: Text("${selectedAudios.length} songs will be deleted."),
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
        final ids = selectedAudios.map((e) => e.id).toList();
        final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

        if (result.isNotEmpty) {
          setState(() {
            audioList.removeWhere((element) => selectedAudios.contains(element));
            selectedAudios.clear();
            isSelectionMode = false;
          });
        }
      } catch (e) {
        debugPrint("Delete Error: $e");
      }
    }
  }

  void _toggleSelection(AssetEntity audio) {
    setState(() {
      if (selectedAudios.contains(audio)) {
        selectedAudios.remove(audio);
        if (selectedAudios.isEmpty) isSelectionMode = false;
      } else {
        selectedAudios.add(audio);
        isSelectionMode = true;
      }
    });
  }

  Future<List<File>> getSelectedFiles() async {
    List<File> files = [];

    for (var audio in selectedAudios) {
      final File? file = await audio.file;

      if (file != null) {
        files.add(file);
      }
    }

    return files;
  }

  Future<void> _playAudio(AssetEntity audio) async {
    final File? file = await audio.file;
    if (file != null) OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: () {
          setState(() {
            isSelectionMode = false;
            selectedAudios.clear();
          });
        })
            : const BackButton(),
        title: Text(
          isSelectionMode ? "${selectedAudios.length} Selected" : widget.folder.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // backgroundColor: Colors.white,
        elevation: 0.5,
        // iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!isSelectionMode)
            IconButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()));
            }, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : audioList.isEmpty
          ? const Center(child: Text("No Audio Found"))
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: audioList.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 75),
        itemBuilder: (context, index) {
          final audio = audioList[index];
          final isSelected = selectedAudios.contains(audio);
          final duration = Duration(seconds: audio.duration);
          final time = "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";

          return ListTile(
            onTap: () => isSelectionMode ? _toggleSelection(audio) : _playAudio(audio),
            onLongPress: () => _toggleSelection(audio),
            selected: isSelected,
            selectedTileColor: Colors.orange.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: isSelected ? Colors.white : Colors.orange,
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
              audio.title ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(time),
            trailing: isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(audio),
              activeColor: Colors.orange,
            )
                : const Icon(Icons.more_vert, color: Colors.grey),
          );
        },
      ),

      // --- BOTTOM ACTION BAR ---
      bottomNavigationBar: isSelectionMode
          ? FileActionBar(
        selectedCount: selectedAudios.length,
        onShare: _handleShare,
        onCopy: () => _handleCopy,
        onMove: () => _handleMove,
        onRename: _handleRename,
        onDelete: _handleDelete,
      )
          : null,
    );
  }
}