# Privacy Policy for Actividata (Life OS)

**Effective Date:** September 12, 2026  
**Last Updated:** September 12, 2026  
**Application Name:** Actividata (Life OS)  
**Package Name / Application ID:** `com.lifehub.app`  
**Developer:** Naufal Atha ([GitHub Repository](https://github.com/naufalatha018-lgtm/life-hub))

---

## 1. Overview & Core Philosophy

**Actividata** ("Life OS", "we", "us", or "our") is designed from the ground up with an **offline-first, zero-knowledge, and privacy-first architecture**. We believe that your personal life data—including financial records, personal notes, secure files, habits, daily tasks, and health metrics—belongs exclusively to you.

- **Offline-First by Default:** The application is fully functional without requiring an internet connection or creating a cloud account. All personal data is saved locally on your device in an encrypted SQLite database.
- **Zero-Knowledge Principle:** We do not track, profile, monetize, or sell your personal information.
- **User Control:** You retain full ownership and control over your data at all times, with granular options to export, back up, or permanently delete your records.

---

## 2. Google Health Connect & Wellness Data

Actividata provides optional wellness and health tracking by integrating directly with **Google Health Connect** (and compatible wearables, such as Redmi Watch 5 Lite synced via Mi Fitness).

### 2.1. Types of Health Data Accessed
Actividata requests explicit, granular **read-only permissions** for the following Health Connect data types:
- **Steps (`android.permission.health.READ_STEPS`):** Daily step count and activity intervals.
- **Heart Rate (`android.permission.health.READ_HEART_RATE`):** Recent heart rate samples for resting and active pulse tracking.
- **Sleep (`android.permission.health.READ_SLEEP`):** Sleep duration and sleep session stages.
- **Calories Burned (`android.permission.health.READ_ACTIVE_CALORIES_BURNED`, `android.permission.health.READ_TOTAL_CALORIES_BURNED`):** Active and total energy burned.

### 2.2. Purpose of Processing Health Data
- Health data is accessed solely to calculate, aggregate, and display personal fitness and wellness statistics directly within your local Actividata dashboard.
- This data powers on-device health widgets, daily progress rings, and trend visualizations.

### 2.3. Health Connect Data Protection & Google Policy Compliance
In strict accordance with the **Google Health Connect Permissions Policy** and Google Play Developer Policies:
1. **No Transfer to Third Parties:** Health data retrieved from Health Connect is processed strictly on your device. We **never** transfer, share, disclose, or sell Health Connect data to third parties, advertising networks, data brokers, or information resellers.
2. **No Advertising Use:** Health data is never used for targeting advertisements, user profiling, or marketing purposes.
3. **No Machine Learning / AI Training:** Health Connect data is never utilized to train generalized artificial intelligence (AI) or machine learning (ML) models.
4. **No Cloud Upload Without Explicit Configuration:** Health Connect telemetry is stored in local volatile memory and device storage; it is not sent to any remote server or cloud database.
5. **Granular User Consent:** Access to Health Connect requires explicit user approval through the official Android Health Connect permission dialog. You can revoke this permission at any time via Android System Settings > Privacy > Health Connect.

---

## 3. Cryptographic Security & Secure Vault (AES-256-GCM)

Actividata includes a built-in Secure File & Note Vault designed to store highly sensitive personal files and confidential notes.

### 3.1. Cryptographic Standards
- **Cipher:** Authenticated Encryption with Associated Data (AEAD) using **AES-256-GCM** (Galois/Counter Mode) with 256-bit keys.
- **Key Derivation:** **PBKDF2** (Password-Based Key Derivation Function 2) using **HMAC-SHA256**, executed with **100,000 iterations** and a cryptographically secure 16-byte random salt (`Random.secure()`).
- **Nonce & Tag Verification:** Every encryption operation generates a unique, cryptographically random 12-byte initialization vector (nonce) and produces a 16-byte Message Authentication Code (MAC / tag) ensuring data confidentiality and integrity.
- **Zero-Knowledge PIN Verification:** PIN validation uses a salted HMAC-SHA256 authentication verifier. Your master PIN and raw derived encryption keys are never stored on disk in plaintext and are wiped from device memory upon app lock or session timeout.

### 3.2. Local Biometrics
If enabled, biometric authentication (fingerprint or face unlock via Android `USE_BIOMETRIC` / `USE_FINGERPRINT`) operates entirely through Android's secure hardware-backed Keystore / BiometricPrompt APIs. Biometric data never leaves the secure hardware enclave of your device and is never accessed or stored by Actividata.

---

## 4. Cloud Synchronization & Supabase Integration (Optional)

Actividata offers an **optional** cloud backup and multi-device synchronization service powered by **Supabase**. Cloud sync is disabled by default and requires you to explicitly sign in.

### 4.1. Synced Data Types
When cloud sync is active, the following user-scoped records may be synchronized:
- Financial wallets and transaction history
- Task management records and checklists
- Habit tracking streaks and completions
- Focus timer sessions and wellness logs (water & mood)

### 4.2. Secure Isolation & Row Level Security (RLS)
- **Strict Row Level Security:** The cloud database enforces PostgreSQL Row Level Security (RLS) across all tables (`USING (auth.uid() = user_id)`). Users can only view, insert, update, or delete records associated with their unique authenticated user ID.
- **Vault Blobs Remain Local:** Raw binary files stored in your AES-256-GCM Secure Vault and confidential note bodies remain strictly local on your device and are **not** transmitted to the cloud database.
- **Transport Security:** All communications between the mobile application and Supabase servers are encrypted in transit using Transport Layer Security (**TLS 1.3 / HTTPS**).

### 4.3. Authentication Providers
Cloud sync supports authentication via:
- Email and One-Time Password (OTP / Magic Link / Password)
- Google Sign-In (OAuth 2.0 token verification)

We store only the authentication credentials necessary to maintain your session (such as user ID and email). We never access your third-party account passwords.

---

## 5. Artificial Intelligence Assistant (Optional / BYOK)

Actividata provides an optional AI Assistant powered by the Google Generative AI (Gemini) API.
- **Bring-Your-Own-Key (BYOK):** Users provide their own Gemini API key. Your API key is encrypted and stored locally on your device via `flutter_secure_storage`.
- **User-Initiated Queries:** AI processing only occurs when you proactively ask a question in the AI Chat tab.
- **No Unsolicited Background Ingestion:** Your personal vault files, sensitive notes, and financial balances are never automatically ingested or transmitted to AI services in the background.

---

## 6. Android Permissions Requested

Actividata requests only the permissions strictly required to provide its features:

| Permission | Category | Purpose |
|---|---|---|
| `INTERNET` | Network | Optional Supabase cloud synchronization and BYOK AI assistant requests. |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Location | Optional, user-initiated local map/weather features; location data is processed locally and not tracked. |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | Security | Local biometric unlock for the app and Secure Vault. |
| `POST_NOTIFICATIONS` | Notifications | Local reminders for scheduled tasks, habit alerts, and focus timer completion. |
| `RECEIVE_BOOT_COMPLETED` | System | Reschedules local notification alarms following device reboots. |
| `VIBRATE` | Device Hardware | Haptic feedback for timers and user interactions. |
| `READ_STEPS`, `READ_HEART_RATE`, `READ_SLEEP`, `READ_ACTIVE_CALORIES_BURNED` | Health Connect | Reading local fitness metrics for dashboard widgets (subject to explicit user consent). |

---

## 7. Data Retention, Export, and Deletion

- **Local Data Deletion:** You can delete individual records or wipe the entire local SQLite database at any time through the in-app Settings menu or by clearing the app's data in Android System Settings.
- **Cloud Account & Data Deletion:** If you use cloud sync, you can request full account and data deletion directly within the application or by contacting us. All associated cloud database rows are permanently deleted via PostgreSQL cascading foreign keys (`ON DELETE CASCADE`).
- **Data Portability:** You can export your local transactions and records to standard formats (such as JSON / CSV) at any time.

---

## 8. Children's Privacy

Actividata is not directed to individuals under the age of 13 (or under 16 in certain jurisdictions such as the European Union). We do not knowingly collect or solicit personal information from children. If we become aware that a child has provided us with personal data, we will take immediate steps to delete such data.

---

## 9. Compliance with International Privacy Regulations

We respect international privacy frameworks, including:
- **General Data Protection Regulation (GDPR - EU/UK):** Legal basis for processing is user consent and performance of service. Users have the right to access, rectify, port, or erase personal data.
- **California Consumer Privacy Act (CCPA / CPRA - US):** We do not sell or share personal information with third parties for monetary or other valuable consideration.
- **Google Play & App Store Health Connect Policies:** Full transparency and non-transfer compliance regarding health data.

---

## 10. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect improvements in our app features or regulatory changes. Any modifications will be posted to this repository with an updated "Last Updated" date. We encourage you to review this policy periodically.

---

## 11. Contact Information

If you have questions, feedback, or concerns regarding this Privacy Policy or your personal data, please contact:

- **Developer:** Naufal Atha
- **GitHub Repository:** [https://github.com/naufalatha018-lgtm/life-hub](https://github.com/naufalatha018-lgtm/life-hub)
- **Issue Tracker:** [https://github.com/naufalatha018-lgtm/life-hub/issues](https://github.com/naufalatha018-lgtm/life-hub/issues)
- **Direct Privacy Link:** [https://github.com/naufalatha018-lgtm/life-hub/blob/master/PRIVACY_POLICY.md](https://github.com/naufalatha018-lgtm/life-hub/blob/master/PRIVACY_POLICY.md)
