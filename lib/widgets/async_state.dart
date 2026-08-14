import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// Dashboard/Kayıtlar/Personel ekranlarının paylaştığı yükleniyor/hata/veri
/// üçlüsü. Ekran, `future`'ı kendi state'inde tutar; `onRetry` genelde
/// `setState(() => future = ...)` çağırır.
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final message = friendlyErrorMessage(snapshot.error!);
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
              ],
            ),
          );
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
