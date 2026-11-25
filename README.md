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

- Flutter 3.47 (stable) con Dart 3.13 o superior.
- Android: Android SDK y un emulador o dispositivo. Web: Chrome.
- No necesita servidor, internet ni cuentas: todos los datos son locales.

```bash
git clone https://github.com/Roger934/Practica-SQLite.git
cd Practica-SQLite
flutter pub get
dart run build_runner build   # opcional: app_database.g.dart ya está en el repo; solo si cambia la tabla
flutter analyze
flutter test
flutter run -d emulator-5554  # Android
```

> En build_runner 2.17 ya no existe la opción `--delete-conflicting-outputs`.

### Web

SQLite corre en el navegador compilado a WebAssembly. `web/` contiene dos archivos de la release oficial
[drift-2.35.4](https://github.com/simolus3/drift/releases/tag/drift-2.35.4), la misma versión de `drift` del `pubspec.lock`:

- `web/sqlite3.wasm`: SQLite compilado a WebAssembly.
- `web/drift_worker.js`: worker que ejecuta la base fuera del hilo de la interfaz.

Si se actualiza `drift`, hay que descargar los dos archivos de la release que coincida con la nueva versión.

Para ejecutar la app y probar la persistencia:

```bash
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

Luego abre http://localhost:8080 en tu Chrome habitual.

- No uses `flutter run -d chrome` para probar persistencia: abre Chrome con un perfil temporal nuevo en cada ejecución y las tareas parecen perderse.
- Los datos dependen del origen. `localhost:8080`, `localhost:5000` y `127.0.0.1:8080` son bases distintas.
- Drift eligió `sharedIndexedDb`, porque OPFS necesita las cabeceras COOP/COEP que el servidor de desarrollo no envía.
- En modo incógnito, o si se borran los datos del sitio, las tareas se pierden.
- Los datos **no** se sincronizan con Android: cada plataforma tiene su propia base local.

## Estructura

- `lib/data/app_database.dart`: tabla `Tareas`, apertura de la base con `driftDatabase` y operaciones.
- `lib/data/app_database.g.dart`: código generado por Drift (no se edita a mano).
- `lib/data/validaciones.dart`: validación del título, independiente de la interfaz.
- `lib/screens/tareas_page.dart`: interfaz; lee las tareas con un `StreamBuilder`, sin consultas dentro de `build()`.

## Plataformas verificadas

| Plataforma                         | Estado                  | Pruebas            |
|------------------------------------|-------------------------|--------------------|
| Android 15 (emulador, API 35)      | Probada                 | P1 a P5 correctas  |
| Web (Chrome, localhost:8080)       | Probada                 | P6 correcta        |
| Windows                            | Prevista (falta Visual Studio C++) |         |
| iOS / macOS / Linux                | Previstas, no probadas  |                    |

## Pruebas manuales (P1–P6)

| ID | Acción | Esperado | Android 15 (emulador) | Chrome |
|----|--------|----------|-----------------------|--------|
| P1 | Agregar tres tareas, cerrar la app por completo y abrirla | Permanecen las tres | Correcta | — |
| P2 | Marcar una como completada y reiniciar | Se conserva el estado | Correcta | — |
| P3 | Cambiar el título y reiniciar | Aparece el nuevo título | Correcta | — |
| P4 | Eliminar una tarea y reiniciar | No reaparece | Correcta | — |
| P5 | Intentar agregar un título vacío | No se registra | Correcta | — |
| P6 | Recargar y cerrar/abrir la pestaña (mismo origen y perfil) | Los datos permanecen | — | Correcta |

En Android, "reiniciar" significa cerrar la app desde la vista de recientes y volver a abrirla. Un hot reload no prueba la persistencia porque no reinicia el proceso.

## Pruebas automatizadas

```bash
flutter test
```

Son 16 pruebas en total:

- **`test/validaciones_test.dart`** (6 pruebas unitarias): rechaza títulos vacíos, de solo espacios o de más de 200 caracteres; acepta el límite exacto y los títulos con espacios alrededor.
- **`test/app_database_test.dart`** (7 pruebas): ejecutan la capa de datos sobre SQLite real en memoria (`NativeDatabase.memory()`).
  - INSERT con normalización y rechazo de títulos vacíos.
  - SELECT ordenado y con ids únicos.
  - UPDATE de título y de estado, conservando el título anterior si el nuevo es inválido.
  - DELETE de una sola tarea.
  - Error comprensible (`TareaException`) cuando el id no existe.
- **`test/widget_test.dart`** (3 pruebas de interfaz): la pantalla inicial carga; agregar desde la interfaz muestra la tarea y la guarda en la base; un título vacío muestra el mensaje y no guarda nada (P5).

Las pruebas usan una base en memoria, así que no modifican los datos reales de la app.

## Estado del proyecto

- [x] Etapa 1: preparación y diseño
- [x] Etapa 2: persistencia real (crear y consultar)
- [x] Etapa 3: edición, cambio de estado y eliminación
- [x] Etapa 4: web, pruebas y documentación de plataformas
