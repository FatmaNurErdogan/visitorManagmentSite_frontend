import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/staff_member.dart';
import '../models/visit.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/visit_card.dart';

class DashboardData {
  DashboardData({required this.pendingApprovals, required this.todaysVisits});

  final List<Visit> pendingApprovals;
  final List<Visit> todaysVisits;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _future;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DashboardData> _load() async {
    final data = await _client.get('/visits/dashboard') as Map<String, dynamic>;
    return DashboardData(
      pendingApprovals: (data['pendingApprovals'] as List<dynamic>)
          .map((json) => Visit.fromJson(json as Map<String, dynamic>))
          .toList(),
      todaysVisits: (data['todaysVisits'] as List<dynamic>)
          .map((json) => Visit.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _act(String path) async {
    try {
      await _client.post(path);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final role = auth.role;
    final showApprovals = role == StaffRole.employee || role == StaffRole.admin;
    final showToday = role == StaffRole.receptionist || role == StaffRole.admin;
    final colors = context.vizitColors;

    return Scaffold(
      appBar: AppBar(
        title: Text('Merhaba, ${auth.name ?? ''}'),
        actions: const [ThemeToggleButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: AsyncStateBuilder<DashboardData>(
          future: _future,
          onRetry: _refresh,
          builder: (context, data) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (showApprovals) ...[
                  Text(
                    'Onayını bekleyenler · ${data.pendingApprovals.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.soft),
                  ),
                  const SizedBox(height: 10),
                  if (data.pendingApprovals.isEmpty)
                    const EmptyState(
                      icon: Icons.check_rounded,
                      title: 'Her şey güncel',
                      message: 'Onay bekleyen ziyaret talebi yok.',
                    ),
                  for (final visit in data.pendingApprovals) ...[
                    VisitCard(
                      visit: visit,
                      subtitle: visit.visitor.company ?? '—',
                      showReason: true,
                      actions: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _act('/visits/${visit.id}/reject'),
                              child: const Text('Reddet'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _act('/visits/${visit.id}/approve'),
                              child: const Text('Onayla'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                ],
                if (showToday) ...[
                  Text(
                    'Bugünün ziyaretleri · ${data.todaysVisits.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.soft),
                  ),
                  const SizedBox(height: 10),
                  if (data.todaysVisits.isEmpty)
                    const EmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'Bugün için bekleyen işlem yok',
                      message: 'Giriş veya çıkış onayı bekleyen bir ziyaret bulunmuyor.',
                    ),
                  for (final visit in data.todaysVisits) ...[
                    VisitCard(
                      visit: visit,
                      subtitle: '${visit.hostEmployee.name}\'i ziyaret ediyor',
                      actions: switch (visit.status) {
                        VisitStatus.accepted => ElevatedButton(
                            onPressed: () => _act('/visits/${visit.id}/checkin'),
                            child: const Text('Girişi Onayla'),
                          ),
                        VisitStatus.checkedIn => ElevatedButton(
                            onPressed: () => _act('/visits/${visit.id}/checkout'),
                            child: const Text('Çıkışı Onayla'),
                          ),
                        _ => null,
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
