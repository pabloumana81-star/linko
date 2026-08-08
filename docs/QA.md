# QA

La suite Admin verifica conjuntamente que Dashboard, Usuarios, Profesionales,
Solicitudes y Reportes resuelvan repositorios Supabase cuando
`BACKEND_MODE=supabase`, y mocks únicamente en modo mock. También cubre la
insignia de backend y la página `/diagnostics`, disponible solo en debug.

Pruebas sin secretos:

```sh
./qa.sh
cd admin && ./qa.sh
```

La raíz ejecuta análisis, unit/widget tests y el flujo MVP en macOS. Admin
ejecuta análisis y tests del backoffice. La certificación determinista
cross-app vive en `admin/test/shared_supabase_synchronization_test.dart`.

Prueba de navegador admin:

```sh
cd admin
flutter test test/admin_browser_flow_test.dart --platform chrome
```

La suite Supabase real es opt-in:

```sh
cd admin
flutter test test/real_supabase_cross_app_test.dart \
  --dart-define=RUN_SUPABASE_TESTS=true \
  --dart-define-from-file=../.env.test
```

Usa un proyecto desechable. `.env.test` debe estar ignorado por Git. CI ejecuta
esta capa solo cuando existen todos los secretos requeridos.

## Certificación E2E del proyecto enlazado

La certificación completa usa exclusivamente el `.env` raíz, exige
`BACKEND_MODE=supabase` y comprueba que `SUPABASE_URL` corresponda al proyecto
enlazado por la CLI. La clave privilegiada se obtiene en memoria para crear y
eliminar identidades `qa_<timestamp>`; nunca se escribe ni se imprime.

```sh
./scripts/qa_supabase.sh
```

La suite cubre descubrimiento, solicitud, conversación, mensajes, cotización,
programación, ejecución, confirmación, rating, archivo, repositorios customer y
professional, Admin, timeline y Realtime. Es opt-in y no forma parte de
`./qa.sh` ni de `admin/qa.sh`.

### Última certificación

Ejecutada el 8 de agosto de 2026 contra el proyecto enlazado:

- Complete workflow: **PASS**.
- Main/Admin synchronization: **PASS**.
- Realtime: **PASS**.
- Isolated cleanup: **PASS**.

La matriz final también aprobó `flutter analyze`, `./qa.sh` y
`cd admin && ./qa.sh`. El test real crea identidades y registros con prefijo
`qa_<timestamp>`, valida que no haya eventos duplicados y elimina únicamente
esos datos. La credencial privilegiada vive solo en memoria durante el proceso.

El modo mock continúa cubierto explícitamente por los scripts QA mediante
`BACKEND_MODE=mock`; no es fallback de una configuración Supabase inválida.
