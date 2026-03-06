import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class FileStorageProvider extends ChangeNotifier {
  int imageCount = 0;
  int videoCount = 0;
  int audioCount = 0;
  int docsCount = 0;
  int downloadsCount = 0;
  int appsCount = 0;
  int allAppCount = 0;
  int systemCount = 0;
  bool isMediaLoading = false;
  bool isDocLoading = false;

  Future<void> fetchMediaCounts() async {
    isMediaLoading = true;
    notifyListeners();

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    print("Permission Status: $ps");

    if (ps.isAuth) {
      final counts = await Future.wait([
        PhotoManager.getAssetCount(type: RequestType.image),
        PhotoManager.getAssetCount(type: RequestType.video),
        PhotoManager.getAssetCount(type: RequestType.audio),
      ]);

      imageCount = counts[0];
      videoCount = counts[1];
      audioCount = counts[2];

      print("Images: $imageCount, Videos: $videoCount, Audio: $audioCount");
    }

    isMediaLoading = false;
    notifyListeners();
  }

  Future<void> fetchAppCount() async {
    try {
      List<AppInfo> allApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: false,
      );

      List<AppInfo> userApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: false,
      );

      appsCount = userApps.length;
      allAppCount = allApps.length;
      systemCount = allApps.length - userApps.length;

      print("All apps: ${allApps.length}");
      print("User apps: ${userApps.length}");
      notifyListeners();

      debugPrint("User Apps: $appsCount");
      debugPrint("System Apps: $systemCount");
    } catch (e) {
      debugPrint("Error fetching apps: $e");
    }
  }

  Future<List<AssetPathEntity>> getImageFolders() async {
    return await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: false,
    );
  }

  Future<List<AssetPathEntity>> getAudioFolders() async {
    return await PhotoManager.getAssetPathList(
      type: RequestType.audio,
      onlyAll: false,
    );
  }

  Future<int> getDocumentCount() async {
    int count = 0;
    final extensions = {'.pdf', '.doc', '.docx', '.txt', '.xlsx', '.pptx', '.zip'};
    final root = Directory("/storage/emulated/0");

    // Helper function to scan folders one by one safely
    Future<void> scanDirectory(Directory dir) async {
      try {
        final List<FileSystemEntity> entities = dir.listSync(recursive: false);

        for (var entity in entities) {
          if (entity is File) {
            String path = entity.path.toLowerCase();
            // Check extension
            if (extensions.any((ext) => path.endsWith(ext))) {
              count++;
            }
          } else if (entity is Directory) {
            // Restricted folders ko skip karein taaki scan na ruke
            String folderName = entity.path.split('/').last;
            if (folderName != "Android" && !folderName.startsWith('.')) {
              await scanDirectory(entity); // Recursive call
            }
          }
        }
      } catch (e) {
        // Permission error wale folders (like /Android/data) yahan skip ho jayenge
        debugPrint("Skipping folder: ${dir.path} due to error");
      }
    }

    if (await root.exists()) {
      await scanDirectory(root);
    }

    return count;
  }


  Future<void> fetchDocuments() async {
    isDocLoading = true;
    notifyListeners();

    var status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (status.isGranted) {
      docsCount = await getDocumentCount();
      print("Document Count: $docsCount");
    } else {
      print("Permission Denied for Documents");
      docsCount = 0;
    }

    isDocLoading = false;
    notifyListeners();
  }

  // downloads

  List<FileSystemEntity> downloadFiles = [];

  Future<void> fetchDownloadFiles() async {
    final directory = Directory("/storage/emulated/0/Download");
    if (directory.existsSync()) {
      List<FileSystemEntity> allFiles = directory.listSync();

      downloadsCount = allFiles.whereType<File>().length;

      allFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      downloadFiles = allFiles;
      notifyListeners();
    }
  }

  //



  List<FileSystemEntity> _clipboard = [];
  bool _isMoveMode = false; // true = Move (Cut), false = Copy

  List<FileSystemEntity> get clipboard => _clipboard;
  bool get isMoveMode => _isMoveMode;

  // Clipboard mein files dalne ke liye
  void copyToClipboard(List<FileSystemEntity> files, {bool isMove = false}) {
    _clipboard = List.from(files);
    _isMoveMode = isMove;
    notifyListeners();
  }

  // Paste karne ka logic
  Future<void> pasteFiles(String destinationPath) async {
    for (var entity in _clipboard) {
      final String newPath = p.join(destinationPath, p.basename(entity.path));

      if (entity is File) {
        if (_isMoveMode) {
          await entity.rename(newPath); // Move
        } else {
          await entity.copy(newPath); // Copy
        }
      } else if (entity is Directory) {
        // Folders ke liye recursive copy/move logic yahan aayega
      }
    }
    _clipboard.clear();
    notifyListeners();
  }


}
