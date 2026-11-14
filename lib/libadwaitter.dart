/// Pure Dart & Flutter implementation of GNOME Libadwaita and GNOME HIG.
library libadwaitter;

// Core framework behaviors
export 'src/core/adw_scroll_behavior.dart';
export 'src/core/adw_scrollbar.dart';
export 'src/core/adw_spring.dart';

// Theme and design tokens
export 'src/l10n/adw_localizations.dart';
export 'src/theme/adw_colors.dart';
export 'src/theme/adw_curves.dart';
export 'src/theme/adw_desktop_settings.dart';
export 'src/theme/adw_metrics.dart';
export 'src/theme/adw_style_manager.dart';
export 'src/theme/adw_theme.dart';
export 'src/theme/adw_typography.dart';

// Widgets: Controls
export 'src/widgets/controls/adw_button.dart';
export 'src/widgets/controls/adw_button_row.dart';
export 'src/widgets/controls/adw_check_button.dart';
export 'src/widgets/controls/adw_combo_row.dart';
export 'src/widgets/controls/adw_entry_row.dart';
export 'src/widgets/controls/adw_spin_row.dart';
export 'src/widgets/controls/adw_switch.dart';
export 'src/widgets/controls/adw_switch_row.dart';
export 'src/widgets/controls/adw_toggle_group.dart';

// Widgets: Containers
export 'src/widgets/containers/adw_action_row.dart';
export 'src/widgets/containers/adw_expander_row.dart';
export 'src/widgets/containers/adw_preferences_group.dart';
export 'src/widgets/containers/adw_preferences_page.dart';
export 'src/widgets/containers/adw_status_page.dart';

// Widgets: Layout
export 'src/widgets/layout/adw_application.dart';
export 'src/widgets/layout/adw_clamp.dart';
export 'src/widgets/layout/adw_header_bar.dart';
export 'src/widgets/layout/adw_toolbar_view.dart';
export 'src/widgets/layout/adw_window.dart';
export 'src/widgets/layout/adw_window_controls.dart';
export 'src/widgets/layout/adw_window_title.dart';

// Widgets: Navigation
export 'src/widgets/navigation/adw_carousel.dart';
export 'src/widgets/navigation/adw_carousel_indicator_dots.dart';
export 'src/widgets/navigation/adw_navigation_split_view.dart';
export 'src/widgets/navigation/adw_navigation_transition.dart';
export 'src/widgets/navigation/adw_navigation_view.dart';
export 'src/widgets/navigation/adw_sidebar_item.dart';
export 'src/widgets/navigation/adw_view_switcher.dart';

// Widgets: Overlays
export 'src/widgets/overlays/adw_about_dialog.dart';
export 'src/widgets/overlays/adw_alert_dialog.dart';
export 'src/widgets/overlays/adw_banner.dart';
export 'src/widgets/overlays/adw_toast.dart';

// Widgets: Display
export 'src/widgets/display/adw_emblem.dart';
