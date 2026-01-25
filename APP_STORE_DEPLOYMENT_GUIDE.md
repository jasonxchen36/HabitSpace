# HabitSpace - App Store Deployment Guide

This comprehensive guide walks you through deploying HabitSpace to the Apple App Store.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup in Xcode](#project-setup-in-xcode)
3. [Code Signing Configuration](#code-signing-configuration)
4. [App Icon Setup](#app-icon-setup)
5. [App Store Connect Setup](#app-store-connect-setup)
6. [Building and Archiving](#building-and-archiving)
7. [Submitting to App Store](#submitting-to-app-store)
8. [App Store Metadata](#app-store-metadata)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have:

- **macOS** with **Xcode 15.0** or later installed
- **Apple Developer Account** ($99/year membership)
- **iPhone or iPad** for testing (AR features require a physical device)
- **App Store Connect** access

---

## Project Setup in Xcode

### Step 1: Open the Project

1. Clone or download the updated repository to your Mac
2. Open `HabitSpace.xcodeproj` in Xcode
3. Wait for Xcode to index the project

### Step 2: Verify Project Structure

Ensure the following files are present:
```
HabitSpace/
├── HabitSpace.xcodeproj/
│   └── project.pbxproj
├── HabitSpaceApp.swift
├── Info.plist
├── HabitSpace.entitlements
├── Assets.xcassets/
│   ├── AppIcon.appiconset/
│   └── AccentColor.colorset/
├── Preview Content/
├── Managers/
├── Models/
├── ViewModels/
├── Views/
└── Extensions/
```

### Step 3: Update Bundle Identifier

1. Select the **HabitSpace** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Change the **Bundle Identifier** to your unique identifier:
   - Format: `com.yourcompany.habitspace`
   - Example: `com.jasonxchen.habitspace`

---

## Code Signing Configuration

### Step 1: Enable Automatic Signing

1. In Xcode, select the **HabitSpace** target
2. Go to **Signing & Capabilities** tab
3. Check **Automatically manage signing**
4. Select your **Team** from the dropdown

### Step 2: Configure Development Team

1. If you don't see your team:
   - Go to **Xcode > Settings > Accounts**
   - Click **+** to add your Apple ID
   - Sign in with your Apple Developer account

### Step 3: Verify Capabilities

The following capabilities are already configured in the entitlements file:
- **Push Notifications** (for habit reminders)

Additional capabilities may need to be enabled in App Store Connect:
- **ARKit** (automatically enabled via Info.plist)
- **Location Services** (for location-based reminders)

---

## App Icon Setup

### Required Icon Sizes

You need to create app icons in the following sizes and add them to `Assets.xcassets/AppIcon.appiconset/`:

| Filename | Size (pixels) | Purpose |
|----------|---------------|---------|
| Icon-20@2x.png | 40x40 | iPhone Notification @2x |
| Icon-20@3x.png | 60x60 | iPhone Notification @3x |
| Icon-29@2x.png | 58x58 | iPhone Settings @2x |
| Icon-29@3x.png | 87x87 | iPhone Settings @3x |
| Icon-40@2x.png | 80x80 | iPhone Spotlight @2x |
| Icon-40@3x.png | 120x120 | iPhone Spotlight @3x |
| Icon-60@2x.png | 120x120 | iPhone App @2x |
| Icon-60@3x.png | 180x180 | iPhone App @3x |
| Icon-20.png | 20x20 | iPad Notification @1x |
| Icon-20@2x-ipad.png | 40x40 | iPad Notification @2x |
| Icon-29.png | 29x29 | iPad Settings @1x |
| Icon-29@2x-ipad.png | 58x58 | iPad Settings @2x |
| Icon-40.png | 40x40 | iPad Spotlight @1x |
| Icon-40@2x-ipad.png | 80x80 | iPad Spotlight @2x |
| Icon-76.png | 76x76 | iPad App @1x |
| Icon-76@2x.png | 152x152 | iPad App @2x |
| Icon-83.5@2x.png | 167x167 | iPad Pro App @2x |
| Icon-1024.png | 1024x1024 | App Store |

### Icon Design Guidelines

- Use a simple, recognizable design
- No transparency (use solid background)
- No rounded corners (iOS adds them automatically)
- Recommended: Use a habit/space themed icon

### Quick Icon Generation

Use one of these tools to generate all sizes from a single 1024x1024 image:
- [App Icon Generator](https://appicon.co/)
- [MakeAppIcon](https://makeappicon.com/)
- [Icon Set Creator](https://apps.apple.com/app/icon-set-creator/id939343785) (Mac App Store)

---

## App Store Connect Setup

### Step 1: Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** > **+** > **New App**
3. Fill in the details:
   - **Platform**: iOS
   - **Name**: HabitSpace
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select your registered bundle ID
   - **SKU**: `habitspace-001` (or any unique identifier)
   - **User Access**: Full Access

### Step 2: Register Bundle ID (if not done)

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** > **+**
4. Select **App IDs** > **Continue**
5. Select **App** > **Continue**
6. Fill in:
   - **Description**: HabitSpace
   - **Bundle ID**: Explicit - `com.yourcompany.habitspace`
7. Enable capabilities:
   - ✅ ARKit
   - ✅ Push Notifications
8. Click **Continue** > **Register**

---

## Building and Archiving

### Step 1: Select Build Target

1. In Xcode, select **Any iOS Device (arm64)** as the build destination
2. Ensure **Release** configuration is selected

### Step 2: Clean Build

1. Go to **Product** > **Clean Build Folder** (⇧⌘K)

### Step 3: Create Archive

1. Go to **Product** > **Archive**
2. Wait for the build to complete
3. The **Organizer** window will open automatically

### Step 4: Validate Archive

1. In the Organizer, select your archive
2. Click **Validate App**
3. Follow the prompts:
   - Select your team
   - Choose signing options (Automatic is recommended)
4. Fix any validation errors before proceeding

---

## Submitting to App Store

### Step 1: Distribute App

1. In the Organizer, select your validated archive
2. Click **Distribute App**
3. Select **App Store Connect** > **Next**
4. Select **Upload** > **Next**
5. Choose distribution options:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number
6. Click **Next** and wait for upload

### Step 2: Complete App Store Connect Submission

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Click **+ Version or Platform** if needed
4. Fill in all required metadata (see next section)
5. Select your uploaded build
6. Click **Submit for Review**

---

## App Store Metadata

### App Information

| Field | Suggested Value |
|-------|-----------------|
| **Name** | HabitSpace |
| **Subtitle** | AR Habit Tracker |
| **Category** | Lifestyle |
| **Secondary Category** | Health & Fitness |

### Description

```
HabitSpace is an innovative habit tracking app that uses augmented reality to help you build better habits.

KEY FEATURES:

🎯 Smart Habit Tracking
• Create and track daily habits with customizable goals
• View your streaks and progress over time
• Get insights into your habit completion patterns

📍 Location-Based Reminders
• Set reminders that trigger when you arrive at specific locations
• Perfect for gym habits, work routines, or home activities

🔔 Intelligent Notifications
• Schedule daily reminders at your preferred times
• Never miss a habit with smart notification system

🌟 Augmented Reality Experience
• Place virtual habit markers in your physical space
• See your habits come to life in AR
• Unique spatial awareness for habit building

📊 Progress Tracking
• Track your current and best streaks
• View completion history
• Stay motivated with visual progress indicators

Build lasting habits with the power of AR technology. Download HabitSpace today and transform your daily routine!
```

### Keywords

```
habit tracker, habits, AR, augmented reality, routine, goals, streaks, reminders, productivity, lifestyle, health, wellness, daily habits, habit building, self improvement
```

### Screenshots Required

You need screenshots for:
- **iPhone 6.7"** (iPhone 15 Pro Max) - Required
- **iPhone 6.5"** (iPhone 11 Pro Max) - Required
- **iPhone 5.5"** (iPhone 8 Plus) - Optional
- **iPad Pro 12.9"** - Required if supporting iPad

Screenshot dimensions:
| Device | Portrait | Landscape |
|--------|----------|-----------|
| iPhone 6.7" | 1290 x 2796 | 2796 x 1290 |
| iPhone 6.5" | 1284 x 2778 | 2778 x 1284 |
| iPad Pro 12.9" | 2048 x 2732 | 2732 x 2048 |

### Privacy Policy

You must provide a privacy policy URL. Create one that covers:
- Data collection (habits, location if used)
- Data storage (local Core Data)
- Third-party services (none by default)
- User rights

Free privacy policy generators:
- [TermsFeed](https://www.termsfeed.com/privacy-policy-generator/)
- [FreePrivacyPolicy](https://www.freeprivacypolicy.com/)

### Support URL

Provide a support URL where users can get help. Options:
- GitHub repository issues page
- Personal website contact form
- Email support page

### Age Rating

Based on the app's features, select:
- **Made for Kids**: No
- **Unrestricted Web Access**: No
- **Gambling**: None
- **Violence**: None
- **Sexual Content**: None

Recommended rating: **4+**

---

## Troubleshooting

### Common Build Errors

**"No signing certificate"**
1. Go to Xcode > Settings > Accounts
2. Select your team and click "Download Manual Profiles"
3. Or enable "Automatically manage signing"

**"Provisioning profile doesn't include capability"**
1. Go to Apple Developer Portal
2. Edit your App ID to include required capabilities
3. Regenerate provisioning profiles

**"Missing required icon"**
1. Ensure all icon sizes are present in AppIcon.appiconset
2. Check that filenames match Contents.json exactly

### Common Submission Rejections

**"Missing privacy policy"**
- Add a valid privacy policy URL in App Store Connect

**"Incomplete metadata"**
- Fill in all required fields including screenshots

**"Guideline 4.2 - Minimum Functionality"**
- Ensure the app has sufficient features and works as described

**"Guideline 2.1 - App Completeness"**
- Test thoroughly before submission
- Remove any placeholder content

### AR-Specific Issues

**"ARKit not available"**
- ARKit requires iOS 11+ and A9 chip or later
- Test on a physical device (simulator doesn't support AR)

**"Camera permission denied"**
- Ensure NSCameraUsageDescription is in Info.plist
- The description must clearly explain why camera access is needed

---

## Post-Submission

### Review Timeline

- **Standard Review**: 24-48 hours (typical)
- **Expedited Review**: Request if critical bug fix needed

### After Approval

1. Set release date (immediate or scheduled)
2. Monitor crash reports in App Store Connect
3. Respond to user reviews
4. Plan updates based on feedback

---

## Version Updates

For future updates:

1. Increment version number in Xcode:
   - **MARKETING_VERSION**: User-visible version (e.g., 1.1.0)
   - **CURRENT_PROJECT_VERSION**: Build number (e.g., 2)

2. Create new archive and upload

3. In App Store Connect:
   - Add new version
   - Update "What's New" section
   - Submit for review

---

## Support

If you encounter issues:
- Check [Apple Developer Forums](https://developer.apple.com/forums/)
- Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Contact [Apple Developer Support](https://developer.apple.com/support/)

---

*Last updated: January 2026*
