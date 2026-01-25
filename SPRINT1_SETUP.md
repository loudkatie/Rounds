# 🚀 Sprint 1 Setup Instructions

## Files to Add to Xcode

The following new files need to be added to the Xcode project:

### Models (add to `Rounds/Models` group):
1. `UserProfile.swift` ✅ Created
2. `AIMemoryContext.swift` ✅ Created

### Services (add to `Rounds/Services` group):
3. `ProfileStore.swift` ✅ Created

### Views/Onboarding (create new group, add file):
4. `OnboardingFlow.swift` ✅ Created

## How to Add in Xcode:

1. Open `Rounds.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), right-click on the `Models` folder
3. Select "Add Files to 'Rounds'..."
4. Navigate to `Rounds/Models/`
5. Select `UserProfile.swift` and `AIMemoryContext.swift`
6. Click "Add"

Repeat for:
- `Services/ProfileStore.swift` 
- Create new group "Onboarding" under Views, add `OnboardingFlow.swift`

## After Adding Files:

Build (Cmd+B) to verify everything compiles.

## What Changed:

### RootView.swift (MODIFIED)
- Now uses `ProfileStore` to check if user has completed onboarding
- Shows `OnboardingFlow` for new users
- Shows `LandingView` for returning users

### New Onboarding Flow:
1. "What's your first name?" 
2. "What's your patient's first name?"
3. "Tell me a bit about [name]'s situation"
→ Profile saved, user proceeds to main app

## Test:

1. Build and run
2. You should see:
   - Splash screen (2 sec)
   - Onboarding flow (3 steps)
   - Main recording screen after completing onboarding

3. Kill and restart app - should skip onboarding and go straight to recording

## To Reset for Testing:

In Xcode console or code, call:
```swift
ProfileStore.shared.resetProfile()
```

Or delete the app from simulator/device to clear UserDefaults.
