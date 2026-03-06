class QuickAccessFolder {
  final String name;
  final String path;

  QuickAccessFolder({
    required this.name,
    required this.path,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "path": path,
    };
  }

  factory QuickAccessFolder.fromJson(Map<String, dynamic> json) {
    return QuickAccessFolder(
      name: json["name"],
      path: json["path"],
    );
  }
}