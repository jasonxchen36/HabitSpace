# HabitSpace Deployment Checklist

Use this checklist to ensure you've completed all steps for App Store submission.

## Pre-Deployment Setup

- [ ] **Xcode installed** (version 15.0 or later)
- [ ] **Apple Developer Account** active and enrolled ($99/year)
- [ ] **App Store Connect** access verified

## Project Configuration

- [ ] Open `HabitSpace.xcodeproj` in Xcode
- [ ] Update **Bundle Identifier** to your unique ID (e.g., `com.yourname.habitspace`)
- [ ] Select your **Development Team** in Signing & Capabilities
- [ ] Enable **Automatic Signing**
- [ ] Verify all source files compile without errors

## App Icons

- [ ] Create a 1024x1024 app icon design
- [ ] Generate all icon sizes using `./generate_icons.sh icon.png`
- [ ] Verify icons appear in Xcode's asset catalog
- [ ] No transparency in icons (use solid background)

## App Store Connect

- [ ] Register **Bundle ID** in Apple Developer Portal
- [ ] Create **App Record** in App Store Connect
- [ ] Prepare **App Description** (see guide for template)
- [ ] Prepare **Keywords** (100 characters max)
- [ ] Create **Privacy Policy** and host it online
- [ ] Set up **Support URL**

## Screenshots

- [ ] Capture screenshots on iPhone 6.7" (1290 x 2796)
- [ ] Capture screenshots on iPhone 6.5" (1284 x 2778)
- [ ] Capture screenshots on iPad Pro 12.9" (2048 x 2732) - if supporting iPad
- [ ] Minimum 3 screenshots per device size
- [ ] Screenshots show key app features

## Build & Submit

- [ ] Select **Any iOS Device (arm64)** as build target
- [ ] Clean build folder (⇧⌘K)
- [ ] Create **Archive** (Product > Archive)
- [ ] **Validate** archive in Organizer
- [ ] **Upload** to App Store Connect
- [ ] Select build in App Store Connect
- [ ] Fill in all required metadata
- [ ] Submit for **App Review**

## Post-Submission

- [ ] Monitor email for review status updates
- [ ] Respond promptly to any reviewer questions
- [ ] After approval, set release date
- [ ] Announce app launch!

---

## Quick Commands

```bash
# Generate app icons (requires ImageMagick)
./generate_icons.sh your-icon-1024.png

# Open project in Xcode
open HabitSpace.xcodeproj
```

## Important Files

| File | Purpose |
|------|---------|
| `HabitSpace.xcodeproj` | Xcode project file |
| `Info.plist` | App configuration and permissions |
| `HabitSpace.entitlements` | App capabilities |
| `Assets.xcassets/AppIcon.appiconset/` | App icons |
| `APP_STORE_DEPLOYMENT_GUIDE.md` | Detailed deployment guide |

## Estimated Timeline

| Task | Time |
|------|------|
| Project setup | 15 min |
| Icon creation | 30 min |
| App Store Connect setup | 30 min |
| Screenshot capture | 1 hour |
| Metadata preparation | 30 min |
| Build & upload | 15 min |
| **Total** | **~3 hours** |

## Need Help?

- See `APP_STORE_DEPLOYMENT_GUIDE.md` for detailed instructions
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
