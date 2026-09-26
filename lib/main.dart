import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'repositories/in_memory_client_repository.dart';
import 'repositories/in_memory_equipment_repository.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/equipment_detail_screen.dart';
import 'screens/equipment_list_screen.dart';
import 'state/client_list_notifier.dart';
import 'state/equipment_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProcatApp());
}

class ProcatApp extends StatelessWidget {
  const ProcatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final equipmentRepository = InMemoryEquipmentRepository();
    final clientRepository = InMemoryClientRepository();

    return MultiProvider(
      providers: [
        Provider.value(value: equipmentRepository),
        Provider.value(value: clientRepository),
        ChangeNotifierProvider(
          create: (_) => EquipmentListNotifier(equipmentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientListNotifier(clientRepository),
        ),
      ],
      child: MaterialApp.router(
        title: 'Прокат мототехники',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        routerConfig: _router,
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
    GoRoute(
      path: '/equipment',
      builder: (context, state) => const EquipmentListScreen(),
    ),
    GoRoute(
      path: '/equipment/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EquipmentDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => const ClientListScreen(),
    ),
    GoRoute(
      path: '/clients/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ClientDetailScreen(id: id);
      },
    ),
  ],
);
