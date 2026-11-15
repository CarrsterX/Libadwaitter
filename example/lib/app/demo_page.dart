/// All pages showcased in the Adwaitter Demo application.
enum DemoPage {
  welcome,
  navigationView,
  splitViews,
  viewSwitcher,
  tabView,
  bottomSheet,
  carousel,
  boxedLists,
  toggleGroups,
  buttons,
  banner,
  toasts,
  spinner,
  avatar,
  alertDialog,
  aboutDialog,
  clamp,
  wrapBox,
  multiLayoutView,
  styleClasses,
  animations,
  appearance,
}

extension DemoPageMeta on DemoPage {
  String get title {
    switch (this) {
      case DemoPage.welcome:
        return 'Welcome';
      case DemoPage.navigationView:
        return 'Navigation View';
      case DemoPage.splitViews:
        return 'Split Views';
      case DemoPage.viewSwitcher:
        return 'View Switcher';
      case DemoPage.tabView:
        return 'Tab View';
      case DemoPage.bottomSheet:
        return 'Bottom Sheet';
      case DemoPage.carousel:
        return 'Carousel';
      case DemoPage.boxedLists:
        return 'Boxed Lists';
      case DemoPage.toggleGroups:
        return 'Toggle Groups';
      case DemoPage.buttons:
        return 'Buttons';
      case DemoPage.banner:
        return 'Banner';
      case DemoPage.toasts:
        return 'Toasts';
      case DemoPage.spinner:
        return 'Spinner';
      case DemoPage.avatar:
        return 'Avatar';
      case DemoPage.alertDialog:
        return 'Alert Dialog';
      case DemoPage.aboutDialog:
        return 'About Dialog';
      case DemoPage.clamp:
        return 'Clamp';
      case DemoPage.wrapBox:
        return 'Wrap Box';
      case DemoPage.multiLayoutView:
        return 'Multi-Layout View';
      case DemoPage.styleClasses:
        return 'Style Classes';
      case DemoPage.animations:
        return 'Animations';
      case DemoPage.appearance:
        return 'Appearance & Accent';
    }
  }
}

