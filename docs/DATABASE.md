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
14. `202608040003_admin_real_data_modules.sql`
15. `202608060001_notify_professional_availability.sql`
16. `202608060002_complete_request_timeline.sql`
17. `202608060003_publish_service_requests.sql`
18. `202608080001_service_requests_replica_identity.sql`
19. `202608080002_sync_rating_summary.sql`
20. `202608080004_auth_onboarding_default.sql`
21. `202608080005_production_professional_profiles.sql`
22. `202608080006_preserve_professional_display_name.sql`
23. `202608090001_harden_professional_verification_privacy.sql`
24. `202608090002_admin_operations_closure.sql`

Tablas principales: `profiles`, `professional_profiles`, `service_requests`,
`conversations`, `messages`, `quotations`, `request_events`, `ratings`,
`reports`, `professional_verification_submissions`, `admin_audit_logs`,
`admin_professional_audit_log`, `admin_request_audit_log` y
`admin_report_audit_log`.

`profiles.id` comparte la identidad de `auth.users`. El trigger
`handle_new_auth_user_profile` y el upsert por clave primaria hacen idempotente
la creación de perfil. Desde `202608080004`, solo los perfiles nuevos nacen con
`onboarding_completed = false`; no se reescriben cuentas existentes.

Los repositorios admin consultan las mismas tablas mediante RPCs. Suspender una
cuenta actualiza `profiles`; verificar un profesional actualiza
`professional_profiles`; dashboard y detalle agregan solicitudes, ratings,
reportes y auditoría persistidos.

La gestión profesional persiste categorías, cobertura, experiencia y portafolio
en `professional_profiles`. Aprobaciones,
rechazos, solicitudes de información y cambios de suspensión se ejecutan con
`perform_admin_professional_action`; el RPC valida el rol admin y registra tanto
la auditoría profesional detallada como la entrada global en
`admin_audit_logs`. Rechazar o pedir información requiere un motivo.

`202608080005` añade `biography` y `experience_description` con valores vacíos
seguros para cuentas existentes. Categorías, cobertura, años de experiencia y
portfolio reutilizan columnas existentes. `list_available_professionals()`
calcula promedio/conteo de ratings y trabajos completados en cada lectura;
ninguno se duplica como nuevo campo. Las reseñas públicas incluyen estrellas,
comentario y fecha, pero no identidad ni datos privados del cliente.

`get_own_professional_profile()` permite cargar perfiles pendientes del usuario
actual. `update_own_professional_profile()` usa `security definer`, valida
`auth.uid()` y `profiles.active_mode = 'professional'`, limita años y cantidad
de servicios y hace un upsert únicamente sobre el ID autenticado. Sus permisos
se revocan a `public`/`anon` y se conceden a `authenticated`.

No existe aún una migración de Supabase Storage. `portfolio` conserva JSON para
URLs HTTPS previamente administradas; habilitar uploads exige crear un bucket,
límites MIME/tamaño y políticas por carpeta de propietario.

`202608080006` garantiza que editar campos profesionales no sobrescriba
`display_name`: el nombre general se usa al crear la ficha, pero una ficha
existente conserva su nombre hasta que exista un flujo explícito para editarlo.

`202608090001` copia `verification_documents` a la tabla privada
`professional_verification_submissions`, valida conteo y equivalencia JSON y
solo después elimina la columna pública. Una discrepancia aborta la transacción.
La FK uno-a-uno usa `on delete cascade`; hay índice por `updated_at` y RLS.

Permisos de verificación privada:

- propietario: `select`, `insert` y actualización de documentos/metadatos propios;
- Admin con `profiles.role = 'admin'`: solo lectura;
- customer, profesional no relacionado, `anon` y `public`: sin lectura;
- aprobación/rechazo: solo `perform_admin_professional_action`, que conserva
  `verification_status` en la tabla pública y registra auditoría.

`get_own_professional_verification()` y
`submit_own_professional_verification()` no aceptan un ID objetivo: usan
`auth.uid()`. `get_admin_professional_detail()` lee la tabla privada después de
validar Admin. Ningún RPC público devuelve documentos, metadata o motivos.

El descubrimiento de la aplicación principal usa
`list_available_professionals`, que solo devuelve profesionales verificados y
con cuenta activa. El historial de solicitudes no depende de ese listado y
permanece disponible para sus participantes.

En modo Supabase, Dashboard, Usuarios, Profesionales, Solicitudes y Reportes
consultan exclusivamente RPCs o repositorios Supabase compartidos. Las
funciones `list_admin_requests()` y `list_admin_reports()` validan el rol admin
en servidor antes de exponer datos que no pertenecen necesariamente al usuario
autenticado.

`perform_admin_report_action()` limita las transiciones a resolver, descartar o
escalar, exige una nota y bloquea repeticiones o cambios sobre cierres. Cada
acción se agrega a `admin_report_audit_log`; no existe borrado desde el cliente.
`perform_admin_request_action()` solo permite marcar para revisión, agregar una
nota o cancelar antes de la confirmación final. La corrección genérica
`correct_admin_request_status()` fue revocada a clientes autenticados. La marca
no altera el estado del workflow y toda intervención queda en
`admin_request_audit_log`. Ambos RPC validan `profiles.role = 'admin'`, mientras
RLS deja los historiales en lectura exclusiva para Admin.

Realtime debe publicar `profiles` y `professional_profiles`. Como RLS impide
que un cliente lea el perfil privado de otro usuario, los cambios de
`profiles.account_status` actualizan `professional_profiles.updated_at` mediante
un trigger. Así Realtime provoca un refresh del descubrimiento sin exponer la
fila privada de `profiles`. Nunca edites una migración ya aplicada: añade otra
con timestamp posterior.

`service_requests` también pertenece a `supabase_realtime` y usa
`REPLICA IDENTITY FULL`. Los streams customer y professional conservan RLS de
participantes y reciben las mismas transiciones sin polling. La timeline
persiste `request_created` y `rating_submitted`; al calificar, el RPC actualiza
de forma transaccional el archivo de la solicitud y el resumen denormalizado de
rating del profesional.

Para un proyecto enlazado:

```sh
supabase link --project-ref PROJECT_REF
supabase db push
```
