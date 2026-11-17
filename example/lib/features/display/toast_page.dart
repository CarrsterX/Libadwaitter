import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

import '../../demo_icons.dart';

class ToastPage extends StatefulWidget {
  const ToastPage({super.key});

  @override
  State<ToastPage> createState() => _ToastPageState();
}

class _ToastPageState extends State<ToastPage> {
  int _toastUndoCount = 0;
  AdwToast? _undoToast;

  @override
  Widget build(BuildContext context) {
    return AdwStatusPage(
      icon: const DemoWidgetIcon(DemoIconType.toasts, size: 128),
      title: const Text('Toasts'),
      description: const Text('Transient in-app notifications'),
      child: AdwClamp(
        maximumSize: 400,
        child: AdwPreferencesGroup(
          children: [
            AdwActionRow(
              title: const Text('Simple Toast'),
              trailing: AdwButton(
                onPressed: () {
                  AdwToastOverlay.of(context).addToast(
                    const AdwToast(title: Text('Simple Toast')),
                  );
                },
                child: const Text('Show'),
              ),
            ),
            AdwActionRow(
              title: const Text('Toast With an Action'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdwButton.flat(
                    padding: const EdgeInsets.all(6),
                    onPressed: _undoToast == null
                        ? null
                        : () {
                            AdwToastOverlay.of(context)
                                .dismissToast(_undoToast!);
                            setState(() => _undoToast = null);
                          },
                    child: const Icon(AdwIcons.user_trash_symbolic, size: 16),
                  ),
                  const SizedBox(width: 6),
                  AdwButton(
                    onPressed: () {
                      _toastUndoCount++;
                      final prevToast = _undoToast;
                      final toast = AdwToast(
                        title: Text(
                          _toastUndoCount == 1
                              ? '‘Lorem Ipsum’ deleted'
                              : '$_toastUndoCount items deleted',
                        ),
                        action: AdwButton(
                          onPressed: () {
                            final count = _toastUndoCount;
                            setState(() {
                              _toastUndoCount = 0;
                              _undoToast = null;
                            });
                            AdwToastOverlay.of(context).addToast(
                              AdwToast(
                                title: Text(
                                  count == 1
                                      ? 'Undoing deleting 1 item'
                                      : 'Undoing deleting $count items',
                                ),
                                timeout: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Undo'),
                        ),
                      );
                      setState(() => _undoToast = toast);
                      AdwToastOverlay.of(context).replaceOrAddToast(
                        toast,
                        replacing: prevToast,
                      );
                    },
                    child: const Text('Show'),
                  ),
                ],
              ),
            ),
            AdwActionRow(
              title: const Text('Toast With a Long Title'),
              trailing: AdwButton(
                onPressed: () {
                  AdwToastOverlay.of(context).addToast(
                    const AdwToast(
                      title: Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
                        'sed do eiusmod tempor incididunt ut labore et dolore.',
                      ),
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
            AdwActionRow(
              title: const Text('Dismiss all Toasts'),
              trailing: AdwButton(
                onPressed: () {
                  AdwToastOverlay.of(context).dismissAll();
                  setState(() => _undoToast = null);
                },
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
