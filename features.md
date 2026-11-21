# Proposed Product Features Roadmap (`features.md`)

This roadmap defines the premium, social interest, and core feature expansions proposed for **`thattimeofday`** to make it an essential, high-utility wellness application.

---

## 🌟 1. Smart Local Hydration Reminders
*   **Description**: Custom local notifications triggered based on the user's menstrual phase.
*   **Why it Matters**: Different phases of the cycle require different hydration baselines (e.g., higher hydration needs during the luteal phase due to water retention and metabolic changes).
*   **User Interface**: A simple scheduler toggle under the Hydration screen allowing hourly reminders that adjust dynamically based on cycle phases.

---

## 📊 2. Advanced Phase Analytics & PDF Diary Export
*   **Description**: Rich vector charts visualizing logs over time, paired with a print-ready PDF export feature.
*   **Why it Matters**: Users often need to share symptom histories or calendar trends with healthcare practitioners.
*   **User Interface**: An "Export PDF Report" button inside the Profile Tab which compiles logs, temperatures, and symptoms into a clean, paginated PDF.

---

## 🔒 3. Safe Sync (End-to-End Encrypted Backups)
*   **Description**: A serverless, privacy-first data syncing mechanism using iCloud/Google Drive or local file encryption.
*   **Why it Matters**: Restores data across devices without compromising the "offline-first, zero-registration" privacy identity of the product.
*   **Implementation**: AES-256 encryption using the user's custom profile master password before uploading to Google Drive/iCloud container storage.

---

## 🥗 4. Interlocking Cycle-Hydration Adaptive Insights
*   **Description**: Merge the hydration logging directly into the cycle calendar.
*   **Why it Matters**: Showing days of low water intake alongside symptom logs (e.g. cramps, headaches) can help users identify personal hydration correlations.
*   **User Interface**: Heatmap overlay on `CustomPeriodCalendar` mapping water targets met alongside period log alerts.

---

## 📲 5. Lock-Screen Widgets & Smart Watch Integration
*   **Description**: Simple iOS WidgetKit / Android Glance widgets showing cycle status (e.g., "Day 12 - Follicular") and water intake progress.
*   **Why it Matters**: Offers rapid, low-friction widgets so users don't need to open the app to check alerts or log water.
