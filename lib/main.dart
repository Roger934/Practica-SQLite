import 'package:flutter/material.dart';

import 'data/app_database.dart';
import 'screens/tareas_page.dart';

void main() {
  runApp(const GestorTareasApp());
}

/// Punto de entrada de la aplicación.
/// Abre la base una sola vez y la cierra al destruir la app.
class GestorTareasApp extends StatefulWidget {
  /// Base opcional; las pruebas pasan una en memoria.
  final AppDatabase? database;

  const GestorTareasApp({super.key, this.database});

  @override
  State<GestorTareasApp> createState() => _GestorTareasAppState();
}

class _GestorTareasAppState extends State<GestorTareasApp> {
  late final AppDatabase _db;
  late final bool _esPropia;

  @override
  void initState() {
    super.initState();
    _esPropia = widget.database == null;
    _db = widget.database ?? AppDatabase();
  }

  @override
  void dispose() {
    // Solo se cierra la base que abrió este widget; la de las pruebas
    // la cierra la propia prueba.
    if (_esPropia) {
      _db.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: TareasPage(database: _db),
    );
  }
}
