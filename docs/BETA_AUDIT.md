# Auditoría de preparación para beta

> Documento histórico. Sus rutas, conteos y hallazgos reflejan la auditoría del
> momento en que fue escrita y no describen necesariamente el estado actual.
> Para reconstrucción y operación usa `ARCHITECTURE.md`, `DATABASE.md`,
> `BOOTSTRAP.md`, `QA.md` y `RECOVERY.md`.

Fecha: 3 de agosto de 2026  
Alcance: aplicación Flutter, repositorios mock/Supabase, navegación, migraciones y pruebas.  
Método: revisión estática del repositorio y ejecución de `./qa.sh`. No se modificó funcionalidad.

## Resumen ejecutivo

La aplicación conserva una base sólida para continuar: los estados de solicitud se mapean de forma centralizada, existe una `RequestStateMachine`, las seis tablas creadas por las migraciones tienen RLS, no se encontró una service-role key en el cliente y el chat libera sus canales al salir. Sin embargo, el build no está listo para una beta en modo Supabase. Hay identificadores incompatibles con columnas UUID, dependencias de tablas que no existen, rutas que dependen de `extra` o de datos mock no nulos, y controles de flujo que pueden evitarse llamando Supabase directamente.

Inventario original: **7 críticos, 12 altos, 12 medios y 8 bajos**.  
Estado actual: **0 críticos pendientes; 7 críticos resueltos**. Los hallazgos altos, medios y bajos permanecen fuera del alcance de este sprint.

## Crítico

### ✅ C-01 — La creación Supabase envía identificadores que no son UUID — Completado

Resolución: `lib/app/router.dart` genera UUID v4 en Supabase, toma el customer autenticado y resuelve el profesional contra el catálogo persistido. `lib/features/requests/data/service_request_supabase_mapper.dart` rechaza defensivamente cualquier ID no UUID. Mock conserva sus IDs locales.

- `lib/app/router.dart:778-788` construye IDs como `request-<timestamp>`, `customer-current`, `profile-<id>` y profesionales provenientes del catálogo placeholder.
- `lib/features/requests/presentation/providers/request_providers.dart:16-17` declara IDs mock literales.
- `supabase/migrations/202608030001_create_service_requests.sql:1-4` exige UUID y referencias a `profiles(id)`.

Impacto: una solicitud creada desde la UI falla en PostgreSQL o referencia perfiles inexistentes. Bloquea el flujo principal de la beta Supabase.

Recomendación: obtener customer/professional IDs autenticados y persistidos; dejar que PostgreSQL genere el ID de solicitud o generar un UUID real.

### ✅ C-02 — El catálogo profesional consulta una tabla no migrada — Completado

Resolución: `supabase/migrations/202608030004_resolve_beta_critical.sql` crea `professional_profiles`, índices contractuales vía PK, RLS de lectura autenticada y gestión por el propietario; el repositorio usa el mismo UUID de `profiles` como identidad profesional.

- `lib/core/backend/data/supabase_backend_repositories.dart:177-203` consulta `professional_profiles`.
- `supabase/migrations/` solo crea `profiles`, `service_requests`, `conversations`, `messages`, `quotations` y `request_events`.

Impacto: búsqueda/perfil/asignación profesional no puede funcionar en un despliegue construido únicamente con las migraciones versionadas.

Recomendación: crear y proteger el esquema profesional o adaptar el repositorio al esquema real, junto con una migración reproducible.

### ✅ C-03 — Ratings depende de objetos de base de datos inexistentes y la UI escribe al mock — Completado

Resolución: la migración `202608030004_resolve_beta_critical.sql` crea `ratings`, la vista segura de resumen y `submit_service_rating` con validación de customer/request/status. `lib/app/router.dart` usa ahora `ratingsRepositoryProvider`, que selecciona mock o Supabase según el runtime, y muestra error controlado si el envío falla.

- `lib/core/backend/data/supabase_backend_repositories.dart:733-781` usa `ratings`, `professional_rating_summaries` y `submit_service_rating`; no hay migración para ellos.
- `lib/app/router.dart:1002-1029` envía la valoración mediante `requestRepositoryProvider`, que es el puente mock también en Supabase.
- `lib/core/backend/backend_repository_factory.dart:49,82` crea y expone ese mock en ambos modos.

Impacto: la valoración parece completarse localmente pero no persiste ni sincroniza; el repositorio Supabase alternativo fallaría si se invocara.

Recomendación: antes de beta, migrar ratings de extremo a extremo o deshabilitar el flujo en Supabase con un estado controlado explícito.

### ✅ C-04 — La máquina de estados puede evitarse desde un cliente autenticado — Completado

Resolución: se elimina la política de update directo, se revocan al rol autenticado los RPC genéricos y se exponen RPC de intención. `transition_request_status` valida transición, actor y evento; horario y propuesta tienen RPC limitados. El repositorio Supabase dejó de actualizar filas directamente.

- `supabase/migrations/202608030003_create_realtime_request_workflow.sql:64-100` define `apply_request_transition` como `security definer` y acepta estado esperado, estado nuevo y tipo de evento proporcionados por el cliente.
- `supabase/migrations/202608030003_create_realtime_request_workflow.sql:216-234` concede esa función y `append_request_event` a cualquier usuario autenticado.
- `supabase/migrations/202608030001_create_service_requests.sql:41-44` permite a ambos participantes actualizar la fila; el trigger de líneas 46-64 protege campos inmutables, pero no valida transiciones ni roles.

Impacto: un cliente modificado puede saltar estados, asignar un estado válido arbitrario o fabricar eventos, aunque la UI use `RequestStateMachine`.

Recomendación: validar en SQL la transición permitida y el actor requerido; revocar actualizaciones directas de estado/programación y exponer RPCs de intención con permisos específicos.

### ✅ C-05 — Rutas de detalle pueden lanzar excepción al abrirse por URL o recarga — Completado

Resolución: `lib/app/router.dart` resuelve detalles por `requestId` mediante providers mock o persistidos y representa carga, error y ausencia en español. Se retiraron los force unwrap de las rutas de detalle, conversación y cotización profesional.

- `lib/app/router.dart:98-112` y `lib/app/router.dart:141-154` fuerzan `!` sobre el detalle síncrono del repositorio de compatibilidad.
- En modo Supabase el dato real es asíncrono, mientras `lib/core/backend/backend_repository_factory.dart:82` sigue entregando un mock distinto para compatibilidad.

Impacto: conversaciones y detalles abiertos mediante deep link, restauración o recarga pueden caer antes de mostrar loading/missing/error.

Recomendación: resolver siempre por `requestId` con el proveedor persistido y representar `loading`, `error` y `not found` sin force unwrap.

### ✅ C-06 — Rutas de confirmación y éxito dependen obligatoriamente de `GoRouterState.extra` — Completado

Resolución: ambas rutas validan `extra` y muestran un estado recuperable cuando falta; ya no realizan casts forzados ni lanzan al recargar/navegar directamente.

- `lib/app/router.dart:773-775` fuerza un `RequestDraft` en confirmación.
- `lib/app/router.dart:834` fuerza el nombre profesional en éxito.

Impacto: recarga web, restauración de estado o navegación directa produce una excepción en lugar de una pantalla recuperable.

Recomendación: usar parámetros serializables/estado persistido y redirigir de forma segura cuando falte el contexto transitorio.

### ✅ C-07 — Las políticas de perfiles impiden leer al otro participante — Completado

Resolución: la migración `202608030004_resolve_beta_critical.sql` añade lectura del perfil contraparte exclusivamente cuando existe una solicitud compartida. Los perfiles ajenos no relacionados siguen bloqueados.

- `supabase/migrations/202608010001_create_profiles.sql:14-17` permite seleccionar un perfil solo a su propietario.
- `lib/core/backend/data/supabase_backend_repositories.dart:218-233` intenta embeber perfiles de cliente y profesional en cada solicitud.

Impacto: la relación contraria puede llegar nula o provocar respuestas incompletas; nombres y detalle compartido no son fiables bajo RLS.

Recomendación: exponer exclusivamente campos públicos mínimos a participantes relacionados, mediante política segura o vista `security_invoker` probada.

## Alto

### A-01 — Estado dividido entre Supabase y el repositorio MVP mock

- `lib/core/backend/backend_repository_factory.dart:37-49,68-82` conserva `MockRequestRepository` en modo Supabase.
- `lib/features/requests/presentation/providers/request_providers.dart:19-21,98-105` expone listas/detalles síncronos de ese mock.
- `lib/app/router.dart:1203-1233` aún envía cambio de horario y reporte de problema al mock.

Esto crea dos verdades: una acción puede verse en una pantalla y faltar para la contraparte o tras reiniciar.

### A-02 — Errores y ausencia se muestran como carga infinita en cotización

- `lib/app/router.dart:1056-1070` usa `.value` y muestra `CircularProgressIndicator` tanto durante carga como ante error o registro inexistente.

Se requiere separar los tres estados y ofrecer reintento/mensaje español.

### A-03 — Detalle profesional oculta carga y error con datos potencialmente obsoletos

- `lib/features/home/presentation/professional_request_detail_screen.dart:87-102` lee `.value` y cae silenciosamente al objeto recibido por navegación.

Una falla backend parece éxito con información vieja; no existe estado de error ni reintento.

### A-04 — El detalle cliente silencia errores realtime

- `lib/app/router.dart:979-1000` consume status, cotización y timeline mediante `.value`, convirtiendo errores en status viejo, cotización ausente o timeline vacío.

Esto incumple el requisito de estados controlados y puede inducir decisiones sobre datos desactualizados.

### A-05 — Operaciones async disparadas sin manejo de excepción

- `lib/app/router.dart:1191-1201,1213-1223` usa `.then(...)` sin `catchError` para horario y rating.
- `lib/app/router.dart:1102-1113` rechaza cotización sin `try/catch`.
- `lib/features/auth/presentation/auth_controller.dart:75-86` actualiza perfil sin convertir errores de repositorio a estado controlado.

Impacto: futuros no manejados, feedback ausente y estado de UI incoherente.

### A-06 — Suscripción realtime por cada fila y familias no auto-dispose

- `lib/features/requests/presentation/providers/request_providers.dart:42-59,67-89` declara familias realtime/future sin `autoDispose`.
- `lib/app/router.dart:900-906` y `lib/features/home/presentation/professional_requests_screen.dart` observan un canal de status por solicitud.

Listas grandes pueden mantener cachés/canales y causar reconstrucciones N por evento. Preferir una consulta/stream de colección o invalidación agregada y ciclo de vida auto-dispose.

### A-07 — Realtime reporta desconexión pero no recrea explícitamente el canal

- `lib/core/backend/data/supabase_backend_repositories.dart:514-540` marca `disconnected`; no se observa backoff/recreación propia tras `timedOut`, `closed` o `channelError`.

Aunque el SDK pueda recuperar ciertos cortes, el contrato de reconexión de la aplicación no queda garantizado ni probado frente a cierres terminales.

### A-08 — Timeline puede presentar fechas ficticias en producción

- `lib/features/home/presentation/widgets/request_timeline.dart:17-42,54-59` completa eventos faltantes con textos y fechas fijas de julio.

En una falla o historia parcial, el usuario ve hechos no persistidos. Los pasos pendientes deben distinguirse de eventos reales.

### A-09 — Fecha relativa calculada contra un día fijo

- `lib/features/requests/presentation/adapters/request_view_adapters.dart:54-59` usa `DateTime(2026, 7, 27)`.

Desde esa fecha el texto queda progresivamente incorrecto y puede producir diferencias negativas ocultas como “recientemente”.

### A-10 — El modelo persistido pierde campos que la UI presenta como reales

- `lib/core/backend/mappers/service_request_supabase_mapper.dart` reconstruye campos de vista no presentes en `service_requests` con valores por defecto.
- `supabase/migrations/202608030001_create_service_requests.sql:1-22` no contiene ubicación, disponibilidad, adjuntos ni metadatos de membresía.

El detalle Supabase no conserva toda la información capturada en creación. Se debe definir qué es dato contractual y persistirlo o retirarlo de la presentación.

### A-11 — Cualquier participante puede falsificar mensajes de sistema

- `supabase/migrations/202608030002_create_realtime_chat.sql:65-77` permite insertar `sender_id is null` y `type = 'system'` a cliente o profesional.

Los mensajes del sistema deben originarse en una función confiable que valide el evento, no directamente desde el cliente.

### A-12 — Identidad no autenticada cae silenciosamente a IDs mock en Supabase

- `lib/features/requests/presentation/providers/request_providers.dart:61-64` retorna el ID mock cuando no hay usuario autenticado, incluso en modo Supabase.

Esto genera filtros UUID inválidos y oculta una sesión ausente. En Supabase debe emitirse un estado de autenticación requerido.

## Medio

### M-01 — Modelos de solicitud duplicados

- Dominio: `lib/features/requests/domain/models/service_request.dart`.
- Presentación: `lib/features/home/presentation/models/customer_service_request.dart` y `lib/features/home/presentation/models/incoming_service_request.dart`.
- Puente: `lib/features/requests/presentation/adapters/request_view_adapters.dart`.

Los modelos de vista son razonables si son proyecciones declaradas, pero actualmente duplican estado y favorecen datos por defecto/obsoletos. Documentar límites o converger en view models derivados inmutables.

### M-02 — Modelos profesionales duplicados

- `lib/features/requests/domain/models/professional_profile.dart`.
- `lib/features/home/presentation/models/professional_profile_data.dart`.
- `lib/features/home/presentation/data/placeholder_professionals.dart`.

La coexistencia contribuye a la confusión entre `profile.id`, `user.id` y IDs placeholder observada en C-01/C-02.

### M-03 — Timeline y timing duplican conceptos de dominio

- `lib/features/requests/domain/models/request_state.dart` define `TimelineStage`.
- `lib/features/home/presentation/models/request_progress_stage.dart` define otra progresión.
- `lib/features/home/presentation/models/request_draft.dart` define `RequestTiming` y `lib/features/requests/presentation/adapters/request_view_adapters.dart:36-44` lo infiere analizando texto.

El parsing textual debe sustituirse por mapeo explícito y exhaustivo.

### M-04 — Componentes visuales duplicados

- `lib/features/home/presentation/widgets/bottom_navigation_widget.dart` y `professional_bottom_navigation_widget.dart`.
- `lib/features/home/presentation/widgets/professional_card.dart` y `professional_card_compact.dart`.
- `lib/features/home/presentation/widgets/request_section_title.dart`, `guest_home_screen.dart:161`, `search_screen.dart:178` y `professional_profile_screen.dart:238`.

Extraer bases parametrizables reduciría divergencia de accesibilidad, estilos y navegación.

### M-05 — Formateo de fecha duplicado

- `lib/features/home/presentation/models/request_draft.dart:15-25`.
- `lib/features/home/presentation/quotation_review_screen.dart:122`.
- `lib/features/home/presentation/quotation_form_screen.dart:300`.

Centralizar en un formateador localizado y probado.

### M-06 — Archivos excesivamente grandes y con responsabilidades mezcladas

- `lib/app/router.dart` (~1240 líneas) construye rutas, adapta modelos y ejecuta casos de uso.
- `lib/core/backend/data/supabase_backend_repositories.dart` (~800 líneas) agrupa todos los repositorios.
- `lib/features/requests/data/mock_request_repository.dart` (~700 líneas) concentra múltiples agregados.

Esto amplía rebuilds, dificulta pruebas aisladas y hace probable que UI invoque el repositorio equivocado.

### M-07 — Pantalla de crear solicitud es código temporal de producción

- `lib/features/home/presentation/create_request_screen.dart` es una pantalla mínima.
- `lib/app/router.dart:344,421` la mantiene alcanzable desde la navegación.

No es ruta muerta, pero sí un callejón funcional: no crea una solicitud ni conduce al flujo por profesional.

### ✅ M-08 — Catálogo placeholder sigue siendo fuente de navegación — Completado

Resolución: discovery Supabase y rutas directas resuelven el profesional por ID
mediante `ProfessionalsRepository`; un ID ausente muestra un estado controlado.
El catálogo placeholder quedó restringido al modo mock.

- `lib/features/home/presentation/data/placeholder_professionals.dart` alimenta
  únicamente discovery mock.
- `lib/features/home/presentation/professional_profile_route.dart` resuelve
  rutas Supabase por ID y diferencia ausencia de error.

### M-09 — Texto de rechazo contradice el modo Supabase

- `lib/features/home/presentation/professional_request_detail_screen.dart:41-45` afirma que la acción “solo actualizará el estado local”, aunque llama al workflow activo.

Terminología UI está mayoritariamente en español, pero este texto es engañoso y debe depender del comportamiento real, no del backend.

### M-10 — Historial de chat presenta timestamps degradados

- `lib/core/backend/mappers/conversation_supabase_mapper.dart` convierte el timestamp persistido a una etiqueta de presentación genérica para mensajes históricos.

Revisar el mapper para que la hora visible derive de `created_at` con locale español, conservando orden cronológico y zona horaria.

### M-11 — Repositorios mock retienen controladores sin contrato de cierre

- `lib/core/backend/data/mock_backend_repositories.dart` mantiene mapas de `StreamController` para solicitudes y cotizaciones, sin `dispose` en esos contratos.
- `lib/features/auth/data/mock_authentication_repository.dart` mantiene el stream de cambios durante toda la vida del repositorio.

En ejecución normal el scope raíz vive toda la app, pero tests repetidos/hot restart pueden acumular recursos. Añadir ciclo de vida explícito.

### M-12 — Documentación de backend no corresponde al esquema actual

- `README.md:42-49` enumera tablas/RPC antiguas (`conversation_messages`, `timeline_events`).
- `README.md:83-85` afirma que solicitudes/chat no persisten, contrario a las migraciones actuales.

Esto puede causar un despliegue incompleto o diagnósticos equivocados.

## Bajo

### ✅ S-01 — Documentos de verificación expuestos por RLS de discovery — Completado

`verification_documents` se añadió históricamente a `professional_profiles`
después de crear una política de lectura para cualquier autenticado. La
migración `202608090001` preserva esos datos en una tabla privada, elimina la
columna pública y restringe lectura a propietario/Admin y escritura al dueño.
Discovery conserva únicamente `verification_status`.

### ✅ S-02 — Reportes y solicitudes Admin sin cierre operativo — Completado

La migración `202608090002_admin_operations_closure.sql` añade transiciones de
reporte protegidas, auditoría inmutable para reportes y acciones acotadas sobre
solicitudes. Resolver, descartar y escalar exigen motivo; no hay borrado ni
reapertura. Las solicitudes solo admiten marca de revisión, nota y cancelación
antes del cierre. La función histórica de corrección arbitraria ya no puede ser
ejecutada por clientes autenticados. El E2E real confirma autorización negativa,
integridad del estado, sincronización y limpieza.

### B-01 — Marcador temporal explícito

- `lib/core/backend/backend_repository_factory.dart:37` contiene “Temporary synchronous bridge”.

No se encontraron literales `TODO`, `FIXME` ni `HACK`; este puente es la deuda temporal explícita principal.

### B-02 — Helper de invalidación aparentemente no usado

- `lib/features/requests/presentation/providers/request_providers.dart:91-96` define `invalidatePersistedRequests`, sin referencias fuera de su declaración.

Eliminarlo o usarlo para evitar bloques manuales divergentes.

### B-03 — Invalidaciones manuales repetidas

- `lib/app/router.dart:812-819,1090-1096` y otros callbacks repiten listas de providers.

Esto ya produjo coexistencia de providers mock/persistidos. Encapsular la invalidación por caso de uso.

### B-04 — Alias de repositorios conservan nomenclatura doble

- `lib/core/backend/data/supabase_backend_repositories.dart:731` y alias equivalentes para solicitudes/conversaciones mantienen dos nombres por implementación.

Confirmar si solo son compatibilidad de pruebas; retirar gradualmente para evitar “repositorios duplicados” nominales.

### ✅ B-05 — Estados de pantallas estáticas no aplican todavía, pero deben quedar contractuales — Completado para perfil profesional

Resolución del perfil profesional: la ruta ofrece loading, no encontrado y
error, y oculta detalles demostrativos cuando usa Supabase. Otras pantallas
históricas de este hallazgo se evalúan en sus hitos correspondientes.

- `guest_home_screen.dart`, `search_screen.dart` y
  `professionals_results_screen.dart` consumen el provider de discovery.
- `professional_profile_route.dart` concentra loading/error/not-found del
  perfil; `professional_profile_screen.dart` recibe solo datos resueltos.
- Los campos de producción ausentes muestran estados vacíos explícitos y las
  reseñas/conteos proceden de datos transaccionales, sin contenido demo.

### B-06 — No hay guardas de ruta centralizadas

- `lib/app/router.dart:235` crea `GoRouter` sin una política global visible de redirección por autenticación/rol.

RLS limita datos, pero una guarda mejora UX y evita pantallas profesionales/cliente fuera de contexto.

### B-07 — La lista mock de cliente no reproduce aislamiento real

- `lib/features/requests/data/mock_request_repository.dart` devuelve la colección compartida desde `getCustomerRequests` sin un aislamiento equivalente a RLS.

Con un solo cliente de demo no se manifiesta, pero reduce el valor de las pruebas de paridad mock/Supabase.

### B-08 — Nombres técnicos ingleses permanecen, no texto UI

- Clases, enums y mensajes internos usan inglés por convención de código.
- La búsqueda de cadenas visibles no encontró copy UI inglesa significativa; las etiquetas y errores visibles revisados están en español.

Mantener una revisión de copy al añadir estados faltantes para conservar “solicitud”, “cotización”, “profesional” y los labels centralizados de `RequestStatus`.

## Auditoría transversal

### Loading, error y excepciones

Cobertura correcta observada en autenticación, listas principales, creación y chat (`lib/features/auth/presentation/welcome_screen.dart`, `lib/features/home/presentation/confirm_request_screen.dart`, `lib/features/requests/presentation/conversation_screen.dart`, `lib/features/home/presentation/professional_requests_screen.dart`). Los huecos de producción están detallados en A-02 a A-05. Las pantallas estáticas no realizan trabajo async hoy.

### Navegación

Las constantes principales tienen rutas registradas y las pantallas de éxito ofrecen salida explícita. No se encontró una ruta declarada completamente huérfana; `createRequest` sí es alcanzable, pero funcionalmente incompleta (M-07). Los riesgos graves son restauración/deep links basados en `extra` y force unwrap (C-05/C-06), fallback incorrecto de profesional (M-08) y ausencia de guardas (B-06). Los detalles usan `_popOrGo`, lo cual ofrece fallback cuando no existe historial.

### Localización y estados

El copy visible revisado está en español. `RequestStatus` y sus transiciones se centralizan en `lib/features/requests/domain/models/request_state.dart` y `lib/features/requests/domain/services/request_state_machine.dart`, un punto positivo. Persisten inconsistencias de datos/terminología en A-08/A-09 y M-09/M-10; no se observó parsing de status disperso en widgets.

### Rendimiento y ciclo de vida

El mayor riesgo es N canales/proveedores por lista y familias sin auto-dispose (A-06), seguido de widgets/archivos monolíticos (M-06). El chat sí realiza limpieza explícita en `lib/features/requests/presentation/conversation_screen.dart` y `lib/core/backend/data/supabase_backend_repositories.dart:552-565`; debe conservarse y extenderse a repositorios mock/workflow.

### Seguridad

Tablas con RLS verificado: `profiles`, `service_requests`, `conversations`, `messages`, `quotations`, `request_events`. No se encontró una Supabase service-role key en `lib/`, archivos versionados o configuración; `lib/core/backend/backend_config.dart` recibe URL/clave pública mediante `String.fromEnvironment`, `.env.example` solo contiene placeholders y `.gitignore:35-37` excluye `.env*` salvo el ejemplo. Los bloqueadores no son ausencia de RLS, sino permisos demasiado amplios y validación insuficiente (C-04, A-11), además de la política de perfiles incompatible con los joins (C-07).

## Orden recomendado antes de beta

1. Corregir identidad/esquema reproducible: C-01, C-02, C-03 y C-07.
2. Hacer cumplir el workflow y autoría en PostgreSQL: C-04 y A-11.
3. Eliminar el estado dividido mock/Supabase: A-01 y A-12.
4. Hacer todas las rutas restaurables y todos los async states explícitos: C-05, C-06, A-02 a A-05.
5. Validar reconexión/canales y retirar datos ficticios: A-06 a A-10.
6. Abordar duplicación y archivos grandes después de estabilizar contratos, sin rediseñar UI.

## Validación

Comando requerido: `./qa.sh`

Resultado: **aprobado**.

- `flutter analyze`: sin problemas.
- Tests unitarios/widget: 95 aprobados, incluidas las regresiones de los siete críticos.
- `integration_test/full_mvp_flow_test.dart`: 1 aprobado.
- Resultado final del script: `All QA checks passed!`.

Nota de entorno: durante el arranque macOS apareció `Failed to foreground app; open returned 1`; el runner continuó, ejecutó el flujo completo y terminó con código 0.
