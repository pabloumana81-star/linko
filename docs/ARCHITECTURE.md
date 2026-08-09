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

La aplicación principal trata Supabase Auth como fuente de sesión y `profiles`
como fuente de rol/onboarding. OAuth y Magic Link finalizan por callback y
`onAuthStateChange`; el guard de navegación reconcilia expiración, logout y
cambio de cuenta. Los detalles están en `docs/AUTHENTICATION.md`.

## Sincronización profesional

Las acciones admin modifican `profiles.account_status` y
`professional_profiles.verification_status` mediante RPC protegido. La app
principal escucha realtime en ambas tablas y vuelve a ejecutar
`list_available_professionals()`. Solo perfiles activos y verificados entran en
Home, búsqueda, resultados o lookup directo.

Mock mode utiliza `ProfessionalAvailabilityStore` como equivalente observable
en memoria. No intenta sincronizar procesos independientes; existe para QA
determinista.

## Discovery y perfil profesional

Home, búsqueda y resultados consumen `professionalDiscoveryProvider`. La
navegación usa `/professional/:professionalId`; el objeto enviado en `extra`
solo optimiza el modo mock. En Supabase, `professionalProfileByIdProvider`
siempre resuelve el ID mediante `ProfessionalsRepository.getProfessionalById`,
que reutiliza `list_available_professionals()` y sus reglas de cuenta activa y
verificación. La UI no consulta Supabase directamente y distingue loading,
ausencia y error.

`placeholderProfessionals` pertenece exclusivamente al backend mock. En
Supabase, `list_available_professionals()` devuelve biografía, servicios,
experiencia, cobertura y portfolio persistidos, junto con rating, reseñas y
trabajos completados calculados desde `ratings` y `service_requests`. El RPC no
expone identidad, correo ni ID del cliente que emitió una reseña.

La pantalla de perfil del modo profesional consume
`ownProfessionalProfileProvider`. El guardado pasa por
`ProfessionalProfileManagementController` y
`ProfessionalsRepository.updateOwnProfessionalProfile`; el widget no consulta
Supabase. `update_own_professional_profile()` valida `auth.uid()`, exige que la
cuenta esté en modo profesional y solo modifica campos editables propios.

`professional_profiles.portfolio` conserva el contrato JSON existente. La app
acepta únicamente URLs HTTPS al leer, pero no permite cargas todavía: no existe
un bucket de Storage ni políticas de objetos versionadas y no se introdujo un
atajo inseguro.

## Seguridad

Los clientes reciben solo la anon/publishable key. RLS está habilitado y los
RPC administrativos validan `profiles.role = 'admin'`. Las service-role keys no
forman parte de ninguna aplicación; la certificación real puede usar una clave
de test exclusivamente para crear y limpiar fixtures aislados.
