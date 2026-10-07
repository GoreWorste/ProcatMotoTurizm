import 'package:flutter_test/flutter_test.dart';
import 'package:procat_moto_turizm/api/auth_api.dart';
import 'package:procat_moto_turizm/core/config.dart';
import 'package:procat_moto_turizm/main.dart';
import 'package:procat_moto_turizm/repositories/app_data_store.dart';
import 'package:procat_moto_turizm/routing/app_router.dart';
import 'package:procat_moto_turizm/state/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'App builds',
    (WidgetTester tester) async {
      if (useApiBackend) return;

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AppDataStore(prefs);
      await store.restore();

      final auth = AuthNotifier(prefs, AuthApi());
      final router = buildAppRouter(auth);
      await tester.pumpWidget(
        ProcatApp(store: store, auth: auth, router: router),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Оборудование'), findsWidgets);
    },
    skip: useApiBackend,
  );
}
