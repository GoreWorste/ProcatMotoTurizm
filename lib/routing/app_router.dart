import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../models/role.dart';
import '../screens/admin_users_screen.dart';
import '../screens/catalog_entity_detail_screen.dart';
import '../screens/catalog_entity_form_screen.dart';
import '../screens/catalog_entity_list_screen.dart';
import '../screens/client_detail_screen.dart';
import '../screens/client_form_screen.dart';
import '../screens/client_list_screen.dart';
import '../screens/equipment_detail_screen.dart';
import '../screens/equipment_form_screen.dart';
import '../screens/equipment_list_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_shell.dart';

String? _requireRole(AuthNotifier auth, Role role) =>
    auth.has(role) ? null : '/forbidden';

GoRouter buildAppRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/equipment',
    redirect: (context, state) {
      if (!useApiBackend) return null;
      if (auth.isRestoring) return null;

      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/equipment';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/equipment',
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/equipment',
            builder: (context, state) => const EquipmentListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (context, state) =>
                    _requireRole(auth, Role.manager),
                builder: (context, state) => const EquipmentFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return EquipmentDetailScreen(id: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (context, state) =>
                        _requireRole(auth, Role.manager),
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return EquipmentFormScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (context, state) =>
                    _requireRole(auth, Role.manager),
                builder: (context, state) => const ClientFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ClientDetailScreen(id: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (context, state) =>
                        _requireRole(auth, Role.manager),
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ClientFormScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            redirect: (context, state) {
              if (!useApiBackend) return null;
              if (auth.has(Role.manager)) return null;
              return '/forbidden';
            },
            builder: (context, state) => const CatalogEntityListScreen(
              kind: CatalogEntityKind.category,
            ),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (context, state) => _requireRole(auth, Role.admin),
                builder: (context, state) => const CatalogEntityFormScreen(
                  kind: CatalogEntityKind.category,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CatalogEntityDetailScreen(
                    kind: CatalogEntityKind.category,
                    id: id,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (context, state) =>
                        _requireRole(auth, Role.admin),
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return CatalogEntityFormScreen(
                        kind: CatalogEntityKind.category,
                        id: id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/brands',
            redirect: (context, state) {
              if (!useApiBackend) return null;
              if (auth.has(Role.manager)) return null;
              return '/forbidden';
            },
            builder: (context, state) => const CatalogEntityListScreen(
              kind: CatalogEntityKind.brand,
            ),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (context, state) => _requireRole(auth, Role.admin),
                builder: (context, state) => const CatalogEntityFormScreen(
                  kind: CatalogEntityKind.brand,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CatalogEntityDetailScreen(
                    kind: CatalogEntityKind.brand,
                    id: id,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (context, state) =>
                        _requireRole(auth, Role.admin),
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return CatalogEntityFormScreen(
                        kind: CatalogEntityKind.brand,
                        id: id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tags',
            redirect: (context, state) {
              if (!useApiBackend) return null;
              if (auth.has(Role.manager)) return null;
              return '/forbidden';
            },
            builder: (context, state) => const CatalogEntityListScreen(
              kind: CatalogEntityKind.tag,
            ),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (context, state) => _requireRole(auth, Role.admin),
                builder: (context, state) => const CatalogEntityFormScreen(
                  kind: CatalogEntityKind.tag,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CatalogEntityDetailScreen(
                    kind: CatalogEntityKind.tag,
                    id: id,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (context, state) =>
                        _requireRole(auth, Role.admin),
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return CatalogEntityFormScreen(
                        kind: CatalogEntityKind.tag,
                        id: id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/admin/users',
            redirect: (context, state) => _requireRole(auth, Role.admin),
            builder: (context, state) => const AdminUsersScreen(),
          ),
        ],
      ),
    ],
  );
}
