typedef WebMediaCommandCallback = void Function(
  String command, {
  int? positionUs,
  int? offsetUs,
});

void webMediaRegisterHandlers(WebMediaCommandCallback onCommand) {}

void webMediaSetMetadata({
  required String title,
  String? artist,
  String? album,
  String? artUrl,
  Duration? duration,
}) {}

void webMediaSetPlaybackState({
  required String status,
  Duration position = Duration.zero,
  double rate = 1.0,
}) {}

void webMediaSetPosition(Duration position) {}

void webMediaDispose() {}
