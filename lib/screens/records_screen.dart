import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/visit.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/visit_card.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String? _statusFilter;
  late Future<List<Visit>> _future;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Visit>> _load() async {
    final data = await _client.get(
      '/visits',
      query: _statusFilter == null ? null : {'status': _statusFilter!},
    ) as Map<String, dynamic>;
    return (data['visits'] as List<dynamic>).map((json) => Visit.fromJson(json as Map<String, dynamic>)).toList();
  }

  void _setFilter(String? status) {
    setState(() {
      _statusFilter = status;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıtlar')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: 'Tümü', selected: _statusFilter == null, onTap: () => _setFilter(null)),
                for (final status in VisitStatus.all)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: VisitStatus.label(status),
                      selected: _statusFilter == status,
                      onTap: () => _setFilter(status),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _setFilter(_statusFilter),
              child: AsyncStateBuilder<List<Visit>>(
                future: _future,
                onRetry: () => _setFilter(_statusFilter),
                builder: (context, visits) {
                  if (visits.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text('Kayıt bulunamadı.', style: TextStyle(color: colors.soft)),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: visits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final visit = visits[index];
                      return VisitCard(
                        visit: visit,
                        subtitle: '${visit.hostEmployee.name} · ${visit.visitor.company ?? "—"}',
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: colors.field,
      selectedColor: scheme.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? scheme.onPrimary : colors.soft,
      ),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    );
  }
}
