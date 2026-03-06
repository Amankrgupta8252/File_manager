import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_manager/data/storage_provider.dart';
import 'glowing_bubble.dart';

class CleanUpPage extends StatefulWidget {
  const CleanUpPage({super.key});

  @override
  State<CleanUpPage> createState() => _CleanUpPageState();
}

class _CleanUpPageState extends State<CleanUpPage> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;

  bool _isCleaning = false;
  bool _showResults = false;
  double _healthPercentage = 0.55;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    Future.delayed(Duration.zero, () {
      final storage = context.read<StorageProvider>();
      setState(() {
        _healthPercentage = (1 - (storage.usedGB / storage.usableTotalGB)).clamp(0.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCleaningProcess() async {
    setState(() => _isCleaning = true);
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isCleaning = false;
      _showResults = true;
      _healthPercentage = 0.92;
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Deep Clean", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Storage Header
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _showResults ? 0.0 : 1.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderInfo("Used", "${storage.usedMarketedGB.toStringAsFixed(1)} GB", theme),
                  _buildHeaderInfo("Total", "${storage.marketedTotalGB.toStringAsFixed(1)} GB", theme),
                ],
              ),
            ),
          ),

          // Glowing Bubble
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            top: _showResults ? 20 : 140,
            left: 0,
            right: 0,
            child: _buildAnimatedBubble(theme),
          ),

          // Results Section
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutQuart,
            top: _showResults ? 200 : MediaQuery.of(context).size.height,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildResultsList(theme),
          ),

          // Start Button
          if (!_showResults)
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: _buildAnimatedButton(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBubble(ThemeData theme) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(_pulseController),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: _showResults ? 140 : 220,
          height: _showResults ? 140 : 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(_isCleaning ? 0.3 : 0.1),
                blurRadius: _isCleaning ? 40 : 20,
                spreadRadius: _isCleaning ? 10 : 2,
              )
            ],
          ),
          child: ClipOval(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  // Ensure WavePainter accepts these 3 arguments: value, percentage, color
                  painter: WavePainter(_waveController.value, _healthPercentage,),
                  child: Center(
                    child: Text(
                      "${(_healthPercentage * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: _showResults ? 28 : 42,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        // theme.canvasColor ya theme.scaffoldBackgroundColor ka use karein
        // taaki ye background se alag dikhe
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _sectionTitle("Large Applications", theme),
          _buildItemCard(Icons.play_circle_fill, "YouTube", "1.4 GB", theme, () {
            // Add your app navigation logic here
          }),
          _buildItemCard(Icons.camera_alt, "Instagram", "920 MB", theme, () {}),
          const SizedBox(height: 20),
          _sectionTitle("Large Folders (>2GB)", theme),
          _buildItemCard(Icons.folder, "Movies", "4.2 GB", theme, () {}),
          _buildItemCard(Icons.folder_special, "WhatsApp Data", "2.8 GB", theme, () {}),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton(ThemeData theme) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isCleaning ? 0.8 : 1.0,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.indigoAccent

        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isCleaning ? null : _startCleaningProcess,
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: _isCleaning
                  ? CircularProgressIndicator(
                color: theme.colorScheme.onPrimary,
                strokeWidth: 3,
              )
                  : Text(
                "START OPTIMIZING",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  // onPrimary hamesha background ke contrast mein hota hai
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildItemCard(IconData icon, String title, String size, ThemeData theme, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      // Dark mode mein card ko thoda light (surface container) rakhein
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.1))
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          // Primary color icon ke liye aur background ke liye opacity
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: theme.colorScheme.primary)
        ),
        title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            )
        ),
        subtitle: Text(
            "Storage: $size",
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            )
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}