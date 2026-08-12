# Implementation Plan - Exclusively Custom Splash Screen

Remove the logo from the native OS splash screen and activate the animated Flutter splash screen. This ensures the user only sees your custom-branded animation during the app's initial load.

## User Review Required

> [!NOTE]
> All Android apps have a "Native Splash" that shows while the OS is loading the app's process. I will set this to a solid **Cream** background to match your app, which effectively "hides" it until your custom animated splash screen takes over.

## Proposed Changes

### 1. App Flow Activation

#### [MODIFY] [main.dart](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/lib/main.dart)
- Update the `home` property of `MaterialApp` to use the `SplashScreen` widget.
- Import `screens/splash_screen.dart`.

### 2. Native Background Cleanup (Android)

I will remove any logo references from the native Android launch screens so they appear as a solid brand color.

#### [MODIFY] [launch_background.xml](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/android/app/src/main/res/drawable/launch_background.xml)
- Change the background drawable to a solid color (`#FFF8E7`).
- Remove the `<item>` containing the `splash` bitmap.

#### [MODIFY] [launch_background.xml](file:///home/tamizharasan/AndroidStudioProjects/maruthi_eats_admin/android/app/src/main/res/drawable-v21/launch_background.xml)
- Apply the same solid color update for newer Android versions.

## Verification Plan

### Manual Verification
1.  **Launch the App**: When the app icon is tapped, you should see a solid cream screen for a split second (native OS load).
2.  **Animation Check**: Immediately after, the **Maruthi Eats** logo should fade in and animate via your custom `SplashScreen` widget.
3.  **Handoff**: Verify there is no "double logo" flicker during the transition from the OS to Flutter.
