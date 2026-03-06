import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FolderViewPage extends StatefulWidget {

  final String path;

  const FolderViewPage({super.key, required this.path});

  @override
  State<FolderViewPage> createState() => _FolderViewPageState();
}

class _FolderViewPageState extends State<FolderViewPage> {

  late Future<List<FileSystemEntity>> files;

  @override
  void initState() {
    super.initState();
    files = loadFiles();
  }

  Future<List<FileSystemEntity>> loadFiles() async {

    final dir = Directory(widget.path);

    if (!await dir.exists()) return [];

    final items = await dir.list().toList();

    items.sort((a,b){
      return p.basename(a.path).compareTo(p.basename(b.path));
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(p.basename(widget.path)),
      ),

      body: FutureBuilder<List<FileSystemEntity>>(

        future: files,

        builder: (context,snapshot){

          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if(data.isEmpty){
            return const Center(child: Text("Empty Folder"));
          }

          return ListView.separated(

            itemCount: data.length,

            separatorBuilder: (_,__) =>
            const Divider(height: 1),

            itemBuilder: (context,index){

              final entity = data[index];

              final name = p.basename(entity.path);

              final isFolder = entity is Directory;

              return ListTile(

                leading: Icon(
                  isFolder ? Icons.folder : Icons.insert_drive_file,
                  color: isFolder ? Colors.orange : Colors.grey,
                ),

                title: Text(name),

                onTap: (){

                  if(isFolder){

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FolderViewPage(path: entity.path),
                      ),
                    );

                  }

                },

              );

            },

          );

        },

      ),

    );

  }

}