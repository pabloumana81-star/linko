# Estado del proyecto LinkO

## Fase actual

Endurecimiento de producción del Backoffice, con gestión de usuarios y profesionales sincronizada con la aplicación principal.

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

## Estado de QA

- Los comandos oficiales son `./qa.sh` y `cd admin && ./qa.sh`.
- La cobertura automatizada incluye autorización, estados de interfaz, mapeo del repositorio, filtros, acciones administrativas, auditoría y sincronización de cuenta.
- El arranque del Admin cubre por regresión los modos mock y Supabase, además de configuración ausente o inválida.
- El resultado de la ejecución más reciente se registra en la entrega del sprint.

## Trabajo restante

- Ejecutar la certificación contra un proyecto Supabase remoto con credenciales de prueba aisladas.
- Validar las políticas RLS y Realtime en cada ambiente desplegado después de aplicar la última migración.
- Completar pruebas manuales de accesibilidad y compatibilidad en los navegadores soportados.
