import 'dart:io';

class TrashScanner {

  static final List<String> trashFolders = [
    "/storage/emulated/0/DCIM/.Trash",
    "/storage/emulated/0/DCIM/.RecycleBin",
    "/storage/emulated/0/DCIM/.globalRecycleBin",
    "/storage/emulated/0/Pictures/.Trash",
    "/storage/emulated/0/Pictures/.RecycleBin",
    "/storage/emulated/0/Movies/.Trash",
    "/storage/emulated/0/Download/.Trash",
  ];

  static Future<List<FileSystemEntity>> scanTrash() async {

    List<FileSystemEntity> trashFiles = [];

    for (String path in trashFolders) {

      final dir = Directory(path);

      if (await dir.exists()) {

        final files = dir.listSync(recursive: true);

        trashFiles.addAll(files.whereType<File>());
      }
    }

    return trashFiles;
  }

  static Future<double> getTrashSize() async {

    final files = await scanTrash();

    int bytes = 0;

    for (var entity in files) {

      if (entity is File) {
        bytes += await entity.length();
      }
    }

    return bytes / (1024 * 1024 * 1024);
  }

  static Future<void> clearTrash() async {

    final files = await scanTrash();

    for (FileSystemEntity file in files) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}