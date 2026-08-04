# LinkO Admin

Backoffice web independiente para usuarios con rol `admin`.

## Ejecutar

Desde este directorio:

```sh
flutter pub get
flutter run -d chrome
```

El modo mock es el predeterminado. Para usar Supabase, emplea únicamente la URL
y la clave pública/anon del proyecto; nunca una clave `service_role`:

```sh
flutter run -d chrome \
  --dart-define=BACKEND_MODE=supabase \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=PUBLIC_ANON_KEY
```

Supabase RLS y las funciones administrativas del backend validan nuevamente el
rol del usuario. La aplicación también bloquea todas las rutas cuando la sesión
no está autenticada como administrador.

Para ejecutar este backoffice y la aplicación principal contra el mismo
proyecto, usa exactamente el mismo archivo `.env` de la raíz:

```sh
# Terminal 1, desde la raíz
flutter run -d macos --dart-define-from-file=.env

# Terminal 2, desde admin/
flutter run -d chrome --dart-define-from-file=../.env
```

El cliente utiliza únicamente `SUPABASE_ANON_KEY`. Las acciones administrativas
se ejecutan mediante RPCs protegidos por rol y RLS sobre las mismas tablas
`profiles`, `professional_profiles`, `service_requests` y `ratings` que consume
la aplicación principal.

El módulo Profesionales lee categorías, cobertura, experiencia, portafolio y
documentos desde `professional_profiles`. Aprobar, rechazar, solicitar más
información, suspender y reactivar se ejecuta mediante RPC; rechazo y solicitud
de información exigen motivo y todas las acciones generan auditoría global y
profesional.

## QA

```sh
./qa.sh
```
