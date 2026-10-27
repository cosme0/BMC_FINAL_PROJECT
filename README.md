# First Gear Gym

A Flutter e-commerce demo with a **Supabase + Xendit** checkout, built for the
BMC finals project.

- **Flutter** — storefront, cart, checkout and order history
- **Firebase/Firestore** — product catalogue (falls back to a bundled demo
  catalogue when Firestore is unavailable)
- **Supabase** — payment Edge Functions and the server-owned `orders` table
- **Xendit** — hosted checkout (TEST mode) opened in an in-app WebView
- **Supabase webhook** — the only thing that can mark an order as `PAID`

The payment flow is the same one used by the working reference project in
`C:\SCHOOLWORKS\student_shop`.

---

## How the payment flow works

```
Flutter checkout
   │  POST { product_name, amount }
   ▼
Supabase Edge Function: create-invoice
   │  1. asks Xendit for an invoice
   │  2. stores a PENDING order with the service-role key
   ▼
Flutter opens invoice_url in a WebView (or the browser on desktop/web)
   │
   ▼
Xendit → webhook → Supabase Edge Function: xendit-webhook
   │  verifies x-callback-token, then sets orders.status = PAID
   ▼
Flutter taps "Done" → reads the status from Supabase
```

Closing the checkout page is **never** treated as proof of payment. The app
always re-reads the status from Supabase.

---

## Project structure

```
lib/
  main.dart                       # Firebase + Supabase bootstrap, providers, theme
  config/app_config.dart          # Supabase URL/key (.env or built-in defaults)
  models/
    payment_order.dart            # Order row returned by Supabase
    product.dart / cart_item.dart # Firestore/local catalogue models
  services/
    app_bootstrap.dart            # Supabase.initialize with timeout
    payment_service.dart          # create-invoice, status check, order history
    product_service.dart          # Firestore catalogue (demo fallback)
  screens/
    home/home_screen.dart         # Store, search, categories
    product/product_detail_screen.dart
    cart/cart_screen.dart
    checkout/checkout_screen.dart # Creates the invoice + opens Xendit
    xendit_webview_screen.dart    # Hosted checkout with Done/verification
    orders/orders_screen.dart     # Order history with PAID badges

supabase/
  config.toml
  migrations/001_initial_schema.sql      # products + orders + RLS
  migrations/002_seed_demo_products.sql  # idempotent demo catalogue
  functions/create-invoice/index.ts      # Xendit invoice + PENDING order
  functions/xendit-webhook/index.ts      # token check + PAID update
  .env.local.example                     # Edge Function secrets template
  tests/01_rls_verification.sql          # proves the client cannot fake PAID
```

---

## Run the app

```powershell
flutter pub get
flutter run
```

The app ships with the working demo Supabase project baked in, so it runs
without any local configuration. To use a different project, copy
`.env.example` to `.env`, edit it, and run with
`--dart-define-from-file=.env`.

The Supabase **publishable/anon** key is public and safe in the app. Never put
the service-role key, Xendit secret key, or webhook token in Flutter code.

---

## Supabase setup (already done for the demo project)

Project: `kfvxqsxycpmawgbwugyr`

1. Run the migrations in the Supabase SQL Editor, in order:
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_seed_demo_products.sql`

2. Set the Edge Function secrets (Dashboard → Edge Functions → Secrets, or
   with the CLI):

   ```powershell
   Copy-Item supabase/.env.local.example supabase/.env.local
   # fill in XENDIT_SECRET_KEY and XENDIT_WEBHOOK_TOKEN
   supabase secrets set --env-file supabase/.env.local --project-ref kfvxqsxycpmawgbwugyr
   ```

   | Secret | Purpose |
   | --- | --- |
   | `XENDIT_SECRET_KEY` | Xendit **test** secret key (`xnd_development_...`) |
   | `XENDIT_WEBHOOK_TOKEN` | Random token Xendit must send in `x-callback-token` |
   | `XENDIT_PAYMENT_METHODS` | Optional, e.g. `GCASH,MAYA` |

3. Deploy the functions:

   ```powershell
   supabase link --project-ref kfvxqsxycpmawgbwugyr
   supabase functions deploy create-invoice --project-ref kfvxqsxycpmawgbwugyr
   supabase functions deploy xendit-webhook --project-ref kfvxqsxycpmawgbwugyr
   ```

4. In the Xendit Dashboard (TEST mode), add a webhook for **invoice.paid**:

   ```
   https://kfvxqsxycpmawgbwugyr.supabase.co/functions/v1/xendit-webhook
   ```

   Use the same value as `XENDIT_WEBHOOK_TOKEN` for the callback token.

   JWT verification must be **disabled** for `xendit-webhook` (Xendit calls it
   server-to-server). The function rejects requests without a valid
   `x-callback-token`.

---

## Database and security

| Table | Access |
| --- | --- |
| `products` | Public read, no client writes |
| `orders` | Public read, **no** client insert/update/delete |

Because there is no client write policy on `orders`, the Flutter app cannot
create or mark an order as `PAID`. Only the Edge Functions (service role) can
do that. Run `supabase/tests/01_rls_verification.sql` to verify this.

---

## Demo flow

1. Launch the app. The gym catalogue loads from Firestore, or from the bundled
   demo catalogue if Firestore is unavailable.
2. Add products to the cart and open **Checkout**.
3. Tap **PAY … WITH XENDIT** → `create-invoice` creates a PENDING order and a
   Xendit invoice.
4. Complete the payment in the Xendit checkout with a test channel
   (GCash/Maya/card/QR Ph).
5. Return to the app and tap **Done**.
6. The app polls Supabase briefly. When the webhook has processed the payment,
   it shows **Payment verified!**
7. Open **My Orders** from the receipt icon in the app bar (or the drawer)
   → the order has a green **PAID** badge.

If the webhook is delayed, the order stays **PENDING** and is shown as such —
the app never shows a false success message.

---

## Build an APK

```powershell
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

The Android manifest already declares the `INTERNET` permission required for
Xendit and Supabase.

---

## Useful commands

```powershell
dart format lib/
flutter analyze
flutter test
```
# BMC_FINAL_PROJECT
