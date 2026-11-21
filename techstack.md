# Production Tech Stack Specifications (`techstack.md`)

This document outlines the current technical stack of **`thattimeofday`** and defines the exact dependencies and integrations required to elevate it to a production-ready, enterprise-grade mobile application.

---

## ⚙️ Core Stack (Currently Integrated)

| Component | Library / Framework | Purpose |
|---|---|---|
| **Framework** | **Flutter SDK (Null-Safety)** | Multi-platform application shell (Android & iOS). |
| **State Management** | **`flutter_bloc`** | Conforming to standard BLoC patterns with unidirectional data flow. |
| **Local Database** | **`hive` / `hive_flutter`** | Fast, lightweight key-value database persisting objects offline. |
| **Monads & functional** | **`fpdart`** | Clean error handling and type-safe functional structures (`Either`). |
| **Design Typography** | **`google_fonts`** | System font overrides to load custom modern fonts (`Space Grotesk`, `Sora`). |
| **Vector Rendering** | **`flutter_svg`** | Scalable icon/logo handling in the splash and toolbar widgets. |

---

## 🚀 Production-Grade Integrations (Proposed Additions)

To transition `thattimeofday` into a fully professional, high-performance product, the following libraries and integrations are required:

### 1. Monetization Stack
*   **`purchases_flutter` (RevenueCat SDK)**:
    *   *Purpose*: Manage in-app purchases, subscriptions, and paywalls.
    *   *Implementation*: Allows unlocking premium features like phase history stats, export logs, and cycle sharing.

### 2. Security & High-Performance Persistence
*   **`flutter_secure_storage`**:
    *   *Purpose*: Secure keychain/keystore encryption key storage.
    *   *Implementation*: Generate an encryption key on the first launch, save it securely, and open encrypted Hive boxes:
        ```dart
        final secureKey = await secureStorage.read(key: 'hive_key');
        final box = await Hive.openBox('cycles_box', encryptionCipher: HiveAesCipher(secureKey));
        ```

### 3. Monitoring & Crash Reporting
*   **`sentry_flutter`**:
    *   *Purpose*: Automatic real-time error tracking and crash reporting.
    *   *Implementation*: Wrap the app runner with Sentry in `main.dart` to monitor and trace Dart / Native Gradle runtime exceptions.

### 4. Background Engagement & Local Reminders
*   **`flutter_local_notifications`**:
    *   *Purpose*: Offline background reminders for hydration and cycle predictions.
    *   *Implementation*: Schedule repeating local alarms (e.g., "Time to drink water!" or "Prediction: Cycle starts in 2 days") without needing a backend push server.

### 5. Utilities & Network Sensing
*   **`share_plus`**: Enable users to securely share/backup their exported JSON backup strings to system sheets.
*   **`connectivity_plus`**: Gracefully check system network adapters if remote backups/restores details are configured.
