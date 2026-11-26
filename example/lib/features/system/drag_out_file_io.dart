import 'dart:io';

/// Writes [content] to a readable `example.txt` file in the system temp
/// directory so external apps can receive it via native Drag & Drop.
Future<String?> materializeExampleAssetFile(String content) async {
  try {
    final file = File('${Directory.systemTemp.path}/example.txt');
    await file.writeAsString(content);
    return file.path;
  } catch (_) {
    return null;
  }
}
