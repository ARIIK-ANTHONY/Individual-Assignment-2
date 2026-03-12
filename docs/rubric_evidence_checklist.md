# Rubric Evidence Checklist

Use this checklist to prove each rubric criterion with concrete code references and demo steps.

## 1. State Management and Clean Architecture (10 pts)

Evidence to show:
- Provider wiring in `lib/main.dart`
- Auth state logic in `lib/providers/auth_provider.dart`
- Listings stream and CRUD state in `lib/providers/listings_provider.dart`
- Service layer boundaries in `lib/services/auth_service.dart` and `lib/services/listing_service.dart`
- No direct Firebase calls in UI files under `lib/screens/`

Demo proof steps:
1. Show service method for one CRUD operation.
2. Show provider method that calls the service.
3. Trigger action in app and show UI rebuild.

## 2. Code Quality and Repository (7 pts)

Evidence to show:
- Incremental commit history with feature-scoped messages.
- Folder structure: `models`, `services`, `providers`, `screens`.
- README architecture and Firebase setup sections.

Demo proof steps:
1. Open commit history and explain progression.
2. Walk through folder structure and one end-to-end flow.

## 3. Authentication (5 pts)

Evidence to show:
- Signup/login logic in `lib/services/auth_service.dart`
- Auth state and errors in `lib/providers/auth_provider.dart`
- Verification gate in `lib/screens/auth_wrapper.dart`
- Email verification flow in `lib/screens/auth/email_verification_screen.dart`

Demo proof steps:
1. Sign up user, show verification prompt.
2. Verify email, then access app.
3. Show `users/{uid}` profile in Firestore Console.

## 4. Location Listings CRUD (5 pts)

Evidence to show:
- Firestore CRUD methods in `lib/services/listing_service.dart`
- Create/edit screen in `lib/screens/listings/add_edit_listing_screen.dart`
- My Listings ownership view in `lib/screens/listings/my_listings_screen.dart`
- Real-time directory stream in `lib/screens/directory/directory_screen.dart`

Demo proof steps:
1. Create listing and show Firestore document.
2. Edit listing and show immediate app update.
3. Delete listing and show removal in app + Firestore.

## 5. Search and Category Filtering (4 pts)

Evidence to show:
- Search and category state in `lib/providers/listings_provider.dart`
- UI filter chips + search in `lib/screens/directory/directory_screen.dart`

Demo proof steps:
1. Filter by category.
2. Search by name.
3. Show real-time updates after creating/editing data.

## 6. Map Integration and Navigation (5 pts)

Evidence to show:
- Embedded map marker in `lib/screens/listings/listing_detail_screen.dart`
- Map overview with markers in `lib/screens/map/map_view_screen.dart`
- External navigation launch logic in `lib/screens/listings/listing_detail_screen.dart`

Demo proof steps:
1. Open detail page and show marker coordinates.
2. Tap navigation and show map handoff.

## 7. Navigation and Settings (4 pts)

Evidence to show:
- BottomNavigationBar in `lib/screens/home_screen.dart`
- Required tabs: Directory, My Listings, Map View, Settings
- User profile and notifications toggle in `lib/screens/setting/settings_screen.dart`

Demo proof steps:
1. Navigate each tab.
2. Toggle notifications and show profile data.

## 8. Deliverables and Demo Quality (10 pts total)

Submit package must include:
- Reflection with Firebase errors + fixes.
- Repository link and README.
- 7-12 minute demo with code walkthrough and Firebase Console visible.
- Design summary with schema and state-management flow.

Final check:
- Verify all links open.
- Verify video length is within requirement.
- Verify PDF contains all required sections.
