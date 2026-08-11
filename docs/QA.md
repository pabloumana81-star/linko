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

`test/auth_platform_configuration_test.dart` cubre el callback exacto y rechazo
de redirects externos; `test/auth_session_recovery_test.dart` cubre callback e
invalidez de Magic Link además de recuperación/cambio/logout; y
`test/diagnostics_test.dart` comprueba redacción de tokens. Son pruebas de código
y no se presentan como certificación real de proveedor.

Ejecución del 9 de agosto de 2026: análisis sin incidencias, 144 pruebas raíz,
integración MVP macOS, 65 pruebas Admin, E2E Supabase real y lint enlazado
aprobaron. No se ejecutó consentimiento Google/Apple ni entrega de correo, por
lo que esos proveedores continúan **MANUAL CERTIFICATION REQUIRED**.

`test/auth_platform_configuration_test.dart` también certifica estáticamente
que Android, iOS y macOS usan `com.linko.app`, que RunnerTests usa el sufijo
correspondiente y que el callback `io.supabase.linko://login-callback/` no
cambió. La búsqueda posterior permite el identificador provisional únicamente
dentro de una aserción negativa de regresión.

Certificación del 9 de agosto de 2026: análisis sin incidencias, 145 pruebas
raíz, integración macOS, APK debug Android, 65 pruebas Admin y E2E Supabase real
aprobaron con `com.linko.app`. La firma de distribución no forma parte de este
PASS y continúa como configuración manual.

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

## Supabase Storage

`test/professional_storage_test.dart` cubre MIME/tamaño, paridad mock,
agregar/eliminar portafolio y documentos, buckets separados, rutas de owner y
triggers contra metadata fabricada. Las regresiones de ruta directa permanecen
en `test/professional_profile_loading_test.dart`.

`integration_test/real_supabase_e2e_test.dart` carga una imagen pública y un
PDF privado con el profesional aislado; comprueba lectura pública del
portafolio, lectura privada del owner, denegación a customer/profesional no
relacionado, rechazo de upload cruzado y metadata fabricada, revisión Admin por
URL firmada, bloqueo posterior a aprobación y eliminación/cleanup. No imprime
rutas privadas, tokens ni enlaces firmados.

Certificación del 9 de agosto de 2026: `flutter analyze`, 151 pruebas raíz,
integración MVP macOS, 66 pruebas Admin, dry-run/aplicación de las migraciones
`202608100001`/`202608100002`, lint enlazado y E2E Supabase real aprobaron.
Mock mode conserva uploads deterministas y la suite real eliminó todos sus
objetos y registros `qa_<timestamp>`.

## Beta Release Readiness

La validación rápida de navegador se ejecuta con:

```sh
./scripts/qa_web.sh
```

Este comando abre el motor Chrome de Flutter y ejecuta:

- Main: inicio a 320, 390, 768 y 1440 px; etiquetas semánticas y foco de
  teclado; guest/customer/discovery/perfil; guest/professional/perfil y
  controles de Storage; texto ampliado hasta 200 %.
- Admin: autorización, navegación desktop, bloqueo no-Admin, sincronización
  mock compartida y drawer compacto a 320 px con texto al 160 %.

El smoke Chrome usa explícitamente `BACKEND_MODE=mock` para ser reproducible y
no demuestra una sesión Supabase dentro de un navegador real. Por separado,
`./scripts/qa_supabase.sh` usa clientes Supabase autenticados y fixtures
aislados para certificar repositorios Main/Admin, RLS, Realtime, workflow,
Storage y cleanup. Ninguna de las dos suites reemplaza la certificación manual
de consentimientos Google/Apple, entrega Magic Link, lectores de pantalla o la
matriz de dispositivos/navegadores.

La regresión de seguridad incluye configuración sin fallback, restricción de
redirect HTTP, ausencia de IDs mock en Supabase y redacción de access/refresh/
ID tokens, JWT, códigos OAuth/Magic Link, API keys, firmas y URLs firmadas. Los
tests de rutas comprueban carga, no encontrado, error y reconexión controlada.

Para un candidato de release también se ejecutan, sin imprimir `.env`:

```sh
flutter analyze
./qa.sh
cd admin && ./qa.sh
cd ..
./scripts/qa_web.sh
flutter build web --release --dart-define-from-file=.env
(cd admin && flutter build web --release --dart-define-from-file=../.env)
flutter build apk --debug --dart-define=BACKEND_MODE=mock
supabase db lint --linked
./scripts/qa_supabase.sh
git diff --check
```

Certificación del 9 de agosto de 2026: analyze, 157 pruebas raíz, 67 Admin
(más una opt-in omitida), 6 smoke Chrome, ambos builds web release, APK debug,
lint enlazado y E2E Supabase real aprobaron. El E2E real completó Main/Admin,
Realtime, Storage y cleanup en 35 segundos. La integración GUI macOS compiló,
pero no pudo lanzar/foreground la app (`open returned 1`) en dos intentos y fue
interrumpida; queda explícitamente **no ejecutada con éxito**, no PASS.

El APK requirió fijar `file_picker 10.3.10`: la línea 11.0.3 no compilaba su
clase Kotlin con el template AGP 9 en modo KGP, mientras activar Built-in Kotlin
rompía `app_links`/tooling. La versión fijada compila y conserva el selector de
archivos, aunque Gradle advierte que KGP será incompatible en una versión futura
de Flutter. Debe revisarse cuando ambos plugins soporten Built-in Kotlin estable.
