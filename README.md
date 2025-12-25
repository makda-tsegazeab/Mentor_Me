# MentorMe

MentorMe is a Flutter application that connects students and parents with tutors. It supports role-based onboarding, profile completion, personalized recommendations, in-app messaging, and tutoring relationship management, all backed by Firebase.

## Key Features
- Role-based onboarding for students, parents, and tutors
- Auth flows with profile completion gates
- Personalized tutor and learner recommendations (content-based + hybrid MF)
- In-app chat with relationship-aware access
- Tutoring relationship requests, activation, and completion
- Ratings and reviews
- Notifications center

## Tech Stack
- Flutter (Dart 3.3+)
- Firebase Auth, Firestore, Storage
- Provider for state management
- flutter_dotenv for environment configuration
- Cloudinary + HTTP (media handling)

## Project Structure
- `lib/main.dart`: app entry, routing, providers
- `lib/screens/`: UI screens for auth, onboarding, home, chat, relationships
- `lib/services/`: recommendation and interaction services
- `lib/providers/`: state and data providers
- `lib/offline_recommender/`: Python-based offline recommender

## Getting Started
### Prerequisites
- Flutter SDK (Dart >= 3.3)
- Firebase project (Auth, Firestore, Storage enabled)

### Setup
1) Install dependencies:
```bash
flutter pub get
```

2) Configure Firebase for your platforms using FlutterFire:
```bash
flutterfire configure
```
This generates `lib/firebase_options.dart` for your project.

3) Configure environment variables:
```bash
copy .env.example .env
```
Fill in the values in `.env`.

4) Run the app:
```bash
flutter run
```

## Environment Variables
See `.env.example` for the full list. Required keys include:
- `FIREBASE_API_KEY_WEB`
- `FIREBASE_APP_ID_WEB`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_MEASUREMENT_ID`

Note: `.env` is included as a Flutter asset. Do not store secrets you would not want shipped to clients.

## Recommendations
MentorMe uses a hybrid recommendation approach:
- Content-based matching in `lib/services/content_recommender.dart`
- Hybrid aggregation of content-based and MF results in `lib/services/recommendation_service.dart`

For offline batch recommendations, use:
- `lib/offline_recommender/offline_recommender.py`
- Install requirements:
```bash
pip install -r lib/offline_recommender/requirements.txt
```
- Provide a Firebase service account at `serviceAccountKey.json` (path referenced inside the script)
- Run:
```bash
python lib/offline_recommender/offline_recommender.py
```

## Testing
```bash
flutter test
```
