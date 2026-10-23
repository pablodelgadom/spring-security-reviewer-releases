# Spring Security Reviewer Desktop — Release Notes (`v2.0.0-rc.1` Pre-Release Beta)

**Fecha / Date:** 2026-10-21  
**Versión / Tag:** `v2.0.0-rc.1` (Public Pre-Release / Beta)  
**Plataforma / Platform:** Windows 10 / 11 (x64) Portable  
**Licencia / License:** Proprietary Freeware (0 € / $0) — Ver `LICENSE` y `THIRD_PARTY_NOTICES.txt`

---

## 🇪🇸 Notas de la Versión (`v2.0.0-rc.1` Beta Pública)

### 1. Resumen de la Pre-Release
`v2.0.0-rc.1` es la primera versión candidata pública (**Pre-Release Beta**) de **Spring Security Reviewer Desktop 2.0**. Empaqueta el motor SAST especializado en Java y Spring Boot junto con el motor heurístico determinista offline en un ejecutable portable para Windows x64 que funciona sin necesidad de instalar Python ni conectarse a Internet.

### 2. Funcionalidades Completas y Verificadas en `v2.0.0-rc.1`
- **Ejecutable Portable Autónomo (`SpringSecurityReviewerDesktop.exe`):** Runtime embebido con ventana nativa **Microsoft Edge WebView2** y **modo de respaldo automático (Fallback)** al navegador predeterminado cuando WebView2 Runtime no está instalado en el sistema.
- **Motor SAST Especializado en Spring Boot 2.x/3.x y Spring Security 5.x/6.x:**
  - Evaluación 100% pasiva (solo lectura) de 14 reglas de seguridad sobre AST Java, archivos `application.properties`/`.yml`, dependencias Maven/Gradle y especificaciones OpenAPI.
- **Clasificación Rigurosa de Honestidad AppSec:**
  - Distinción explícita en la interfaz y en los informes entre **`✓ Evidencia Estática (STATIC_EVIDENCE)`** y **`⚡ Hipótesis Estática (HYPOTHESIS)`**.
  - Ningún hallazgo estático se presenta como vulnerabilidad confirmada dinámicamente.
- **Motor Heurístico Determinista Offline (Activo por Defecto):**
  - Explicaciones técnicas bilingües (ES/EN), parches de código Java y **plantillas estáticas de pruebas de regresión JUnit 5 + MockMvc** listas para copiar y ejecutar manualmente con `mvn test` o `gradle test`.
- **Historial Local, Comparativa de Auditorías y Exportación:**
  - Persistencia local en `%LOCALAPPDATA%\SpringSecurityReviewer`, comparador diferencial entre dos auditorías y exportación de informes en Markdown (`.md`) y JSON (`.json`).
- **Endurecimiento de Seguridad del Servidor Local (`S-01` a `S-05`):**
  - Autenticación obligatoria por sesión mediante token criptográfico efímero de 256 bits (`X-Operator-Token`) bootstrappeado por fragmento URL (`#ssr_token=`) y limpiado de `window.location.hash`.
  - Validación estricta de `Host`, `Origin` y `Referer` por puerto activo en todos los métodos HTTP contra DNS Rebinding y pestañas externas del navegador.
  - Protección de límites de directorio (`validate_project_boundary`), bloqueo de carpetas críticas del sistema y redacción automática de rutas/tokens en logs locales.

### 3. Alcance Actual, Limitaciones y Hoja de Ruta Post-Beta
- **IA Local con LLM (Estado: Conector Experimental Opcional):** El paquete portable incorpora SAST offline y utiliza por defecto el **Motor Heurístico Determinista Offline** (sin empaquetar modelos LLM pesados). Incluye un conector experimental opcional para usuarios que ya ejecuten **Ollama** localmente en `127.0.0.1:11434`. La integración avanzada de IA local sigue pendiente y será la **Prioridad #1** tras esta beta.
- **Pruebas Dinámicas / DAST (Estado: Solo Plantillas Estáticas JUnit 5):** Esta versión **no** ejecuta escaneos DAST activos ni tráfico de ataque contra aplicaciones en ejecución; genera exclusivamente plantillas de código JUnit 5 / MockMvc para validación manual del desarrollador. La integración de DAST real sigue pendiente y será la **Prioridad #2** tras la fase de IA local.
- **Entorno de Validación de esta Pre-Release:** Las pruebas de verificación del paquete portable (`Verify-CleanWindowsVM.ps1`: arranque sin Python en `PATH`, ventana nativa WebView2 y modo de respaldo, escaneo SAST, informes, historial, seguridad del servidor local y análisis con Microsoft Defender) se realizaron en un **entorno aislado dentro del equipo anfitrión**, no en una máquina virtual (VM) independiente. Los scripts reproducibles para validación en VM limpia se incluyen en la carpeta `verification/`.
- **Ejecutable sin Firma Digital Comercial:** El binario de esta pre-release no está firmado con un certificado comercial Authenticode OV/EV. **No recomendamos desactivar Windows Defender ni omitir SmartScreen sin verificar antes la integridad criptográfica del paquete** mediante `SHA256SUMS.txt`.

### 4. Sumas de Verificación Criptográfica (`SHA-256`)
```text
98d0e9c35e65dfecaeee16c66fffdace4a7bc0465f10989c16e48cec2af370d7  SpringSecurityReviewer-v2.0.0-rc.1-Windows-x64.zip
37c38d595114daf301828fc0a1db97c02751210b13ba144a5389009cdaf8de1c  SpringSecurityReviewerDesktop/SpringSecurityReviewerDesktop.exe
```

---

## 🇬🇧 Release Notes (`v2.0.0-rc.1` Public Pre-Release Beta)

### 1. Pre-Release Summary
`v2.0.0-rc.1` is the first public pre-release beta of **Spring Security Reviewer Desktop 2.0**, delivering a standalone Windows x64 portable SAST analyzer and deterministic offline remediation engine for Java and Spring Boot applications at $0 operational cost.

### 2. Production-Verified Capabilities in `v2.0.0-rc.1`
- **Standalone Windows x64 Portable Package:** Runs without a system Python installation; uses native **Microsoft Edge WebView2** and automatically falls back to the default system browser if WebView2 Runtime is missing.
- **Strict Static Evidence vs. Risk Hypothesis Classification:** Clearly separates AST-verified configuration facts (`STATIC_EVIDENCE`) from context-dependent security hypotheses (`HYPOTHESIS`).
- **Deterministic Offline Heuristic Engine & JUnit 5 Templates:** Built-in bilingual (ES/EN) root-cause analysis, Spring Security code patches, and static JUnit 5 + MockMvc regression test templates for manual developer execution.
- **Hardened Local Loopback Security (`S-01` through `S-05`):** 256-bit ephemeral `X-Operator-Token` authentication on all API endpoints, strict `Host`/`Origin`/`Referer` enforcement, system directory boundary checks, and sanitized rotating logs.

### 3. Known Limitations, Test Environment & Post-Beta Priorities
- **Local LLM AI (Pending Advanced Integration):** Includes offline SAST and the built-in heuristic engine by default, plus an experimental optional connector for local Ollama (`127.0.0.1:11434`). Advanced self-contained local AI integration remains pending and is **Priority #1** post-beta.
- **DAST (Pending Real Dynamic Engine):** Restricted to static JUnit 5 / MockMvc test template generation for manual execution (`mvn test` / `gradle test`). Real dynamic DAST verification remains pending and is **Priority #2** post-beta.
- **Pre-Release Verification Environment:** Pre-release verification tests (`Verify-CleanWindowsVM.ps1`: startup without Python on `PATH`, real WebView2 & fallback, SAST scan, reports, history, local server security, and Microsoft Defender scan) were executed in an **isolated environment on the host machine**, not inside an independent hypervisor VM. Reproducible scripts for clean VM testing are provided under `verification/`.
- **Unsigned Binary:** `v2.0.0-rc.1` is not signed with a commercial Authenticode certificate. Always verify the `SHA-256` checksum against `SHA256SUMS.txt` and scan with Microsoft Defender rather than disabling endpoint protection or blindly bypassing SmartScreen.
