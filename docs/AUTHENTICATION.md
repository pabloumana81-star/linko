# Autenticación

## Arquitectura

Supabase Auth es la fuente de identidad y sesión. `AuthController` observa
`onAuthStateChange`, recupera o renueva la sesión persistida y entrega la
identidad a `ProfileRepository`. La tabla `profiles` es la única fuente para el
nombre persistido, modo customer/professional, rol, suspensión y estado de
onboarding. Los metadatos OAuth solo sirven para inicializar un perfil que aún
no existe.

El flujo es:

```text
Supabase Auth -> AuthenticationRepository -> AuthController
              -> ProfileRepository -> profiles + Realtime
              -> guard de GoRouter -> onboarding o experiencia activa
```

El modo guest no crea una sesión ni un perfil. Un evento nulo de Auth no lo
convierte accidentalmente en usuario anónimo. Al autenticarse después, la
identidad Supabase reemplaza explícitamente al invitado.

## Flujos passwordless

- Google y Apple usan `signInWithOAuth`. Lanzar el navegador no se interpreta
  como autenticación terminada: LinkO espera el callback y el evento de sesión.
- El correo usa `signInWithOtp` para enviar un magic link. No se almacena ni se
  solicita contraseña.
- En web, el retorno usa el origen actual. En Android, iOS y macOS usa
  `AUTH_REDIRECT_URL`, actualmente `io.supabase.linko://login-callback/`.
- Si el usuario cierra o cancela el proveedor, la pantalla de acceso queda
  operativa. Errores del proveedor se muestran en español y se reportan sin
  tokens ni credenciales.

Apple puede omitir nombre y correo en accesos posteriores. LinkO nunca
sobrescribe un perfil existente con metadata faltante: vuelve a cargar
`profiles`. Si Apple no entrega nombre en el primer OAuth web, el usuario puede
completarlo mediante el perfil/onboarding.

## Sesión y rutas

`supabase_flutter` persiste la sesión por plataforma. Al arrancar, LinkO lee
`currentSession`; si está expirada, exige un refresh válido antes de cargar el
perfil. `signedOut`, refresh inválido, logout y cambio de cuenta limpian o
reemplazan el perfil observado. Una ruta funcional nunca conserva UI
autenticada después de perder la sesión.

Perfiles nuevos reciben `onboarding_completed = false`; perfiles existentes no
se modifican. Elegir customer o professional persiste el modo y completa el
onboarding. La clave primaria `profiles.id = auth.users.id`, el trigger de Auth
y el `upsert` por `id` impiden perfiles duplicados respetando RLS.

## Configuración externa

En Supabase Dashboard:

1. En Authentication > URL Configuration añade la URL web desplegada y
   `io.supabase.linko://login-callback/**` a Redirect URLs.
2. Habilita Email y configura la plantilla Magic Link para usar la URL de
   redirección solicitada.
3. Habilita Google con el Client ID y Client Secret creados en Google Cloud.
   Autoriza `https://<project-ref>.supabase.co/auth/v1/callback` en Google y los
   orígenes web reales.
4. Habilita Apple con Team ID, Services ID, Key ID y secreto generado desde la
   clave `.p8`. El Services ID web debe ser el primer Client ID y su Return URL
   es `https://<project-ref>.supabase.co/auth/v1/callback`.
5. En Apple Developer habilita Sign in with Apple para los App IDs de iOS y
   macOS. El OAuth web de Apple requiere rotar el client secret antes de su
   vencimiento (normalmente cada seis meses).

Los Client Secrets y archivos `.p8` pertenecen a los dashboards/gestores de
secretos, nunca a `.env` ni al cliente Flutter.

## Estado de certificación

La arquitectura, recuperación, rutas, deep links y pruebas deterministas están
**CODE COMPLETE**. Google, Apple y la entrega real de Magic Link permanecen
**PROVIDER CERTIFIED pendiente** hasta validar consent/cancel/error y callback
en cada dominio, dispositivo y cuenta de producción configurados externamente.
