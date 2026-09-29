import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _paths = [
    '/equipment',
    '/clients',
    '/categories',
    '/brands',
    '/tags',
  ];

  int _indexForLocation(String location) {
    for (var i = 0; i < _paths.length; i++) {
      if (location.startsWith(_paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexForLocation(location);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (!wide) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(_paths[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.precision_manufacturing_outlined),
              label: 'Оборудование',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Клиенты',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              label: 'Категории',
            ),
            NavigationDestination(
              icon: Icon(Icons.business_outlined),
              label: 'Бренды',
            ),
            NavigationDestination(
              icon: Icon(Icons.label_outline),
              label: 'Теги',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => context.go(_paths[i]),
            extended: MediaQuery.sizeOf(context).width >= 1200,
            labelType: MediaQuery.sizeOf(context).width >= 1200
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.precision_manufacturing_outlined),
                label: Text('Оборудование'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                label: Text('Клиенты'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                label: Text('Категории'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.business_outlined),
                label: Text('Бренды'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.label_outline),
                label: Text('Теги'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
