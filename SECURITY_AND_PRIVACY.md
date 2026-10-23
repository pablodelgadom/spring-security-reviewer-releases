# Documentación de Seguridad, Privacidad y Limitaciones (`v2.0.0-rc.1`)
# Security, Privacy & Limitations Policy (`v2.0.0-rc.1`)

---

## 🇪🇸 Español

### 1. Privacidad y Garantía de Cero Telemetría
- **100% Ejecución Local:** Todo el procesamiento de archivos `.java`, `pom.xml`, `build.gradle`, `.properties` y `.yml` ocurre exclusivamente en la memoria y disco local del equipo del usuario (`127.0.0.1`).
- **Cero Telemetría y Cero Conexiones a la Nube:** La aplicación no incorpora SDKs de analítica, rastreadores ni realiza peticiones a servidores externos en Internet.
- **Almacenamiento Local Controlado:** El historial de auditorías (`scans/`), informes exportados (`reports/`) y registros de diagnóstico (`logs/ssr_desktop.log`) se guardan en `%LOCALAPPDATA%\SpringSecurityReviewer` bajo los permisos NTFS de la cuenta del usuario de Windows.
- **Redacción Automática en Logs:** El formateador `SanitizingFormatter` redacta automáticamente el token de sesión en memoria y reemplaza la ruta del perfil del usuario (`%USERPROFILE%`) antes de escribir en el archivo de log local.

### 2. Seguridad del Servidor Local (`127.0.0.1`)
Spring Security Reviewer Desktop **no** asume que escuchar en `127.0.0.1` sea suficiente para proteger la aplicación frente a otras pestañas del navegador o procesos locales:
1. **Autenticación Criptográfica por Sesión (`S-01`, `S-02`):**
   - En cada inicio se genera un token efímero de 256 bits (`secrets.token_urlsafe(32)`).
   - El token nunca se expone en `GET /api/v1/health` ni en cookies HTTP. Se inyecta únicamente en la ventana autorizada mediante el fragmento URL `#ssr_token=<token>`, que el cliente web guarda en `sessionStorage` y elimina inmediatamente de la barra de direcciones (`history.replaceState`).
   - Todos los endpoints de datos y acciones (`/api/v1/scans`, `/api/v1/browse-folder`, `/api/v1/demo-project`, `/api/v1/ai/*`, `/api/v1/dast/*`) exigen la cabecera `X-Operator-Token` validada en tiempo constante (`secrets.compare_digest`).
2. **Protección contra DNS Rebinding y CSRF Local (`S-03`):**
   - `LocalSecurityMiddleware` valida en **todos** los métodos HTTP (`GET`, `POST`, `DELETE`) que las cabeceras `Host`, `Origin` y `Referer` coincidan exactamente con el puerto local activo (`127.0.0.1:<puerto>` o `localhost:<puerto>`).
   - Cualquier petición originada desde una página web externa (`https://evil.com`) o desde otro servidor de desarrollo local (`http://localhost:3000`, `http://127.0.0.1:5173`) es rechazada con `HTTP 403 Forbidden`.
3. **Aislamiento de Rutas y Modo Solo Lectura (`S-04`):**
   - El motor SAST abre los archivos del proyecto auditado exclusivamente en modo lectura de texto/AST y **jamás ejecuta** `mvn`, `gradle`, `javac` ni código del proyecto analizado.
   - `validate_project_boundary()` bloquea el escaneo de directorios críticos del sistema operativo y de credenciales (`C:\Windows`, `C:\Program Files`, `System32`, `.ssh`, `.aws`, `.gnupg`, `AppData\Roaming`).

### 3. Limitaciones Conocidas de la Versión `v2.0.0-rc.1` (Pre-Release Beta)
1. **Alcance del Análisis Estático (SAST):**
   - El analizador evalúa código fuente Java y archivos de configuración de Spring Boot; no analiza archivos binarios compilados (`.jar` / `.war` / `.class`) ni código Kotlin/Scala en esta versión.
   - Los hallazgos marcados como **`⚡ Hipótesis Estática`** representan patrones potencialmente peligrosos en el código que requieren que el desarrollador verifique si existe una mitigación en otra capa (por ejemplo, en un API Gateway o lógica de negocio personalizada).
2. **Estado de IA Local y DAST:**
   - **IA Local:** `v2.0.0-rc.1` utiliza por defecto el **Motor Heurístico Determinista Offline**. El conector con Ollama local es experimental y opcional.
   - **DAST:** `v2.0.0-rc.1` **no** realiza pruebas dinámicas automatizadas contra aplicaciones en ejecución; genera plantillas estáticas de pruebas JUnit 5 / MockMvc para que el desarrollador las ejecute manualmente.
3. **Ejecutable Sin Firma Authenticode:**
   - El binario `SpringSecurityReviewerDesktop.exe` aún no cuenta con firma digital Authenticode OV/EV.
   - **Recomendación de seguridad:** No desactives Windows Defender ni ignores SmartScreen a ciegas. Verifica siempre el hash `SHA-256` del archivo descargado frente a `SHA256SUMS.txt` y ejecuta un análisis puntual con Microsoft Defender (`MpCmdRun.exe -Scan -ScanType 3`) antes de abrir el programa.

---

## 🇬🇧 English

### 1. Privacy & Zero-Telemetry Architecture
- **100% Local Processing:** All source code inspection runs strictly on `127.0.0.1` in read-only mode. Zero source code, metrics, or telemetry ever leave your machine.
- **No Untrusted Code Execution:** Auditing a third-party repository never invokes `mvn`, `gradle`, `javac`, or target bytecode.

### 2. Local Loopback Server Hardening (`S-01` – `S-05`)
- **256-Bit Ephemeral Session Token (`X-Operator-Token`):** Bootstrapped via URL fragment (`#ssr_token=`) and scrubbed immediately from browser history; never exposed on `/api/v1/health`.
- **Strict `Host` / `Origin` / `Referer` Enforcement:** Blocks cross-origin browser tab requests and DNS rebinding attacks across all HTTP methods (`403 Forbidden`).
- **System Directory Boundary Protection:** Prevents scanning OS system directories (`C:\Windows`, `Program Files`, `.ssh`, `.aws`, `.gnupg`, `AppData\Roaming`).

### 3. Known Limitations in `v2.0.0-rc.1`
- **Java Source Only:** Inspects `.java`, `pom.xml`, `build.gradle`, `.properties`, `.yml`, and OpenAPI files (does not decompile `.jar`/`.class` binaries).
- **Experimental Local AI & Static JUnit Templates:** Uses the built-in Deterministic Offline Heuristic Engine by default (Ollama connector is experimental/optional) and generates static JUnit 5 / MockMvc test templates for manual execution rather than live automated DAST attacks.
- **Unsigned Binary Verification:** Do **not** disable Windows Defender or blindly bypass SmartScreen. Always verify the SHA-256 hash against `SHA256SUMS.txt` before running the pre-release executable.
