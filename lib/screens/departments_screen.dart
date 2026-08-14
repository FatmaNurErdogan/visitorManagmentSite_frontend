import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/department.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_toggle_button.dart';

/// Personel formundaki "Departman" seçim listesini yöneten ekran — sadece
/// ADMIN erişebilir (bkz. Personel ekranındaki AppBar action).
class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  late Future<List<Department>> _future;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Department>> _load() async {
    final data = await _client.get('/departments') as Map<String, dynamic>;
    return (data['departments'] as List<dynamic>)
        .map((json) => Department.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addDepartment() async {
    final added = await showDialog<bool>(context: context, builder: (_) => const _AddDepartmentDialog());
    if (added == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departmanlar'),
        actions: const [ThemeToggleButton()],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addDepartment, child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: AsyncStateBuilder<List<Department>>(
          future: _future,
          onRetry: _refresh,
          builder: (context, departments) {
            if (departments.isEmpty) {
              return ListView(
                children: const [
                  EmptyState(
                    icon: Icons.apartment_rounded,
                    title: 'Henüz departman yok',
                    message: 'Sağ alttaki + ile ilk departmanı ekleyin.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: departments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final department = departments[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Text(department.name, style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AddDepartmentDialog extends StatefulWidget {
  const _AddDepartmentDialog();

  @override
  State<_AddDepartmentDialog> createState() => _AddDepartmentDialogState();
}

class _AddDepartmentDialogState extends State<_AddDepartmentDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Zorunlu alan');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().client.post('/departments', body: {'name': name});
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni departman'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Departman adı', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ekle'),
        ),
      ],
    );
  }
}
