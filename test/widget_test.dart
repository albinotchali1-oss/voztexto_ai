import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voztexto_ai/main.dart';

void main() {
  testWidgets('exibe a página inicial e as funcionalidades planejadas', (
    tester,
  ) async {
    await tester.pumpWidget(const VozTextoApp());

    expect(find.text('VOZTEXTO'), findsOneWidget);
    expect(find.text('Selecionar arquivo'), findsOneWidget);
    expect(find.text('Conversor'), findsWidgets);
    expect(find.text('Transcrição'), findsWidgets);
    expect(find.text('Tradução'), findsWidgets);
    expect(find.text('Histórico'), findsWidgets);
  });

  testWidgets('não permite seleção enquanto o recurso não está pronto', (
    tester,
  ) async {
    await tester.pumpWidget(const VozTextoApp());

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Selecionar arquivo'),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('abre o conversor com seleção por galeria ou arquivos', (
    tester,
  ) async {
    await tester.pumpWidget(const VozTextoApp());
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Conversor'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vídeo para áudio'), findsOneWidget);
    expect(find.text('Selecionar vídeo MP4'), findsOneWidget);
    expect(find.textContaining('não é enviado'), findsOneWidget);

    await tester.tap(find.text('Selecionar vídeo MP4'));
    await tester.pumpAndSettle();

    expect(find.text('Galeria'), findsOneWidget);
    expect(find.text('Arquivos'), findsOneWidget);
  });
}
