# Contributing to VanGo Parent App

Thank you for contributing to the VanGo Parent Application! As a team, we follow these guidelines to ensure our Flutter code is clean and our git history is organized.

## 🛠️ Setup for Development

1.  **Flutter Version:** Ensure you are using Flutter 3.x (Stable Channel).
2.  **Editor:** VS Code is recommended (install the Flutter & Dart extensions).
3.  **Dependencies:** Always run `flutter pub get` after pulling changes.

## 🌿 Branching Strategy

We use the **Gitflow** workflow. Please do not push directly to `main`.

* `main`: Production-ready code (Presentation / Demo version).
* `dev`: Integration branch. Merge your features here.
* `feature/your-feature`: Work on your specific task here.

**Naming Convention:**
* `feature/map-tracking`
* `fix/login-error`
* `ui/payment-screen`

## 🧩 Flutter Coding Standards

* **State Management:** Use `Provider` (or BLoC if agreed) for global state.
* **Folder Structure:** Keep logic in `services/` and UI in `screens/`.
* **Assets:** Place all images in `assets/images/` and register them in `pubspec.yaml`.
* **Formatting:** Run `dart format .` before committing your code.

## 🚀 How to Submit a Change

1.  Create a new branch: `git checkout -b feature/my-new-feature`
2.  Commit your changes: `git commit -m "Add child profile edit screen"`
3.  Push to the branch: `git push origin feature/my-new-feature`
4.  Open a **Pull Request (PR)** against the `dev` branch.
5.  Request a review from at least one team member.