# Gestor de tareas local (SQLite + Drift)

Aplicación Flutter que administra tareas en una base de datos **SQLite local**, sin servidor ni conexión a internet. Una sola base de código para Android, iOS, Windows, Linux, macOS y web.

## Tecnología de persistencia elegida

**Drift** + **drift_flutter**.

- **Drift** es un ORM para SQLite en Dart. Las tablas se definen como clases de Dart y `build_runner` genera el código tipado para consultar e insertar. Además permite consultas reactivas (`Stream`) con las que la interfaz se actualiza sola después de cada escritura.
- **drift_flutter** ofrece `driftDatabase(...)`, que abre la base en la ubicación correcta de cada plataforma: un archivo en el directorio de la app en Android, iOS y escritorio, y OPFS o IndexedDB mediante WebAssembly en el navegador.
- Se descartó `sqflite` porque no soporta web ni escritorio sin paquetes adicionales, y `shared_preferences` porque no es una base de datos SQLite.

## Diseño de la tabla `tareas`

| Columna      | Tipo Drift     | Tipo SQLite | Restricciones                      |
|--------------|----------------|-------------|------------------------------------|
| `id`         | `IntColumn`    | INTEGER     | PRIMARY KEY, AUTOINCREMENT         |
| `titulo`     | `TextColumn`   | TEXT        | NOT NULL, de 1 a 200 caracteres    |
| `completada` | `BoolColumn`   | INTEGER     | NOT NULL, DEFAULT 0 (0 = no, 1 = sí) |

Cada registro se identifica con `id`, un entero que SQLite asigna automáticamente al insertar y que no se reutiliza. Edición, cambio de estado y eliminación se hacen por `id`. SQLite no tiene un tipo booleano nativo, así que `completada` se guarda como 0 o 1.

## Requisitos y ejecución

```bash
flutter pub get
dart run build_runner build   # regenera lib/data/app_database.g.dart si cambia la tabla
flutter analyze
flutter test
flutter run -d emulator-5554  # o -d chrome
```

> En build_runner 2.17 ya no existe la opción `--delete-conflicting-outputs`.

## Estructura

- `lib/data/app_database.dart`: tabla `Tareas`, apertura de la base con `driftDatabase` y operaciones.
- `lib/data/app_database.g.dart`: código generado por Drift (no se edita a mano).
- `lib/data/validaciones.dart`: validación del título, independiente de la interfaz.
- `lib/screens/tareas_page.dart`: interfaz; lee las tareas con un `StreamBuilder`, sin consultas dentro de `build()`.

## Plataformas verificadas

| Plataforma                         | Estado                  | Pruebas            |
|------------------------------------|-------------------------|--------------------|
| Android 15 (emulador, API 35)      | Probada                 | P1 y P5 correctas  |
| Web (Chrome)                       | Pendiente               |                    |
| Windows                            | Prevista (falta Visual Studio C++) |         |
| iOS / macOS / Linux                | Previstas, no probadas  |                    |

## Estado del proyecto

- [x] Etapa 1: preparación y diseño
- [x] Etapa 2: persistencia real (crear y consultar)
- [ ] Etapa 3: edición, cambio de estado y eliminación
- [ ] Etapa 4: web, pruebas y documentación de plataformas
