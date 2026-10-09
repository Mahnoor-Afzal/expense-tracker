# Premium Wealth Manager 💎

A sophisticated, high-performance Flutter wealth management application designed with a premium "Half White & Sky Blue" aesthetic. This app empowers users to take full control of their financial life with advanced tracking, security, and portability features.

## ✨ Premium Features

*   **Premium Design**: Modern Material 3 UI featuring a Sky Blue (0xFF38BDF8) and Half White (0xFFF1F5F9) palette.
*   **Dynamic Budget Meter**: Real-time visual tracking of monthly spending against defined limits on the Home Page.
*   **Biometric Security**: Protect your financial data with Fingerprint/FaceID authentication via `local_auth`.
*   **Data Portability**: Full CSV Export and Import capabilities to keep your data under your control.
*   **Multi-Currency Support**: Flexible currency settings to manage wealth globally.
*   **Smart Analytics**: Categorized expense distribution and trend analysis.
*   **Persistent Reminders**: Never miss a transaction with automated daily notifications.
*   **Profile Management**: Personalized user experience with name and budget customization.
*   **Theming**: Seamless switching between Light, Dark, and System modes.

## 🛠 Tech Stack

*   **Framework**: Flutter (Material 3)
*   **Local Database**: Hive (NoSQL, high performance)
*   **Charts**: FL Chart
*   **Security**: local_auth (Biometrics)
*   **Portability**: CSV parser & Share Plus
*   **Notifications**: flutter_local_notifications & Timezone

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (3.0.0 or higher)
*   Android Studio / VS Code

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/wealth-manager.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

## 🔐 Biometric Setup (Android)

To enable biometric features, the app includes necessary permissions in `AndroidManifest.xml`. Ensure your device has biometrics registered in system settings.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
