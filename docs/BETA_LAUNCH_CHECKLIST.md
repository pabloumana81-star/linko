# Checklist de lanzamiento de beta externa

Estados permitidos: **READY**, **EXTERNAL BLOCKER**, **MANUAL TEST REQUIRED** y
**OPTIONAL**. Un elemento automatizado READY no sustituye evidencia manual o
externa exigida por otro elemento.

## Distribución

- **EXTERNAL BLOCKER** — Configurar Google Play Internal/Closed Testing y sus
  testers; registrar y validar la upload key.
- **EXTERNAL BLOCKER** — Completar Apple Developer/TestFlight, App ID,
  capacidades, certificados y provisioning profiles.
- **READY** — AAB Android firmado: 59.0 MB en
  `build/app/outputs/bundle/release/app-release.aab`; firma verificada y upload
  key fuera del repositorio.
- **EXTERNAL BLOCKER** — Generar y validar el artefacto iOS firmado. Solo existe
  evidencia de `Runner.app` release `--no-codesign` (25.2 MB).
- **MANUAL TEST REQUIRED** — Confirmar versión y build único antes de cada
  upload. Main está hoy en `1.0.0+1`; Android/iOS lo consumen correctamente.
- **EXTERNAL BLOCKER** — Aprobar release notes reales por plataforma. No usar
  contenido provisional como texto de tienda.

## Autenticación

- **EXTERNAL BLOCKER** — Configurar y certificar Google con cuenta nueva,
  existente, cancelación, error y callback permitido.
- **EXTERNAL BLOCKER** — Configurar y certificar Apple con cuenta nueva,
  existente, metadata limitada, cancelación y callback permitido.
- **EXTERNAL BLOCKER** — Certificar Magic Link, plantilla, entrega real de
  correo, enlace válido/expirado y callback permitido.
- **MANUAL TEST REQUIRED** — Cold-start callback en Android y iPhone con la app
  cerrada y abierta.
- **MANUAL TEST REQUIRED** — Logout/login, cambio de cuenta y restauración de
  sesión en builds instalados.
- **READY** — Recuperación, expiración, sesión inválida, guest, onboarding y
  rutas protegidas tienen cobertura automatizada.

## Ruta crítica customer

- **MANUAL TEST REQUIRED** — Onboarding y selección customer.
- **MANUAL TEST REQUIRED** — Home, categoría/discovery y perfil profesional.
- **MANUAL TEST REQUIRED** — Crear solicitud, elegir profesional y enviarla.
- **MANUAL TEST REQUIRED** — Seguir estado y abrir chat.
- **MANUAL TEST REQUIRED** — Completar servicio y enviar rating/review.
- **READY** — El ciclo equivalente pasó E2E contra Supabase con fixtures
  aislados; falta repetirlo como usuario en dispositivos reales.

## Ruta crítica professional

- **MANUAL TEST REQUIRED** — Onboarding y selección professional.
- **MANUAL TEST REQUIRED** — Crear/editar perfil, agregar/eliminar portafolio y
  enviar documento de verificación apropiado para beta.
- **MANUAL TEST REQUIRED** — Recibir solicitud y aceptar/rechazar cuando la UI
  lo permita.
- **MANUAL TEST REQUIRED** — Chat, cotización, programación y finalización.
- **READY** — Perfil, Storage, solicitud, Realtime y workflow equivalentes
  pasaron E2E contra Supabase.

## Seguridad y privacidad

- **READY** — RLS y aislamiento cross-user certificados con customer,
  professional no relacionado y Admin distintos.
- **READY** — Ownership de Storage, portafolio público controlado y documentos
  de verificación privados certificados.
- **READY** — URL firmada Admin temporal: no persiste ni se registra.
- **READY** — Logout, sesión expirada/inválida y redacción de secretos tienen
  regresiones automatizadas.
- **READY** — Auditoría de secretos/artefactos rastreados aprobada.
- **MANUAL TEST REQUIRED** — Confirmar en builds instalados que UI/logs no
  muestran tokens, credenciales, URLs firmadas, documentos ni stack traces.

## Dispositivos físicos

- **MANUAL TEST REQUIRED** — Android: instalación, cold start y ruta crítica.
- **MANUAL TEST REQUIRED** — iPhone: instalación, cold start y ruta crítica.
- **MANUAL TEST REQUIRED** — Teclado, safe areas y navegación sin overflow.
- **MANUAL TEST REQUIRED** — Picker nativo de imagen/PDF: selección,
  cancelación, permisos del sistema y error.
- **MANUAL TEST REQUIRED** — Background/resume, pérdida/recuperación de red y
  ausencia de listeners/mensajes duplicados.
- **MANUAL TEST REQUIRED** — Lector de pantalla, foco, contraste y texto grande.

## Operaciones

- **EXTERNAL BLOCKER** — Definir canal de soporte/contacto: `[POR DEFINIR]`.
- **READY** — Usar `BETA_BUG_REPORT_TEMPLATE.md` y la clasificación S0–S3.
- **EXTERNAL BLOCKER** — Asignar responsables y tiempos de respuesta para
  incidentes S0/S1: `[POR DEFINIR]`.
- **MANUAL TEST REQUIRED** — Probar alta y retiro de testers en Play/TestFlight
  sin borrar datos de otros usuarios.
- **READY** — QA automatizada identifica fixtures como `qa_<timestamp>` y
  elimina solo los actores, filas y objetos creados por esa ejecución.
- **MANUAL TEST REQUIRED** — Para datos de beta humana, mantener un registro de
  IDs de cuenta autorizados y alcance de limpieza; revisar cada objetivo antes
  de eliminarlo. Nunca usar prefijos, consultas amplias ni scripts automáticos
  para inferir y borrar datos de usuarios.
- **READY** — Rollback técnico documentado en `DEPLOYMENT.md`; el rollback de
  aplicación no revierte migraciones Supabase.
- **OPTIONAL** — Dashboard de monitoreo/alertas y resumen periódico de beta.

## Legal y tiendas

Estos puntos son checkpoints; no constituyen texto ni asesoría legal.

- **EXTERNAL BLOCKER** — Privacy policy aprobada y URL real: `[POR DEFINIR]`.
- **EXTERNAL BLOCKER** — Terms of service aprobados y URL real: `[POR DEFINIR]`.
- **EXTERNAL BLOCKER** — Proceso y texto de account/data deletion:
  `[POR DEFINIR]`.
- **EXTERNAL BLOCKER** — Contacto de soporte publicado: `[POR DEFINIR]`.
- **EXTERNAL BLOCKER** — Declaraciones de privacidad/datos de Google Play y
  Apple completadas con información real: `[POR DEFINIR]`.
- **EXTERNAL BLOCKER** — Decidir entidad legal y titular de cuentas developer:
  `[POR DEFINIR]`.
- **EXTERNAL BLOCKER** — Completar Google Play developer verification.
- **EXTERNAL BLOCKER** — Completar Apple Developer enrollment.

## Estrategia de datos beta

1. Los fixtures automatizados conservan `qa_<timestamp>` y cleanup exacto en la
   misma ejecución; una credencial privilegiada permanece solo en memoria.
2. Los testers humanos usan cuentas reales de beta registradas por ID en un
   inventario operativo externo al repositorio. No se etiquetan ni descubren
   por semejanza de correo/nombre.
3. Cada limpieza humana requiere alcance aprobado, vista previa de IDs/objetos,
   verificación de ownership y registro del resultado. Se preserva toda fila u
   objeto no enumerado expresamente.
4. Suspender o retirar acceso de un tester no implica borrar sus datos. La
   retención/eliminación depende de la política legal y del proceso de account/
   data deletion aún pendientes.

