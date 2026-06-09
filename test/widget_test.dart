// Test básico de humo: comprueba que la app arranca y muestra el HUD.

import 'package:flutter_test/flutter_test.dart';

import 'package:fog_of_war/main.dart';

void main() {
  testWidgets('La app arranca y muestra la ciudad en el HUD',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FogOfWarApp());

    // La tarjeta de estadísticas del HUD muestra el nombre de la ciudad.
    expect(find.text('Barcelona'), findsOneWidget);
  });
}
