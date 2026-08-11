# Criterios GO/NO-GO para beta externa

La decisión se toma por plataforma objetivo y requiere evidencia fechada. Un
PASS automatizado no completa una verificación externa o manual.

## GO

GO requiere simultáneamente:

- QA automatizada completa verde y auditoría de secretos/artefactos aprobada.
- E2E real contra el Supabase objetivo verde, incluyendo RLS, Realtime, Storage
  y cleanup aislado.
- Build distribuible firmado para la plataforma objetivo, con versión/build
  único y verificación de firma.
- Canal interno/cerrado de Google Play o TestFlight configurado y probado.
- Cada proveedor Auth habilitado certificado con cuenta nueva/existente,
  cancelación/error, entrega cuando aplique y callback real.
- Ruta crítica customer y professional PASS en al menos un dispositivo físico
  representativo de la plataforma, incluyendo cold start, background/resume,
  red interrumpida, picker, teclado y safe areas.
- Cero defectos S0/S1 abiertos; cualquier S2 aceptado tiene workaround y dueño.
- Privacy policy, terms, account/data deletion, soporte y declaraciones de
  tienda disponibles y aprobados por responsables autorizados.
- Responsable de incidentes, canal de soporte, retiro de testers, estrategia de
  datos y rollback disponibles.

## NO-GO

Es NO-GO si ocurre cualquiera de estas condiciones:

- Falla QA, E2E real, RLS/aislamiento, Realtime crítico, Storage privado,
  cleanup o auditoría de secretos.
- El artefacto no está firmado, usa identidad/versión incorrecta, repite un
  build rechazado o no puede instalarse por el canal objetivo.
- Un proveedor Auth habilitado no completa login/callback/logout/restauración
  real, o Magic Link no se entrega de forma confiable.
- La ruta crítica falla en dispositivo físico, pierde datos, duplica acciones o
  expone errores sin control.
- Existe un S0/S1 abierto o una sospecha de exposición cross-user, documento
  privado, token, credencial o URL firmada.
- Faltan requisitos legales/privacidad/soporte obligatorios para la tienda o
  jurisdicción aplicable.
- No existe rollback operativo o no puede identificarse/retirarse el grupo de
  testers sin afectar usuarios ajenos.

## Estado actual — 11 de agosto de 2026

**NO-GO para beta externa hoy.** La parte técnica automatizada y el E2E real
Supabase están verdes; Android tiene AAB firmado. Siguen sin evidencia: canal de
distribución Play/TestFlight, iOS firmado, certificación real de proveedores
Auth, matriz física, canal/responsables de soporte e incidentes, y decisiones/
materiales legales y de tienda.

La decisión puede pasar a GO por plataforma solo cuando cada punto requerido de
`BETA_LAUNCH_CHECKLIST.md` tenga evidencia READY o PASS correspondiente.

