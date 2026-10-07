# App Store Connect privacy answers

Last audited against the app and bundled iOS SDKs: 7 October 2026 (version 1.1.0, the redesign)

These are conservative answers for the current release. They include the data types declared by the bundled GoogleSignIn iOS SDK, not only the fields directly read by the Dart code.

This file is a worksheet. The answers themselves live in App Store Connect and must be changed there by the account owner.

**Changed since the last audit:** the app now asks for location (when in use) for place search, sends place searches to two OpenStreetMap-based services, and stores workout names, location types, saved places and manually logged workouts. Precise Location is now selected.

## Data collection

For "Do you or your third-party partners collect data from this app?", answer:

**Yes, we collect data from this app.**

## Data types to select

| App Store data type | Purpose | Linked to the user? | Used for tracking? | Why |
| --- | --- | --- | --- | --- |
| Health & Fitness → Fitness | App Functionality | Yes | No | Workout names, times, exercise names, sets, reps, weights, and manually logged workouts stored in Supabase |
| Contact Info → Name | App Functionality | Yes | No | Google Sign-In profile and first-name greeting |
| Contact Info → Email Address | App Functionality | Yes | No | Google Sign-In and Supabase authentication |
| Contact Info → Phone Number | App Functionality | Yes | No | Declared by the bundled GoogleSignIn privacy manifest; the app does not request a phone scope |
| Location → Precise Location | App Functionality | Yes | No | Device coordinates are sent to the place search services when the user has allowed location, and the coordinates of a place the user saves with a workout are stored in Supabase against their account. The app asks for reduced accuracy, but nothing guarantees the result is coarse, so answer Precise |
| Location → Coarse Location | App Functionality | Yes | No | Declared by GoogleSignIn; authentication and place search services also receive IP/network metadata |
| Identifiers → User ID | App Functionality; Analytics | Yes | No | Google/Supabase account ID and GoogleSignIn SDK declaration |
| Identifiers → Device ID | Analytics | Yes | No | Declared by the bundled GoogleSignIn privacy manifest |
| Usage Data → Other Usage Data | Analytics | Yes | No | Declared by the bundled GoogleSignIn privacy manifest |
| Other Data → Other Data Types | App Functionality; Analytics | Yes | No | Declared by the bundled GoogleSignIn privacy manifest |

For each selected type, answer **No** to tracking. The app does not use data for third-party advertising, developer advertising or marketing, or cross-app tracking.

## Data types not selected for this release

- **Diagnostics:** there is no independent crash-reporting, performance-monitoring, or diagnostics SDK in the current dependency set.
- **Product Interaction:** the app does not add an analytics SDK. Use **Other Usage Data** above because the current GoogleSignIn privacy manifest declares it.
- **Search History:** text typed into the place search is sent to Photon to answer that search and is not stored by the app or linked to the account. If a stricter reading is wanted, select Search History for App Functionality, not linked to the user.
- Advertising Data, Purchases, Financial Info, Contacts, Photos or Videos, Audio Data, Sensitive Info, and Browsing History.

## Evidence checked

- `lib/state/user_authentication_state.dart` requests Google `email` and `profile` scopes and sends the resulting tokens to Supabase Auth.
- `lib/state/user_authentication_state.dart` requests Apple name and email scopes, sends the Apple identity token to Supabase Auth, and stores an encrypted Apple refresh token for account-deletion revocation.
- Workout state code stores workouts, exercises, sets, reps, and weights in user-protected Supabase tables after authentication.
- `supabase/migrations/20261006232241_add_workout_details_and_manual_workouts.sql` adds the workout name, location type, place name, address and coordinates, a saved time on each set, and the `manual_workouts` table (row level security, deleted with the account).
- `lib/data/place_search/device_location.dart` asks for when-in-use location at medium accuracy, only from "Use current location", and reads the last known position once permission exists. `ios/Runner/Info.plist` carries `NSLocationWhenInUseUsageDescription`.
- `lib/data/place_search/osm_place_search_service.dart` sends search text and, when known, coordinates to `photon.komoot.io`, and coordinates to `overpass-api.de`, with a User-Agent naming the app. No account identifier is sent.
- `lib/data/theme_mode_storage.dart` keeps the appearance choice in a file on the device only.
- `pubspec.yaml` contains no advertising, analytics, Sentry, Firebase Analytics, or crash-reporting dependency.
- The GoogleSignIn privacy manifest (`PrivacyInfo.xcprivacy`) declares Name, Email Address, Phone Number, Coarse Location, User ID, Device ID, Other Usage Data, and Other Data Types, linked to the user and not used for tracking. Plugins can now arrive through Swift Package Manager as well as CocoaPods, so find the manifest in the built app or Xcode's privacy report, not at a fixed `ios/Pods/` path.
- `geolocator_apple` ships its own `PrivacyInfo.xcprivacy`. It was not read for this audit; check it in Xcode's privacy report for the archive.
- Supabase Auth audit logs can store authentication action, timestamp, user ID, IP address, user agent, and provider metadata.

## Submission check

Before every App Store submission:

1. Generate or inspect Xcode's privacy report for the exact archive being submitted.
2. Recheck the GoogleSignIn and geolocator privacy manifests after any pod or package update.
3. Update both App Store Connect and the public policy if an SDK or data flow changes.
4. Confirm the public privacy-policy URL loads without authentication.

Apple guidance:

- <https://developer.apple.com/app-store/app-privacy-details/>
- <https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy>
- <https://developer.apple.com/app-store/review/guidelines/>

## Separate App Review consideration

Sign in with Apple and in-app account deletion are implemented. Authentication is required because workout records are stored against, and retrieved from, the user's Supabase account.
