# Maruthi Eats — Professional Admin Dashboard

A high-performance, responsive Flutter application designed for restaurant staff to manage incoming orders, menu inventory, and business performance in real-time. This app shares a unified Firebase backend with the customer-facing Maruthi Eats app, ensuring seamless operational synchronicity.

---

## 🚀 Key Features

### 📋 Actionable Orders Dashboard
Stay on top of your kitchen operations with a real-time, tabbed dashboard.
*   **Status Tracking**: Separate views for Active, Delivered, and Cancelled orders.
*   **High-Density Summaries**: View order items, delivery addresses, and payment modes at a glance.
*   **Quick Status Progression**: One-tap buttons to move orders through their lifecycle (Confirmed → Preparing → Out for Delivery → Delivered).
*   **Time Awareness**: Integrated "Time Ago" indicators to track order latency.

### 🍴 Intelligent Menu Management
Take full control over your restaurant's digital presence.
*   **Visual Category Grid**: Organise your menu into high-impact categories with custom images.
*   **Drag-and-Drop Reordering**: Manually define the exact sequence of categories as they appear in the customer app.
*   **Advanced Item Controls**:
    *   **Availability Toggle**: Instantly mark items as "In Stock" or "Sold Out."
    *   **Smart Pricing**: Manage original prices and set promotional discounted prices with a single toggle.
    *   **Veg/Non-Veg Indicators**: Clearly visible markers for better kitchen coordination.
*   **Real-time Previews**: Instant visual feedback when adding or editing category/item images.

### 📊 Sales Insights & Analytics
Make data-driven decisions with built-in reporting tools.
*   **Revenue Tracking**: Real-time calculation of total finalized sales.
*   **Volume Metrics**: Track total order counts and average order value.
*   **Flexible Filtering**: View data for Today, Yesterday, Last 7 Days, or the Current Month.
*   **Custom Periods**: Select any specific date or custom date range for historical analysis.

---

## 💎 Premium UI/UX Experience

*   **Responsive Design**: Built with `ScreenUtil` for a consistent, professional experience across all screen sizes and tablets.
*   **Branded Experience**: Custom animated splash screen and themed navigation that reinforces the Maruthi Eats brand identity.
*   **iOS PWA Optimized**: Fully configured for "Add to Home Screen" usage on iPhones, providing a native, full-screen look and feel without browser chrome.
*   **Staff Efficiency**: Direct "Call Customer" integration within order details for immediate communication.

---

## 🛠️ Technical Setup

### 1. Backend Integration
This app must be connected to the **SAME** Firebase project as the customer app to share data.
```bash
# Configure Firebase
flutterfire configure
```
Ensure you have a `staff` collection in Firestore where each document ID matches a staff member's **Firebase Auth UID**.

### 2. Branding & Icons
The app uses automated tools for consistent branding.
```bash
# Generate mobile launcher icons
flutter pub run flutter_launcher_icons:main
```

### 3. PWA Deployment (Firebase Hosting)
The app is configured for multi-site hosting.
```bash
# Build the web app
flutter build web

# Deploy to the admin-specific site
npx firebase-tools deploy --only hosting:admin
```

---

## 🛡️ Security & Integrity
*   **Strict Validation**: Input logic prevents zero-pricing and ensuring discounted prices are valid.
*   **Defensive Parsing**: Resilient data models handle corrupted or missing Firestore data without crashing.
*   **Access Control**: Designed to work with role-based Firestore rules (requires `isAdmin()` check).

---
*Built with ❤️ for Maruthi Eats Staff.*
