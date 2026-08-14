# Walkthrough - Advanced Special Offers & Combos

I have expanded the promotions system to include a powerful **Special Offers** engine, supporting both complex Combo Bundles and "Buy X Get Y Free" promotional rules.

## Changes Made

### 1. New Promotions Engine
- **Unified Hub**: Renamed the "Coupons" tab to **"Offers"** and introduced a tabbed interface to manage both standard **Coupons** and the new **Special Offers**.
- **Dynamic Offer Model**: Created [offer.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/models/offer.dart) which supports:
    - **Combo / Bundles**: Group multiple items (e.g., 2x Biriyani + 1x Coke) into a single offer with a fixed price.
    - **Buy X Get Y Free**: Set up conditional rewards like "Buy 2 Pizzas, Get 1 Coke Free."

### 2. Powerful Offer Builder
- **Intuitive Form**: Developed [offer_form_screen.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/screens/offer_form_screen.dart) with a dedicated type-selector.
- **Smart Item Picker**: Built a searchable [menu_item_picker.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/widgets/menu_item_picker.dart) to easily select dishes from your current menu.
- **Quantity Controls**: Adjust exact counts for both "Buy" conditions and "Bundle" contents.

### 3. Integrated Management
- **Offer Dashboard**: Added [offer_management_screen.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/screens/offer_management_screen.dart) with color-coded badges to differentiate between "Combo" and "Reward" types.
- **Instant Control**: Same as coupons, you can toggle any special offer on or off instantly with a single switch.

## How to Test

1.  Open the app and tap the **Offers** tab in the bottom navigation.
2.  Select the **Special Offers** sub-tab.
3.  Tap **(+)** to create a new offer.
4.  **Try a Combo**:
    - Select **Combo / Bundle** type.
    - Tap **Add Items to Bundle** and select multiple dishes.
    - Set the quantities (e.g., 2 of one, 1 of another).
    - Set a **Bundle Price** (e.g., 500) and **Save**.
5.  **Try a Reward (BOGO)**:
    - Select **Buy X Get Y** type.
    - Pick a "Buy Item" (e.g., Burger) and set "Buy Qty" to 2.
    - Pick a "Get FREE Item" (e.g., Coke) and set "Free Qty" to 1.
    - **Save** and verify both appear in your management list.

> [!TIP]
> Use clear titles like "Family Feast Combo" or "BOGO Weekend" to make these offers attractive to your customers!
