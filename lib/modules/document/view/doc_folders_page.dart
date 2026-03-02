import 'dart:io';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:flutter/foundation.dart'; // compute ke liye
import 'package:flutter/material.dart';
import 'package:file_manager/modules/document/view/folder/folder_doc_page.dart';

class DocFoldersPage extends StatefulWidget {
  const DocFoldersPage({super.key});

  @override
  State<DocFoldersPage> createState() => _DocFoldersPageState();
}

class _DocFoldersPageState extends State<DocFoldersPage> {
  static Map<String, List<File>> _scanForDocs(dynamic _) {
    Map<String, List<File>> docFolders = {};
    final extensions = {'.pdf', '.doc', '.docx', '.txt', '.xlsx', '.pptx'};

    final List<String> targetFolders = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
    ];

    for (String path in targetFolders) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        try {
          final List<FileSystemEntity> entities = dir.listSync(recursive: true);
          for (var entity in entities) {
            if (entity is File) {
              String filePath = entity.path.toLowerCase();
              if (extensions.any((ext) => filePath.endsWith(ext))) {
                String parentPath = entity.parent.path;
                docFolders.putIfAbsent(parentPath, () => []).add(entity);
              }
            }
          }
        } catch (e) {
          debugPrint("Folder skip: $path");
        }
      }
    }
    return docFolders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document"),
        actions: [
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
      body: FutureBuilder<Map<String, List<File>>>(
        future: compute(_scanForDocs, null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text("Scanning Documents Fast..."),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Documents Found"));
          }

          final folderMap = snapshot.data!;
          final folderPaths = folderMap.keys.toList();

          return ListView.separated(
            itemCount: folderPaths.length,
            separatorBuilder: (c, i) => const Divider(indent: 70),
            itemBuilder: (context, index) {
              String path = folderPaths[index];
              return ListTile(
                leading: const Icon(
                  Icons.folder,
                  color: Colors.green,
                  size: 35,
                ),
                title: Text(path.split('/').last),
                subtitle: Text("${folderMap[path]!.length} files"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => FolderDocsPage(
                      folderName: path.split('/').last,
                      files: folderMap[path]!,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
