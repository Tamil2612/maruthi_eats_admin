# Maruthi Eats — Admin App

Flutter app for restaurant staff to view incoming orders, update order
status, and manage the menu. Uses the **same Firebase project** as the
customer app — same Firestore data, same brand colors.

## What's included

- **Staff login** (email/password) — no public sign-up, this app is
  restricted to restaurant staff only
- **Orders dashboard** — live list, tabs for Active / Delivered / Cancelled
- **Order detail** — items, payment info, one-tap status progression
  (Confirmed → Preparing → Out for Delivery → Delivered), cancel option,
  "Mark Cash Collected" for COD orders
- **Menu management** — add/edit/delete items, toggle availability on/off
  instantly (this is what makes an item show/hide as "sold out" in the
  customer app)

## Setup

1. **Connect to the SAME Firebase project as the customer app:**
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Select the same project you used for the customer app — this is what
   makes both apps share the same `orders` and `menu_items` data.
   Then uncomment the import and switch to
   `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
   in `lib/main.dart`, same as the customer app.

2. **Create staff accounts manually** in Firebase Console → Authentication
   → Users → Add user (email + password). This app has no self-registration
   screen on purpose — you don't want random people signing up as "admin."

3. **Install dependencies and run:**
   ```
   flutter pub get
   flutter run
   ```
   You can also run this as a web app for a restaurant-counter tablet/PC:
   ```
   flutter run -d chrome
   ```
   or build it for hosting: `flutter build web`

## Known TODOs

- **Firestore security rules** — critical before going live. Staff accounts
  need write access to `orders` and `menu_items`; customers should never be
  able to write `order_status` or `payment_status` directly (only this admin
  app / your backend should).
- **Delivery partner assignment** — not built yet. Right now, status just
  moves linearly; if you want to assign a specific delivery person per order,
  that's a natural next screen (add a dropdown of `/delivery_partners` on the
  order detail screen).
- **Push notification on new order** — the dashboard updates live via
  Firestore while the app is open, but a sound/notification alert for staff
  when a new order lands isn't wired up yet (would need FCM + a Cloud
  Function trigger on order creation).
