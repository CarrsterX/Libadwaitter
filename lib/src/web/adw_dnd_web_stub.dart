typedef WebDropCallback = void Function({
  required String type,
  required double x,
  required double y,
  List<String> files,
  String? text,
});

void webDndRegister(WebDropCallback onEvent) {}
