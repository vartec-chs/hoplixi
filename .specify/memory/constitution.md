<!--
Sync Impact Report:
- Version change: Initial → 1.0.0
- Modified principles: N/A (initial version)
- Added sections: All (initial creation)
- Removed sections: None
- Templates status:
  ✅ plan-template.md - reviewed, aligns with constitution
  ✅ spec-template.md - reviewed, aligns with constitution  
  ✅ tasks-template.md - reviewed, aligns with constitution
  ✅ agent-file-template.md - reviewed, aligns with constitution
- Follow-up TODOs: None
-->

# Hoplixi Constitution

## Core Principles

### I. Service-Oriented Architecture (NON-NEGOTIABLE)

All data operations MUST flow through the service layer. Direct DAO access from UI or providers is strictly prohibited. Services MUST return `ServiceResult<T>` objects containing success status, optional message, and optional data. No exceptions shall be thrown to consumers; all errors MUST be caught, logged minimally (without sensitive data), and returned as failed results.

**Rationale**: This pattern ensures consistent error handling, security (no sensitive data leakage), testability, and clear separation of concerns. It prevents tight coupling between UI and data layers.

### II. Encryption-First Security

All sensitive data (passwords, TOTP secrets, secure notes) MUST be encrypted before storage using the established `CryptoManager` pattern with authenticated encryption (nonce + ciphertext + auth tag). Plaintext sensitive data MUST NEVER be logged. All primary keys MUST use UUID v4. Decryption and validation MUST follow the `simple_box.dart` pattern.

**Rationale**: Password managers are high-value targets. Authenticated encryption with per-record nonces prevents tampering and ensures confidentiality even if the database is compromised.

### III. Code Generation Discipline

Any modification to Drift tables, Freezed classes, or JSON serialization MUST be followed by running `build_runner.bat` (or `dart run build_runner build --delete-conflicting-outputs`). Generated code MUST be up-to-date before commits. Development MUST NOT proceed if generation produces errors.

**Rationale**: Outdated generated code causes runtime errors and compilation failures. Strict discipline prevents hours of debugging generated code mismatches.

### IV. Riverpod v3 Notifier API Only

State management MUST exclusively use Riverpod v3's Notifier, AsyncNotifier, or StreamNotifier APIs. Legacy APIs (Provider, FutureProvider, ConsumerWidget, etc.) are forbidden. Providers MUST be named with `*_provider.dart` suffix and organized within feature modules or common directories.

**Rationale**: Notifier API provides better type safety, consistency, and aligns with Riverpod's future direction. Mixing API versions creates confusion and maintenance burden.

### V. Custom UI Components Enforcement

User input MUST use project-specific components: `TextField` and `PasswordField` from `common/` for text entry, `SmoothButton` for actions, `SliderButton` for destructive confirmations. Generic Flutter widgets for these purposes are prohibited. Theme colors MUST come from `core/theme/colors.dart` via `themeProvider`.

**Rationale**: Consistency in UX, security features (like password visibility toggle), and centralized theming. Custom components enforce security best practices and maintain brand identity.

### VI. Structured Logging Without Secrets

All operations MUST use `app_logger.dart` functions (`logInfo`, `logError`, `logDebug`). Logs MUST NEVER contain plaintext passwords, TOTP seeds, encryption keys, or personally identifiable information. User-facing notifications MUST use `ToastHelper` from `toastification.dart`.

**Rationale**: Logs may be stored insecurely or transmitted for debugging. Leaking secrets in logs defeats the entire security model of a password manager.

### VII. Test-Driven Feature Development

New features and entities MUST follow this sequence: (1) Create Drift table, (2) Create DAO, (3) Register in `hoplixi_store.dart`, (4) Run code generation, (5) Create service following existing patterns (`password_service.dart`, `totp_service.dart`), (6) Update SQL triggers if needed. Integration tests SHOULD be written for critical flows.

**Rationale**: Structured approach prevents missing steps (like forgetting triggers or services), ensures consistency, and maintains architectural integrity.

## Security Requirements

### Cryptographic Standards

- Use `crypto_box.dart` with `encryptUtf8WithAutoNonce` for encryption
- Store encrypted data as: `{ nonce, cipher, tag }`
- Validate on decryption using `simple_box.dart` patterns
- MUST use authenticated encryption (AES-256-GCM or ChaCha20-Poly1305)
- Key derivation MUST use appropriate KDF (Argon2 or PBKDF2 with high iterations)

### Data Handling

- SQLCipher for database-level encryption
- `flutter_secure_storage` for master key/credentials
- No sensitive data in SharedPreferences
- Automatic session timeout enforcement
- Clipboard clearing after password copy

### Platform Security

- Platform-specific secure storage (Keychain on iOS/macOS, Keystore on Android, DPAPI on Windows)
- Permission requests MUST be minimal and justified
- No network calls without explicit user consent
- Web platform intentionally disabled for security reasons

## Development Workflow

### Code Organization

- Feature modules: `lib/features/<name>/` (widgets, screens, providers)
- Shared components: `lib/common/`
- Core infrastructure: `lib/core/`
- Data layer: `lib/hoplixi_store/`
- Navigation: `lib/router/` (GoRouter with smooth transitions)

### Responsive Design

- Use `ResponsiveFramework` breakpoints consistently:
  - MOBILE: ≤450px
  - TABLET: 451–1000px
  - DESKTOP: ≥1001px
- Layouts MUST adapt gracefully across all supported platforms

### Build and Release

- Pre-build checklist: Run code generation, verify no errors
- Windows: `flutter build windows`
- Android: `flutter build apk`
- Production builds via `release.bat`
- Version format: `MAJOR.MINOR.PATCH+BUILD` (semantic versioning)

### Quality Gates

- No direct DAO calls from UI/providers
- No raw SQL outside Drift (except triggers)
- No legacy Riverpod APIs
- No plaintext secrets in logs
- All providers use Notifier API
- Build runner passes without errors
- Service layer returns `ServiceResult<T>` consistently

## Governance

### Constitutional Authority

This constitution supersedes all other development practices and guidelines. When conflicts arise between this document and other guidance files (`AGENT.md`, `copilot-instructions.md`), this constitution takes precedence.

### Amendment Process

1. Proposed changes MUST document rationale and impact
2. Version bump follows semantic versioning:
   - **MAJOR**: Breaking governance changes, principle removal/redefinition
   - **MINOR**: New principles or materially expanded guidance  
   - **PATCH**: Clarifications, wording improvements, typo fixes
3. Amendment date MUST be updated in ISO format (YYYY-MM-DD)
4. Dependent templates and guidance files MUST be updated for consistency
5. All amendments MUST include a Sync Impact Report

### Compliance Verification

- All feature specifications (`spec.md`) MUST pass Constitution Check section
- All implementation plans (`plan.md`) MUST re-verify compliance after design phase
- Violations MUST be justified in Complexity Tracking section or rejected
- AI agents MUST verify constitutional compliance before code generation
- Review process MUST validate adherence to service layer, encryption, and UI component requirements

### Living Documentation

- Runtime development guidance in `AGENT.md` and `.github/copilot-instructions.md`
- These files provide operational details but cannot contradict constitutional principles
- MCP servers: Use Dart server for library searches, SequentialThinking for complex multi-step reasoning
- Quick checklist before commits: build_runner passed, services use `ServiceResult`, providers use Notifier API

**Version**: 1.0.0 | **Ratified**: 2025-10-05 | **Last Amended**: 2025-10-05
