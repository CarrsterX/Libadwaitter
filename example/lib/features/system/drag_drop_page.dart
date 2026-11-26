import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import 'drag_out_file_stub.dart'
    if (dart.library.io) 'drag_out_file_io.dart';

class DragDropPage extends StatefulWidget {
  const DragDropPage({super.key});

  @override
  State<DragDropPage> createState() => _DragDropPageState();
}

class _DragDropPageState extends State<DragDropPage> {
  final List<({String title, String subtitle})> _droppedItems = [];
  final List<String> _droppedFiles = [];
  final GlobalKey _emojiButtonKey = GlobalKey();
  String _selectedEmoji = '🐧';
  String? _exampleAssetPath;
  String _exampleAssetText = 'Hello World!';

  @override
  void initState() {
    super.initState();
    _prepareExampleAssetFile();
  }

  Future<void> _prepareExampleAssetFile() async {
    try {
      final text = await rootBundle.loadString('assets/example.txt');
      _exampleAssetText = text.trim().isNotEmpty ? text : 'Hello World!';
      final path = await materializeExampleAssetFile(_exampleAssetText);
      if (mounted && path != null) {
        setState(() => _exampleAssetPath = path);
      }
    } catch (_) {
      // Fallback to plain text if asset cannot be materialized
    }
  }

  void _handleDrop(List<String> files, String? text) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      for (final path in files) {
        final name = path.split('/').last;
        _droppedItems.insert(0, (title: name, subtitle: '[$ts] File: $path'));
        _droppedFiles.insert(0, path);
      }
      if (text != null && text.isNotEmpty) {
        _droppedItems.insert(0, (title: text, subtitle: '[$ts] Dropped text'));
      }
      while (_droppedItems.length > 15) {
        _droppedItems.removeLast();
      }
      while (_droppedFiles.length > 10) {
        _droppedFiles.removeLast();
      }
    });
  }

  Future<void> _shareText(BuildContext toastContext) async {
    final res = await AdwPortal.share(
      title: 'Share from Adwaitter Demo',
      subject: 'Libadwaitter',
      text: 'Shared from Adwaitter Demo — https://github.com/CarrsterX/Libadwaitter',
    );
    if (!mounted || !toastContext.mounted) return;
    AdwToastOverlay.maybeOf(toastContext)?.addToast(
      AdwToast(
        title: Text(
          res.isGranted
              ? 'Share sheet opened / copied'
              : 'Share ${res.status.name}',
        ),
      ),
    );
  }

  Future<void> _pickEmoji(BuildContext toastContext) async {
    double? x;
    double? y;
    final box =
        _emojiButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final pos = box.localToGlobal(Offset(box.size.width / 2, box.size.height));
      x = pos.dx;
      y = pos.dy;
    }
    final res = await AdwPortal.pickEmoji(x: x, y: y);
    if (!mounted) return;
    if (res.isGranted && res.value != null && res.value!.isNotEmpty) {
      setState(() => _selectedEmoji = res.value!);
    } else if (toastContext.mounted && res.isUnsupported) {
      AdwToastOverlay.maybeOf(toastContext)?.addToast(
        const AdwToast(
          title: Text('Native emoji chooser is Linux-only (use keyboard on Android)'),
        ),
      );
    }
  }

  Future<void> _shareDroppedFiles(BuildContext toastContext) async {
    if (_droppedFiles.isEmpty) return;
    final res = await AdwPortal.share(
      title: 'Share Dropped Files',
      filePaths: _droppedFiles,
    );
    if (!mounted || !toastContext.mounted) return;
    AdwToastOverlay.maybeOf(toastContext)?.addToast(
      AdwToast(
        title: Text(
          res.isGranted
              ? 'File share opened'
              : 'Share ${res.status.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return AdwToastOverlay(
      child: Builder(
        builder: (toastContext) => AdwPreferencesPage(
      children: [
        const AdwStatusPage(
          icon: Icon(AdwIcons.folder_download_symbolic, size: 64),
          title: Text('Drag & Drop / Share'),
          description: Text(
            'Drop files or text from external apps, or share content via the native Android Share Sheet and Linux portals.',
          ),
        ),
        const SizedBox(height: 16),
        AdwPreferencesGroup(
          title: const Text('Native Share Sheet'),
          children: [
            AdwActionRow(
              title: const Text('Share Sample Text'),
              subtitle: const Text(
                'Opens Android Share Sheet or copies to clipboard on Linux',
              ),
              trailing: AdwButton.suggested(
                onPressed: () => _shareText(toastContext),
                child: const Text('Share'),
              ),
            ),
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.linux ||
                    defaultTargetPlatform == TargetPlatform.android))
              AdwActionRow(
                title: const Text('Share Dropped Files'),
                subtitle: Text(
                  _droppedFiles.isEmpty
                      ? 'Drop a file below first to enable sharing'
                      : '${_droppedFiles.length} file(s) ready to share',
                ),
                trailing: AdwButton(
                  onPressed: _droppedFiles.isNotEmpty
                      ? () => _shareDroppedFiles(toastContext)
                      : null,
                  child: const Text('Share Files'),
                ),
              ),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux)
              AdwActionRow(
                title: const Text('Native Emoji Chooser (Linux)'),
                subtitle: Text('Selected: $_selectedEmoji'),
                trailing: AdwButton(
                  key: _emojiButtonKey,
                  onPressed: () => _pickEmoji(toastContext),
                  child: Text('Pick $_selectedEmoji'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.android)) ...[
          AdwPreferencesGroup(
            title: const Text('Drag Out'),
            description: const Text(
              'Grab the file below and drag it into Files (Nautilus), a text editor, or another app.',
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: AdwDragSource(
                    filesProvider: () => _exampleAssetPath != null
                        ? <String>[_exampleAssetPath!]
                        : const <String>[],
                    text: _exampleAssetText,
                    child: _NautilusFileTile(
                      fileName: 'example.txt',
                      subtitle: '13 bytes',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        AdwDropTarget(
          onDrop: _handleDrop,
          builder: (context, isDraggingOver, child) {
            return AnimatedContainer(
              duration: AdwCurves.resolve(context, AdwCurves.shortDuration),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: isDraggingOver
                    ? theme.colors.accentColor.withValues(alpha: 0.14)
                    : theme.colors.cardBackground,
                borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
                border: Border.all(
                  color: isDraggingOver
                      ? theme.colors.accentColor
                      : (theme.colors.isHighContrast
                          ? theme.colors.borderColor
                          : theme.colors.windowForeground
                              .withValues(alpha: 0.14)),
                  width: isDraggingOver ? 2.0 : 1.0,
                ),
              ),
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AdwIcons.folder_download_symbolic,
                size: 36,
                color: theme.colors.accentColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Drop files or text here',
                style: theme.typography.title4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Supports multi-file drops and plain text / URLs',
                style: theme.typography.body.copyWith(
                  color: theme.colors.windowForeground.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AdwPreferencesGroup(
          title: const Text('Dropped Items'),
          headerSuffix: _droppedItems.isNotEmpty
              ? AdwButton.flat(
                  onPressed: () => setState(_droppedItems.clear),
                  child: const Text('Clear'),
                )
              : null,
          children: _droppedItems.isEmpty
              ? [
                  AdwActionRow(
                    title: Text(
                      'Nothing dropped yet',
                      style: theme.typography.body.copyWith(
                        color: theme.colors.windowForeground
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ]
              : _droppedItems
                  .map(
                    (item) => AdwActionRow(
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                    ),
                  )
                  .toList(growable: false),
        ),
      ],
    ),
      ),
    );
  }
}

class _NautilusFileTile extends StatefulWidget {
  final String fileName;
  final String subtitle;

  const _NautilusFileTile({
    required this.fileName,
    required this.subtitle,
  });

  @override
  State<_NautilusFileTile> createState() => _NautilusFileTileState();
}

class _NautilusFileTileState extends State<_NautilusFileTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final isDark = theme.colors.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AdwCurves.resolve(context, AdwCurves.shortDuration),
        width: 112,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered
              ? theme.colors.hoverColor
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(10),
          border: (theme.colors.isHighContrast && _isHovered)
              ? Border.all(color: theme.colors.borderColor, width: 1.0)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF424246)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colors.isHighContrast
                      ? theme.colors.borderColor
                      : theme.colors.windowForeground.withValues(alpha: 0.16),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  AdwIcons.text_x_generic_symbolic,
                  size: 28,
                  color: theme.colors.windowForeground.withValues(alpha: 0.78),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.typography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.typography.caption.copyWith(
                color: theme.colors.secondaryForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
