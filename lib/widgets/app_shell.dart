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

  Widget? _railLeading(BuildContext context, AuthNotifier auth, bool extended) {
    if (!useApiBackend || auth.user == null) return null;
    final user = auth.user!;
    final theme = Theme.of(context);
    final initial = user.displayName.trim().isEmpty
        ? '?'
        : user.displayName.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: extended ? 18 : 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(
              initial,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (extended) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 88,
              child: Text(
                user.displayName,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              user.role.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget? _railTrailing(BuildContext context, AuthNotifier auth) {
    if (!useApiBackend || auth.user == null) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canManageUsers(auth))
            _RailAction(
              tooltip: 'Пользователи',
              icon: Icons.admin_panel_settings_outlined,
              onPressed: () => context.go('/admin/users'),
            ),
          _RailAction(
            tooltip: 'Выйти',
            icon: Icons.logout,
            onPressed: auth.logout,
          ),
        ],
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
    final extended =
        MediaQuery.sizeOf(context).width >= LayoutBreakpoints.railExtendedMin;

    if (!wide) {
      return Scaffold(
        appBar: useApiBackend && auth.user != null
            ? AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auth.user!.displayName,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      auth.user!.role.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                toolbarHeight: 56,
                actions: [
                  if (canManageUsers(auth))
                    IconButton(
                      tooltip: 'Пользователи',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.go('/admin/users'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 22),
                    ),
                  IconButton(
                    tooltip: 'Выйти',
                    visualDensity: VisualDensity.compact,
                    onPressed: auth.logout,
                    icon: const Icon(Icons.logout, size: 22),
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
          NavigationRail(
            selectedIndex: index.clamp(0, items.length - 1),
            onDestinationSelected: (i) => context.go(items[i].path),
            extended: extended,
            minWidth: 72,
            minExtendedWidth: 168,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: _railLeading(context, auth, extended),
            trailing: _railTrailing(context, auth),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon, size: 22),
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

class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
