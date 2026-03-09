import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../utils/data/quick_access_provider.dart';
import '../../../models/quick_access_model.dart';
import '../../../services/quick_access_service.dart';
import '../../home/view/folder_view_page.dart';
import 'package:provider/provider.dart';

class AddFolderPage extends StatefulWidget {
  const AddFolderPage({super.key});

  @override
  State<AddFolderPage> createState() => _AddFolderPageState();
}

class _AddFolderPageState extends State<AddFolderPage> {
  List<FileSystemEntity> files = [];
  Set<FileSystemEntity> selected = {};
  String currentPath = "/storage/emulated/0";

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    Directory dir = Directory(currentPath);
    List<FileSystemEntity> list = dir.listSync();

    list.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });

    setState(() {
      files = list;
    });
  }

  void _openFolder(Directory dir) async {

    await QuickAccessService.trackFolder(dir.path);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderViewPage(path: dir.path),
      ),
    );
  }

  Future<bool> _onBack() async {
    if (currentPath == "/storage/emulated/0") return true;

    Directory parent = Directory(currentPath).parent;
    currentPath = parent.path;
    _loadFiles();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${selected.length} Selected"),
              Text(
                currentPath,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        body: ListView.separated(
          itemCount: files.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entity = files[index];
            final name = p.basename(entity.path);

            return ListTile(
              leading: Icon(
                entity is Directory ? Icons.folder : Icons.insert_drive_file,
                color: entity is Directory ? Colors.orange : Colors.blue,
              ),
              title: Text(name),
              onTap: () {
                if (entity is Directory) {
                  _openFolder(entity);
                }
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: selected.isEmpty ? null : _createFolder,
          child: const Icon(Icons.create_new_folder),
        ),
      ),
    );
  }

  /// CREATE FOLDER + MOVE FILES + QUICK ACCESS + OPEN FOLDER
  Future<void> _createFolder() async {
    TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Create Folder",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Folder name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          String name = controller.text.trim();
                          if (name.isEmpty) return;

                          String path = "$currentPath/$name";
                          Directory newDir = Directory(path);
                          if (!await newDir.exists()) {
                            await newDir.create();
                          }

                          // Agar aap file move logic rakh rahe ho, yahan add kar sakte ho
                          for (var file in selected) {
                            String newPath = "$path/${p.basename(file.path)}";
                            await file.rename(newPath);
                          }

                          selected.clear();
                          Navigator.pop(context); // close BottomSheet
                          _loadFiles(); // refresh current folder

                          // 🔹 Ye wala snippet add karo yahan, folder create hone ke turant baad
                          final quickAccessProvider = context.read<QuickAccessProvider>();
                          await quickAccessProvider.addToHistory(
                            QuickAccessFolder(name: name, path: path),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderViewPage(path: path),
                            ),
                          );
                        },
                        child: const Text("Create"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}