package com.example.file_manager

import android.content.Context
import android.os.storage.StorageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {

    private val CHANNEL = "storage_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "getSDCard") {

                    val storageManager =
                        getSystemService(Context.STORAGE_SERVICE) as StorageManager

                    val volumes = storageManager.storageVolumes

                    for (volume in volumes) {

                        if (!volume.isPrimary && volume.directory != null) {

                            val file = volume.directory!!

                            val totalSpace = file.totalSpace
                            val freeSpace = file.freeSpace
                            val usedSpace = totalSpace - freeSpace

                            val response = HashMap<String, Any>()
                            response["path"] = file.absolutePath
                            response["total"] = totalSpace
                            response["free"] = freeSpace
                            response["used"] = usedSpace

                            result.success(response)
                            return@setMethodCallHandler
                        }
                    }

                    result.success(null)
                }
            }
    }
}