import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class FileOperations {

  static Future<void> shareFiles(Set<FileSystemEntity> entities) async {
    List<XFile> files = [];

    for (var entity in entities) {
      if (entity is File) {
        files.add(XFile(entity.path));
      }
    }

    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
    }
  }

  static Future<void> copyFiles(
      Set<FileSystemEntity> entities,
      String destinationPath,
      ) async {

    for (var entity in entities) {

      String name = p.basename(entity.path);
      String newPath = p.join(destinationPath, name);

      if (entity is File) {
        await entity.copy(newPath);
      }

      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  static Future<void> moveFiles(
      Set<FileSystemEntity> entities,
      String destinationPath,
      ) async {

    for (var entity in entities) {

      String name = p.basename(entity.path);
      String newPath = p.join(destinationPath, name);

      await entity.rename(newPath);
    }
  }

  static Future<void> _copyDirectory(
      Directory source,
      Directory destination,
      ) async {

    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (var entity in source.list(recursive: false)) {

      if (entity is Directory) {
        await _copyDirectory(
            entity,
            Directory(p.join(destination.path, p.basename(entity.path)))
        );
      }

      if (entity is File) {
        await entity.copy(
            p.join(destination.path, p.basename(entity.path))
        );
      }
    }
  }
}