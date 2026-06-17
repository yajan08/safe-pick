# SafePick Developer Onboarding & Workflow Guide

Welcome to the SafePick project! This document is the ultimate source of truth for any new developer joining the team. It covers setting up your local environment from scratch, configuring the backend, running the app, and safely interacting with GitHub.

---

## 1. Prerequisites (What you need installed)
Before touching the code, ensure your new laptop has the following installed:
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Ensure `flutter doctor` passes).
- **Node.js**: [Install Node.js](https://nodejs.org/) (Required for Firebase Cloud Functions).
- **Git**: [Install Git](https://git-scm.com/).
- **Android Studio / VS Code**: Ensure you have the Dart and Flutter extensions installed.

---

## 2. Initial Setup (First Day)

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/safe-pick.git
cd safe-pick
```

### Step 2: Install App Dependencies
Because packages are ignored by Git to save space, download them locally:
```bash
flutter pub get
```

### Step 3: Install Backend Dependencies (Firebase Functions)
Our backend logic (like ETA calculations) runs on Firebase Cloud Functions. You must install the Node packages for them:
```bash
cd functions
npm install
cd ..
```

### Step 4: Setup Environment Secrets (.env)
> [!IMPORTANT]  
> For security reasons, the `.env` file is intentionally ignored by Git and will NEVER be downloaded when you clone the app. 

To connect to our MQTT broker and APIs, you must manually recreate the `.env` file:
1. Duplicate the `.env.example` file and rename the copy to `.env`.
   - Windows: `copy .env.example .env`
   - Mac/Linux: `cp .env.example .env`
2. Open the new `.env` file and replace the placeholder text with the actual production credentials (ask the lead developer/admin for these).

### Step 5: Setup Firebase CLI (Required for Backend Deployment)
To deploy Cloud Functions or update Firestore Rules, install the Firebase CLI and log in:
```bash
npm install -g firebase-tools
firebase login
```
*(You will need the lead developer to grant your Google account access to the Firebase Project).*

---

## 3. Running & Testing the App

### Running Locally
Connect a physical device via USB or start an Android/iOS Emulator, then run:
```bash
flutter run
```

### Running Tests
Before opening a Pull Request, always ensure you haven't broken existing logic:
```bash
flutter analyze   # Checks for syntax and linting errors
flutter test      # Runs all unit and widget tests
```

---

## 4. GitHub Workflow (How to contribute safely)

To keep the `main` branch stable, follow this standard Git workflow:

### A. Start New Work
Always pull the latest code and create a new branch for your feature or bugfix:
```bash
git checkout main
git pull origin main
git checkout -b feature/your-new-feature-name
```

### B. Save Your Work (Commit)
As you write code, stage and commit your changes:
```bash
git status                  # Review which files you've changed
git add .                   # Stage all changes
git commit -m "feat: added new UI card for parent dashboard"
```

### C. Push to GitHub
```bash
git push origin feature/your-new-feature-name
```
*After pushing, go to GitHub.com and open a Pull Request (PR) to merge your code into `main`.*

### D. What if someone else updated main while I was working?
If another developer pushed code to `main` while you were building your feature, you need to pull their changes into your branch to prevent conflicts:
```bash
git checkout main
git pull origin main
git checkout feature/your-new-feature-name
git merge main
```

---

## Critical Rules to Remember
1. **NEVER commit the `.env` file.** Our `.gitignore` blocks it, but if you ever override it, you compromise the entire system.
2. If you add a new package (e.g., `flutter pub add http`), you MUST commit the updated `pubspec.yaml` and `pubspec.lock` files so other developers get the new package when they pull.
3. If you write a new Firebase Function in `functions/index.js`, deploy it using: `firebase deploy --only functions`.
