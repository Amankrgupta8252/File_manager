import 'dart:io';
import 'package:file_manager/modules/clean_up/view/wave_painter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../../../utils/cleaner_helper.dart';
import 'glowing_bubble.dart';

class CleanUpPage extends StatefulWidget {
  const CleanUpPage({super.key});

  @override
  State<CleanUpPage> createState() => _CleanUpPageState();
}

class _CleanUpPageState extends State<CleanUpPage>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;

  bool _isScanning = false;
  bool _isInitialLoading = true;
  double _healthPercentage = 0.45;
  double _scanProgress = 0;

  Map<String, double> _realCategoryData = {
    "Images": 0,
    "Videos": 0,
    "Audio": 0,
    "Docs": 0,
  };
  List<Map<String, dynamic>> _realAppsData = [];
  List<Map<String, dynamic>> _junkFilesData = [];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _performRealScan();
  }

  Future<void> _performRealScan() async {
    if (!await Permission.manageExternalStorage.request().isGranted) {
      await openAppSettings();
      return;
    }

    setState(() => _isScanning = true);
    final result = await CleanerHelper.startSafeScan();
    final junkFiles = await _scanJunkFiles();

    if (!mounted) return;
    setState(() {
      _realCategoryData = result.categorySizes;
      _realAppsData = result.realApps.where((app) => app['size'] > 0).toList();
      _junkFilesData = junkFiles;
      double totalUsed = result.categorySizes.values.fold(0, (a, b) => a + b);
      _healthPercentage = (1 - (totalUsed / 128)).clamp(0.1, 1.0);
      _isScanning = false;
      _isInitialLoading = false;
    });
  }

  Future<void> _cleanStorage() async {
    setState(() {
      _scanProgress = 0;
      _isScanning = true;
    });

    // Fake progress animation for better UX
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 15));
      if (!mounted) return;
      setState(() => _scanProgress = i / 100);
    }

    int cleanedBytes = await CleanerHelper.cleanJunkFiles();
    final result = await CleanerHelper.startSafeScan();
    final junkFiles = await _scanJunkFiles();

    if (!mounted) return;
    setState(() {
      _realCategoryData = result.categorySizes;
      _realAppsData = result.realApps.where((app) => app['size'] > 0).toList();
      _junkFilesData = junkFiles;
      _healthPercentage = 1.0; // Show full health after cleaning
      _isScanning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Cleaned ${(cleanedBytes / (1024 * 1024)).toStringAsFixed(2)} MB Junk Files",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(

        title: const Text(
          "Deep Analyzer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _performRealScan,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isInitialLoading 
          ? _buildLoadingState()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GlowingBubble(
                    percentage: _isScanning ? _scanProgress : _healthPercentage,
                    animationValue: _waveController.value,
                    isCleaning: _isScanning,
                    showResults: false,
                  ),
                  const SizedBox(height: 30),
                  _sectionHeader("Junk Files", theme),
                  _buildJunkFilesSection(theme),
                  const SizedBox(height: 25),
                  _sectionHeader("Real-time Distribution", theme),
                  _buildCategoryGrid(theme),
                  const SizedBox(height: 25),
                  _sectionHeader("App Folder Storage", theme),
                  _buildAppsList(theme),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isInitialLoading ? null : _buildScanButton(),
    );
  }

  Future<List<Map<String, dynamic>>> _scanJunkFiles() async {
    List<Map<String, dynamic>> junkFiles = [];

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
            String fileName = p.basename(path);

            if (path.endsWith(".log") ||
                path.endsWith(".tmp") ||
                path.endsWith(".cache") ||
                path.endsWith(".thumb") ||
                path.endsWith(".bak")) {

              int size = f.lengthSync();
              String type = _getJunkFileType(path);

              junkFiles.add({
                'name': fileName,
                'path': f.path,
                'size': size,
                'type': type,
                'icon': _getJunkFileIcon(type),
                'color': _getJunkFileColor(type),
              });

            }

          } catch (_) {}

        }

      } catch (_) {}

    }

    return junkFiles;
  }

  String _getJunkFileType(String path) {
    if (path.endsWith(".log")) return "Log Files";
    if (path.endsWith(".tmp")) return "Temp Files";
    if (path.endsWith(".cache")) return "Cache Files";
    if (path.endsWith(".thumb")) return "Thumbnails";
    if (path.endsWith(".bak")) return "Backup Files";
    return "Other";
  }

  IconData _getJunkFileIcon(String type) {
    switch (type) {
      case "Log Files":
        return Icons.description;
      case "Temp Files":
        return Icons.timer;
      case "Cache Files":
        return Icons.cached;
      case "Thumbnails":
        return Icons.image;
      case "Backup Files":
        return Icons.backup;
      default:
        return Icons.file_present;
    }
  }

  Color _getJunkFileColor(String type) {
    switch (type) {
      case "Log Files":
        return Colors.orange;
      case "Temp Files":
        return Colors.red;
      case "Cache Files":
        return Colors.blue;
      case "Thumbnails":
        return Colors.purple;
      case "Backup Files":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildJunkFilesSection(ThemeData theme) {
    if (_junkFilesData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No any type of junk files",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your storage is clean and optimized",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You are safe! (●'◡'●)",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _junkFilesData.length > 5 ? 5 : _junkFilesData.length,
              itemBuilder: (context, index) {
                final junkFile = _junkFilesData[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: junkFile['color'].withOpacity(0.1),
                    child: Icon(junkFile['icon'], color: junkFile['color']),
                  ),
                  title: Text(
                    junkFile['name'],
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(junkFile['type']),
                  trailing: Text(
                    junkFile['size'] < 1024 * 1024
                        ? "${(junkFile['size'] / 1024).toStringAsFixed(1)} KB"
                        : "${(junkFile['size'] / (1024 * 1024)).toStringAsFixed(1)} MB",
                  ),
                );
              },
            ),
            if (_junkFilesData.length > 5)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "... and ${_junkFilesData.length - 5} more junk files",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3 + _pulseController.value * 0.2),
                          blurRadius: 30 + _pulseController.value * 20,
                          spreadRadius: 5 + _pulseController.value * 10,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: CustomPaint(
                        painter: WavePainter(
                          _waveController.value,
                          0.5,
                          theme.colorScheme.primary
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Analyzing...",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            "Deep Analyzer is scanning your storage",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This may take a few moments",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: _realCategoryData.entries
            .map(
              (e) => _categoryTile(
                e.key,
                "${e.value.toStringAsFixed(3)} GB",
                _getIcon(e.key),
                _getColor(e.key),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAppsList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: _realAppsData
              .map(
                (app) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: app['color'].withOpacity(0.1),
                    child: Icon(app['icon'], color: app['color']),
                  ),
                  title: Text(app['name']),
                  trailing: Text(
                    "${(app['size'] as double).toStringAsFixed(2)} GB",
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _categoryTile(String title, String size, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                Text(
                  size,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isScanning ? null : _cleanStorage,
        icon: const Icon(Icons.cleaning_services),
        label: const Text(
          "CLEAN JUNK FILES",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          elevation: 8,
        ),
      ),
    );
  }

  IconData _getIcon(String key) => key == "Images"
      ? Icons.image
      : key == "Videos"
      ? Icons.movie
      : key == "Audio"
      ? Icons.music_note
      : Icons.description;

  Color _getColor(String key) => key == "Images"
      ? Colors.blue
      : key == "Videos"
      ? Colors.orange
      : key == "Audio"
      ? Colors.purple
      : Colors.green;
}
