import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_manager/modules/video/view/folder/folder_videos_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoFoldersPage extends StatelessWidget {
  const VideoFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text("Video Albums", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        // RequestType.video se sirf video wale folders milenge
        future: PhotoManager.getAssetPathList(type: RequestType.video),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No videos found"));
          }

          final folders = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: folders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final folder = folders[index];

              return FutureBuilder<int>(
                future: folder.assetCountAsync,
                builder: (context, countSnapshot) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.video_collection, color: Colors.red),
                    ),
                    title: Text(folder.name == "Recent" ? "All Videos" : folder.name),
                    subtitle: Text("${countSnapshot.data ?? 0} videos"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FolderVideosPage(folder: folder)),
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