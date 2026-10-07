import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/auth_api.dart';
import 'core/api_client.dart';
import 'core/config.dart';
import 'repositories/api/api_catalog_repositories.dart';
import 'repositories/api/api_client_repository.dart';
import 'repositories/api/api_equipment_repository.dart';
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
import 'routing/app_router.dart';
import 'state/auth_notifier.dart';
import 'state/catalog_notifier.dart';
import 'state/client_list_notifier.dart';
import 'state/equipment_list_notifier.dart';
import 'state/named_entity_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  AppDataStore? store;
  if (!useApiBackend) {
    store = AppDataStore(prefs);
    await store.restore();
  }

  final auth = AuthNotifier(prefs, AuthApi());
  await auth.restore();

  final router = buildAppRouter(auth);

  runApp(ProcatApp(store: store, auth: auth, router: router));
}

class ProcatApp extends StatelessWidget {
  const ProcatApp({
    super.key,
    this.store,
    required this.auth,
    required this.router,
  });

  final AppDataStore? store;
  final AuthNotifier auth;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    late final EquipmentRepository equipmentRepository;
    late final ClientRepository clientRepository;
    late final CategoryRepository categoryRepository;
    late final BrandRepository brandRepository;
    late final TagRepository tagRepository;
    Dio? dio;

    if (useApiBackend) {
      dio = buildDio(
        tokenProvider: () => auth.accessToken,
        onRefreshTokens: auth.refreshTokens,
      );
      equipmentRepository = ApiEquipmentRepository(dio);
      clientRepository = ApiClientRepository(dio);
      categoryRepository = ApiCategoryRepository(dio);
      brandRepository = ApiBrandRepository(dio);
      tagRepository = ApiTagRepository(dio);
    } else {
      final dataStore = store!;
      equipmentRepository = PersistentEquipmentRepository(dataStore);
      clientRepository = PersistentClientRepository(dataStore);
      categoryRepository = PersistentCategoryRepository(dataStore);
      brandRepository = PersistentBrandRepository(dataStore);
      tagRepository = PersistentTagRepository(dataStore);
    }

    Widget app = MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        if (dio != null) Provider<Dio>.value(value: dio),
        if (store != null) Provider<AppDataStore>.value(value: store!),
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
        routerConfig: router,
        builder: (context, child) {
          final message = store?.storageResetMessage;
          if (message != null && child != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messenger = ScaffoldMessenger.maybeOf(context);
              messenger?.showSnackBar(SnackBar(content: Text(message)));
              store!.storageResetMessage = null;
            });
          }
          var body = child ?? const SizedBox();
          if (useApiBackend && auth.isAuthenticated) {
            body = InactivityWatcher(
              timeout: inactivityLogoutDuration,
              onTimeout: () => auth.logout(),
              child: body,
            );
          }
          return body;
        },
      ),
    );

    return app;
  }
}
