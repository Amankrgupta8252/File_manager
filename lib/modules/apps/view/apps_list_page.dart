import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppsListPage extends StatefulWidget {
  final String title;
  final bool excludeSystem;

  const AppsListPage({
    super.key,
    required this.title,
    required this.excludeSystem
  });

  @override
  State<AppsListPage> createState() => _AppsListPageState();
}

class _AppsListPageState extends State<AppsListPage> {
  Key _refreshKey = UniqueKey();

  // --- UNINSTALL FUNCTION ---
  Future<void> _uninstallApp(String packageName) async {
    try {
      bool? isUninstalled = await InstalledApps.uninstallApp(packageName);

      if (isUninstalled == true) {
        setState(() {
          _refreshKey = UniqueKey();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("App uninstalled successfully")),
          );
        }
      }
    } catch (e) {
      debugPrint("Uninstall Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
      ),
      body: FutureBuilder<List<AppInfo>>(
        key: _refreshKey,
        future: InstalledApps.getInstalledApps(
          excludeSystemApps: widget.excludeSystem,
          withIcon: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No apps found"));
          }

          final apps = snapshot.data!;

          return ListView.builder(
            itemCount: apps.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              AppInfo app = apps[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  // side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: app.icon != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(app.icon!, width: 45, height: 45),
                  )
                      : const Icon(Icons.android, size: 45, color: Colors.green),
                  title: Text(
                    app.name ?? "Unknown App",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    app.packageName ?? "",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  // --- UNINSTALL BUTTON ---
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _uninstallApp(app.packageName),
                  ),
                  onTap: () => InstalledApps.startApp(app.packageName),
                  onLongPress: () => InstalledApps.openSettings(app.packageName),
                ),
              );
            },
          );
        },
      ),
    );
  }
}