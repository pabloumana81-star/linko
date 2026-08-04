# Recuperación

## Nuevo Mac y clon limpio

1. Instala Xcode y acepta su licencia; instala CocoaPods.
2. Instala Flutter, Chrome, Git y Supabase CLI.
3. Ejecuta `flutter doctor` y resuelve errores del target deseado.
4. Clona el repositorio y crea `.env` desde `.env.example`.
5. Ejecuta `scripts/bootstrap.sh`.
6. Ejecuta ambos comandos documentados en `docs/QA.md`.

## Proyecto Supabase vacío

1. Crea el proyecto y conserva URL y anon key fuera de Git.
2. Configura `.env` con `BACKEND_MODE=supabase`.
3. Enlaza con `supabase link --project-ref PROJECT_REF`.
4. Ejecuta `scripts/bootstrap.sh --migrate`; respeta el orden descrito en
   `docs/DATABASE.md`.
5. Habilita Email y los proveedores OAuth requeridos.
6. Registra `AUTH_REDIRECT_URL` en Authentication URL Configuration.
7. Crea el primer perfil admin mediante un proceso operativo seguro; no desde
   el cliente Flutter.
8. Confirma RLS, publicación realtime y ejecuta la certificación Supabase en un
   proyecto de pruebas antes de producción.

## Variables

`BACKEND_MODE`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `AUTH_REDIRECT_URL` son
las únicas variables runtime de los clientes. Credenciales de certificación y
service-role pertenecen solo al entorno de test/CI.

## Limitaciones conocidas

- La suite Supabase real necesita un proyecto aislado y secretos explícitos.
- OAuth exige configuración externa por proveedor y plataforma.
- El test macOS necesita un host con interfaz gráfica; CI Linux ejecuta las
  capas unitarias y de widget.
- Mock mode no sincroniza dos procesos; simula el contrato en un mismo test.
