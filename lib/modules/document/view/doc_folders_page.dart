import 'dart:io';
import 'package:file_manager/modules/document/view/folder/folder_doc_page.dart';
import 'package:flutter/material.dart';

class DocFoldersPage extends StatefulWidget {
  const DocFoldersPage({super.key});

  @override
  State<DocFoldersPage> createState() => _DocFoldersPageState();
}

class _DocFoldersPageState extends State<DocFoldersPage> {

  Future<Map<String, List<File>>> _getDocFolders() async {
    Map<String, List<File>> docFolders = {};
    final dir = Directory('/storage/emulated/0/');

    try {
      final List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);

      for (var entity in entities) {
        if (entity is File) {
          String path = entity.path.toLowerCase();
          // Extensions check karein
          if (path.endsWith('.pdf') || path.endsWith('.doc') || path.endsWith('.docx') || path.endsWith('.txt')) {
            String folderPath = entity.parent.path;

            if (docFolders.containsKey(folderPath)) {
              docFolders[folderPath]!.add(entity);
            } else {
              docFolders[folderPath] = [entity];
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error scanning docs: $e");
    }
    return docFolders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text("Document Folders", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, List<File>>>(
        future: _getDocFolders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No documents found"));
          }

          final folderMap = snapshot.data!;
          final folderPaths = folderMap.keys.toList();

          return ListView.builder(
            itemCount: folderPaths.length,
            itemBuilder: (context, index) {
              String path = folderPaths[index];
              String folderName = path.split('/').last;
              int fileCount = folderMap[path]!.length;

              return ListTile(
                leading: const Icon(Icons.folder_shared, color: Colors.green, size: 40),
                title: Text(folderName),
                subtitle: Text("$fileCount documents"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FolderDocsPage(
                        folderName: folderName,
                        files: folderMap[path]!,
                      ),
                    ),
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