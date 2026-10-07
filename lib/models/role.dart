/// Роли проката (аналог Spring hasRole, уровень для сравнения).
enum Role {
  viewer(1),
  manager(2),
  admin(3);

  const Role(this.level);

  final int level;

  static Role parse(String raw) {
    switch (raw.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'manager':
        return Role.manager;
      case 'viewer':
      default:
        return Role.viewer;
    }
  }

  String get apiValue => name;

  String get label => switch (this) {
        Role.viewer => 'Наблюдатель',
        Role.manager => 'Менеджер',
        Role.admin => 'Администратор',
      };
}
