typedef WebNotificationCallback = void Function(
  String id,
  String actionId,
  bool isClosed,
);

Future<Map<String, dynamic>> webOpenUri(String uri) async =>
    const {'status': 'unsupported'};

Future<Map<String, dynamic>> webShare({
  String? title,
  String? text,
  String? url,
}) async =>
    const {'status': 'unsupported'};

Future<Map<String, dynamic>> webRequestNotificationPermission() async =>
    const {'status': 'unsupported'};

Future<Map<String, dynamic>> webSendNotification({
  required String id,
  required String title,
  String? body,
  required WebNotificationCallback onEvent,
}) async =>
    const {'status': 'unsupported'};

Future<Map<String, dynamic>> webWithdrawNotification(String id) async =>
    const {'status': 'unsupported'};
