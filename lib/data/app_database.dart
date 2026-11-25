import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/tarea.dart';
import 'validaciones.dart';

part 'app_database.g.dart';

/// Tabla `tareas`. Drift genera a partir de esta clase el CREATE TABLE
/// y el código tipado para INSERT, SELECT, UPDATE y DELETE.
@DataClassName('TareaEntidad')
class Tareas extends Table {
  /// INTEGER PRIMARY KEY AUTOINCREMENT: SQLite asigna el id al insertar.
  IntColumn get id => integer().autoIncrement()();

  /// TEXT NOT NULL, de 1 a 200 caracteres.
  TextColumn get titulo =>
      text().withLength(min: 1, max: longitudMaximaTitulo)();

  /// SQLite no tiene booleano: Drift lo guarda como INTEGER (0 o 1).
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  /// Sin argumentos abre la base persistente de la plataforma.
  /// En las pruebas se puede pasar otro executor (por ejemplo, en memoria).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  /// drift_flutter elige el almacenamiento según la plataforma:
  /// un archivo SQLite en móvil y escritorio, y en web, SQLite compilado
  /// a WebAssembly guardado en OPFS o IndexedDB.
  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  /// SELECT reactivo: emite la lista de nuevo cada vez que la tabla cambia.
  Stream<List<Tarea>> observarTareas() {
    final consulta = select(tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  /// INSERT. Valida y normaliza el título antes de guardarlo.
  /// Devuelve el id asignado.
  Future<int> agregarTarea(String titulo) {
    _comprobarTitulo(titulo);
    return into(tareas).insert(
      TareasCompanion.insert(titulo: normalizarTitulo(titulo)),
    );
  }

  /// UPDATE del título de la tarea con ese id.
  Future<void> actualizarTitulo(int id, String titulo) async {
    _comprobarTitulo(titulo);
    final filas = await (update(tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(normalizarTitulo(titulo))));
    _comprobarExiste(filas, id);
  }

  /// UPDATE del estado (completada o pendiente) de la tarea con ese id.
  Future<void> cambiarEstado(int id, bool completada) async {
    final filas = await (update(tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    _comprobarExiste(filas, id);
  }

  /// DELETE de la tarea con ese id.
  Future<void> eliminarTarea(int id) async {
    final filas =
        await (delete(tareas)..where((t) => t.id.equals(id))).go();
    _comprobarExiste(filas, id);
  }

  static void _comprobarTitulo(String titulo) {
    final error = validarTitulo(titulo);
    if (error != null) {
      throw TareaException(error);
    }
  }

  /// UPDATE y DELETE devuelven cuántas filas afectaron; 0 significa que el
  /// id ya no existe (por ejemplo, se borró en otra pantalla).
  static void _comprobarExiste(int filasAfectadas, int id) {
    if (filasAfectadas == 0) {
      throw TareaException('La tarea con ID $id ya no existe.');
    }
  }

  static Tarea _aModelo(TareaEntidad fila) => Tarea(
        id: fila.id,
        titulo: fila.titulo,
        completada: fila.completada,
      );
}
