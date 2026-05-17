# Laphing POS

Point of Sale application for Laphing operations, built with Flutter and Firebase.

## Features

- Menu ordering flow for customer/tablet mode
- Kitchen display flow for order processing
- Admin home and finance-related screens
- Firebase Authentication based routing (`AuthGate`)
- Optional queue display screen
- Firebase Functions folder for backend helpers (including Razorpay order creation)

## Tech Stack

- Flutter (Material 3)
- Firebase Core + Firebase Auth
- Firebase Hosting/Functions (Node.js)

## Project Structure

- [lib/](lib/) – Flutter app source
- [functions/](functions/) – Cloud Functions (Node)
- [assets/](assets/) – Images and menu assets
- Platform folders: [android/](android/), [ios/](ios/), [web/](web/), [windows/](windows/), [linux/](linux/), [macos/](macos/)

## Prerequisites

- Flutter SDK installed
- Dart SDK (comes with Flutter)
- Firebase project configured

## Environment Setup

The Firebase API key is read from a Dart define in [lib/main.dart](lib/main.dart).

Use this key when running/building:

- `FIREBASE_API_KEY`

Example run:

`flutter run --dart-define=FIREBASE_API_KEY=YOUR_API_KEY`

Example web run:

`flutter run -d chrome --dart-define=FIREBASE_API_KEY=YOUR_API_KEY`

## Install & Run

1. Get dependencies:

	 `flutter pub get`

2. Run app:

	 `flutter run --dart-define=FIREBASE_API_KEY=YOUR_API_KEY`

## Build

- Android APK:

	`flutter build apk --dart-define=FIREBASE_API_KEY=YOUR_API_KEY`

- Web:

	`flutter build web --dart-define=FIREBASE_API_KEY=YOUR_API_KEY`

## Notes

- Do not hardcode secrets in source.
- If a key was previously exposed, rotate/revoke it in Google Cloud and update deployments.

## License

This repository currently has no explicit license file.
