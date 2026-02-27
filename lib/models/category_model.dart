import 'package:flutter/material.dart';

class FileCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String count;
  final Widget? page;

  FileCategory({required this.name, required this.icon, required this.color, required this.count, this.page});
}