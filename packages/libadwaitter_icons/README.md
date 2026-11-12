# libadwaitter_icons

Paquete independiente de iconos para Flutter con el conjunto oficial de **iconos simbólicos de Adwaita de GNOME**.

Este paquete está completamente desacoplado de `libadwaitter`, permitiendo utilizar los iconos oficiales de GNOME en cualquier aplicación de Flutter (ya sea con `Material`, `Cupertino` o `Libadwaitter`) sin obligar a los desarrolladores a arrastrar dependencias innecesarias.

---

## 🏛️ Reconocimientos Upstream

Todos los iconos provienen directamente del repositorio oficial de GNOME en **GitLab**:

* **[Adwaita Icon Theme en GitLab](https://gitlab.gnome.org/GNOME/adwaita-icon-theme)**: Conjunto de iconos vectoriales del escritorio GNOME.

---

## 🚀 Uso

```yaml
dependencies:
  flutter:
    sdk: flutter
  libadwaitter_icons: ^0.1.0
```

```dart
import 'package:flutter/widgets.dart';
import 'package:libadwaitter_icons/libadwaitter_icons.dart';

Widget build(BuildContext context) {
  return const Icon(
    AdwIcons.document_save_symbolic,
    size: 20,
  );
}
```

---

## 📜 Licencia

* Iconos basados en el tema oficial de GNOME bajo licencias **LGPL-2.1+ / CC-BY-SA 3.0**. Consulta [LICENSE](LICENSE) para más información.

