/// Material 3 window classes (app-direction section 5). Width decides the
/// layout, never orientation.
enum WindowClass {
  /// < 600dp: phone, split screen. Bottom bar or app bar only.
  compact,

  /// 600-839dp: 10-11" tablet portrait. 88dp rail.
  medium,

  /// 840-1199dp: 8" tablet landscape. 88dp rail.
  expanded,

  /// >= 1200dp: 10-11" tablet landscape (the edubox_tablet AVD). 240dp rail.
  large;

  static WindowClass of(double width) {
    if (width < 600) return WindowClass.compact;
    if (width < 840) return WindowClass.medium;
    if (width < 1200) return WindowClass.expanded;
    return WindowClass.large;
  }

  bool get isCompact => this == WindowClass.compact;

  bool get hasRail => this != WindowClass.compact;

  bool get hasExtendedRail => this == WindowClass.large;

  /// Horizontal gutter around the content canvas.
  double get gutter => switch (this) {
    WindowClass.compact => 16,
    WindowClass.medium => 24,
    WindowClass.expanded => 32,
    WindowClass.large => 32,
  };
}
