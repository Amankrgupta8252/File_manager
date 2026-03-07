import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ScanResult {

  final Map<String, double> categorySizes;
  final List<String> largeFilePaths;
  final List<Map<String, dynamic>> realApps;

  ScanResult({
    required this.categorySizes,
    required this.largeFilePaths,
    required this.realApps,
  });

}

class CleanerHelper {
  static const int largeFileThreshold = 524288000;
  static ScanResult _doHeavyScan(String rootPath) {

    int img = 0;
    int vid = 0;
    int aud = 0;
    int doc = 0;

    List<String> large = [];

    Map<String, int> appFolderSizes = {
      "WhatsApp": 0,
      "Telegram": 0,
      "Instagram": 0
    };

    List<String> scanFolders = [

      "/storage/emulated/0/DCIM",
      "/storage/emulated/0/Pictures",
      "/storage/emulated/0/Movies",
      "/storage/emulated/0/Music",
      "/storage/emulated/0/Download",

      "/storage/emulated/0/WhatsApp/Media",
      "/storage/emulated/0/Telegram/Telegram Images",
      "/storage/emulated/0/Telegram/Telegram Video",
      "/storage/emulated/0/Telegram/Telegram Documents",

    ];

    for (String folderPath in scanFolders) {

      try {

        final dir = Directory(folderPath);

        if (!dir.existsSync()) continue;

        final files = dir.listSync(recursive: true, followLinks: false);

        int scanned = 0;

        for (var f in files) {

          if (scanned > 10000) break;
          scanned++;

          if (f is! File) continue;

          try {

            final path = f.path;

            if (path.contains("/Android/data") ||
                path.contains("/Android/obb") ||
                path.contains("/.")) {
              continue;
            }

            int size = f.lengthSync();
            String ext = p.extension(path).toLowerCase();

            // images
            if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
              img += size;
            }

            // videos
            else if (['.mp4', '.mkv', '.mov', '.avi'].contains(ext)) {
              vid += size;
            }

            // audio
            else if (['.mp3', '.wav', '.m4a'].contains(ext)) {
              aud += size;
            }

            // docs
            else if ([
              '.pdf',
              '.docx',
              '.txt',
              '.zip',
              '.apk'
            ].contains(ext)) {
              doc += size;
            }

            // large files
            if (size >= largeFileThreshold) {
              large.add(path);
            }

            // app folder size
            if (path.contains("WhatsApp")) {
              appFolderSizes["WhatsApp"] =
                  (appFolderSizes["WhatsApp"] ?? 0) + size;
            }

            if (path.contains("Telegram")) {
              appFolderSizes["Telegram"] =
                  (appFolderSizes["Telegram"] ?? 0) + size;
            }

            if (path.contains("Instagram")) {
              appFolderSizes["Instagram"] =
                  (appFolderSizes["Instagram"] ?? 0) + size;
            }

          } catch (_) {}

        }

      } catch (_) {}

    }

    double toGB(int bytes) {
      return bytes / (1024 * 1024 * 1024);
    }

    return ScanResult(

      categorySizes: {

        "Images": toGB(img),
        "Videos": toGB(vid),
        "Audio": toGB(aud),
        "Docs": toGB(doc),

      },

      largeFilePaths: large,

      realApps: appFolderSizes.entries.map((e) => {

        "name": e.key,
        "size": toGB(e.value),
        "icon": _getAppIcon(e.key),
        "color": _getAppColor(e.key),

      }).toList(),

    );

  }

  static IconData _getAppIcon(String name) {

    if (name == "WhatsApp") return Icons.chat;
    if (name == "Telegram") return Icons.send;

    return Icons.apps;

  }

  static Color _getAppColor(String name) {

    if (name == "WhatsApp") return Colors.green;
    if (name == "Telegram") return Colors.blue;

    return Colors.purple;

  }

  static Future<ScanResult> startSafeScan() async {

    return await compute(_doHeavyScan, "/storage/emulated/0");

  }

  // ======================
  // JUNK CLEANER
  // ======================

  static Future<int> cleanJunkFiles() async {

    int deletedBytes = 0;

    List<String> junkFolders = [

      "/storage/emulated/0/Download",
      "/storage/emulated/0/DCIM/.thumbnails",
      "/storage/emulated/0/WhatsApp/Media/.Statuses",

    ];

    for (String folder in junkFolders) {

      try {

        final dir = Directory(folder);

        if (!dir.existsSync()) continue;

        final files = dir.listSync(recursive: true, followLinks: false);

        int scanned = 0;

        for (var f in files) {

          if (scanned > 5000) break;
          scanned++;

          if (f is! File) continue;

          try {

            String path = f.path.toLowerCase();

            if (path.endsWith(".log") ||
                path.endsWith(".tmp") ||
                path.endsWith(".cache") ||
                path.endsWith(".thumb") ||
                path.endsWith(".bak")) {

              int size = f.lengthSync();

              await f.delete();

              deletedBytes += size;

            }

          } catch (_) {}

        }

      } catch (_) {}

    }

    return deletedBytes;

  }

}