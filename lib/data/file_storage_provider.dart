  import 'dart:io';

  import 'package:file_manager/data/document/getDocumentCount.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:installed_apps/app_info.dart';
  import 'package:installed_apps/installed_apps.dart';
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

    Future<void> fetchDocuments() async {
      isDocLoading = true;
      notifyListeners();

      docsCount = await getDocumentCount();

      isDocLoading = false;
      notifyListeners();
    }


  }

