import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/validaciones.dart';

/// Pruebas unitarias de la validación del título (F1 y P5).
void main() {
  group('validarTitulo', () {
    test('rechaza un título vacío', () {
      expect(validarTitulo(''), 'El título no puede estar vacío.');
    });

    test('rechaza un título compuesto solo por espacios', () {
      expect(validarTitulo('    '), isNotNull);
      expect(validarTitulo(' \t \n '), isNotNull);
    });

    test('rechaza un título de más de $longitudMaximaTitulo caracteres', () {
      expect(validarTitulo('a' * (longitudMaximaTitulo + 1)), isNotNull);
    });

    test('acepta un título en el límite de $longitudMaximaTitulo caracteres',
        () {
      expect(validarTitulo('a' * longitudMaximaTitulo), isNull);
    });

    test('acepta un título válido con espacios alrededor', () {
      expect(validarTitulo('  Estudiar Drift  '), isNull);
    });
  });

  test('normalizarTitulo quita los espacios de los extremos', () {
    expect(normalizarTitulo('  Comprar pan  '), 'Comprar pan');
  });
}
