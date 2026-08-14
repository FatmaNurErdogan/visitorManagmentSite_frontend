import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/staff_member.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/role_chip.dart';
import '../widgets/theme_toggle_button.dart';
import 'departments_screen.dart';
import 'staff_form_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late Future<List<StaffMember>> _future;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StaffMember>> _load() async {
    final data = await _client.get('/staff') as Map<String, dynamic>;
    return (data['staff'] as List<dynamic>)
        .map((json) => StaffMember.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const StaffFormScreen()),
    );
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final isAdmin = context.watch<AuthService>().role == StaffRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Departmanlar',
              icon: const Icon(Icons.apartment_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DepartmentsScreen()),
              ),
            ),
          const ThemeToggleButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _openForm, child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: AsyncStateBuilder<List<StaffMember>>(
          future: _future,
          onRetry: _refresh,
          builder: (context, staff) {
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: staff.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = staff[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member.name, style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink)),
                            const SizedBox(height: 2),
                            Text(member.email, style: TextStyle(fontSize: 12, color: colors.soft)),
                            if (member.department != null && member.department!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(member.department!, style: TextStyle(fontSize: 11.5, color: colors.soft)),
                            ],
                          ],
                        ),
                      ),
                      RoleChip(role: member.role),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
