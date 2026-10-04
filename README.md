# PetTrack

Historical academic Flutter application for pet profiles, feeding, calendar events
and walking routes, originally integrated with Firebase and Google services.

## Overview

PetTrack was developed for **“Hackathons of Cloud Services: Co-creating and
deploying”**, within the **Multimedia Systems 2024–2025** course. This repository
preserves the team's implementation as a portfolio artifact.

**The original Firebase, Google Cloud and Gemini infrastructure is no longer
maintained or deployed. A clone alone does not provide a working application.**

## Historically implemented features

- Pet profiles with photos, birth dates, species, sex, breed and daily feeding goals.
- Photo selection/compression, Firebase Storage uploads and Gemini-assisted breed identification.
- Feeding counters with a daily reset and missed-meal push reminder function.
- Google Calendar creation, event listing and task creation associated with pets.
- GPS walking-route capture, Google Maps display and per-pet Firestore route records.
- Google sign-in, user profiles and FCM device-token registration.
- Gemini-generated pet characteristics; generated text is not verified veterinary advice.

These features depended on external configuration and hosted services. The task
screen's historical name suggests editing, but its published implementation creates
events; event editing/deletion is not implemented here.

## Historical architecture

| Component | Role in the original implementation |
| --- | --- |
| Flutter / Dart | Screens, reusable widgets and mobile platform integration |
| Firebase Authentication / Google Sign-In | Authentication and Google Calendar authorization |
| Cloud Firestore | User profiles, pet attributes, feeding counters, FCM tokens and walking routes |
| Firebase Storage | Uploaded pet photos |
| Google Calendar API | A PetTrack calendar and pet-associated events |
| Google Maps / device location | Map display and walking-route recording |
| Gemini REST API | Image-based breed identification and pet characteristics |
| Firebase Cloud Messaging | Device registration and feeding reminders |
| Python Cloud Function | Reset feeding counters and send reminders |

The original documentation describes a midnight Scheduler → Pub/Sub → function
trigger. Its schedule, infrastructure definitions and deployed security rules are
not included. The reset function uses Functions Framework CloudEvents. The Flutter
client also references a historical Cloud Run `get_pets` endpoint whose server
implementation is absent. Neither endpoint nor deployment compatibility is verified.

## Repository structure

```text
lib/
  components/             Shared widgets, Google authentication and legacy map
  core/                   Colors and text styles
  models/                 Firestore pet helpers
  screens/                Login, pets, calendar, walks and profile
  services/               Calendar, FCM and user-profile access
CloudFunctions/reset-feed/ Python reset/reminder function and requirements
assets/                   Historical UI and launcher artwork
android/, ios/            Mobile projects
web/, macos/, linux/, windows/  Flutter platform scaffolding
```

## Local inspection and configuration

Source and configuration can be inspected without contacting any cloud service:

```sh
git clone https://github.com/luismz14/PetTrack.git
cd PetTrack
```

With a compatible Flutter SDK already installed, use `flutter pub get` to resolve
the application dependencies. `pubspec.yaml` requires Dart `^3.7.2`; keep the
application's `pubspec.lock`. Do not treat the platform scaffolding as evidence that
every listed platform is supported by all plugins or has been tested.

The historical startup requires these **local, ignored** files:

| File | Purpose |
| --- | --- |
| `.env` | Copy [`.env.example`](.env.example); the Dart client reads `GEMINI_API_KEY`. A blank value is only a placeholder, not working Gemini configuration. |
| `lib/firebase_options.dart` | FlutterFire-generated platform options, imported directly by `main.dart`. A fresh clone has no replacement/stub. |
| `android/app/google-services.json` | Android Firebase configuration |
| `ios/Runner/GoogleService-Info.plist` / macOS equivalent | Firebase platform configuration, if targeting those platforms |
| `android/key.properties` | Historical Android Maps configuration: `MAPS_API_KEY=YOUR_LOCALLY_PROVIDED_KEY` |
| `android/local.properties` | Local Flutter/Android SDK paths generated/configured by tooling |

`android/gradle.properties` contains non-sensitive project settings and belongs in
version control. Android release builds currently use the debug signing configuration;
the source is not a store-release package.

The client still declares `.env` as a Flutter asset because `dotenv.load()` loads
that asset at startup. Removing the declaration alone would break the preserved
setup. **Any value in that file is bundled into the app and can be extracted.**
Never put server credentials in it or treat client-side Gemini keys as secure
production secret storage. Android Maps keys also need appropriate application/API
restrictions if someone independently recreates that integration. OAuth client IDs
and Firebase project/app IDs are identifiers, not automatically private credentials.

Full execution would require separately recreating Firebase, OAuth/Calendar, Maps,
Gemini, FCM and function/trigger configuration, as well as defining and reviewing
Firestore/Storage security rules. That restoration is outside this cleanup. The
included `firebase.json` preserves historical FlutterFire identifiers and points to
the actual Python source directory; it is not a validated deployment recipe.

## Interface and validation limits

Firebase initializes before the app starts. Authentication controls entry to the
home screen, and the pet/calendar/walk/profile screens access live services directly.
There is no offline demo or bundled sample dataset. Adding a useful offline mode
would require more than a small isolated entry path, so the historical navigation
has been preserved.

Flutter/Dart were unavailable in the cleanup environment; no formatter, analyzer,
mobile build or end-to-end cloud test was run. Python syntax, structured
configuration and local documentation/asset references were checked. The repository
is historical evidence, not a claim of current production readiness. Known limitations
include the unsent Cloud Run token parameter, feeding-state synchronization, route
cancellation/permission edge cases and unbounded reset-function batching.

## Assets and privacy

See [the asset inventory](ASSETS.md) for provenance and publication decisions.
The example photograph, logo banner and screenshot composite are excluded from the
working tree and preserved privately. Their historical Git copies still exist.
The retained custom illustrations and Android/iOS launcher derivatives are team-authored
PetTrack artwork approved for public redistribution. No pet records, uploaded photos,
route exports, real `.env`,
service accounts or keystore are intentionally distributed in the current tree.

## Contributors

- Albert Capdevila Estadella
- Levon Kesoyan Galstyan
- Luis Martínez Zamora

## License and publication status

Team-authored PetTrack code and material are licensed under the [MIT License](LICENSE).
The user has confirmed authorization to publish the team's project and retained custom
artwork. Flutter/template material and dependencies retain their separate
[upstream terms](THIRD_PARTY_NOTICES.md).

Git history is retained by explicit user decision. Earlier commits still contain
historical identifiers and excluded media and may become accessible on publication.
The current tree presents a historical academic artifact with the runtime limitations
described above.
