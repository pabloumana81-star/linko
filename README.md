# LinkO

LinkO es un marketplace con dos aplicaciones Flutter independientes que
comparten un único backend Supabase:

- La raíz contiene la aplicación de clientes y profesionales.
- [`admin/`](admin/) contiene el backoffice Flutter Web.

## Inicio rápido

```sh
cp .env.example .env
scripts/bootstrap.sh
```

`BACKEND_MODE` es obligatorio y solo acepta `mock` o `supabase`; no existe un
fallback silencioso. Para Supabase, ambas aplicaciones deben usar el mismo
`.env` con `BACKEND_MODE=supabase`, `SUPABASE_URL`, la clave pública
`SUPABASE_ANON_KEY` y `AUTH_REDIRECT_URL`.

```sh
# Aplicación principal
flutter run -d macos --dart-define-from-file=.env

# Backoffice
cd admin
flutter run -d chrome --dart-define-from-file=../.env
```

Nunca uses una service-role key en una aplicación cliente.

Los documentos de verificación profesional no forman parte del perfil público:
RLS limita su lectura al propietario y al Backoffice Admin autorizado.

En Supabase, discovery y rutas directas de perfiles profesionales cargan datos
persistidos por ID. El catálogo demostrativo se conserva únicamente con
`BACKEND_MODE=mock`.

El perfil muestra biografía, servicios, experiencia, cobertura y portfolio
persistidos. Promedio, reseñas y trabajos completados se derivan de operaciones
reales. Los profesionales mantienen sus datos desde su pantalla de Perfil; la
carga de fotos permanece deshabilitada hasta configurar Supabase Storage.

## Validación

```sh
./qa.sh
cd admin && ./qa.sh
cd ..
./scripts/qa_supabase.sh # opt-in; requiere proyecto Supabase enlazado
```

## Documentación

- [Arquitectura](docs/ARCHITECTURE.md)
- [Base de datos](docs/DATABASE.md)
- [QA y certificación](docs/QA.md)
- [Autenticación passwordless](docs/AUTHENTICATION.md)
- [Bootstrap](docs/BOOTSTRAP.md)
- [Recuperación](docs/RECOVERY.md)
- [Backoffice](admin/README.md)
