import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/app_data_store.dart';
import 'repositories/brand_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/equipment_repository.dart';
import 'repositories/persistent_brand_repository.dart';
import 'repositories/persistent_category_repository.dart';
import 'repositories/persistent_client_repository.dart';
import 'repositories/persistent_equipment_repository.dart';
import 'repositories/persistent_tag_repository.dart';
import 'repositories/tag_repository.dart';
import 'models/brand.dart';
import 'models/category.dart';
import 'models/tag.dart';
import 'screens/catalog_entity_detail_screen.dart';
import 'screens/catalog_entity_form_screen.dart';
import 'screens/catalog_entity_list_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_form_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/equipment_detail_screen.dart';
import 'screens/equipment_form_screen.dart';
import 'screens/equipment_list_screen.dart';
import 'state/catalog_notifier.dart';
import 'state/client_list_notifier.dart';
import 'state/equipment_list_notifier.dart';
import 'state/named_entity_list_notifier.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final store = AppDataStore(prefs);
  await store.restore();

  runApp(ProcatApp(store: store));
}

class ProcatApp extends StatelessWidget {
  const ProcatApp({super.key, required this.store});

  final AppDataStore store;

  @override
  Widget build(BuildContext context) {
    final equipmentRepository = PersistentEquipmentRepository(store);
    final clientRepository = PersistentClientRepository(store);
    final categoryRepository = PersistentCategoryRepository(store);
    final brandRepository = PersistentBrandRepository(store);
    final tagRepository = PersistentTagRepository(store);

    return MultiProvider(
      providers: [
        Provider.value(value: store),
        Provider<EquipmentRepository>.value(value: equipmentRepository),
        Provider<ClientRepository>.value(value: clientRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<BrandRepository>.value(value: brandRepository),
        Provider<TagRepository>.value(value: tagRepository),
        ChangeNotifierProvider(
          create: (_) => EquipmentListNotifier(equipmentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientListNotifier(clientRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogNotifier(
            categoryRepository,
            brandRepository,
            tagRepository,
          )..refresh(),
        ),
        ChangeNotifierProvider<NamedEntityListNotifier<Category>>(
          create: (c) => NamedEntityListNotifier<Category>(
            finder: categoryRepository.find,
            detailLoader: categoryRepository.findById,
            softDeleter: categoryRepository.softDelete,
            hardDeleter: categoryRepository.hardDelete,
            restorer: categoryRepository.restore,
            bulkHardDeleter: categoryRepository.deleteMany,
          ),
        ),
        ChangeNotifierProvider<NamedEntityListNotifier<Brand>>(
          create: (c) => NamedEntityListNotifier<Brand>(
            finder: brandRepository.find,
            detailLoader: brandRepository.findById,
            softDeleter: brandRepository.softDelete,
            hardDeleter: brandRepository.hardDelete,
            restorer: brandRepository.restore,
            bulkHardDeleter: brandRepository.deleteMany,
          ),
        ),
        ChangeNotifierProvider<NamedEntityListNotifier<Tag>>(
          create: (c) => NamedEntityListNotifier<Tag>(
            finder: tagRepository.find,
            detailLoader: tagRepository.findById,
            softDeleter: tagRepository.softDelete,
            hardDeleter: tagRepository.hardDelete,
            restorer: tagRepository.restore,
            bulkHardDeleter: tagRepository.deleteMany,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Прокат мототехники',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        routerConfig: _router,
        builder: (context, child) {
          final message = store.storageResetMessage;
          if (message == null || child == null) return child ?? const SizedBox();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger?.showSnackBar(SnackBar(content: Text(message)));
            store.storageResetMessage = null;
          });
          return child;
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
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
          builder: (context, state) => const CatalogEntityListScreen(
            kind: CatalogEntityKind.category,
          ),
          routes: [
            GoRoute(
              path: 'new',
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
          builder: (context, state) => const CatalogEntityListScreen(
            kind: CatalogEntityKind.brand,
          ),
          routes: [
            GoRoute(
              path: 'new',
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
          builder: (context, state) => const CatalogEntityListScreen(
            kind: CatalogEntityKind.tag,
          ),
          routes: [
            GoRoute(
              path: 'new',
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
      ],
    ),
  ],
);
