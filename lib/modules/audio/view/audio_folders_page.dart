import 'package:file_manager/modules/audio/view/folder/audio_list_page.dart';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../../../data/file_storage_provider.dart';

class AudioFoldersPage extends StatelessWidget {
  const AudioFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FileStorageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          "Music",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),

        actions: [
          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          }, icon: const Icon(Icons.search, )),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, )),
        ],
      ),
      body: FutureBuilder<List<AssetPathEntity>>(
        future: provider.getAudioFolders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No audio folders found"));
          }

          final folders = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: folders.length,
            separatorBuilder: (context, index) =>
            const Divider(height: 1),
            itemBuilder: (context, index) {
              final folder = folders[index];

              return FutureBuilder<int>(
                future: folder.assetCountAsync,
                builder: (context, countSnapshot) {
                  final count = countSnapshot.data ?? 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 5),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      folder.name == "Recent"
                          ? "All Music"
                          : folder.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text("$count songs"),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AudioListPage(folder: folder),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
