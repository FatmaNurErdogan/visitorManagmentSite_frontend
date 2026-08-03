import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/services/api_client.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  testWidgets('Vizit app builds without crashing', (WidgetTester tester) async {
    final authService = AuthService(client: ApiClient());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authService,
        child: const VizitApp(),
      ),
    );

    // AuthService.restore() burada çağrılmıyor (secure storage platform
    // eklentisi widget testinde yok) — AuthGate bu yüzden yükleniyor
    // durumunda kalır. Bu test sadece uygulamanın çökmeden kurulduğunu
    // doğrular.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
