import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/validaciones.dart';
import '../models/tarea.dart';

/// Pantalla principal. Lee las tareas de SQLite mediante un Stream reactivo:
/// después de cada escritura, Drift emite la lista actualizada sin que
/// haga falta volver a consultar a mano.
class TareasPage extends StatefulWidget {
  final AppDatabase database;

  const TareasPage({super.key, required this.database});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  /// El Stream se crea una sola vez aquí, nunca dentro de build().
  late final Stream<List<Tarea>> _tareasStream;

  @override
  void initState() {
    super.initState();
    _tareasStream = widget.database.observarTareas();
  }

  Future<void> _agregarTarea() async {
    final titulo = _tituloController.text;
    final error = validarTitulo(titulo);
    if (error != null) {
      _mostrarMensaje(error);
      return;
    }
    try {
      await widget.database.agregarTarea(titulo);
      _tituloController.clear();
    } catch (e) {
      _mostrarMensaje('No se pudo guardar la tarea: $e');
    }
  }

  void _alternarCompletada(Tarea tarea, bool completada) {
    _mostrarMensaje('Pendiente: implementar actualización de tarea');
  }

  void _editarTarea(Tarea tarea) {
    _mostrarMensaje('Pendiente: implementar edición de título');
  }

  void _eliminarTarea(Tarea tarea) {
    _mostrarMensaje('Pendiente: implementar eliminación de tarea');
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _agregarTarea(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Tarea>>(
                stream: _tareasStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al leer las tareas: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) =>
                        _construirTarea(tareas[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarea(Tarea tarea) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: tarea.completada,
          onChanged: (valor) {
            if (valor != null) {
              _alternarCompletada(tarea, valor);
            }
          },
        ),
        title: Text(tarea.titulo),
        subtitle: Text('ID: ${tarea.id}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => _editarTarea(tarea),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _eliminarTarea(tarea),
            ),
          ],
        ),
      ),
    );
  }
}
