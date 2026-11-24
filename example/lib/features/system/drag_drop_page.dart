import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

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
        AdwDropTarget(
          onDrop: _handleDrop,
          builder: (context, isDraggingOver, child) {
            return AnimatedContainer(
              duration: AdwCurves.shortDuration,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: isDraggingOver
                    ? theme.colors.accentColor.withValues(alpha: 0.14)
                    : theme.colors.cardBackground,
                borderRadius: BorderRadius.circular(AdwMetrics.cardRadius),
                border: Border.all(
                  color: isDraggingOver
                      ? theme.colors.accentColor
                      : theme.colors.windowForeground.withValues(alpha: 0.14),
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
