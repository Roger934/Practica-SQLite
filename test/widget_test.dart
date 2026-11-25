import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/main.dart';

/// Base en memoria para no tocar el archivo real de la app.
/// closeStreamsSynchronously evita que el test se quede esperando
/// a los Streams de Drift dentro del reloj simulado de testWidgets.
AppDatabase crearBasePrueba() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

/// Desmontar la interfaz antes de cerrar la base evita
/// temporizadores pendientes del Stream de Drift.
Future<void> cerrar(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await db.close();
}

/// Lee la base fuera del reloj simulado de testWidgets: dentro de él,
/// un await a la base nunca termina porque nadie avanza el tiempo.
Future<List<String>> leerDesdeBase(WidgetTester tester, AppDatabase db) async {
  final tareas = await tester.runAsync(() => db.observarTareas().first);
  return tareas!.map((t) => t.titulo).toList();
}

/// pumpAndSettle con límite: si algo no se estabiliza, la prueba falla
/// en 5 s en lugar de quedarse colgada.
Future<void> asentar(WidgetTester tester) => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    final db = crearBasePrueba();

    await tester.pumpWidget(GestorTareasApp(database: db));
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await cerrar(tester, db);
  });

  testWidgets('Agregar desde la interfaz guarda la tarea en la base',
      (tester) async {
    final db = crearBasePrueba();
    await tester.pumpWidget(GestorTareasApp(database: db));
    await asentar(tester);

    await tester.enterText(find.byType(TextField), 'Comprar pan');
    await tester.tap(find.text('Agregar tarea'));
    await asentar(tester);

    // Aparece en la lista (vía el Stream) y quedó guardada en SQLite.
    expect(find.text('Comprar pan'), findsOneWidget);
    expect(await leerDesdeBase(tester, db), ['Comprar pan']);

    await cerrar(tester, db);
  });

  testWidgets('Un título vacío muestra el error y no se guarda (P5)',
      (tester) async {
    final db = crearBasePrueba();
    await tester.pumpWidget(GestorTareasApp(database: db));
    await asentar(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pump();

    expect(find.text('El título no puede estar vacío.'), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
    expect(await leerDesdeBase(tester, db), isEmpty);

    await cerrar(tester, db);
  });
}
