import 'dart:io';

Future<int> getDocumentCount() async {
  int count = 0;

  final Directory root = Directory('/storage/emulated/0');

  final extensions = [
    '.pdf', '.doc', '.docx',
    '.txt', '.xls', '.xlsx',
    '.ppt', '.pptx'
  ];

  await for (final entity
  in root.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final path = entity.path.toLowerCase();

      if (extensions.any((ext) => path.endsWith(ext))) {
        count++;
      }
    }
  }

  return count;
}