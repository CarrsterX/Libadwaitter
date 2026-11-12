import 'package:flutter/widgets.dart';

import '../containers/adw_action_row.dart';
import 'adw_switch.dart';

/// A preference row with an integrated switch (`AdwSwitchRow`).
///
/// Toggles the boolean state either by interacting directly with the
/// switch or clicking anywhere on the row body.
class AdwSwitchRow extends StatelessWidget {
  final Widget? leading;
  final Widget? prefix;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdwSwitchRow({
    super.key,
    this.leading,
    this.prefix,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdwActionRow(
      prefix: prefix ?? leading,
      title: title,
      subtitle: subtitle,
      suffix: AdwSwitch(
        value: value,
        onChanged: onChanged,
      ),
      onPressed: onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}

