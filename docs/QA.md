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

## Autenticación y recuperación

`test/authentication_foundation_test.dart`,
`test/auth_session_recovery_test.dart`, `test/profile_repository_test.dart` y
`test/auth_platform_configuration_test.dart` cubren estado Auth, reinicio,
refresh inválido/expirado, logout, segundo login, cambio de cuenta, guest,
onboarding, perfil persistido, rutas protegidas y callbacks nativos.

La suite automatizada no puede certificar pantallas de consentimiento ni
entrega de correo de proveedores externos. La matriz manual de release debe
ejecutar Google, Apple y Magic Link en web, Android, iOS y macOS, incluyendo
cancelación, error, usuario existente y usuario nuevo. Consulta
`docs/AUTHENTICATION.md` para la configuración exacta.

Última ejecución del 8 de agosto de 2026: `flutter analyze`, `./qa.sh`,
`cd admin && ./qa.sh` y `./scripts/qa_supabase.sh` aprobaron. La certificación
de proveedores externos permanece separada de este PASS automatizado.

## Perfil profesional

`test/professional_profile_loading_test.dart` valida el mapeo del RPC Supabase,
lookup por ID, reconstrucción de la ruta sin `extra`, optimización con estado en
mock, ID inexistente, error de repositorio y ausencia de contaminación
placeholder en Supabase. La certificación real también consulta por ID al
profesional aislado después de aprobar su verificación.

Certificación del 8 de agosto de 2026: análisis, 125 pruebas raíz, integración
MVP macOS, 57 pruebas Admin y `./scripts/qa_supabase.sh` aprobaron. El E2E real
confirmó lookup por ID del profesional verificado sin afectar Realtime ni la
limpieza aislada.

`test/professional_profile_production_data_test.dart` cubre mapeo completo,
persistencia de campos editables, rechazo del servidor, modo mock, estados
vacíos y render de reseñas/conteos/portfolio reales. El E2E Supabase actualiza
el perfil autenticado, rechaza un intento customer y confirma que discovery
recibe los mismos datos después de la verificación.

Certificación del 8 de agosto de 2026: `flutter analyze`, 131 pruebas raíz,
integración MVP macOS, 57 pruebas Admin y el E2E Supabase real aprobaron. La
certificación real también confirmó rechazo de edición por un customer,
sincronización de los campos profesionales y limpieza aislada.

## Privacidad de verificación

`test/professional_verification_privacy_test.dart` valida copia antes de borrar,
RLS propietario/Admin, escritura solo propia y ausencia de campos privados en
discovery. Admin verifica que su detalle use la tabla protegida. El E2E real
confirma que customer y profesional no relacionado obtienen cero filas, el
propietario lee la suya, Admin puede revisarla y la aprobación conserva
discovery, Realtime y el flujo completo.

Certificación del 9 de agosto de 2026: análisis sin incidencias, 135 pruebas
raíz, integración MVP macOS, 58 pruebas Admin, lint del esquema y E2E Supabase
real aprobaron. El test Admin real opt-in permanece omitido dentro de su QA
normal porque la certificación raíz ya cubre el backend enlazado y su limpieza.

## Operaciones Admin

`admin/test/admin_operations_test.dart` cubre resolver, descartar, escalar,
motivos obligatorios, auditoría, duplicados y paridad mock para intervenciones
de solicitudes. `test/admin_operations_migration_test.dart` verifica las
garantías contractuales del SQL. El E2E real ejecuta marca y nota sin cambiar el
estado de la solicitud, rechaza customer no autorizado, escala y resuelve un
reporte, comprueba sus auditorías y limpia esos registros aislados.

Certificación del 9 de agosto de 2026: `flutter analyze`, 138 pruebas raíz,
integración MVP macOS, 65 pruebas Admin, `supabase db lint --linked` y E2E
Supabase real aprobaron. El dry-run y la aplicación de
`202608090002_admin_operations_closure.sql` finalizaron correctamente.
