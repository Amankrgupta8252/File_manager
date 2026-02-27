import 'package:file_manager/data/file_storage_provider.dart';
import 'package:file_manager/data/storage_provider.dart';
import 'package:file_manager/modules/home/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_store_plus/media_store_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MediaStore initialization (IMPORTANT)
  await MediaStore.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => FileStorageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'File Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

