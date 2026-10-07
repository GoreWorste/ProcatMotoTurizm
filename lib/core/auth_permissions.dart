import '../models/role.dart';
import '../state/auth_notifier.dart';

/// Создание/редактирование оборудования и клиентов.
bool canEditRentals(AuthNotifier auth) => auth.has(Role.manager);

/// Справочники (категории, бренды, теги) и жёсткое удаление.
bool canManageCatalog(AuthNotifier auth) => auth.has(Role.admin);

bool canManageUsers(AuthNotifier auth) => auth.has(Role.admin);
