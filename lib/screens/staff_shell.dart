import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/staff_member.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';
import 'rooms_screen.dart';
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

  // Panel ve Kayıtlar sekmelerine her dönüşte verilerini tazelemek için:
  // anahtarını değiştirmek Flutter'a o ekranı sıfırdan kurmasını (yeni
  // initState → yeni API çağrısı) söyler. Aksi halde IndexedStack aynı
  // widget örneğini canlı tutar ve başka bir yerde (ör. onay/checkin)
  // değişen durum, sekmeye geri dönüldüğünde eski haliyle görünür kalır.
  int _dashboardTick = 0;
  int _recordsTick = 0;
  int _roomsTick = 0;

  void _onSelect(int value) {
    setState(() {
      if (value == 0) _dashboardTick++;
      if (value == 1) _recordsTick++;
      if (value == 2) _roomsTick++;
      _index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().role == StaffRole.admin;

    final pages = [
      DashboardScreen(key: ValueKey(_dashboardTick)),
      RecordsScreen(key: ValueKey(_recordsTick)),
      RoomsScreen(key: ValueKey(_roomsTick)),
      if (isAdmin) const StaffScreen(),
      const ProfileScreen(),
    ];
    final index = _index >= pages.length ? 0 : _index;

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onSelect,
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
          const NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room_rounded),
            label: 'Odalar',
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
