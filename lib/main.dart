import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final authService = AuthService(client: ApiClient());
  await authService.restore();

  runApp(
    ChangeNotifierProvider.value(
      value: authService,
      child: const VizitApp(),
    ),
  );
}
