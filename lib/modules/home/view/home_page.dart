import 'dart:io';
import 'package:file_manager/clean_up/view/clean_up_page.dart';
import 'package:file_manager/modules/apps/view/apps_list_page.dart';
import 'package:file_manager/modules/audio/view/audio_folders_page.dart';
import 'package:file_manager/modules/document/view/doc_folders_page.dart';
import 'package:file_manager/modules/downloads/view/downloads_page.dart';
import 'package:file_manager/modules/favorites/view/favorites_page.dart';
import 'package:file_manager/modules/home/view/folder_view_page.dart';
import 'package:file_manager/modules/images/view/image_folders_page.dart';
import 'package:file_manager/modules/internal_storage/view/InternalStoragePage.dart';
import 'package:file_manager/modules/recent/view/recent_files_page.dart';
import 'package:file_manager/modules/search/view/search_page.dart';
import 'package:file_manager/modules/trash/view/system_bin_page.dart';
import 'package:file_manager/modules/video/view/folder/folder_videos_page.dart';
import 'package:file_manager/modules/video/view/video_folders_page.dart';
import 'package:file_manager/sd_card/view/SDCardStoragePage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:file_manager/models/category_model.dart';
import 'package:file_manager/data/storage_provider.dart';
import 'package:file_manager/data/file_storage_provider.dart';

import '../../../data/quick_access_provider.dart';
import '../../../models/quick_access_model.dart';
import '../../../services/quick_access_service.dart';
import '../../add_folder/view/add_folder_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fileProvider = context.read<FileStorageProvider>();
      final quickAccess = context.read<QuickAccessProvider>();

      // File counts
      fileProvider.fetchMediaCounts();
      fileProvider.fetchDocuments();
      fileProvider.fetchAppCount();

      // Load Quick Access history
      quickAccess.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageProvider>();
    final fileStorage = context.watch<FileStorageProvider>();

    // --- DYNAMIC LIST WITH PAGES ---
    final List<FileCategory> categories = [
      FileCategory(
        name: "Images",
        icon: Icons.image_outlined,
        color: Colors.blue,
        count: "${fileStorage.imageCount} files",
        page: const ImageFoldersPage(), // Direct Page Assignment
      ),
      FileCategory(
        name: "Videos",
        icon: Icons.video_library_outlined,
        color: Colors.red,
        count: "${fileStorage.videoCount} files",
        page: const VideoFoldersPage(),
      ),
      FileCategory(
        name: "Audio",
        icon: Icons.music_note_outlined,
        color: Colors.orange,
        count: "${fileStorage.audioCount} files",
        page: AudioFoldersPage(),
      ),
      FileCategory(
        name: "Documents",
        icon: Icons.description_outlined,
        color: Colors.green,
        count: "${fileStorage.docsCount} files",
        page: const DocFoldersPage(),
      ),
      FileCategory(
        name: "Downloads",
        icon: Icons.file_download_outlined,
        color: Colors.brown,
        count: "${fileStorage.downloadsCount} files",
        page: DownloadsPage(),
      ),
      FileCategory(
        name: "Apps",
        icon: Icons.apps_outage_outlined,
        color: Colors.teal,
        count: "${fileStorage.allAppCount}",
        page: AppsListPage(title: "Apps", excludeSystem: false),
      ),
      FileCategory(
        name: "System",
        icon: Icons.settings_applications,
        color: Colors.grey,
        count: "${storage.systemGB.toStringAsFixed(1)} GB Reserved",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          "My Files",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await storage.updateStorage();
          await fileStorage.fetchMediaCounts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStorageCard(storage),

                if (storage.hasSDCard) ...[
                  const SizedBox(height: 15),
                  _buildSDCard(storage),
                ],

                const SizedBox(height: 25),
                const Text(
                  "Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // --- CATEGORY GRID ---
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryTile(category, () {
                      if (category.page != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => category.page!,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${category.name} page coming soon!"),
                          ),
                        );
                      }
                    });
                  },
                ),
                // --- QUICK ACTIONS ---
                const SizedBox(height: 25),

                Text(
                  "Collections",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 15),
                _buildQuickActionTile(
                  "Recent Files",
                  Icons.access_time,
                  color: Colors.blueGrey,
                  pages: RecentFilesPage(),
                ),
                _buildQuickActionTile(
                  "Favorites",
                  Icons.star_border,
                  color: Colors.amber,
                  pages: FavoritesPage(),
                ),
                _buildQuickActionTile(
                  "Trash",
                  Icons.delete_outline,

                  pages: SystemBinPage(),
                ),
                SizedBox(height: 2),
                _buildCategoryTile(
                  FileCategory(
                    name: "Create Folder",
                    icon: Icons.create_new_folder_outlined,
                    color: Colors.indigo,
                    count: "Create new",
                  ),
                  _showCreateFolderDialog,
                ),
                SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.history, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "Quick Access",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    FutureBuilder<List<String>>(
                      future: QuickAccessService.getFolders(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("No recent folders"),
                          );
                        }

                        return Column(
                          children: snapshot.data!.map((path) {
                            String folderName = p.basename(path);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),

                              child: _buildCategoryTile(
                                FileCategory(
                                  name: folderName,
                                  icon: Icons.folder_open,
                                  color: Colors.deepPurple,
                                  count: path,
                                ),

                                () {
                                  openFolder(context, path);
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 15),

                SizedBox(height: 15),
                _buildCategoryTile(
                  FileCategory(
                    name: "Add Folder",
                    icon: Icons.create_new_folder_outlined,
                    color: Colors.indigoAccent,
                    count: "Select files",
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddFolderPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 10,),
                _buildCategoryTile(
                  FileCategory(
                    name: "Clean Up",
                    icon: Icons.cleaning_services_rounded,
                    count: "count",
                    color: Color(0xff9c6602),
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CleanUpPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSDCard(StorageProvider storage) {
    double progress = (storage.marketedSDGB > 0)
        ? (storage.sdUsedGB / storage.marketedSDGB)
        : 0.0;

    if (!storage.hasSDCard) {
      return const SizedBox();
    }

    double usedPercent = storage.sdUsedGB / storage.sdTotalGB;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SDCardStoragePage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF009624)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "SD Card",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Icon(Icons.sd_storage, color: Colors.white, size: 32),
              ],
            ),

            const SizedBox(height: 10),

            /// Storage Info
            Text(
              "${storage.sdUsedGB.toStringAsFixed(2)} GB / "
              "${storage.marketedSDGB.toStringAsFixed(2)} GB",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: usedPercent,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            /// Free Space
            Text(
              "${((1 - progress) * 100).toStringAsFixed(0)}% Free Space Left",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(FileCategory category, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).focusColor.withOpacity(0.03),
          // color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(category.count, style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard(StorageProvider storage) {
    double progress = (storage.usableTotalGB > 0)
        ? (storage.usedGB / storage.usableTotalGB)
        : 0.0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InternalStoragePage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.blue],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: storage.isLoading
            ? const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Internal Storage",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Icon(Icons.storage, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${storage.usedMarketedGB.toStringAsFixed(1)} GB / ${storage.marketedTotalGB.toStringAsFixed(1)} GB",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${((1 - progress) * 100).toStringAsFixed(0)}% Free Space Left",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    String title,
    IconData icon, {
    Color? color,
    Widget? pages,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          if (pages != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => pages),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$title feature coming soon!")),
            );
          }
        },
      ),
    );
  }

  void _showCreateFolderDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Folder"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter folder name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _createFolder(controller.text);
                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFolder(String name) async {
    try {
      final path = "/storage/emulated/0/MyFiles/$name";

      final directory = Directory(path);

      if (!await directory.exists()) {
        await directory.create(recursive: true);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Folder Created")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Folder already exists")));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void openFolder(BuildContext context, String path) async {
    await QuickAccessService.trackFolder(path);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FolderViewPage(path: path)),
    );
  }
}
