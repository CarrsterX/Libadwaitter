import 'dart:async';

import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const String _notificationId = 'libadwaitter-demo-test';

  final TextEditingController _titleController =
      TextEditingController(text: 'Adwaitter Demo');
  final TextEditingController _bodyController = TextEditingController(
    text: 'Interactive system notification from Libadwaitter.',
  );

  int _priorityIndex = 1; // Normal
  bool _includeActions = true;
  String _permissionStatus = 'Not requested';
  final List<String> _eventLog = <String>[];
  StreamSubscription<AdwNotificationEvent>? _subscription;

  static const List<String> _priorityLabels = [
    'Low',
    'Normal',
    'High',
    'Urgent',
  ];

  static const List<AdwNotificationPriority> _priorities = [
    AdwNotificationPriority.low,
    AdwNotificationPriority.normal,
    AdwNotificationPriority.high,
    AdwNotificationPriority.urgent,
  ];

  @override
  void initState() {
    super.initState();
    _subscription = AdwPortal.notificationEvents.listen(_onNotificationEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onNotificationEvent(AdwNotificationEvent event) {
    if (!mounted) return;
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final kind = event.isDefaultAction
        ? 'Tapped notification body'
        : 'Clicked action "${event.actionId}"';
    final payloadInfo =
        event.payload != null ? ' (payload: ${event.payload})' : '';
    setState(() {
      _eventLog.insert(0, '[$ts] $kind — id: ${event.notificationId}$payloadInfo');
      if (_eventLog.length > 10) {
        _eventLog.removeLast();
      }
    });
  }

  Future<void> _requestPermission(BuildContext context) async {
    final result = await AdwPortal.requestNotificationPermission();
    if (!mounted) return;
    setState(() {
      _permissionStatus = result.isGranted
          ? 'Granted'
          : '${result.status.name}${result.errorMessage != null ? ' (${result.errorMessage})' : ''}';
    });
    if (context.mounted) {
      AdwToastOverlay.maybeOf(context)?.addToast(
        AdwToast(
          title: Text('Notification permission: $_permissionStatus'),
        ),
      );
    }
  }

  Future<void> _sendNotification(BuildContext context) async {
    final title = _titleController.text.trim().isEmpty
        ? 'Adwaitter Demo'
        : _titleController.text.trim();
    final body = _bodyController.text.trim();

    final result = await AdwPortal.sendNotification(
      id: _notificationId,
      title: title,
      body: body.isEmpty ? null : body,
      iconName: 'preferences-system-notifications-symbolic',
      priority: _priorities[_priorityIndex],
      payload: 'demo-payload',
      actions: _includeActions
          ? const [
              AdwNotificationAction(id: 'open', label: 'Open'),
              AdwNotificationAction(id: 'ack', label: 'Acknowledge'),
            ]
          : const [],
    );
    if (!mounted) return;
    final message = result.isGranted
        ? 'System notification sent'
        : 'Notification ${result.status.name}: ${result.errorMessage ?? ''}';
    if (context.mounted) {
      AdwToastOverlay.maybeOf(context)?.addToast(
        AdwToast(title: Text(message)),
      );
    }
  }

  Future<void> _withdrawNotification(BuildContext context) async {
    await AdwPortal.withdrawNotification(_notificationId);
    if (!mounted) return;
    if (context.mounted) {
      AdwToastOverlay.maybeOf(context)?.addToast(
        const AdwToast(title: Text('Notification withdrawn')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return AdwToastOverlay(
      child: Builder(
        builder: (toastContext) => AdwPreferencesPage(
          children: [
            const AdwStatusPage(
              icon: Icon(
                AdwIcons.preferences_system_notifications_symbolic,
                size: 64,
              ),
              title: Text('Notifications'),
              description: Text(
                'Send interactive system notifications on Linux (GNotification / XDG Portal) and Android (NotificationManager).',
              ),
            ),
            const SizedBox(height: 16),
            AdwPreferencesGroup(
              title: const Text('Permission'),
              children: [
                AdwActionRow(
                  title: const Text('Notification Permission'),
                  subtitle: Text('Status: $_permissionStatus'),
                  trailing: AdwButton(
                    onPressed: () => _requestPermission(toastContext),
                    child: const Text('Request'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdwPreferencesGroup(
              title: const Text('Compose'),
              children: [
                AdwEntryRow(
                  title: const Text('Title'),
                  controller: _titleController,
                ),
                AdwEntryRow(
                  title: const Text('Body'),
                  controller: _bodyController,
                ),
                AdwComboRow<String>(
                  title: const Text('Priority'),
                  items: _priorityLabels,
                  selectedItem: _priorityLabels[_priorityIndex],
                  onSelected: (value) {
                    final idx = _priorityLabels.indexOf(value);
                    if (idx >= 0) setState(() => _priorityIndex = idx);
                  },
                ),
                AdwActionRow(
                  title: const Text('Include Action Buttons'),
                  subtitle: const Text('Adds "Open" and "Acknowledge" buttons'),
                  trailing: AdwSwitch(
                    value: _includeActions,
                    onChanged: (v) => setState(() => _includeActions = v),
                  ),
                  onPressed: () =>
                      setState(() => _includeActions = !_includeActions),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AdwButton.suggested(
                  isPill: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  onPressed: () => _sendNotification(toastContext),
                  child: const Text('Send Notification'),
                ),
                const SizedBox(width: 12),
                AdwButton(
                  isPill: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onPressed: () => _withdrawNotification(toastContext),
                  child: const Text('Withdraw'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdwPreferencesGroup(
              title: const Text('Received Events'),
              description: const Text(
                'Click the notification body or one of its action buttons to verify native callbacks.',
              ),
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
                          'No events received yet',
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
        ),
      ),
    );
  }
}
