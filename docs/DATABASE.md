# Base de datos

Las migraciones se aplican en orden lexicográfico:

1. `202608010001_create_profiles.sql`
2. `202608030001_create_service_requests.sql`
3. `202608030002_create_realtime_chat.sql`
4. `202608030003_create_realtime_request_workflow.sql`
5. `202608030004_resolve_beta_critical.sql`
6. `202608030005_add_admin_role.sql`
7. `202608030006_create_admin_dashboard.sql`
8. `202608030007_create_admin_user_management.sql`
9. `202608030008_create_admin_professional_management.sql`
10. `202608030009_sync_professional_availability.sql`
11. `202608030010_admin_request_corrections.sql`
12. `202608040001_harden_admin_users.sql`
13. `202608040002_harden_admin_professionals.sql`

Tablas principales: `profiles`, `professional_profiles`, `service_requests`,
`conversations`, `messages`, `quotations`, `request_events`, `ratings`,
`reports`, `admin_audit_logs`, `admin_professional_audit_log` y
`admin_request_audit_log`.

Los repositorios admin consultan las mismas tablas mediante RPCs. Suspender una
cuenta actualiza `profiles`; verificar un profesional actualiza
`professional_profiles`; dashboard y detalle agregan solicitudes, ratings,
reportes y auditoría persistidos.

La gestión profesional persiste categorías, cobertura, experiencia, portafolio
y documentos de verificación en `professional_profiles`. Aprobaciones,
rechazos, solicitudes de información y cambios de suspensión se ejecutan con
`perform_admin_professional_action`; el RPC valida el rol admin y registra tanto
la auditoría profesional detallada como la entrada global en
`admin_audit_logs`. Rechazar o pedir información requiere un motivo.

El descubrimiento de la aplicación principal usa
`list_available_professionals`, que solo devuelve profesionales verificados y
con cuenta activa. El historial de solicitudes no depende de ese listado y
permanece disponible para sus participantes.

Realtime debe publicar `profiles` y `professional_profiles`; la última
migración lo configura de forma idempotente. Nunca edites una migración ya
aplicada: añade otra con timestamp posterior.

Para un proyecto enlazado:

```sh
supabase link --project-ref PROJECT_REF
supabase db push
```
