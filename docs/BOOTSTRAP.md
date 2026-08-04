# Bootstrap

Requisitos: macOS con Xcode/CocoaPods para la app nativa, Flutter compatible
con Dart 3.12, Chrome, Git y Supabase CLI.

```sh
git clone REPOSITORY_URL linko
cd linko
cp .env.example .env
# Edita .env localmente sin imprimirlo ni confirmarlo.
scripts/bootstrap.sh
```

El script verifica Flutter y Supabase CLI, valida `.env` y resuelve las
dependencias de ambos paquetes. No aplica cambios remotos por defecto.

Después de enlazar y revisar el proyecto correcto:

```sh
supabase link --project-ref PROJECT_REF
scripts/bootstrap.sh --migrate
```

Arranque compartido:

```sh
flutter run -d macos --dart-define-from-file=.env
cd admin
flutter run -d chrome --dart-define-from-file=../.env
```
