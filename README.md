# MoneyTrail

A simple expense tracker app built with Flutter. You can note down your income and expenses, set a monthly budget, and see where your money goes. Everything is saved on your phone and works offline.

## Features

- Add income and expenses with category, date, time and a note
- Calculator-style keypad (type `250+120×2` and the amount is calculated for you)
- Edit or delete entries (swipe left to delete, with Undo)
- Search by note or category
- Month-wise view, grouped by day
- Tap the **Income** or **Expense** card on the Home screen to see only that type, tap again to see all
- Monthly budget with a progress bar
- Insights: spending by category (donut chart), last 6 months chart, daily average, and simple tips
- Currency choice (₹, $, €, £)
- Light / dark / system theme
- Export data as CSV
- "Load demo data" button to try the app quickly

## How to run

Needs Flutter 3.10 or newer.

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Run tests

```bash
flutter analyze
flutter test
```

## Project structure

```
lib/
  core/        theme and currency
  models/      Transaction and Category
  data/        storage, categories, demo data
  services/    analytics, insights, calculator, CSV export
  providers/   app state (Provider)
  screens/     Home, Add/Edit, Detail, Insights, Settings, Splash
  widgets/     charts, keypad and other reusable widgets
test/          unit and widget tests
```

## Tech used

- Flutter and Dart
- Provider (state management)
- shared_preferences (local storage)
- intl (date and currency formatting)



