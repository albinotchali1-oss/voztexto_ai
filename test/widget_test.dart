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

  testWidgets('navega entre todas as secções sem simular funcionalidades', (
    tester,
  ) async {
    await tester.pumpWidget(const VozTextoApp());

    const destinations = {
      'Conversor':
          'A conversão de arquivos ainda não está disponível nesta versão.',
      'Transcrição':
          'A transcrição de áudio ainda não está disponível nesta versão.',
      'Tradução':
          'A tradução de textos ainda não está disponível nesta versão.',
      'Histórico':
          'O histórico estará disponível quando as ferramentas forem implementadas.',
    };

    for (final entry in destinations.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(entry.key),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(
        find.text('Nenhuma operação é executada nesta versão.'),
        findsOneWidget,
      );
    }
  });
}