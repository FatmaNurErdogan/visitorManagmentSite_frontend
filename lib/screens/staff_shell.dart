import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/staff_member.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';
import 'staff_screen.dart';

/// Personel girişi sonrası kök ekran: alt gezinme çubuğuyla Panel / Kayıtlar
/// / (Yönetici ise) Personel / Profil arasında geçiş.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().role == StaffRole.admin;

    final pages = [
      const DashboardScreen(),
      const RecordsScreen(),
      if (isAdmin) const StaffScreen(),
      const ProfileScreen(),
    ];
    final index = _index >= pages.length ? 0 : _index;

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Panel',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Kayıtlar',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Personel',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
