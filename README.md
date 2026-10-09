# Wealth Manager - Expense Tracker 💎

A sophisticated, high-performance Flutter wealth management application designed with a premium "Half White & Sky Blue" aesthetic. This app empowers users to take full control of their financial life with advanced tracking, smart calculations, and portability features.

## ✨ Key Features

*   **Smart Calculator**: Built-in math expression evaluator in the amount field (e.g., `100+50*2`) for quick entries.
*   **Premium Design**: Modern Material 3 UI featuring a refined Sky Blue and Half White palette, optimized for mobile viewing.
*   **Debt & Loan Tracker**: Manage your debts and loans efficiently in a dedicated section.
*   **Savings Goals**: Set and track your financial targets with progress visualization.
*   **Dynamic Budget Meter**: Real-time visual tracking of monthly spending against defined limits.
*   **Data Portability**: Full CSV Export and Import capabilities for seamless data management.
*   **Multi-Currency Support**: Support for Rs., $, €, £, ¥, PKR, and INR.
*   **Smart Analytics**: Categorized expense distribution and trend analysis via interactive charts.
*   **Automated Reminders**: Persistent daily notifications to ensure you never miss a transaction.
*   **Test Notification**: Verify notification settings directly from the app settings.
*   **Theming**: Seamless switching between Light and Dark modes.

## 🛠 Tech Stack

*   **Framework**: Flutter (Material 3)
*   **Local Database**: Hive (High-performance NoSQL)
*   **Math Engine**: function_tree (For amount field calculations)
*   **Charts**: FL Chart
*   **Notifications**: flutter_local_notifications & Timezone
*   **Portability**: CSV parser & Share Plus

## 🚀 Getting Started

### Prerequisites

*   **Flutter SDK**: `^3.0.0`
*   **Android**: minSdk 21 (with Core Library Desugaring)

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Mahnoor-Afzal/expense-tracker.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

### Release Build

To generate a release APK with proper icon rendering:
```bash
flutter build apk --release --no-tree-shake-icons
```

## 🔐 Android Configuration

The app is pre-configured with:
*   ProGuard rules for Hive and Notification models.
*   Java 8 Desugaring for broad device compatibility.
*   Necessary permissions for Alarms and Notifications.

## 📄 License

This project is licensed under the MIT License.
