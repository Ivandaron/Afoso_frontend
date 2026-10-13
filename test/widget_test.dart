import 'package:afoso1/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app builds login screen without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AfosoApp()));

    expect(find.text('Bienvenue 👋'), findsOneWidget);
  });
}
