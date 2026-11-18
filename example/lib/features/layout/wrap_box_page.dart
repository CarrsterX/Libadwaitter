import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class WrapBoxPage extends StatefulWidget {
  const WrapBoxPage({super.key});

  @override
  State<WrapBoxPage> createState() => _WrapBoxPageState();
}

class _WrapBoxPageState extends State<WrapBoxPage> {
  static const List<String> _loremIpsum = [
    'Lorem', 'Ipsum', 'Dolor', 'Sit', 'Amet', 'Consectetur', 'Adipiscing',
    'Elit', 'Sed', 'Do', 'Eiusmod', 'Tempor', 'Incididunt', 'Ut', 'Labore',
    'Et', 'Dolore', 'Magnam', 'Aliquam', 'Quaerat', 'Voluptatem', 'Ut',
    'Enim', 'Aeque', 'Doleamus', 'Animo', 'Cum', 'Corpore', 'Dolemus',
    'Fieri', 'Tamen', 'Permagna', 'Accessio', 'Potest', 'Si', 'Aliquod',
    'Aeternum', 'Ullus', 'Investigandi', 'Veri', 'Nisi', 'Inveneris', 'Et',
    'Quaerendi', 'Defatigatio', 'Turpis', 'Est', 'Cum', 'Esset', 'Accusata',
    'Et', 'Vituperata', 'Ab', 'Hortensio', 'Qui', 'Liber', 'Cum', 'Et',
    'Mortem', 'Contemnit', 'Qua', 'Qui', 'Est', 'Imbutus', 'Quietus',
    'Esse', 'Numquam', 'Potest', 'Praeterea', 'Bona', 'Praeterita',
    'Grata', 'Recordatione', 'Renovata', 'Delectant', 'Est', 'Autem',
    'Situm', 'In',
  ];

  final List<_TagItem> _tags = [];
  int _currentWord = 0;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 10; i++) {
      _appendTag();
    }
  }

  void _appendTag() {
    _tags.add(_TagItem(id: _nextId++, label: _loremIpsum[_currentWord]));
    _currentWord = (_currentWord + 1) % _loremIpsum.length;
  }

  void _addTag() {
    setState(_appendTag);
  }

  void _removeTag(int id) {
    setState(() {
      _tags.removeWhere((tag) => tag.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.wrapBox, size: 128),
      title: const Text('Wrap Box'),
      description: const Text(
        'A box-like widget that can wrap into multiple lines.',
      ),
      maxWidth: 400.0,
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 12.0),
      clampChild: false,
      child: AdwClamp(
        minimumMargin: 0.0,
        child: AdwWrapBox(
          lineSpacing: 6.0,
          childSpacing: 6.0,
          children: [
            for (final tag in _tags)
              _TagChip(
                key: ValueKey(tag.id),
                label: tag.label,
                foregroundColor: theme.colors.windowForeground,
                textStyle: theme.typography.body,
                onRemove: () => _removeTag(tag.id),
              ),
            AdwButton(
              style: AdwButtonStyle.flat,
              isCircular: true,
              padding: const EdgeInsets.all(9.0),
              onPressed: _addTag,
              child: const Icon(
                AdwIcons.list_add_symbolic,
                size: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagItem {
  final int id;
  final String label;

  const _TagItem({required this.id, required this.label});
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final TextStyle textStyle;
  final VoidCallback onRemove;

  const _TagChip({
    super.key,
    required this.label,
    required this.foregroundColor,
    required this.textStyle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: foregroundColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99.0),
      ),
      padding: const EdgeInsetsDirectional.only(start: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: AdwButton(
              style: AdwButtonStyle.flat,
              isCircular: true,
              padding: const EdgeInsets.all(6.0),
              onPressed: onRemove,
              child: const Icon(
                AdwIcons.window_close_symbolic,
                size: 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
