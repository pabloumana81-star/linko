# Estado del proyecto LinkO

## Fase actual

Production Application Identity. Android, iOS y macOS usan `com.linko.app` y
conservan el callback Supabase independiente; falta registrar y firmar esta
identidad en las consolas externas.

## Módulos completados

- Aplicación principal para clientes y profesionales.
- Backoffice web independiente con acceso exclusivo para administradores.
- Dashboard administrativo.
- Gestión de usuarios: listado, búsqueda, filtros, detalle, suspensión, reactivación y auditoría.
- Gestión de profesionales: datos operativos, filtros, detalle, documentos, aprobación, rechazo motivado, solicitud de información, suspensión, reactivación y auditoría.
- Reportes: resolución, descarte y escalamiento sin borrado, con motivo e historial.
- Solicitudes Admin: detalle, marca de revisión, notas de intervención y cancelación limitada a estados operativamente válidos.
- Repositorios seleccionables para los modos mock y Supabase.
- Sincronización del estado de cuenta mediante `profiles.account_status`.
- Sincronización de visibilidad y distintivo profesional mediante `professional_profiles.verification_status` y Realtime.
- Dashboard, Usuarios, Profesionales, Solicitudes y Reportes usan datos Supabase reales cuando `BACKEND_MODE=supabase`; los repositorios mock quedan limitados al modo mock y QA.
- La selección administrativa está centralizada y cuenta con diagnóstico debug de backend, repositorios, sesión, Realtime y disponibilidad de base de datos.
- `BACKEND_MODE` se valida estrictamente en la configuración compartida: solo acepta `mock` o `supabase`; un valor ausente o inválido detiene el arranque con un mensaje controlado y nunca activa datos mock de forma silenciosa.
- Autenticación principal con Google, Apple y Magic Link mediante Supabase Auth;
  la sesión se completa únicamente al recibir el callback de Auth.
- Recuperación con refresh de sesiones expiradas, invalidación controlada,
  logout, cambio de cuenta y reconciliación de rutas protegidas.
- Guest separado de la sesión Supabase y transición segura hacia una cuenta.
- Perfil, rol, suspensión y onboarding proceden de `profiles`; usuarios nuevos
  completan la selección customer/professional sin duplicar perfiles.
- Discovery navega por ID profesional y el perfil reconstruye su estado desde
  `ProfessionalsRepository.getProfessionalById` cuando Supabase está activo.
- IDs inexistentes y fallos de backend muestran estados controlados en español;
  ningún profesional placeholder sustituye datos Supabase.
- Biografía, servicios, experiencia, cobertura y portfolio forman parte del
  contrato profesional real. Rating, reseñas y trabajos completados se calculan
  desde `ratings` y `service_requests`.
- El perfil profesional propio se crea o actualiza mediante un RPC que valida
  `auth.uid()` y el modo profesional; el cliente nunca escribe otro perfil.
- `professional_verification_submissions` conserva material privado fuera de
  `professional_profiles`: solo el propietario puede enviarlo/modificarlo y
  solo propietario o Admin autorizado pueden leerlo.
- Redirects Auth restringidos al origen web actual o callback nativo exacto;
  sesiones persistidas se validan contra Supabase y los diagnósticos redactan
  tokens sin perder contexto ni stack traces.
- Identidad de producción `com.linko.app` alineada en Android, iOS y macOS;
  targets Apple de pruebas usan `com.linko.app.RunnerTests`.

## Estado de QA

- Los comandos oficiales son `./qa.sh` y `cd admin && ./qa.sh`.
- La cobertura automatizada incluye autorización, estados de interfaz, mapeo del repositorio, filtros, acciones administrativas, auditoría y sincronización de cuenta.
- Autenticación cubre recuperación tras reinicio, expiración, sesión inválida,
  logout/login, cambio de cuenta, guest, cancelación OAuth, onboarding y
  configuración de deep links.
- El arranque del Admin cubre por regresión los modos mock y Supabase, además de configuración ausente o inválida.
- El resultado de la ejecución más reciente se registra en la entrega del sprint.
- La certificación real completa se ejecuta de forma opt-in con
  `./scripts/qa_supabase.sh`; crea únicamente registros `qa_<timestamp>`, valida
  sincronización cross-app y confirma su limpieza.
- Certificación final del 8 de agosto de 2026:
  - Flujo completo: **PASS**.
  - Sincronización Main/Admin: **PASS**.
  - Realtime: **PASS**.
  - Limpieza aislada: **PASS**.
  - `flutter analyze`, QA raíz y QA Admin: **PASS**.
- Certificación del hito de autenticación del 8 de agosto de 2026:
  - Recuperación y estados de sesión automatizados: **PASS**.
  - QA raíz y QA Admin: **PASS**.
  - Regresión E2E Supabase Main/Admin/Realtime: **PASS**.
  - Google, Apple y entrega Magic Link reales: **PROVIDER CERTIFIED pendiente**.
- Production UX & Operations Closure — Phase 1, 8 de agosto de 2026:
  - Perfil directo por ID y estados UX: **PASS**.
  - QA raíz (125 pruebas + integración macOS): **PASS**.
  - QA Admin (57 pruebas; opt-in omitido por diseño): **PASS**.
  - Lookup real Supabase y regresión Main/Admin/Realtime: **PASS**.
- Professional Profile — Real Production Data, 8 de agosto de 2026:
  - Migraciones de perfil real y edición propia: **APLICADAS**.
  - Análisis y QA raíz (131 pruebas + integración macOS): **PASS**.
  - QA Admin (57 pruebas; opt-in omitido por diseño): **PASS**.
  - Edición/autorización, Main/Admin, Realtime y limpieza E2E: **PASS**.
- Harden Professional Verification Privacy, 9 de agosto de 2026:
  - Migración privada con preservación validada: **APLICADA**.
  - QA raíz (135 pruebas + integración macOS): **PASS**.
  - QA Admin (58 pruebas; opt-in omitido por diseño): **PASS**.
  - RLS propietario/Admin, discovery, aprobación, Realtime y E2E: **PASS**.
- Admin Operations Closure, 9 de agosto de 2026:
  - Migración `202608090002_admin_operations_closure.sql`: **APLICADA**.
  - QA raíz (138 pruebas + integración macOS): **PASS**.
  - QA Admin (65 pruebas; 1 opt-in omitida por diseño): **PASS**.
  - Lint de esquema, autorización Admin/no-Admin, auditoría, sincronización y E2E real: **PASS**.
- Production Authentication Provider Certification, 9 de agosto de 2026:
  - Redirect/session/token hardening: **CODE COMPLETE / AUTOMATED TESTED**.
  - QA raíz (144 pruebas + integración macOS): **PASS**.
  - QA Admin (65 pruebas; 1 opt-in omitida por diseño): **PASS**.
  - E2E Supabase y lint enlazado: **PASS**.
  - Google/Apple/Magic Link real: **MANUAL CERTIFICATION REQUIRED**.
  - Ajustes públicos Supabase: Email habilitado; Google y Apple no habilitados.
- Production Application Identity, 9 de agosto de 2026:
  - Android/iOS/macOS y RunnerTests: **CODE COMPLETE / AUTOMATED TESTED**.
  - QA raíz (145 pruebas + integración macOS): **PASS**.
  - Build APK debug con `com.linko.app`: **PASS**.
  - QA Admin (65 pruebas) y E2E Supabase real: **PASS**.

## Trabajo restante

- Convertir Configuración Admin de pantalla base a módulo funcional cuando se
  definan sus opciones operativas.
- Definir, después de observar la beta, si se necesita reapertura de reportes;
  no forma parte del flujo operativo actual.
- Configurar un bucket de Supabase Storage, políticas de objetos y
  transformación de imágenes antes de habilitar carga de portfolio desde el
  cliente. El contrato de URLs persistidas ya puede leerlas.
- Certificar externamente Google, Apple y entrega de Magic Link con credenciales,
  dominios, plantillas y cuentas reales; el código está completo, pero los
  proveedores aún no están certificados.
- Registrar `com.linko.app` y configurar firma/capacidades antes de certificar
  dispositivos Apple/Android; el repositorio no contiene credenciales de firma.
- Revalidar RLS y Realtime después de cada migración futura.
- Completar pruebas manuales de accesibilidad y compatibilidad en los navegadores soportados.
