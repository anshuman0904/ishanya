# Ishanya App

**Ishanya** is a Flutter-based mobile application developed for **Ishanya India Foundation (IIF)** during a hackathon by Team 7. Designed for parents of children enrolled at IIF, the app provides secure access to essential student information, including educator details, enrolled programs, attendance records, academic reports, and important notifications. It fetches data from a Python backend connected to a MySQL database and integrates push notifications for updates.


## Features

- **Splash Screen**: Displays the app logo and checks authentication status.
- **Login System**: Authenticates students via a Python backend and registers their device for push notifications.
- **Home Screen**: Displays student information, medical details, enrollment records, session details, and family information.
- **Educator Details**: Provides a contact directory for educators, allowing users to email or call directly.
- **Program Enrollment**: Shows a list of programs the student is enrolled in, with color-coded categorization.
- **Attendance Tracking**: Displays attendance history with a summary section and progress indicators.
- **Academic Reports**: Lists report cards and allows users to open them in an external browser.
- **Notifications**: Displays push notifications fetched from a remote API.
- **Logout Functionality**: Manages session state with SharedPreferences and Firebase Cloud Messaging.

## Tech Stack

- **Flutter**: UI framework for building the mobile app.
- **Firebase**: Push notifications and authentication management.
- **Python Backend**: REST API for authentication and data retrieval.
- **MySQL**: Database for storing student details.
- **Google Fonts**: Custom typography for UI consistency.
- **SharedPreferences**: Local storage for session persistence.
- **intl package**: Date formatting.
- **url_launcher**: Opens academic reports in external browsers.

## Installation

### Prerequisites
- Flutter SDK installed
- Android Studio or VS Code (with Flutter extensions)
- Firebase configured with `google-services.json` (for Android)

### Steps
1. Clone the repository:
   ```sh
   git clone https://github.com/anshuman0904/ishanya.git
   cd ishanya
   ```
2. Install dependencies:
    ```sh
    flutter pub get
    ```
3. Run the app:
    ```sh
    flutter run
    ```

## 📽 Demo Video
[![Ishanya App Demo](https://img.youtube.com/vi/s9_QIaiPKGE/0.jpg)](https://www.youtube.com/watch?v=s9_QIaiPKGE)

## 📥 Download APK
[Download the application](https://github.com/anshuman0904/ishanya/blob/main/release/app-release.apk)