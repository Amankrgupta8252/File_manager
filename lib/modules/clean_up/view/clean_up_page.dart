import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
  double _healthPercentage = 0.45;
  double _scanProgress = 0;

  Map<String, double> _realCategoryData = {
    "Images": 0,
    "Videos": 0,
    "Audio": 0,
    "Docs": 0,
  };
  List<Map<String, dynamic>> _realAppsData = [];

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

    if (!mounted) return;
    setState(() {
      _realCategoryData = result.categorySizes;
      _realAppsData = result.realApps.where((app) => app['size'] > 0).toList();
      double totalUsed = result.categorySizes.values.fold(0, (a, b) => a + b);
      _healthPercentage = (1 - (totalUsed / 128)).clamp(0.1, 1.0);
      _isScanning = false;
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

    if (!mounted) return;
    setState(() {
      _realCategoryData = result.categorySizes;
      _realAppsData = result.realApps.where((app) => app['size'] > 0).toList();
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
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _performRealScan,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
      floatingActionButton: _buildScanButton(),
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
