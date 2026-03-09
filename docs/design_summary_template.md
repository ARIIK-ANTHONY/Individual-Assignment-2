# Design Summary (Template)

## 1. Firestore Structure
Describe each collection and why it was designed this way.

### users/{uid}
- Fields:
- Purpose:

### listings/{listingId}
- Fields:
- Purpose:

### reviews/{reviewId}
- Fields:
- Purpose:

## 2. Listing Model and Data Flow
Explain how listing data moves:
- Firestore -> Service -> Provider -> UI
- UI action -> Provider -> Service -> Firestore

## 3. State Management Approach
- Library used: Provider
- Why selected:
- How loading/success/error states are handled:
- How real-time updates are reflected in Directory/My Listings/Map:

## 4. Authentication and Authorization
- Signup/login/logout flow
- Email verification enforcement
- User profile creation in Firestore
- Firestore security rules used for users/listings/reviews

## 5. Search, Filter, and Map Integration
- How search and category filtering are implemented
- How coordinates are stored and rendered on GoogleMap
- How external navigation is launched

## 6. Trade-offs and Technical Challenges
List practical trade-offs and constraints:
- Example: permissive read rules for public directory
- Example: handling Firebase resend rate limits
- Example: map API key and emulator testing

## 7. Future Improvements
- Push notifications integration
- Better location permission UX
- Pagination/indexing for large datasets
