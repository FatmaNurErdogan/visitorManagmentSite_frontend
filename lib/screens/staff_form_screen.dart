import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/department.dart';
import '../models/staff_member.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class StaffFormScreen extends StatefulWidget {
  const StaffFormScreen({super.key});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _role = StaffRole.employee;
  String? _department;
  bool _submitting = false;

  late Future<List<Department>> _departmentsFuture;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _loadDepartments();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<List<Department>> _loadDepartments() async {
    final data = await _client.get('/departments') as Map<String, dynamic>;
    return (data['departments'] as List<dynamic>)
        .map((json) => Department.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Formdan ayrılmadan hızlıca yeni departman eklemek için — tam departman
  // yönetimi Personel ekranındaki "Departmanlar" ekranında.
  Future<void> _quickAddDepartment() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yeni departman'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Departman adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    try {
      await _client.post('/departments', body: {'name': name});
      if (!mounted) return;
      setState(() {
        _department = name;
        _departmentsFuture = _loadDepartments();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await context.read<AuthService>().client.post('/staff', body: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'role': _role,
        if (_department != null) 'department': _department,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni personel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ad soyad'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli bir e-posta gir' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
              validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter olmalı' : null,
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: StaffRole.employee, label: Text('Personel')),
                ButtonSegment(value: StaffRole.receptionist, label: Text('Resepsiyon')),
                ButtonSegment(value: StaffRole.admin, label: Text('Yönetici')),
              ],
              selected: {_role},
              onSelectionChanged: (selection) => setState(() => _role = selection.first),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<Department>>(
              future: _departmentsFuture,
              builder: (context, snapshot) {
                final departments = snapshot.data ?? const <Department>[];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _department,
                        decoration: const InputDecoration(labelText: 'Departman (opsiyonel)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Departman yok')),
                          ...departments.map(
                            (department) => DropdownMenuItem(value: department.name, child: Text(department.name)),
                          ),
                        ],
                        onChanged: (value) => setState(() => _department = value),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Yeni departman ekle',
                      onPressed: _quickAddDepartment,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Hesap Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
