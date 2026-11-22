import 'dart:async';

import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class SystemTrayPage extends StatefulWidget {
  const SystemTrayPage({super.key});

  @override
  State<SystemTrayPage> createState() => _SystemTrayPageState();
}

class _SystemTrayPageState extends State<SystemTrayPage> {
  bool? _trayAvailable;
  bool _trayActive = false;
  bool _hideOnClose = false;
  int _pingCount = 0;
  final List<String> _eventLog = <String>[];
  StreamSubscription<AdwTrayEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = AdwSystemTray.events.listen(_handleTrayEvent);
    _checkAvailability();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    if (_trayActive) {
      AdwSystemTray.hide();
    }
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final available = await AdwSystemTray.isAvailable();
    if (!mounted) return;
    setState(() => _trayAvailable = available);
  }

  List<AdwTrayMenuItem> _buildMenuItems() => [
        const AdwTrayMenuItem(id: 'show', label: 'Show Adwaitter Demo'),
        AdwTrayMenuItem(
          id: 'ping',
          label: _pingCount == 0 ? 'Send Ping' : 'Send Ping ($_pingCount)',
        ),
        const AdwTrayMenuItem.separator(),
        const AdwTrayMenuItem(id: 'hide_tray', label: 'Remove Tray Icon'),
      ];

  void _logEvent(String text) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _eventLog.insert(0, '[$ts] $text');
      if (_eventLog.length > 10) {
        _eventLog.removeLast();
      }
    });
  }

  void _handleTrayEvent(AdwTrayEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case AdwTrayEventType.activate:
        AdwSystemTray.showWindow();
        _logEvent('Tray icon activated (primary click)');
      case AdwTrayEventType.menuItemClicked:
        final id = event.itemId ?? '';
        _logEvent('Menu item clicked: "$id"');
        if (id == 'show') {
          AdwSystemTray.showWindow();
        } else if (id == 'ping') {
          setState(() => _pingCount++);
          AdwSystemTray.updateMenu(_buildMenuItems());
        } else if (id == 'hide_tray') {
          _toggleTray(false);
        }
      case AdwTrayEventType.windowHiddenToTray:
        _logEvent('Window hidden to background');
      case AdwTrayEventType.windowRestored:
        _logEvent('Window restored from background');
    }
  }

  Future<void> _toggleTray(bool enabled) async {
    if (enabled) {
      final ok = await AdwSystemTray.show(
        title: 'Adwaitter Demo',
        tooltip: 'Adwaitter Demo — Running in background',
        iconName: 'applications-system-symbolic',
        menuItems: _buildMenuItems(),
      );
      if (!mounted) return;
      setState(() => _trayActive = ok);
      if (ok) {
        _logEvent('Tray icon registered');
      }
    } else {
      await AdwSystemTray.hide();
      if (!mounted) return;
      setState(() {
        _trayActive = false;
        _hideOnClose = false;
      });
      _logEvent('Tray icon removed');
    }
  }

  Future<void> _toggleHideOnClose(bool enabled) async {
    await AdwSystemTray.setHideOnClose(enabled);
    if (!mounted) return;
    setState(() => _hideOnClose = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);
    final statusText = switch (_trayAvailable) {
      null => 'Checking D-Bus StatusNotifierWatcher...',
      true => 'Available (StatusNotifierHost / AppIndicator detected)',
      false => 'Unavailable (Linux desktop with AppIndicator / SNI host required)',
    };

    return AdwPreferencesPage(
      children: [
        const AdwStatusPage(
          icon: Icon(AdwIcons.applications_system_symbolic, size: 64),
          title: Text('System Tray'),
          description: Text(
            'Linux background mode and interactive StatusNotifierItem / AppIndicator tray icon via pure GDBus (zero external dependencies).',
          ),
        ),
        const SizedBox(height: 16),
        AdwPreferencesGroup(
          title: const Text('Detection'),
          children: [
            AdwActionRow(
              title: const Text('StatusNotifier Host'),
              subtitle: Text(statusText),
              trailing: AdwButton(
                onPressed: _checkAvailability,
                child: const Text('Refresh'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdwPreferencesGroup(
          title: const Text('Background & Tray Controls'),
          children: [
            AdwActionRow(
              title: const Text('Show Tray Icon'),
              subtitle: const Text(
                'Publishes org.kde.StatusNotifierItem + com.canonical.dbusmenu',
              ),
              trailing: AdwSwitch(
                value: _trayActive,
                onChanged: _toggleTray,
              ),
              onPressed: () => _toggleTray(!_trayActive),
            ),
            AdwActionRow(
              title: const Text('Hide to Background on Close'),
              subtitle: const Text(
                'Closing the window hides it to the tray instead of exiting',
              ),
              trailing: AdwSwitch(
                value: _hideOnClose,
                onChanged: _trayActive ? _toggleHideOnClose : null,
              ),
              onPressed:
                  _trayActive ? () => _toggleHideOnClose(!_hideOnClose) : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdwButton.suggested(
              isPill: true,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              onPressed: _trayActive ? () => AdwSystemTray.hideWindow() : null,
              child: const Text('Hide Window to Tray'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AdwPreferencesGroup(
          title: const Text('Tray Events'),
          headerSuffix: _eventLog.isNotEmpty
              ? AdwButton.flat(
                  onPressed: () => setState(_eventLog.clear),
                  child: const Text('Clear'),
                )
              : null,
          children: _eventLog.isEmpty
              ? [
                  AdwActionRow(
                    title: Text(
                      'No tray events received yet',
                      style: theme.typography.body.copyWith(
                        color: theme.colors.windowForeground
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ]
              : _eventLog
                  .map((entry) => AdwActionRow(title: Text(entry)))
                  .toList(growable: false),
        ),
      ],
    );
  }
}
