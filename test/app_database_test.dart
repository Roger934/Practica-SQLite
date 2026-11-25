import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/data/validaciones.dart';
import 'package:gestor_tareas_local/models/tarea.dart';

/// Pruebas de la capa de persistencia con SQLite real en memoria.
/// Ejecutan las mismas sentencias INSERT/SELECT/UPDATE/DELETE que la app,
/// pero sin tocar el archivo de la base del dispositivo.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<Tarea>> leerTareas() => db.observarTareas().first;

  test('INSERT: guarda la tarea con título normalizado y pendiente', () async {
    final id = await db.agregarTarea('  Estudiar Drift  ');

    final tareas = await leerTareas();
    expect(tareas, hasLength(1));
    expect(tareas.single.id, id);
    expect(tareas.single.titulo, 'Estudiar Drift');
    expect(tareas.single.completada, isFalse);
  });

  test('INSERT: rechaza títulos vacíos y no guarda nada', () async {
    await expectLater(db.agregarTarea('   '), throwsA(isA<TareaException>()));
    expect(await leerTareas(), isEmpty);
  });

  test('SELECT: devuelve las tareas ordenadas por id con ids únicos',
      () async {
    final a = await db.agregarTarea('A');
    final b = await db.agregarTarea('B');
    final c = await db.agregarTarea('C');

    final tareas = await leerTareas();
    expect(tareas.map((t) => t.id), [a, b, c]);
    expect({a, b, c}, hasLength(3));
  });

  test('UPDATE: cambia el título y el estado', () async {
    final id = await db.agregarTarea('Original');

    await db.actualizarTitulo(id, '  Nuevo título ');
    await db.cambiarEstado(id, true);

    final tarea = (await leerTareas()).single;
    expect(tarea.titulo, 'Nuevo título');
    expect(tarea.completada, isTrue);

    await db.cambiarEstado(id, false);
    expect((await leerTareas()).single.completada, isFalse);
  });

  test('UPDATE: rechaza un título vacío y conserva el anterior', () async {
    final id = await db.agregarTarea('Se queda');

    await expectLater(
      db.actualizarTitulo(id, ''),
      throwsA(isA<TareaException>()),
    );
    expect((await leerTareas()).single.titulo, 'Se queda');
  });

  test('DELETE: elimina solo la tarea indicada', () async {
    final borrar = await db.agregarTarea('Borrar');
    final conservar = await db.agregarTarea('Conservar');

    await db.eliminarTarea(borrar);

    final tareas = await leerTareas();
    expect(tareas.map((t) => t.id), [conservar]);
  });

  test('UPDATE y DELETE con un id inexistente lanzan TareaException',
      () async {
    expect(db.actualizarTitulo(999, 'X'), throwsA(isA<TareaException>()));
    expect(db.cambiarEstado(999, true), throwsA(isA<TareaException>()));
    expect(db.eliminarTarea(999), throwsA(isA<TareaException>()));
  });
}
