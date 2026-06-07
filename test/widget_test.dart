// Test básico de humo: comprueba que la app arranca y muestra el título.

import 'package:flutter_test/flutter_test.dart';

import 'package:fog_of_war/main.dart';

void main() {
  testWidgets('La app arranca y muestra el título Fog of War',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FogOfWarApp());

    // El título aparece en la barra superior (AppBar).
    expect(find.text('Fog of War'), findsOneWidget);
  });
}
