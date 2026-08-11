# Despliegue web controlado

LinkO tiene dos artefactos Flutter Web independientes: la aplicación principal
en la raíz y el Backoffice en `admin/`. No existe un proveedor ni dominio
seleccionado en el repositorio. Ambos consumen el mismo proyecto Supabase y el
hosting debe mantenerlos en orígenes explícitamente autorizados.

## Configuración de producción

La configuración se compila mediante `--dart-define-from-file`; no se carga un
archivo `.env` como asset ni se modifica en runtime.

| Variable | Requerida | Contrato |
|---|---:|---|
| `BACKEND_MODE` | Sí | Debe ser `supabase` para producción. `mock` solo sirve para desarrollo/QA explícito. |
| `SUPABASE_URL` | Sí | Origen HTTPS del proyecto Supabase compartido. |
| `SUPABASE_ANON_KEY` | Sí | Clave pública anon/publishable del cliente. Nunca una service-role key. |
| `AUTH_REDIRECT_URL` | Sí | Callback nativo exacto `io.supabase.linko://login-callback/`. En web, OAuth retorna al origen HTTPS actual validado por `AuthRedirectPolicy`. |

No hay otras variables de producción consumidas por el código. Google/Apple,
SMTP, service-role, signing y secretos OAuth se configuran fuera del cliente.
La falta o invalidez detiene el arranque con una pantalla española controlada;
no existe fallback silencioso a mock.

`.env` permanece ignorado. `.env.example` contiene placeholders y el default
local mock; no debe usarse directamente para publicar.

## Build reproducible

Desde la raíz:

```sh
./scripts/build_web_release.sh
```

Opcionalmente se puede pasar otra ruta segura:

```sh
./scripts/build_web_release.sh /ruta/segura/linko.production.env
```

El wrapper exige Supabase, URL HTTPS, clave pública no vacía y callback exacto;
después ejecuta analyze, toda la suite mock y el build web release. Solo informa
presencia/validez y nunca imprime valores. El resultado `build/web/` es un
artefacto efímero ignorado por Git.

Para Admin, después de validar el mismo archivo con el wrapper raíz:

```sh
cd admin
flutter build web --release --dart-define-from-file=../.env
```

## Hosting y rutas SPA

El proveedor debe:

1. Servir únicamente por HTTPS y redirigir HTTP a HTTPS.
2. Servir archivos existentes normalmente.
3. Responder con `/index.html` y HTTP 200 para cualquier ruta de aplicación no
   correspondiente a un archivo.
4. No cachear `index.html` indefinidamente; los assets con hash sí pueden tener
   cache inmutable.

La regla conceptual está en `deployment/spa_fallback.example`. Es necesaria
para `/`, `/welcome`, `/professional/:id`, detalles de solicitudes,
conversaciones y el resto de rutas GoRouter al refrescar o abrir un deep link.

Main y Admin deben tener fallback hacia su propio `index.html`; nunca deben
servirse mutuamente como fallback.

## Headers de seguridad

`deployment/security_headers.example` define el baseline agnóstico:

- HSTS después de confirmar HTTPS estable en el dominio elegido.
- `X-Content-Type-Options: nosniff`.
- `Referrer-Policy: strict-origin-when-cross-origin`.
- `Permissions-Policy` mínima.
- CSP con `frame-ancestors 'none'`, `object-src 'none'`, workers blob de Flutter
  y CanvasKit de `www.gstatic.com`.

Antes de publicar sustituye `<SUPABASE_ORIGIN>` y
`<SUPABASE_REALTIME_ORIGIN>` por los orígenes exactos HTTPS/WSS. Si se
self-hostea CanvasKit, elimina `www.gstatic.com` después de verificar el build.
No uses `*`, no añadas `unsafe-eval` por comodidad y prueba la CSP en report-only
antes de hacerla bloqueante. El hosting es responsable de aplicar los headers a
`index.html` y rutas SPA, no solo a assets.

## Certificación posterior al despliegue

Automatizable sin autenticación:

```sh
./scripts/post_deploy_check.sh https://origen-real-de-beta
```

Comprueba HTTPS, carga de LinkO, fallback de `/welcome` y
`/professional/health-check`, headers obligatorios, `frame-ancestors` y ausencia
de un indicador mock en HTML.

Checklist manual/autenticado obligatorio:

1. Abrir diagnósticos debug/staging y confirmar Supabase, repositorios Supabase,
   usuario/rol correctos, Realtime conectado y base alcanzable.
2. Verificar discovery y perfil profesional directo por ID.
3. Ejecutar smoke customer y professional, incluidos refresh/deep links.
4. Si Admin se despliega, confirmar Admin autorizado y bloqueo no-Admin.
5. Confirmar portafolio público, documento privado y URL firmada temporal Admin.
6. Inspeccionar consola/network: sin tokens, Magic Links, URLs firmadas ni
   credenciales privadas. La anon/publishable key es pública y esperada.
7. Certificar Google, Apple y Magic Link solo después de registrar los orígenes
   reales en Supabase/proveedores.

`./scripts/qa_supabase.sh` sigue siendo la certificación automatizada previa al
deployment para Main/Admin, RLS, Realtime, Storage y cleanup aislado; no es un
test browser contra el URL publicado.

## Rollback

1. Identifica el último commit de aplicación conocido como bueno y conserva el
   commit fallido para diagnóstico.
2. Crea un checkout/worktree limpio de ese commit.
3. Recupera la misma configuración pública desde el gestor seguro, nunca desde
   Git ni logs.
4. Ejecuta `scripts/build_web_release.sh` y redepliega el artefacto resultante.
5. Ejecuta el health check y el checklist autenticado.

El rollback de aplicación no revierte Supabase. Las migraciones son forward-safe
y no deben deshacerse automáticamente. Una corrección de esquema requiere una
nueva migración revisada y un plan específico de preservación/backup; nunca un
script destructivo genérico.

## CI

Cada push/PR ejecuta analyze, tests, auditoría de secretos/artefactos y builds
web en modo mock explícito para validar compilación sin credenciales. Los smoke
Chrome Main/Admin también son secret-free. Esto no certifica configuración de
producción ni conectividad real.

La certificación Supabase remota continúa manual/protegida y solo corre cuando
los secrets del repositorio están presentes. Ninguna service-role key llega al
bundle Flutter.
