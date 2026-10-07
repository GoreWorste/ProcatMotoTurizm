/// Точки перелома ПР6 (ширина viewport, px).
abstract final class LayoutBreakpoints {
  static const double mobile = 360;
  static const double tablet = 768;
  static const double desktop = 1280;
  static const double wide = 1920;

  /// Боковая навигация вместо нижней.
  static const double sideNavMin = tablet;

  /// Таблица вместо карточек в списках.
  static const double listTableMin = tablet;

  /// Развёрнутые подписи NavigationRail.
  static const double railExtendedMin = desktop;
}
