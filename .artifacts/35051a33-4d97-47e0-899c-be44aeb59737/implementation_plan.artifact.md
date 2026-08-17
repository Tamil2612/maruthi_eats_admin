# Implementation Plan - Combo Item Display in Order Details

Implement the logic to display the contents of Combo/Bundle items within the Order Details screen, providing staff with a clear view of exactly what needs to be prepared for bundled offers.

## User Review Required

> [!NOTE]
> This change assumes that the customer app sends `is_combo: true` and a `bundle_items` list for combo items in an order.

## Proposed Changes

### Data Model

#### [MODIFY] [order.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/models/order.dart)
- Update `OrderModel.fromFirestore` to preserve `is_combo` and `bundle_items` for each item in the order.

### Screens & UI

#### [MODIFY] [order_detail_screen.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/screens/order_detail_screen.dart)
- Update `_ItemsCard` to check for `is_combo`.
- If an item is a combo, display its sub-items in a nested list with a distinct style (smaller font, bullet points).

## Verification Plan

### Manual Verification
1.  **Test Combo Order**: (Simulated via Firestore console if needed) Create an order containing an item with `is_combo: true` and a `bundle_items` list.
2.  **Visual Check**: Open the Order Details screen for that order.
3.  **Verify Nesting**: Ensure the main combo item is shown at its fixed price, and its contents are listed clearly underneath it.
