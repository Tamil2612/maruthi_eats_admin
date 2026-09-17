# Implementation Plan - Category Menu Items UI Upgrade

Elevate the user interface for the category-specific menu item list to make it more professional, visually engaging, and informative.

## Proposed Changes

### Screens & UI

#### [MODIFY] [category_items_screen.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/screens/category_items_screen.dart)
- **Search Functionality**: Add a search bar at the top of the list to quickly find specific dishes within the category.
- **Summary Header**: Add a compact header card showing the category image (as a background or thumbnail) and the total count of items.
- **Redesigned Item Card (`_MenuItemCard`)**:
    - **Premium Look**: Use a more modern card design with a dedicated image area and balanced white space.
    - **Badge Support**: Move the Veg/Non-Veg indicator to a prominent badge on the image itself.
    - **Availability State**: Dim the entire card or add a "Sold Out" overlay when an item is marked as unavailable.
    - **Price Highlighting**: Use larger, bolder typography for the current price and a subtle strikethrough for the original price.
- **Improved Loading & Empty States**: Refine the visual feedback when items are loading or when none are found.

### Theming & Spacing
- Use `ScreenUtil` for fine-tuned control over all dimensions.
- Apply subtle shadows and border radii for a cohesive "High Density" design.

## Verification Plan

### Manual Verification
1.  **Search Test**: Type a dish name in the search bar and verify the list filters in real-time.
2.  **Summary Check**: Verify the total item count in the header matches the actual number of items.
3.  **Visual Audit**: Ensure the new card design looks crisp and scales correctly across different screen sizes.
4.  **Availability Toggle**: Mark an item as unavailable and check if the card visual state changes (e.g., becomes slightly transparent or shows an overlay).
5.  **Veg/Non-Veg Badges**: Confirm the green/red indicator is clearly visible on the item images.
