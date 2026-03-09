# Kigali City Services & Places Directory

Flutter mobile app for discovering and managing public services and lifestyle places in Kigali.

## Features

- Firebase Authentication (email/password)
- Email verification flow before full access
- Firestore-backed user profiles (`users` collection)
- Listings CRUD (`listings` collection)
- Real-time directory updates with Provider state management
- Search by name + category filtering
- Detail page with embedded Google Map marker
- Launch external Google Maps navigation
- Reviews with aggregated listing rating/count
- Bottom navigation: Directory, My Listings, Map View, Settings
- Settings with profile info and local notification toggle

## Tech Stack

- Flutter
- Provider (state management)
- Firebase Auth
- Cloud Firestore
- google_maps_flutter
- url_launcher

## Project Structure

```text
lib/
  models/        # Firestore data models (Listing, Review, UserProfile)
  services/      # Firebase/Auth/Firestore data access layer
  providers/     # App state + business logic (AuthProvider, ListingsProvider)
  screens/       # UI pages and flows
  theme/         # App theme and constants
```

Architecture flow:

`Firestore/Auth -> services -> providers -> UI`

UI widgets do not directly perform Firestore CRUD.

## Firestore Data Model

### `users/{uid}`

- `email` (string)
- `displayName` (string)
- `createdAt` (timestamp)
- `notificationsEnabled` (bool)

### `listings/{listingId}`

- `name` (string)
- `category` (string)
- `address` (string)
- `contactNumber` (string)
- `description` (string)
- `latitude` (double)
- `longitude` (double)
- `createdBy` (string, UID)
- `createdByName` (string)
- `createdAt` (timestamp)
- `rating` (double)
- `reviewCount` (int)

### `reviews/{reviewId}`

- `listingId` (string)
- `userId` (string, UID)
- `userName` (string)
- `rating` (double)
- `comment` (string)
- `createdAt` (timestamp)

## Firebase Security Rules

- `users`: owner-only access
- `listings`: public read, owner-managed CRUD, controlled aggregate field update for reviews
- `reviews`: public read, authenticated owner write/update/delete

Rules file: `firestore.rules`

## Setup

1. Install Flutter SDK and Android Studio.
2. Create Firebase project.
3. Enable Authentication: Email/Password.
4. Add Android app in Firebase with package:
	- `com.example.individual_assignment2`
5. Download `google-services.json` to:
	- `android/app/google-services.json`
6. Ensure Maps API key exists in:
	- `android/app/src/main/AndroidManifest.xml`
7. Install dependencies:

```bash
flutter pub get
```

8. Deploy Firestore rules:

```bash
firebase deploy --only firestore:rules
```

9. Run app on emulator/device:

```bash
flutter run -d emulator-5554
```

## Demo Video Checklist (7-12 min)

- Sign up, login, logout, email verification
- Create listing
- Edit listing
- Delete listing
- Search + filter
- Detail page map marker
- Navigation launch to Google Maps
- Show Firebase Console changes live
- Show key provider/service files while explaining logic

## Notes

- App is intended for Android emulator/physical device execution.
- For best grading, keep incremental commits with meaningful messages.
