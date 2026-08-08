# Estado del proyecto LinkO

## Fase actual

Hito de autenticación passwordless y recuperación de sesión en certificación.
El backend compartido y Backoffice conservan su certificación contra el
proyecto Supabase real.

## Módulos completados

- Aplicación principal para clientes y profesionales.
- Backoffice web independiente con acceso exclusivo para administradores.
- Dashboard administrativo.
- Gestión de usuarios: listado, búsqueda, filtros, detalle, suspensión, reactivación y auditoría.
- Gestión de profesionales: datos operativos, filtros, detalle, documentos, aprobación, rechazo motivado, solicitud de información, suspensión, reactivación y auditoría.
- Solicitudes, reportes y configuración base del Backoffice.
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

## Trabajo restante

- Convertir Configuración Admin de pantalla base a módulo funcional cuando se
  definan sus opciones operativas.
- Completar acciones operativas de resolución de reportes y gestión avanzada de
  solicitudes; actualmente estos módulos ofrecen datos reales y seguimiento.
- Sustituir el fallback visual de perfil profesional usado en deep links sin
  estado por una carga directa desde Supabase.
- Certificar externamente Google, Apple y entrega de Magic Link con credenciales,
  dominios, plantillas y cuentas reales; el código está completo, pero los
  proveedores aún no están certificados.
- Revalidar RLS y Realtime después de cada migración futura.
- Completar pruebas manuales de accesibilidad y compatibilidad en los navegadores soportados.
