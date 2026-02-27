import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class FolderDocsPage extends StatelessWidget {
  final String folderName;
  final List<File> files;

  const FolderDocsPage({super.key, required this.folderName, required this.files});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          scrolledUnderElevation: 0,
          title: Text(folderName)),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          File file = files[index];
          String fileName = file.path.split('/').last;

          return ListTile(
            leading: Icon(
              fileName.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.description,
              color: fileName.endsWith('.pdf') ? Colors.red : Colors.blue,
            ),
            title: Text(fileName),
            subtitle: Text("${(file.lengthSync() / 1024).toStringAsFixed(1)} KB"),
            onTap: () {
              OpenFile.open(file.path);
            },
          );
        },
      ),
    );
  }
}