import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:open_file/open_file.dart';

class AudioListPage extends StatefulWidget {
  final AssetPathEntity folder;
  const AudioListPage({super.key, required this.folder});

  @override
  State<AudioListPage> createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage> {
  List<AssetEntity> audioList = [];
  Set<AssetEntity> selectedAudios = {}; // Selected audios store karne ke liye
  bool isLoading = true;
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchAudios();
  }

  Future<void> _fetchAudios() async {
    setState(() => isLoading = true);
    final count = await widget.folder.assetCountAsync;
    final list = await widget.folder.getAssetListPaged(page: 0, size: count);
    setState(() {
      audioList = list;
      isLoading = false;
    });
  }

  // --- DELETE LOGIC ---
  Future<void> _deleteSelectedAudios() async {
    if (selectedAudios.isEmpty) return;

    try {
      final ids = selectedAudios.map((e) => e.id).toList();
      final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

      if (result.isNotEmpty) {
        setState(() {
          audioList.removeWhere((element) => selectedAudios.contains(element));
          selectedAudios.clear();
          isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selected audios deleted")),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
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

  Future<void> _playAudio(AssetEntity audio) async {
    final File? file = await audio.file;
    if (file != null) {
      OpenFile.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          isSelectionMode ? "${selectedAudios.length} Selected" : widget.folder.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: _deleteSelectedAudios, // AppBar delete button
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
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(audio);
              } else {
                _playAudio(audio);
              }
            },
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
                    child: Icon(Icons.check_circle, size: 18, color: Colors.green),
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
    );
  }
}