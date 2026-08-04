import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final authService = AuthService(client: ApiClient());
  final themeController = ThemeController();
  await Future.wait([authService.restore(), themeController.restore()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: themeController),
      ],
      child: const VizitApp(),
    ),
  );
}
