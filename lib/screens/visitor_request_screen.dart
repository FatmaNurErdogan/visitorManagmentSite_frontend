import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/host.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/theme_toggle_button.dart';
import 'visitor_confirmation_screen.dart';

class VisitorRequestScreen extends StatefulWidget {
  const VisitorRequestScreen({super.key});

  @override
  State<VisitorRequestScreen> createState() => _VisitorRequestScreenState();
}

class _VisitorRequestScreenState extends State<VisitorRequestScreen> {
  late Future<List<Host>> _hostsFuture;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  Host? _selectedHost;
  DateTime? _scheduledAt;
  bool _submitting = false;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _hostsFuture = _loadHosts();
  }

  Future<List<Host>> _loadHosts() async {
    final data = await _client.get('/hosts') as Map<String, dynamic>;
    final list = data['hosts'] as List<dynamic>;
    return list.map((json) => Host.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      // Türkiye için 24 saat formatı — cihazın diline bakılmaksızın AM/PM göstermesin.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;

    // Ziyaretler sadece mesai saatleri içinde alınabiliyor (backend de bunu
    // doğruluyor) — burada erken uyarmak bir sunucu round-trip'i kurtarır.
    if (time.hour < 9 || time.hour >= 18) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lütfen 09:00–18:00 arasında bir saat seç.')));
      return;
    }

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHost == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen kimi ziyaret ettiğini seç.')));
      return;
    }
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tarih ve saat seç.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await _client.post('/visits', body: {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'hostEmployeeId': _selectedHost!.id,
        'visitReason': _reasonCtrl.text.trim(),
        // .toUtc() şart: aksi halde saat dilimi bilgisi olmadan gönderilir ve
        // backend'in kendi saat dilimine göre yanlış yorumlanabilir (ör.
        // sunucu UTC'deyse cihaz Türkiye saatinden 3 saat farklı okur).
        'scheduledAt': _scheduledAt!.toUtc().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => VisitorConfirmationScreen(
          visitorName: _nameCtrl.text.trim(),
          hostName: _selectedHost!.name,
          reason: _reasonCtrl.text.trim(),
          scheduledAt: _scheduledAt!,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ziyaret talebi'),
        actions: const [ThemeToggleButton()],
      ),
      body: AsyncStateBuilder<List<Host>>(
        future: _hostsFuture,
        onRetry: () => setState(() {
          _hostsFuture = _loadHosts();
        }),
        builder: (context, hosts) {
          return Form(
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
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon'),
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
                DropdownButtonFormField<Host>(
                  initialValue: _selectedHost,
                  decoration: const InputDecoration(labelText: 'Kimi ziyaret ediyorsun'),
                  items: hosts
                      .map((host) => DropdownMenuItem(value: host, child: Text(host.displayName)))
                      .toList(),
                  onChanged: (host) => setState(() => _selectedHost = host),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Ziyaret nedeni'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _pickSchedule,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tarih & saat (09:00–18:00)'),
                    isEmpty: false,
                    child: Text(
                      _scheduledAt == null
                          ? 'Seç'
                          : DateFormat('d MMMM, HH:mm', 'tr_TR').format(_scheduledAt!),
                      style: TextStyle(color: _scheduledAt == null ? colors.soft : colors.ink),
                    ),
                  ),
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
                      : const Text('Talebi Gönder'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
