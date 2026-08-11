# Preparación móvil para beta

## Identidad y retorno de autenticación

Android e iOS usan `com.linko.app`. El retorno nativo sigue siendo
`io.supabase.linko://login-callback/`: Android lo recibe en una actividad
`singleTop` y iOS registra el esquema en `CFBundleURLTypes`. El SDK de Supabase
procesa el retorno y emite el estado de sesión; LinkO no interpreta ni registra
tokens. Los retornos con otro esquema, host, query o fragmento son rechazados
por `AuthRedirectPolicy` antes de iniciar OAuth o Magic Link.

La mecánica de sesión, cierre de sesión, cambio de cuenta, sesión inválida y
restauración está cubierta automáticamente. Google, Apple y la entrega real de
Magic Link requieren todavía configuración externa y una prueba física; no se
consideran certificados solo por compilar.

## Android

- `applicationId`, namespace y paquete Kotlin: `com.linko.app`.
- SDK mínimo, compile y target se heredan del SDK Flutter bloqueado por el
  proyecto.
- Solo se solicita `android.permission.INTERNET`. Imágenes y PDF se eligen con
  el selector del sistema, sin permisos amplios de almacenamiento, fotos o
  cámara.
- El teclado usa `adjustResize` y el callback usa `singleTop`.
- Release nunca usa la clave debug. Sin `android/key.properties` se puede
  validar un artefacto release sin firma. Para distribución, copiar
  `android/key.properties.example` a `android/key.properties`, completar los
  cuatro valores en un entorno seguro y conservar el `.jks` fuera de Git.

## iOS

- Runner usa `com.linko.app`; RunnerTests usa `com.linko.app.RunnerTests`.
- No hay Team ID, certificado ni perfil de aprovisionamiento inventado.
- No se declaran permisos de cámara o fototeca porque el producto usa el
  selector documental del sistema y no captura medios directamente.
- La validación local más fuerte sin credenciales es un build iOS release sin
  codesign. La firma, capacidades del App ID y prueba física quedan externas.

## Archivos y Storage

El editor solicita JPG/JPEG, PNG o WebP para portafolio y también PDF para
verificación. Solicita bytes al selector, valida MIME y límites de 5 MB/10 MB
en el repositorio y muestra errores controlados. Cancelar es un no-op; un
selector no disponible o un resultado ilegible muestra un mensaje en español.
Supabase Storage conserva RLS y ownership definidos en las migraciones.

## Ciclo de vida y Realtime

Supabase conserva la sesión persistida. Al volver del background, el chat
cancela su canal anterior y crea una única suscripción nueva, evitando listeners
duplicados. Los fallos muestran estado de reconexión/reintento y no cambian a
polling ni a repositorios mock. Una carga interrumpida libera su estado ocupado
y conserva un error controlado; el backend decide si el objeto llegó a
persistirse.

## Matriz manual antes de beta externa

1. Android físico: instalación firmada, cold start, Google/Magic Link, cancelar
   OAuth, background/resume en chat, selector de imagen/PDF y red interrumpida.
2. iPhone físico: instalación firmada, Apple/Google/Magic Link, retorno con app
   cerrada y abierta, metadata limitada de Apple, selector y red interrumpida.
3. Ambos: logout/login con otra cuenta, expiración forzada, solicitudes y chat,
   teclado, safe areas, tamaños de texto del sistema y conectividad lenta.
4. Confirmar en release que no aparecen overlay debug, backend mock, tokens,
   URLs privadas, stack traces ni credenciales.

## Configuración externa pendiente

- Keystore/upload key y configuración Play Console.
- Apple Team, App ID/capability, certificados y provisioning profiles.
- Credenciales y redirect allow-list de Google, Apple y correo en Supabase.
- Dispositivos, cuentas reales y canales de distribución beta.

## Resultado automatizado del 11 de agosto de 2026

- `flutter analyze`: PASS.
- QA Main: PASS, 168 tests y flujo MVP macOS (compiló; el host tardó en
  foreground, pero el test terminó PASS).
- QA Admin: PASS, 67 tests y 1 test opt-in omitido.
- Supabase lint: PASS; E2E real Main/Admin/Realtime/Storage/cleanup: PASS.
- Android APK release: PASS, 60.7 MB, sin firma; AAB release: PASS, 59.0 MB,
  sin firma. Ninguno usa la clave debug.
- iOS release `--no-codesign`: BLOCKED por el host, que no tiene instalado el
  platform SDK iOS 26.5. El simulador está bloqueado por el mismo componente.
- `git diff --check` y auditoría de secretos/artefactos: PASS.

La advertencia KGP de `file_picker 10.3.10` permanece como deuda de tooling:
compila hoy, pero una versión futura de Flutter exigirá migrar el plugin a
Built-in Kotlin.
