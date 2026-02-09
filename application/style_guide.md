# Care4Elder Style Guide

## Brand Identity

### Logo
The **Care4Elder** logo is the primary identifier of the application.

- **Source Asset**: `assets/images/logo.png`
- **Usage**:
  - **Splash Screen**: Centered, 200x200px, with scale animation.
  - **Login/OTP Headers**: Top left or centered, height 50px.
  - **App Icon**: Should be generated from the source asset for Android (mipmap) and iOS (AppIcon).

### Brand Colors
Consistent color usage ensures brand recognition.

- **Primary Blue**: `AppColors.primaryBlue` (Check `lib/core/theme/app_colors.dart` for hex value)
- **Text Dark**: `AppColors.textDark`
- **Text Grey**: `AppColors.textGrey`
- **Error Red**: `AppColors.error`
- **Success Green**: `Colors.green`

### Typography
We use **Roboto** (via `google_fonts`) for a clean, modern, and accessible interface.

- **Headings**: Bold, larger size (e.g., 28sp, 32sp).
- **Body**: Regular/Medium, readable size (14sp, 16sp).
- **Buttons**: Bold, uppercase or capitalized.

## Implementation Guidelines

### Logo Replacement
When using the logo in code, always use `BoxFit.contain` to ensure no cropping:
```dart
Image.asset(
  'assets/images/logo.png',
  height: 50, // Standard height for headers
  fit: BoxFit.contain, // CRITICAL: Prevent cropping
  // width: auto, // Maintain aspect ratio
  errorBuilder: (context, error, stackTrace) {
     return const Icon(Icons.health_and_safety); // Fallback
  },
)
```

### Launcher Icons
To update the app icon for Android and iOS:
1.  Ensure `assets/images/logo.png` is high resolution (1024x1024 recommended).
2.  Replace files in:
    -   **Android**: `android/app/src/main/res/mipmap-*/ic_launcher.png`
    -   **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
3.  Recommended: Use `flutter_launcher_icons` package to automate generation.

## UI Components
- **Buttons**: Rounded corners (e.g., `BorderRadius.circular(12)`), Primary Blue background, White text.
- **Inputs**: Outline border, rounded corners (12px), clear validation messages.
- **Cards**: White background, subtle shadow, rounded corners.

