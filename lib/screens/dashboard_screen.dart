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

  // Bir ziyaretin onay/checkin butonuna basılır basılmaz o karttaki
  // butonları devre dışı bırakmak için: aksi halde ağ isteği (ve ardından
  // gelen yenileme) tamamlanana kadar buton tıklanabilir kalır, kullanıcı
  // aynı işlemi iki kez tetikleyebilir ("zaten işlendi" hatası kafa karıştırır).
  final Set<String> _processingVisitIds = {};

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

  // Blok gövde şart: `() => _future = _load()` atamanın kendisini (bir
  // Future) döndürür ve Flutter setState'e "callback bir Future döndürdü"
  // hatasıyla senkron olarak fırlar — dışarıdaki try/catch bunu yanlışlıkla
  // ağ hatası sanıp "sunucuya ulaşılamadı" gösterirdi, ekran yine de doğru
  // veriyle güncellenirdi (atama zaten olmuştu) ama mesaj yanıltıcıydı.
  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _act(String visitId, String path, String successMessage) async {
    setState(() => _processingVisitIds.add(visitId));
    try {
      await _client.post(path);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _processingVisitIds.remove(visitId));
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
                    Builder(builder: (context) {
                      final busy = _processingVisitIds.contains(visit.id);
                      return VisitCard(
                        visit: visit,
                        subtitle: visit.visitor.company ?? '—',
                        showReason: true,
                        actions: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => _act(visit.id, '/visits/${visit.id}/reject', 'Talep reddedildi'),
                                child: const Text('Reddet'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: busy
                                    ? null
                                    : () => _act(visit.id, '/visits/${visit.id}/approve', 'Onaylandı'),
                                child: busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Onayla'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
                    Builder(builder: (context) {
                      final busy = _processingVisitIds.contains(visit.id);
                      final busyIndicator = const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      );
                      return VisitCard(
                        visit: visit,
                        subtitle: '${visit.hostEmployee.name}\'i ziyaret ediyor',
                        actions: switch (visit.status) {
                          VisitStatus.accepted => ElevatedButton(
                              onPressed: busy
                                  ? null
                                  : () => _act(visit.id, '/visits/${visit.id}/checkin', 'Giriş onaylandı'),
                              child: busy ? busyIndicator : const Text('Girişi Onayla'),
                            ),
                          VisitStatus.checkedIn => ElevatedButton(
                              onPressed: busy
                                  ? null
                                  : () => _act(visit.id, '/visits/${visit.id}/checkout', 'Çıkış onaylandı'),
                              child: busy ? busyIndicator : const Text('Çıkışı Onayla'),
                            ),
                          _ => null,
                        },
                      );
                    }),
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
