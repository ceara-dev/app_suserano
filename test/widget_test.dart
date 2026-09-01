import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:app_rotina/data/models/models.dart';
import 'package:app_rotina/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<Routine> routineBox;
  late Box<Checkin> checkinBox;

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_widget_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RoutineStepAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RoutineAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CheckinAdapter());
    }
    routineBox = await Hive.openBox<Routine>('routines', bytes: Uint8List(0));
    checkinBox = await Hive.openBox<Checkin>('checkins', bytes: Uint8List(0));
  });

  setUp(() async {
    await routineBox.clear();
    await checkinBox.clear();
  });

  testWidgets('cria uma rotina e faz check-in dos passos',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      App(routineBox: routineBox, checkinBox: checkinBox),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rotinas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova rotina'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Nome *'), 'Treino de manhã');
    await tester.tap(find.text('Adicionar passo'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Passo 1 *'), 'Flexões');
    await tester.dragUntilVisible(
      find.text('Criar rotina'),
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar rotina'));
    await tester.pumpAndSettle();

    expect(find.text('Treino de manhã'), findsOneWidget);
    expect(find.text('1 passo'), findsOneWidget);

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();

    expect(find.text('Treino de manhã'), findsOneWidget);
    expect(find.text('Flexões'), findsOneWidget);

    await tester.tap(find.text('Flexões'));
    await tester.pumpAndSettle();

    expect(find.text('1 de 1 rotinas concluídas'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('navega para a aba de métricas', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(routineBox: routineBox, checkinBox: checkinBox),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Métricas'));
    await tester.pumpAndSettle();

    expect(find.text('Sequência atual (dias)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Últimos 7 dias'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Últimos 7 dias'), findsOneWidget);
  });
}
