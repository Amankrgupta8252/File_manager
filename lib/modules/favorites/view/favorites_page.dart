import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> favoritePaths = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritePaths = prefs.getStringList('favorite_files') ?? [];
      isLoading = false;
    });
  }

  Future<void> _removeFromFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    favoritePaths.remove(path);
    await prefs.setStringList('favorite_files', favoritePaths);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Favorites", ),
        // backgroundColor: Colors.white,
        elevation: 0.5,
        // iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoritePaths.isEmpty
          ? const Center(child: Text("No favorites added yet"))
          : ListView.separated(
        itemCount: favoritePaths.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final path = favoritePaths[index];
          final file = File(path);
          final fileName = p.basename(path);

          if (!file.existsSync()) return const SizedBox(); // Skip deleted files

          return ListTile(
            leading: const Icon(Icons.star, color: Colors.amber, size: 30),
            title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text("Starred File"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeFromFavorite(path),
            ),
            onTap: () => OpenFile.open(path),
          );
        },
      ),
    );
  }
}