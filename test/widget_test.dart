import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/main.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    // Base en memoria para no tocar el archivo real de la app.
    // closeStreamsSynchronously evita que el test se quede esperando
    // a los Streams de Drift dentro del reloj simulado de testWidgets.
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

    await tester.pumpWidget(GestorTareasApp(database: db));
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Desmontar la interfaz antes de cerrar la base evita
    // temporizadores pendientes del Stream de Drift.
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
