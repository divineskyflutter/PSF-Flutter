# 🚀 DreamStride App

DreamStride is a Flutter-based mobile app that helps Dream Managers scale their impact and assist employees in identifying and achieving their dreams. Originally created for A1 employees, the long-term vision is to expand across the organization and commercialize it as part of the TMV suite of products.

---

## 👥 Roles Overview

### Dream Manager
- Invites Dreamers
- Views and manages Dreamers’ dreams
- Provides coaching and mentorship
- Manages and shares library resources
- Invites Accountability Partners
- Sends messages and calls to Dreamers

### Dreamer
- Invited by Dream Manager
- Creates and updates dreams
- Views shared library resources
- Invites Accountability Partners
- Sends messages to Partners

### Accountability Partner
- Invited by Dreamers
- Views Dreamers' progress
- Sends motivational messages
- Initiates phone calls to Dreamers

---

## 🌟 Features

| **Task**                         | **Dream Manager** | **Dreamer** | **Partner** |
|----------------------------------|-------------------|-------------|-------------|
| Invite Dreamers                  | ✅                |             |             |
| Create Dreams                    |                   | ✅          |             |
| View a Dreamer’s Dream           | ✅                | ✅          | ✅          |
| Edit a Dream                     |                   | ✅          |             |
| Send messages to a Dreamer       | ✅                | ✅          | ✅          |
| Initiate a phone call to a Dreamer | ✅              | ✅          | ✅          |
| View Library                     | ✅                | ✅          | ✅          |
| Share Library Content            | ✅                | ✅          |             |
| Manage Library                   | ✅                |             |             |
| Invite Partners                  | ✅                | ✅          |             |
| Receive push notifications       | ✅                | ✅          | ✅          |
| Add Notes                        | ✅                |             |             |

---

## ⚙️ Tech Stack
- **Cross-platform** Flutter app (Android & iOS)
- **State Management**: GetX
- **Architecture**: MVC (Model-View-Controller)
- **Push Notifications**: Firebase
- **AI Integration**: ChatGPT API

---

## 🧱 Folder Structure (MVC)

```plaintext
lib/
│── api/               # Handles API-related functionality
│── constants/         # Configuration files, including constants, formatters, enums, and utilities  
│── controllers/       # GetX controllers for state management  
│── data/              # Database migrations and scripts for future data management  
│── dialogs/           # Custom dialogs used throughout the app  
│── enums/             # Enumerations used in the app  
│── models/            # Data models representing app structures  
│── services/          # Background tasks, service logic, and Firebase configuration settings  
│── view/              # Application screens and their associated UI widgets  
│── widgets/           # Reusable widgets used across the app  
│── main.dart          # Application entry point  

assets/                # Static assets such as images, fonts, icons, and Lottie animations  
```

---

# 📱 Flutter App – Dependency Overview

This Flutter project integrates essential packages for state management, networking, storage, user interaction, security, device access, and notifications.

---

## 📦 Dependencies

### 🗂️ State Management
- **[get: ^4.6.6](https://pub.dev/packages/get)**  
  Efficient state management, intelligent dependency injection, and route management.

### 🌐 Networking
- **[dio: ^5.8.0+1](https://pub.dev/packages/dio)**  
  A powerful HTTP client with interceptors, global configuration, and FormData support.
- **[firebase_core: ^3.12.1](https://pub.dev/packages/firebase_core)**  
  Required for initializing Firebase services.
- **[firebase_messaging: ^15.2.4](https://pub.dev/packages/firebase_messaging)**  
  To handle push notifications using Firebase Cloud Messaging (FCM).

### 💾 Storage
- **[shared_preferences: ^2.5.2](https://pub.dev/packages/shared_preferences)**  
  For storing key-value pairs locally on the device.

### 🧑💻 User Interaction
- **[fluttertoast: ^8.2.12](https://pub.dev/packages/fluttertoast)**  
  Display toast messages to the user for brief notifications.
- **[image_picker: ^1.1.2](https://pub.dev/packages/image_picker)**  
  Access images from the device camera or gallery.

### 🔐 Encryption & Security
- **[encrypt: ^5.0.3](https://pub.dev/packages/encrypt)**  
  Used for encrypting and decrypting sensitive data securely.

### 📱 Device & Permissions
- **[device_info_plus: ^11.3.0](https://pub.dev/packages/device_info_plus)**  
  Collect hardware and software information about the device.
- **[permission_handler: ^11.4.0](https://pub.dev/packages/permission_handler)**  
  Request runtime permissions for things like storage, camera, etc.

### 🔔 Notifications & UI Enhancements
- **[flutter_local_notifications: ^18.0.1](https://pub.dev/packages/flutter_local_notifications)**  
  Display notifications locally on the device.
- **[shimmer: ^3.0.0](https://pub.dev/packages/shimmer)**  
  Add shimmer loading effects to improve perceived performance.

---
   
## 🚀 Setup and Installation

### Prerequisites
- Flutter `3.27.3`
- Dart `3.6.1`
- Kotlin `2.1.0`
- Android Gradle Plugin `8.8.0`
- Android Studio Version `Android Studio Ladybug Feature Drop | 2024.2.2`

## Environment Configuration

The project uses the `envied` package for environment variable management. Environment files are located in the `env/` directory at the project root.

#### Environment Files Structure

```
env/
├── dev.env
└── prod.env
```

#### Example Environment File

```env
BASE_URL=https://dev.example.com
API_VERSION=v2
```

#### Environment Class Structure

Each flavor has a corresponding Dart class in `lib/app/config/env/`:

```dart
import 'package:envied/envied.dart';

part 'env_dev.g.dart';

@Envied(path: 'env/dev.env', obfuscate: true)
final class EnvDev {
  @EnviedField(varName: 'BASE_URL')
  static final String baseUrl = _EnvDev.baseUrl;

  @EnviedField(varName: 'API_VERSION')
  static final String apiVersion = _EnvDev.apiVersion;
}
```

### Generate Environment Files

After creating or modifying `.env` files, generate the corresponding Dart files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or for continuous generation during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## 🎯 Flavors Configuration

The project supports three flavors:

| Flavor | Environment | API Endpoint | App Name    |
|--------|-------------|--------------|-------------|
| `dev` | Development | DEV API | DreamStride |
| `prod` | Production | PROD API | DreamStride |

### Android Flavor Configuration

Flavors are configured in `android/app/build.gradle.kts`:

```kotlin
flavorDimensions += "app"
productFlavors {
    
  create("prod") {
    dimension = "environment"
    resValue("string", "app_name", "DreamStride")
    resValue("string", "domain_url", "dreamstride.com")
  }
  create("dev") {
    dimension = "environment"
    resValue("string", "app_name", "DreamStride")
    resValue("string", "domain_url", "dev.dreamstride.com")
  }
  
}
```

## 🚀 Running the App

### Development (DEV)

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### Production

```bash
flutter run --flavor prod -t lib/main_prod.dart
```

### With Release Mode

```bash
flutter run --release --flavor dev -t lib/main_dev.dart
flutter run --release --flavor prod -t lib/main_prod.dart
```

## 📦 Building the App

### Android APK

```bash
# Dev
flutter build apk --flavor dev -t lib/main_dev.dart

# Production
flutter build apk --flavor prod -t lib/main_prod.dart
```

### Android App Bundle (AAB)

```bash
# Dev
flutter build appbundle --flavor dev -t lib/main_dev.dart

# Production
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

### iOS

```bash
# Dev
flutter build ipa --flavor dev -t lib/main_dev.dart

# Production
flutter build ipa --flavor prod -t lib/main_prod.dart
```

## 🎯 Flavors Configuration

The project supports three flavors:

| Flavor | Environment | API Endpoint | App Name         |
|--------|-------------|--------------|------------------|
| `dev` | Development | DEV API | DreamStride DEV  |
| `prod` | Production | PROD API | DreamStride     |

### ❗Important Note

- Whenever you change the `baseUrl`, search for all occurrences of the existing URL throughout the project and replace it with the new one **without** `https://` (for deep linking).
- If any route related to deep linking changes, ensure it's updated in `link_services.dart`.
- When adding new GIFs to the assets, update the loop logic in `send_msg_card.dart` to include them.
- Use `Get.to()` for navigation to independent screens (without a bottom navigation bar), and `Navigator` for screens that **share** a bottom navigation bar.

**🔗 App Link Setup (Android & iOS)**

- **Hosted Asset Link (Android):**

  **DEV Environment**:[`https://dev.dreamstride.com/.well-known/assetlinks.json`](https://dev.dreamstride.com/.well-known/assetlinks.json)
  **UAT Environment**:[`https://dreamstride.com/.well-known/assetlinks.json`](https://dreamstride.com/.well-known/assetlinks.json)


- **Hosted Asset Link (IOS):**
- **DEV Environment**:[`https://dev.dreamstride.com/.well-known/apple-app-site-association`](https://dev.dreamstride.com/.well-known/apple-app-site-association)
- **UAT Environment**:[`https://dreamstride.com/.well-known/apple-app-site-association`](https://dreamstride.com/.well-known/apple-app-site-association)


- **Generate Android SHA256 fingerprint:**
  ```bash
  cd android
  ./gradlew signingReport
  ```

-  Copy the **SHA256 fingerprint** from the signing report and **share it with the backend team** so they can add it to the hosted `assetlinks.json` file.

**🔗 App Linking Validation**

**✅ To Test Android App Linking**

Use the Google Digital Asset Links Statement List Generator and Tester:

[https://developers.google.com/digital-asset-links/tools/generator](https://developers.google.com/digital-asset-links/tools/generator)

**✅ To Test iOS App Linking**

Use the Apple App Site Association File Validator:

[https://app-site-association.cdn-apple.com/a/v1/dreamstride.com](https://app-site-association.cdn-apple.com/a/v1/dreamstride.com)



## ✍️ Contributing

### Branching
- `develop` – All development code
- `feature/{feature-name}` – for new features


### Commit Format
- `feat: feature-name` – for new features
- `fix: issue-name` – for bug fixes
- `refactor: name` – for code restructuring

### Merge Requests
- Use proper tags in your commits
- Ensure your branch is up-to-date with `develop`
- Add a clear title and description

---

## 📄 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---
