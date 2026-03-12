# Kigali City Services & Places Directory

A Flutter mobile app that helps Kigali residents find and navigate to essential services and lifestyle spots — hospitals, police stations, libraries, restaurants, cafés, parks, and more. Built with Firebase on the backend and Provider for state management, the app lets authenticated users browse a live directory, add their own listings, and get turn-by-turn directions straight from a listing's detail page.

---

## What the App Does

When you open the app you land on a searchable directory of places. You can filter by category, tap any listing to open a detail page with an embedded map, and hit "Get Directions" to hand off navigation to Google Maps. If you want to contribute, you create an account, verify your email, and start adding listings that immediately appear in the shared directory for everyone. You can edit or delete only your own listings — both in the app and enforced server-side by Firestore rules.

Key features at a glance:

- **Authentication** — email/password signup and login, email verification enforced before entry, Firestore user profile created on signup
- **Directory** — real-time listing feed with live search by name and one-tap category filters
- **My Listings** — personal CRUD view; create, edit, and delete your own entries
- **Detail & Map** — embedded Google Map marker for each listing, plus a navigation button that launches Google Maps directions
- **Map View** — full-screen map showing all listings as markers; tapping one previews the card and lets you jump to the detail page
- **Settings** — shows your profile name, email, verification status, and a toggle for location notification preferences
- **Reviews** — leave a star rating and comment on any listing; aggregate rating updates live via a Firestore transaction

---

## Tech Stack

| Layer | Tool |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| State management | Provider (`ChangeNotifier`) |
| Maps | google_maps_flutter |
| Navigation launch | url_launcher |
| Location | geolocator |

---

## Architecture

The project follows a strict layered architecture so no UI widget ever touches Firebase directly:

```
Firebase / Auth
    ↓
  services/          ← AuthService, ListingService (all Firestore + Auth calls live here)
    ↓
  providers/         ← AuthProvider, ListingsProvider (state, streams, CRUD methods)
    ↓
  screens/           ← UI reads from providers via Consumer / context.watch
```

### Project structure

```
lib/
  models/       ListingModel, ReviewModel, UserProfile — Firestore DTOs
  services/     AuthService, ListingService — Firebase access layer
  providers/    AuthProvider, ListingsProvider — app state via ChangeNotifier
  screens/      auth/, directory/, listings/, map/, setting/
  theme/        AppTheme, AppConstants
```

---

## Firestore Schema

### `users/{uid}`
Keyed by Firebase Auth UID for a direct one-to-one mapping. Stores the user's display name, normalized email, account creation timestamp, and their notification preference toggle.

| Field | Type | Notes |
|---|---|---|
| `email` | string | normalized to lowercase |
| `displayName` | string | |
| `createdAt` | timestamp | |
| `notificationsEnabled` | bool | default true |

### `listings/{listingId}`
The core of the app. Each document powers a directory card, a detail page, and a map marker from a single record — no extra reads needed.

| Field | Type | Notes |
|---|---|---|
| `name` | string | |
| `category` | string | Hospital, Restaurant, Café, etc. |
| `address` | string | |
| `contactNumber` | string | |
| `description` | string | |
| `latitude` / `longitude` | double | validated to Rwanda bounds on write |
| `createdBy` | string | UID — used for ownership checks |
| `createdByName` | string | denormalized for display |
| `createdAt` | timestamp | |
| `rating` | double | aggregate, updated via transaction |
| `reviewCount` | int | aggregate |

### `reviews/{reviewId}`
Kept separate from listings so detail-page review streams don't bloat the directory feed. Review writes trigger a Firestore transaction that atomically recalculates the parent listing's `rating` and `reviewCount`.

| Field | Type |
|---|---|
| `listingId` | string |
| `userId` | string (UID) |
| `userName` | string |
| `rating` | double |
| `comment` | string |
| `createdAt` | timestamp |

---

## Security Rules

Rules are in `firestore.rules`. The core logic:

- **users** — a user can only read and write their own profile document (`request.auth.uid == userId`)
- **listings** — anyone can read; only the creator can update or delete (`resource.data.createdBy == request.auth.uid`); any signed-in user may update only the `rating` and `reviewCount` aggregate fields
- **reviews** — public read; only the reviewer can create, update, or delete their own review
- Everything else is denied by default

---

## State Management

I chose Provider because it integrates cleanly with Flutter's widget tree and keeps things readable without overengineering for a project of this scale.

**AuthProvider** listens to Firebase's `authStateChanges()` stream and drives the `AuthWrapper` router. It exposes auth status, the current user object, the Firestore user profile, and all auth methods. Loading and error states are tracked with an enum and surfaced as user-readable strings.

**ListingsProvider** subscribes to two Firestore streams on startup — one for all listings (Directory + Map) and one scoped to the current user's UID (My Listings). Search and category filtering happen in-memory on the cached stream data, so the UI responds instantly without extra network calls. CRUD operations go through `ListingService` and errors are caught and exposed to whichever screen triggered them.

---

## Getting Started

**Prerequisites:** Flutter SDK, Android Studio, a Firebase project with Email/Password auth enabled, and a Google Maps API key.

1. Clone the repo.

2. Copy the key template and fill in your values:
  ```bash
  cp android/key.properties.example android/key.properties
  # edit android/key.properties with your MAPS_API_KEY
  ```

3. Place your `google-services.json` from the Firebase Console into `android/app/`.

4. Install dependencies:
  ```bash
  flutter pub get
  ```

5. Deploy Firestore security rules:
  ```bash
  firebase deploy --only firestore:rules
  ```

6. Run on emulator or device:
  ```bash
  flutter run -d emulator-5554
  ```

> The app is designed and tested for Android. Web execution is not supported.

---

## Demo Video Coverage

The 7–12 minute demo covers:

1. Sign up → email verification → login
2. Create a listing (coordinates auto-detected from device)
3. Edit the listing, confirm change in Firestore Console
4. Delete the listing, confirm removal in Firestore Console
5. Search by name and filter by category
6. Open a listing detail — show map marker coordinates from Firestore
7. Launch Google Maps navigation from the detail page
8. Walk through `listing_service.dart` → `listings_provider.dart` → `directory_screen.dart` to explain data flow
