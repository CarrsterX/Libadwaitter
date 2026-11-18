import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  final GlobalKey _avatarKey = GlobalKey();
  late final TextEditingController _textController;
  bool _showInitials = true;
  double _size = 128;
  File? _customImageFile;

  late final List<String> _contacts;

  static const _firstNames = [
    'Adam',
    'Adrian',
    'Anna',
    'Charlotte',
    'Frédérique',
    'Ilaria',
    'Jakub',
    'Jennyfer',
    'Julia',
    'Justin',
    'Mario',
    'Miriam',
    'Mohamed',
    'Nourimane',
    'Owen',
    'Peter',
    'Petra',
    'Rachid',
    'Rebecca',
    'Sarah',
    'Thibault',
    'Wolfgang',
  ];

  static const _lastNames = [
    'Bailey',
    'Bernard',
    'Bonnet',
    'Davis',
    'Durand',
    'Egger',
    'Fournier',
    'García',
    'González',
    'Han',
    'Kowalski',
    'Lefèvre',
    'López',
    'Martin',
    'Meyer',
    'Müller',
    'Novak',
    'Patel',
    'Rossi',
    'Schmidt',
    'Urasawa',
    'Weber',
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _contacts = List.generate(30, (_) {
      final first = _firstNames[rng.nextInt(_firstNames.length)];
      final last = _lastNames[rng.nextInt(_lastNames.length)];
      return '$first $last';
    });
    _textController = TextEditingController(
      text: '${_firstNames[rng.nextInt(_firstNames.length)]} '
          '${_lastNames[rng.nextInt(_lastNames.length)]}',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarFile() async {
    final result = await AdwPortal.openFiles(
      title: 'Select an Avatar',
      multiple: false,
    );
    if (!mounted) return;
    if (result.status == AdwPortalStatus.granted &&
        result.value != null &&
        result.value!.isNotEmpty) {
      final path = result.value!.first;
      final lower = path.toLowerCase();
      const imageExts = ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'];
      if (!imageExts.any(lower.endsWith)) {
        AdwToastOverlay.of(context).addToast(
          const AdwToast(title: Text('Please select a valid image file')),
        );
        return;
      }
      setState(() {
        _customImageFile = File(path);
      });
    }
  }

  Future<void> _exportAvatarToFile() async {
    final result = await AdwPortal.saveFile(
      title: 'Save Avatar',
      currentName: 'avatar.png',
    );
    if (!mounted ||
        result.status != AdwPortalStatus.granted ||
        result.value == null) {
      return;
    }

    final boundary =
        _avatarKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final file = File(result.value!);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    if (!mounted) return;

    final fileName = result.value!.split('/').last;
    AdwToastOverlay.of(context).addToast(
      AdwToast(title: Text('Exported to $fileName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final double bottomInset =
        MediaQuery.maybePaddingOf(context)?.bottom ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 32, 16, 32 + bottomInset),
      child: Column(
        children: [
          RepaintBoundary(
            key: _avatarKey,
            child: AdwAvatar(
              size: _size,
              text: _textController.text,
              showInitials: _showInitials,
              customImage:
                  _customImageFile != null ? FileImage(_customImageFile!) : null,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Avatar',
            style: theme.typography.title1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A user avatar with generated fallback',
            style: theme.typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 38),
          AdwClamp(
            maximumSize: 430,
            child: Column(
              children: [
                AdwPreferencesGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    AdwEntryRow(
                      title: const Text('Text'),
                      controller: _textController,
                      editIcon: const Icon(
                        AdwIcons.document_edit_symbolic,
                        size: 16,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    AdwSwitchRow(
                      title: const Text('Show Initials'),
                      value: _showInitials,
                      onChanged: (value) =>
                          setState(() => _showInitials = value),
                    ),
                    AdwActionRow(
                      title: const Text('File'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdwButton(
                            onPressed: _pickAvatarFile,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  AdwIcons.document_open_symbolic,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _customImageFile != null
                                      ? _customImageFile!.path.split('/').last
                                      : '(None)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          AdwButton.flat(
                            padding: const EdgeInsets.all(6),
                            onPressed: _customImageFile == null
                                ? null
                                : () => setState(() => _customImageFile = null),
                            child: const Icon(
                              AdwIcons.user_trash_symbolic,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdwSpinRow(
                      title: const Text('Size'),
                      value: _size,
                      min: 24,
                      max: 320,
                      step: 8,
                      onChanged: (value) => setState(() => _size = value),
                    ),
                    AdwActionRow(
                      title: const Text('Export to File'),
                      trailing: AdwButton.flat(
                        padding: const EdgeInsets.all(6),
                        onPressed: _customImageFile == null
                            ? null
                            : _exportAvatarToFile,
                        child: const Icon(
                          AdwIcons.document_save_symbolic,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdwPreferencesGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    for (final name in _contacts)
                      AdwActionRow(
                        minHeight: 64,
                        prefix: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: AdwAvatar(
                            size: 40,
                            text: name,
                            showInitials: true,
                          ),
                        ),
                        title: Text(name),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
