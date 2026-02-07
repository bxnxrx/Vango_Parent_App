# VanGo: Parent Mobile Application

## Project Overview
The **VanGo Parent App** solves the anxiety parents face regarding school transport. It provides real-time visibility into their child's journey, replaces manual phone calls with automated notifications, and simplifies attendance management.

### Key Features
* ** Real-Time Tracking:** View the live location of the school van on Google Maps with ETA updates.
* ** Smart Notifications:** Receive instant alerts for:
    * Van approaching pickup/drop-off.
    * Child boarded/dropped off.
    * Unexpected delays or emergencies.
* ** Attendance Management:** Mark your child as "Coming" or "Not Coming" for the day to update the driver's route automatically.
* ** Digital Payments:** View monthly fees and payment history (Integration with Payment Gateway).
* ** Driver Communication:** Secure, in-app messaging to contact the driver without distractions.
* ** Child Profiles:** Manage multiple children and their specific pickup locations.

---

## 📸 Screenshots
| Login Screen | Live Map | Child Profile | Notifications |
|:---:|:---:|:---:|:---:|
| ![Login](docs/screenshots/login.png) | ![Map](docs/screenshots/map.png) | ![Profile](docs/screenshots/profile.png) | ![Alerts](docs/screenshots/notifications.png) |

---

## 🛠️ Tech Stack
This application is built using **Flutter** and integrates with several key services:

* **Framework:** Flutter (Dart)
* **State Management:** Provider / BLoC (Select whichever you used)
* **Maps:** Google Maps Flutter SDK
* **Real-Time:** Socket.IO Client (for GPS stream)
* **Notifications:** Firebase Cloud Messaging (FCM)
* **Storage:** Secure Storage (for JWT Tokens)




---

##  Folder Structure
The project follows a feature-first architecture for scalability.

```text
lib/
├── config/              # App-wide constants, themes, and routes
├── models/              # Data models (Parent, Child, Trip, Payment)
├── screens/             # UI Screens
│   ├── auth/            # Login & Registration
│   ├── home/            # Dashboard
│   ├── map/             # Live tracking view
│   ├── profile/         # Child & User management
│   └── payment/         # Payment history
├── services/            # API & External Service Logic
│   ├── api_service.dart # REST calls to Node.js backend
│   ├── socket_service.dart # Listen to GPS updates
│   └── auth_service.dart # Supabase Auth handle
├── widgets/             # Reusable UI components (Buttons, Cards)
└── main.dart            # Entry point
