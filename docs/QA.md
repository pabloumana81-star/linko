# QA

Pruebas sin secretos:

```sh
./qa.sh
cd admin && ./qa.sh
```

La raíz ejecuta análisis, unit/widget tests y el flujo MVP en macOS. Admin
ejecuta análisis y tests del backoffice. La certificación determinista
cross-app vive en `admin/test/shared_supabase_synchronization_test.dart`.

Prueba de navegador admin:

```sh
cd admin
flutter test test/admin_browser_flow_test.dart --platform chrome
```

La suite Supabase real es opt-in:

```sh
cd admin
flutter test test/real_supabase_cross_app_test.dart \
  --dart-define=RUN_SUPABASE_TESTS=true \
  --dart-define-from-file=../.env.test
```

Usa un proyecto desechable. `.env.test` debe estar ignorado por Git. CI ejecuta
esta capa solo cuando existen todos los secretos requeridos.
