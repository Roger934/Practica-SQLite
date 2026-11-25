/// Reglas de validación del título de una tarea.
/// Están separadas de la interfaz y de la base para poder probarlas solas.
const int longitudMaximaTitulo = 200;

/// Error de la capa de datos con un mensaje pensado para mostrarse al usuario.
class TareaException implements Exception {
  final String mensaje;
  const TareaException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Devuelve el título sin espacios al inicio y al final.
String normalizarTitulo(String titulo) => titulo.trim();

/// Devuelve un mensaje de error comprensible, o `null` si el título es válido.
String? validarTitulo(String titulo) {
  final limpio = normalizarTitulo(titulo);
  if (limpio.isEmpty) {
    return 'El título no puede estar vacío.';
  }
  if (limpio.length > longitudMaximaTitulo) {
    return 'El título no puede superar $longitudMaximaTitulo caracteres.';
  }
  return null;
}
