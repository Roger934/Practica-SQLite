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
    final ok = await _ejecutar(
      'guardar la tarea',
      () => widget.database.agregarTarea(titulo),
    );
    if (ok) _tituloController.clear();
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    await _ejecutar(
      'actualizar el estado',
      () => widget.database.cambiarEstado(tarea.id, completada),
    );
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditarTarea(tituloActual: tarea.titulo),
    );
    if (nuevoTitulo == null) return; // Cancelado.
    final ok = await _ejecutar(
      'editar la tarea',
      () => widget.database.actualizarTitulo(tarea.id, nuevoTitulo),
    );
    if (ok) _mostrarMensaje('Tarea actualizada');
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${tarea.titulo}"? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final ok = await _ejecutar(
      'eliminar la tarea',
      () => widget.database.eliminarTarea(tarea.id),
    );
    if (ok) _mostrarMensaje('Tarea eliminada');
  }

  /// Ejecuta una operación de la base y muestra un mensaje si falla.
  /// Devuelve true si terminó bien.
  Future<bool> _ejecutar(String accion, Future<Object?> Function() op) async {
    try {
      await op();
      return true;
    } on TareaException catch (e) {
      _mostrarMensaje(e.mensaje);
    } catch (e) {
      _mostrarMensaje('No se pudo $accion: $e');
    }
    return false;
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
        title: Text(
          tarea.titulo,
          style: tarea.completada
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
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

/// Diálogo para editar el título. Tiene su propio controlador para poder
/// liberarlo en dispose(). Devuelve el nuevo título, o null si se cancela.
class _DialogoEditarTarea extends StatefulWidget {
  final String tituloActual;

  const _DialogoEditarTarea({required this.tituloActual});

  @override
  State<_DialogoEditarTarea> createState() => _DialogoEditarTareaState();
}

class _DialogoEditarTareaState extends State<_DialogoEditarTarea> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.tituloActual);
  String? _error;

  void _guardar() {
    final error = validarTitulo(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Título',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _guardar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
