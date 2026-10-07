# FittenUp Privacy Policy

Last updated: 7 October 2026

Public URL: <https://nathanbyrnecode.github.io/workout-tracker/>

This Privacy Policy explains how FittenUp ("the app"), provided by Nathan Byrne ("we", "us", or "our"), handles information when you use the app on iOS or Android.

The app stores workout information in Supabase so that it is available through your signed-in account. Account information is processed for sign-in, security, and account administration. If you choose to add a place to a workout, the app can use your device's location and a place search to suggest places. We do not sell personal information, display advertising, or use personal information for cross-app tracking.

## Data we handle

### Information used for sign-in

When you choose Google Sign-In, the app requests the `email` and `profile` scopes. The sign-in process can provide your name, email address, Google account identifier, profile information, and authentication tokens.

When you choose Sign in with Apple, the app requests your name and email address. Apple may provide a private relay email address if you choose to hide your email. The sign-in process also provides an Apple account identifier, identity token, and authorization code. The authorization code is exchanged for a refresh token, which is encrypted before being stored in Supabase so that your Apple authorization can be revoked if you delete your account.

Supabase creates and stores an internal user ID and session records so that you can remain signed in.

### Authentication and technical records

Supabase automatically records authentication events such as sign-in, token refresh, and sign-out. Those records can include your user ID, IP address, user-agent or device information, timestamp, action, and sign-in provider. We use these records only to operate, secure, and troubleshoot authentication.

The Google Sign-In SDK included in the iOS app declares that it may process name, email address, phone number, coarse location, user ID, device ID, other usage data, and other data types for app functionality and analytics. The app itself requests only email and profile access from Google and does not ask you to enter a phone number. Data handled by Google is also governed by Google's privacy terms.

### Location and place search

Adding a place to a workout is optional. A workout can be saved with no place at all.

The app asks for permission to use your device's location only when you tap "Use current location". It asks for location while the app is in use, never in the background, and at a reduced accuracy that is enough to find places near you. Once you have allowed it, the app also reads your device's last known location whenever you open the place search, so that it can list nearby places and show distances without asking again.

To find places, the app sends requests to two public services that use OpenStreetMap data:

- **Photon**, run by Komoot, receives the text you type into the place search. If your location is known, it also receives your coordinates, so that results near you come first and so that "Use current location" can be turned into an address.
- **The Overpass API**, run by FOSSGIS e.V., receives your coordinates when the app lists gyms, sports centres, and parks near you.

Like any internet service, both also receive your IP address and a label identifying the app. These requests do not include your name, email address, or account ID. We do not control how long these services keep their own request records.

We do not store your device's location. We store a place only when you save one with a workout, as described under "Workout data". You can withdraw location permission at any time in your device's settings; place search by typing keeps working without it.

### What we do not add

The current version of the app does not include advertising, independent analytics, crash-reporting, or diagnostics SDKs. It does not send push notifications and does not ask for notification permission. We do not collect payment details, contacts, photos, microphone data, or health data from Apple Health or Health Connect, and we do not track your location in the background.

## Workout data

The following is stored in Supabase and linked to your account:

- Workout start and end times, exercise names, set counts, reps, weights, and the time each set was saved.
- The name you give a workout and its location type (Gym, Home, Park, or Other).
- If you choose a place for a workout: the place's name, address, and coordinates.
- Workouts you log by hand for past days: the date, name, location type, and place if you chose one.

The app retrieves this information after you sign in. It does not keep a local workout database or provide offline workout storage.

Your choice of light or dark appearance is kept in a small file on your device and is not sent to us.

## How we use data

We use account, authentication, workout, and location data:

- To authenticate you and maintain your signed-in session.
- To show your first name within the app.
- To save, retrieve, update, and delete your workout records.
- To show your activity, streaks, and totals in the Tracker.
- To suggest nearby places and attach a place to a workout when you ask for it.
- To revoke linked sign-in authorization when you delete your account.
- To prevent abuse, protect account security, and investigate authentication problems.
- To comply with applicable law and enforce our legal rights.

Where applicable, we rely on performance of the service you request, our legitimate interests in operating and securing the app, consent where required (including your permission to use device location), and compliance with legal obligations.

## Service providers

- **Apple** provides identity authentication through Sign in with Apple. See the [Apple Privacy Policy](https://www.apple.com/legal/privacy/).
- **Google** provides identity authentication through Google Sign-In. See the [Google Privacy Policy](https://policies.google.com/privacy).
- **Supabase** provides account, session, authentication, and workout database infrastructure. See the [Supabase Privacy Policy](https://supabase.com/privacy).
- **Komoot (Photon)** provides place search and address lookup. See the [Komoot Privacy Policy](https://www.komoot.com/privacy).
- **FOSSGIS e.V. (Overpass API)** provides the list of nearby places. See the [FOSSGIS Privacy Policy](https://www.fossgis.de/datenschutzerkl%C3%A4rung/).

Place data comes from OpenStreetMap and is © OpenStreetMap contributors, available under the [Open Database Licence](https://www.openstreetmap.org/copyright).

These providers process information on our behalf or as independent controllers under their own terms. The place search services are public services that we use without a contract; they act as independent controllers of the request data they receive. Where a provider processes information on our behalf, we require protections that are at least equivalent to those described in this policy and required by applicable law. We may also disclose information where required by law, to protect rights or safety, or as part of a business transfer. We do not sell or rent your personal information.

## Retention and deletion

Workout information, including workout names, saved places, and workouts logged by hand, is retained in Supabase while your account remains active unless you delete the individual workout. You can remove a saved place from a workout by editing it.

Supabase account and authentication information is retained while your account remains active and as reasonably necessary for security, legal, and operational purposes. Authentication log retention depends on the service configuration and plan.

You can delete your account from the Profile area of the app. Account deletion removes your Supabase account and all associated workout data, including saved places and workouts logged by hand, revokes or disconnects the linked sign-in provider where supported, and removes associated authentication data subject to necessary security, legal, and operational retention.

If account deletion does not complete, email [nbyrne0101@gmail.com](mailto:nbyrne0101@gmail.com) from the address linked to your account. We may need to verify your request.

## Your choices and rights

You can sign out or delete your account at any time from the Profile area of the app. You can also edit or delete individual saved workouts in the app.

You can use the app without sharing your location. You can refuse the location prompt, or withdraw permission later in your device's settings, and still save workouts and search for places by typing.

Depending on where you live, you may have rights to access, correct, delete, restrict, or object to processing of your personal information, or to receive a portable copy. You may also withdraw consent where processing relies on consent and complain to your local data-protection authority.

## Security

We use established authentication providers, encryption for stored Apple revocation tokens, and reasonable administrative and technical safeguards to protect account information. No storage or transmission method is completely secure, so we cannot guarantee absolute security.

## Children

The app is not directed to children under 13, and we do not knowingly collect personal information from children under 13. If you believe a child has provided account information, please contact us so we can investigate and delete it where required.

## International transfers

Apple, Google, Supabase, Komoot, and FOSSGIS e.V. may process information in countries other than the country where you live. Where required, they and we use appropriate safeguards for international transfers under applicable data-protection law.

## Changes to this policy

We may update this policy when the app, our providers, or legal requirements change. We will post the revised policy on the public webpage and update the "Last updated" date. Material changes may also be communicated in the app where appropriate.

## Contact

For privacy questions or requests, contact:

Nathan Byrne

[nbyrne0101@gmail.com](mailto:nbyrne0101@gmail.com)
