import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_toggle_button.dart';

const _pollInterval = Duration(seconds: 4);

/// Ziyaretçinin onay mailindeki `https://{domain}/visit/{token}` linkine
/// tıklayınca (deep link ile) veya linki tarayıcıda açınca ulaştığı sohbet
/// ekranı. Giriş gerektirmez — token kimliğin yerine geçiyor. Backend
/// tarafı: /api/mobile/visitor/[token]/messages (visitorSite reposunda).
class VisitorChatScreen extends StatefulWidget {
  const VisitorChatScreen({super.key, required this.token});

  final String token;

  @override
  State<VisitorChatScreen> createState() => _VisitorChatScreenState();
}

class _VisitorChatScreenState extends State<VisitorChatScreen> {
  final _client = ApiClient();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Timer? _pollTimer;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _errorMessage;

  String get _path => '/visitor/${widget.token}/messages';

  @override
  void initState() {
    super.initState();
    _poll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final data = await _client.get(_path) as Map<String, dynamic>;
      final list = data['messages'] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _messages = list.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
        _loading = false;
        _errorMessage = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      // 404 = sohbet artık kapalı (ziyaret reddedildi/iptal oldu/süresi
      // doldu ya da token geçersiz) — bu kalıcı bir durum, tekrar denemenin
      // anlamı yok. Diğer hatalarda (ağ vs.) polling devam eder.
      if (e is ApiException && e.statusCode == 404) {
        _pollTimer?.cancel();
      }
      setState(() {
        _loading = false;
        _errorMessage = friendlyErrorMessage(e);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final data = await _client.post(_path, body: {'body': text}) as Map<String, dynamic>;
      final message = ChatMessage.fromJson(data['message'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _textCtrl.clear();
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet'),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _messages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.soft),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                        ),
                      ),
                      _Composer(
                        controller: _textCtrl,
                        sending: _sending,
                        onSend: _send,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;
    final isSelf = message.senderType == SenderType.visitor;

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isSelf ? scheme.primary : colors.field,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.body,
              style: TextStyle(color: isSelf ? Colors.white : colors.ink, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context),
              style: TextStyle(
                color: isSelf ? Colors.white.withValues(alpha: 0.8) : colors.soft,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Bir mesaj yaz...'),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
