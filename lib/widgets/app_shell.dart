import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/auth_permissions.dart';
import '../core/config.dart';
import '../core/layout_breakpoints.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  List<_NavItem> _items(AuthNotifier auth) {
    final items = <_NavItem>[
      const _NavItem('/equipment', Icons.precision_manufacturing_outlined, 'Оборудование'),
      const _NavItem('/clients', Icons.people_outline, 'Клиенты'),
    ];
    if (!useApiBackend || auth.has(Role.manager)) {
      items.addAll(const [
        _NavItem('/categories', Icons.category_outlined, 'Категории'),
        _NavItem('/brands', Icons.business_outlined, 'Бренды'),
        _NavItem('/tags', Icons.label_outline, 'Теги'),
      ]);
    }
    return items;
  }

  int _indexForLocation(String location, List<_NavItem> items) {
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path)) return i;
    }
    return 0;
  }

  Widget? _userSidebar(BuildContext context, AuthNotifier auth) {
    if (!useApiBackend || auth.user == null) return null;
    return SizedBox(
      width: 200,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auth.user!.displayName,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                auth.user!.role.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (canManageUsers(auth))
                TextButton.icon(
                  onPressed: () => context.go('/admin/users'),
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                  label: const Text('Пользователи'),
                ),
              TextButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Выйти'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final items = _items(auth);
    final location = GoRouterState.of(context).uri.path;
    final index = _indexForLocation(location, items);
    final wide = MediaQuery.sizeOf(context).width >= LayoutBreakpoints.sideNavMin;
    final userSidebar = _userSidebar(context, auth);

    if (!wide) {
      return Scaffold(
        appBar: useApiBackend && auth.user != null
            ? AppBar(
                title: Text(auth.user!.displayName),
                actions: [
                  if (canManageUsers(auth))
                    IconButton(
                      tooltip: 'Пользователи',
                      onPressed: () => context.go('/admin/users'),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                    ),
                  IconButton(
                    tooltip: 'Выйти',
                    onPressed: auth.logout,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              )
            : null,
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index.clamp(0, items.length - 1),
          onDestinationSelected: (i) => context.go(items[i].path),
          destinations: [
            for (final item in items)
              NavigationDestination(icon: Icon(item.icon), label: item.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (userSidebar != null) userSidebar,
          NavigationRail(
            selectedIndex: index.clamp(0, items.length - 1),
            onDestinationSelected: (i) => context.go(items[i].path),
            extended:
                MediaQuery.sizeOf(context).width >= LayoutBreakpoints.railExtendedMin,
            labelType: MediaQuery.sizeOf(context).width >=
                    LayoutBreakpoints.railExtendedMin
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
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

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String label;
}
