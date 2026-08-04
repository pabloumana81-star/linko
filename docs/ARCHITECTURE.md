# Arquitectura

LinkO contiene dos aplicaciones desplegables y un backend compartido:

- La raíz es la aplicación Flutter para clientes y profesionales.
- `admin/` es el backoffice Flutter Web y tiene router, navegación y presentación propios.
- `supabase/migrations/` es la definición versionada del backend común.

El backoffice depende del paquete raíz mediante `path: ..` únicamente para
contratos y componentes compartidos: configuración backend, autenticación,
modelos de solicitudes, repositorios base, diagnóstico y tokens visuales. La
aplicación principal no depende del paquete admin.

Ambas aplicaciones construyen `BackendConfig.fromEnvironment()` y seleccionan
repositorios Riverpod mock o Supabase. En Supabase usan la misma URL, clave
pública y `SupabaseClient`. GoRouter es independiente en cada aplicación.

## Sincronización profesional

Las acciones admin modifican `profiles.account_status` y
`professional_profiles.verification_status` mediante RPC protegido. La app
principal escucha realtime en ambas tablas y vuelve a ejecutar
`list_available_professionals()`. Solo perfiles activos y verificados entran en
Home, búsqueda, resultados o lookup directo.

Mock mode utiliza `ProfessionalAvailabilityStore` como equivalente observable
en memoria. No intenta sincronizar procesos independientes; existe para QA
determinista.

## Seguridad

Los clientes reciben solo la anon/publishable key. RLS está habilitado y los
RPC administrativos validan `profiles.role = 'admin'`. Las service-role keys no
forman parte de ninguna aplicación; la certificación real puede usar una clave
de test exclusivamente para crear y limpiar fixtures aislados.
