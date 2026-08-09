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

Los redirects se originan exclusivamente en configuración compilada: web usa
`Uri.base.origin` y nativo exige `io.supabase.linko://login-callback/` mediante
`AuthRedirectPolicy`. La sesión persistida se valida contra `/auth/v1/user`
antes de aceptar identidad. Diagnósticos conservan contexto y stack trace, pero
redactan access, refresh e ID tokens y cabeceras Authorization/API key.

La identidad nativa compartida es `com.linko.app` para Android, iOS, macOS y el
runner Linux.
Android alinea `applicationId`, namespace y paquete Kotlin; Apple alinea Runner
y RunnerTests. El esquema OAuth `io.supabase.linko` es independiente del bundle
ID para permitir el callback estable entre plataformas.

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

`ProfessionalProfileManagementController` también concentra Storage. El
repositorio valida MIME/tamaño, carga bajo la carpeta del usuario y registra
metadata mediante RPC; presentación no consulta Supabase directamente.
`professional_profiles.portfolio` conserva URLs HTTPS legacy y metadata nueva
con `path`. Al leer, el repositorio transforma únicamente las rutas del bucket
público en URLs públicas. Mock mantiene el mismo contrato de agregar/eliminar
de forma determinista.

## Privacidad de verificación profesional

`professional_profiles.verification_status` permanece público porque discovery,
el distintivo y Realtime dependen de él. Documentos y metadatos de verificación
viven en `professional_verification_submissions`, fuera de la tabla que clientes
autenticados pueden descubrir. RLS permite lectura al propietario y a usuarios
con `profiles.role = 'admin'`; solo el propietario puede insertar o actualizar.

El propietario usa RPCs sin parámetro de usuario, ligados a `auth.uid()`. Admin
recibe documentos exclusivamente a través de `get_admin_professional_detail()`,
que vuelve a validar el rol en servidor. Los RPC de discovery y perfil público
no unen ni devuelven la tabla privada. Esta tabla no se publica en Realtime;
las aprobaciones continúan actualizando `professional_profiles` y mantienen el
comportamiento observable existente.

Los archivos viven en `professional-verification`, bucket privado. Owner puede
cargar, listar y eliminar solo mientras no esté verificado; Admin genera bajo
demanda una URL firmada de 60 segundos para revisión. Esa URL no entra al modelo
persistido, logs ni RPCs. Triggers de integridad exigen que cada metadata nueva
corresponda a un objeto real de la carpeta propietaria y preservan sin alterar
metadata legacy ya existente.
Una referencia heredada sin `path` sigue visible para trazabilidad, pero la UI
no ofrece abrirla ni eliminar un archivo que Storage no administra.

## Seguridad

Los clientes reciben solo la anon/publishable key. RLS está habilitado y los
RPC administrativos validan `profiles.role = 'admin'`. Las service-role keys no
forman parte de ninguna aplicación; la certificación real puede usar una clave
de test exclusivamente para crear y limpiar fixtures aislados.

## Operaciones administrativas

Reports y Requests mantienen contratos de repositorio compartidos, con
implementaciones mock deterministas y Supabase seleccionadas centralmente. La
UI Admin nunca escribe tablas ni decide transiciones: invoca RPCs de intención
que vuelven a autorizar al actor, bloquean la fila y agregan auditoría.

Los reportes son un flujo cerrado `open/in_review/escalated` hacia `resolved` o
`dismissed`; no se borran ni se reabren. En solicitudes, Admin puede inspeccionar
detalle e historial, marcar revisión, documentar una intervención y cancelar
solo antes del cierre. No hay mutación arbitraria de estado, por lo que las
transiciones de customer/professional siguen siendo la fuente del workflow.
