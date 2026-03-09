import 'package:file_manager/modules/home/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'utils/data/file_storage_provider.dart';
import 'utils/data/quick_access_provider.dart';
import 'utils/data/storage_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MediaStore.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => FileStorageProvider()),
        ChangeNotifierProvider(create: (_) => QuickAccessProvider()),
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      themeMode: ThemeMode.system,

      title: 'File Manager',
      home: const HomePage(),
    );
  }
}
