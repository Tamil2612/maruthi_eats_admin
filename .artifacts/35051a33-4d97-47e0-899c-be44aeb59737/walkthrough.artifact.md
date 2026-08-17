# Walkthrough - Combo Item Display Enhancement

I have implemented the logic to display the specific contents of Combo/Bundle items within the **Order Details** screen. This ensures your staff knows exactly which individual dishes to prepare when a bundle is ordered.

## Changes Made

### 1. Enhanced Data Modeling
- **[`order.dart`](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/models/order.dart)**: Updated the `OrderModel.fromFirestore` factory to correctly identify and parse combo-specific data (`is_combo` flag and the `bundle_items` list).

### 2. Nested UI Breakdown
- **[`order_detail_screen.dart`](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/screens/order_detail_screen.dart)**:
    - Re-engineered the `_ItemsCard` to detect combo items.
    - Added a stylized nested list for combo contents, using bullet points and italicized text to clearly differentiate sub-items from main order entries.
    - Highlighted combo titles in the brand's Maroon color for better visual hierarchy.

## How to Test

1.  Open an order that contains a combo item (e.g., "Family Feast Bundle").
2.  Observe the **Order Items** card.
3.  Verify that the combo name is shown at its bundle price.
4.  Check that the specific individual items (e.g., "• 2x Veg Biryani", "• 1x Pepsi") are listed clearly indented below the combo name.

> [!TIP]
> This improvement eliminates any ambiguity for the kitchen staff, as they no longer need to remember what's inside each promotional combo—the app tells them exactly what to pack.
