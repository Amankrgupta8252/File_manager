import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class SdCardStorageProvider extends ChangeNotifier {

  static const MethodChannel _channel =
  MethodChannel('storage_channel');

  String? sdCardPath;
  bool hasSDCard = false;

  Future<void> detectSDCardNative() async {
    try {
      final result =
      await _channel.invokeMethod<Map>('getSDCard');

      if (result != null && result['path'] != null) {
        hasSDCard = true;
        sdCardPath = result['path'];
      } else {
        hasSDCard = false;
        sdCardPath = null;
      }

      print("Native SD Path: $sdCardPath");

    } catch (e) {
      print("Native SD Error: $e");
      hasSDCard = false;
    }

    notifyListeners();
  }
}