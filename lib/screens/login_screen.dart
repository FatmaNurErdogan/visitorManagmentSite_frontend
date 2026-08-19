import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/staff_member.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _expectedRole = 'employee';
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await context.read<AuthService>().login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            expectedRole: _expectedRole,
          );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
      appBar: AppBar(
        title: const Text('Giriş yap'),
        actions: const [ThemeToggleButton()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'employee', label: Text('Personel')),
                ButtonSegment(value: 'receptionist', label: Text('Resepsiyon')),
              ],
              selected: {_expectedRole},
              onSelectionChanged: (selection) => setState(() => _expectedRole = selection.first),
            ),
            const SizedBox(height: 20),
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
              validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu alan' : null,
              onFieldSubmitted: (_) => _submit(),
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
                  : const Text('Giriş Yap'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  context.read<AuthService>().loginOffline(
                        name: 'Debug Admin',
                        email: _emailCtrl.text.trim().isEmpty ? 'debug@local' : _emailCtrl.text.trim(),
                        role: StaffRole.admin,
                      );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Admin test (dev)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
