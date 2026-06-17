# Developer Onboarding Guide

Welcome to the SafePick project! This guide covers everything you need to set up the app on a fresh computer and start contributing securely.

## 1. Prerequisites
Ensure you have the following installed on your new machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/)
- Android Studio / VS Code (with Flutter extensions)

## 2. Cloning the Repository
Clone the project to your local machine:
```bash
git clone https://github.com/your-username/safe-pick.git
cd safe-pick
```

## 3. Install Packages
The repository does not store downloaded packages (to save space). You must download them locally:
```bash
flutter pub get
```

## 4. Setup Environment Secrets (.env)
> [!IMPORTANT]
> For security reasons, the `.env` file is intentionally ignored by Git and will NOT be downloaded when you clone the app. 

You must manually recreate the `.env` file to connect to the backend services.

1. In the root of the `safe-pick` folder, duplicate the `.env.example` file and rename the copy to `.env`.
   - On Windows: `copy .env.example .env`
   - On Mac/Linux: `cp .env.example .env`
2. Open the new `.env` file and replace the placeholder text with the actual production credentials (request these from the lead developer/admin).

## 5. Firebase Configuration
The `firebase.json` and `firebase_options.dart` files are already included in the repository. As long as you have the `.env` file set up, the app will automatically connect to the correct Firebase project on boot. No manual Firebase CLI setup is needed just to run the app.

## 6. Run the App
Connect an emulator or a physical device, and run:
```bash
flutter run
```

---

## Git Security Rules
- **NEVER** commit the `.env` file or any file containing hardcoded passwords. Our `.gitignore` is set up to block `.env`, but always double-check before committing.
- If you add new packages, remember to run `flutter pub get` and commit the updated `pubspec.yaml` and `pubspec.lock`.
