# Implementation Plan - Fix Firestore Permissions for Promotions

The `PERMISSION_DENIED` error occurs because the new `coupons` and `offers` collections haven't been added to your Firestore Security Rules.

## User Review Required

> [!IMPORTANT]
> **Action Required in Firebase Console:**
> You must manually copy and paste the updated rules below into your [Firebase Console](https://console.firebase.google.com/) → Firestore Database → Rules.

## Proposed Changes

### Firestore Security Rules (Update in Console)

I have added the rules for the `coupons` and `offers` collections. These rules allow any signed-in user to read them (so they show up in the app) but only staff/admins can create or edit them.

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helpers ──────────────────────────────────────────────
    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return isSignedIn() && exists(/databases/$(database)/documents/staff/$(request.auth.uid));
    }

    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    // ── /users/{uid} ─────────────────────────────────────────
    match /users/{uid} {
      allow read: if isOwner(uid) || isAdmin();
      allow write: if isOwner(uid);

       match /{allSubcollections=**} {
        allow read, write: if isOwner(uid);
      }
    }

    // ── /menu_items/{itemId} ─────────────────────────────────
    match /menu_items/{itemId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ── /categories/{categoryId} ─────────────────────────────
    match /categories/{categoryId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ── /coupons/{couponId} ──────────────────────────────────
    match /coupons/{couponId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ── /offers/{offerId} ────────────────────────────────────
    match /offers/{offerId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // ── /orders/{orderId} ────────────────────────────────────
    match /orders/{orderId} {
      allow read: if isAdmin() || (isSignedIn() && resource.data.customer_id == request.auth.uid);
      allow create: if isSignedIn()
                    && request.resource.data.customer_id == request.auth.uid
                    && request.resource.data.order_status == 'placed'
                    && request.resource.data.payment_status in ['pending', 'cod_pending'];
      allow update: if isAdmin()
                    || (isSignedIn()
                        && resource.data.customer_id == request.auth.uid
                        && resource.data.order_status == 'placed'
                        && request.resource.data.order_status == 'cancelled'
                        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['order_status', 'updated_at']));
      allow delete: if false;

      match /status_log/{logId} {
        allow read: if isAdmin()
                    || (isSignedIn() && get(/databases/$(database)/documents/orders/$(orderId)).data.customer_id == request.auth.uid);
        allow write: if isAdmin();
      }
    }

    // ── /staff/{uid} ──────────────────────────────────────────
    match /staff/{uid} {
      allow read: if isAdmin();
      allow write: if false;
    }

    // ── /delivery_partners/{partnerId} ───────────────────────
    match /delivery_partners/{partnerId} {
      allow read, write: if isAdmin();
    }
  }
}
```

## Verification Plan

### Manual Verification
1.  **Apply Rules**: Copy the code above into the Firebase Console and click **Publish**.
2.  **Verify Coupons**: Open the Coupons tab in the Admin App. The "Permission Denied" error should disappear, and you should be able to see/create coupons.
3.  **Verify Offers**: Switch to the Special Offers tab. You should now be able to see/create offers without errors.
