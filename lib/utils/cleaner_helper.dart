import 'dart:io';
import 'package:path/path.dart' as p;

class CleanerHelper {
  static final List<String> _junkExtensions = ['.tmp', '.log', '.cache', '.temp',];

  static Future<Map<String, List<File>>> scanStorage() async {
    List<File> junk = [];
    List<File> large = [];
    Map<String, List<File>> duplicates = {};
    Map<String, File> seenFiles = {};

    try {
      final dir = Directory("/storage/emulated/0/");
      final entities = dir.listSync(recursive: true, followLinks: false);

      for (var entity in entities) {
        if (entity is File) {
          // 1. Junk Check
          String ext = p.extension(entity.path).toLowerCase();
          if (_junkExtensions.contains(ext)) junk.add(entity);

          // 2. Large Files Check (> 20MB)
          int sizeInBytes = entity.lengthSync();
          if (sizeInBytes > 20 * 1024 * 1024) large.add(entity);

          // 3. Simple Duplicate Check (Name + Size)
          String key = "${p.basename(entity.path)}_${sizeInBytes}";
          if (seenFiles.containsKey(key)) {
            duplicates.putIfAbsent(key, () => [seenFiles[key]!]).add(entity);
          } else {
            seenFiles[key] = entity;
          }
        }
      }
    } catch (e) {
      print("Scan Error: $e");
    }

    return {
      "junk": junk,
      "large": large,
      "duplicates": duplicates.values.expand((e) => e.skip(1)).toList(),
    };
  }
}