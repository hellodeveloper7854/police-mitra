# Quick Start Guide - FCM Implementation

## 🚀 5-Minute Setup

### Step 1: Supabase Database (2 minutes)
Go to Supabase SQL Editor and run:
```sql
ALTER TABLE registrations
ADD COLUMN IF NOT EXISTS fcm_token TEXT;
```

### Step 2: Test the App (2 minutes)
```bash
flutter run
```
Login and check console for: `FCM Token: xxxxx`

### Step 3: Verify Token (1 minute)
Check Supabase registrations table for `fcm_token` column value

## ✅ Done!

Your app is now ready for push notifications!

## 📋 What's Working

- ✅ FCM token generated automatically
- ✅ Token stored in PostgreSQL on login
- ✅ Token stored in Supabase on login
- ✅ Token auto-refreshes and updates both databases
- ✅ Ready to send push notifications

## 🧪 Quick Test

1. Run app on Android device
2. Login with any user
3. Check console: Look for "FCM Token: ..."
4. Copy the token
5. Go to Firebase Console → Cloud Messaging
6. Send test notification with that token

## 📱 Sending Notifications

### Option 1: Firebase Console (Easy)
1. https://console.firebase.google.com
2. Project: hqms-b916a
3. Cloud Messaging → Send message

### Option 2: Backend API (Programmatic)
Use the FCM tokens from your database with Firebase Admin SDK

## 🔧 Files Modified

```
android/app/google-services.json         ← NEW
android/app/build.gradle                 ← Modified
android/settings.gradle                  ← Modified
lib/services/fcm_service.dart            ← NEW
lib/screens/login_screen.dart            ← Modified
lib/main.dart                            ← Modified
pubspec.yaml                             ← Modified
policemitraappbackend/server.js          ← Modified
```

## 📚 Full Documentation

- `IMPLEMENTATION_COMPLETE.md` - Complete summary
- `FCM_IMPLEMENTATION_SUMMARY.md` - Detailed guide
- `FCM_DATA_FLOW.md` - Visual diagrams
- `FIREBASE_ANDROID_SETUP.md` - Android setup

## ❓ FAQ

**Q: Where is the FCM token stored?**
A: In BOTH PostgreSQL and Supabase registrations table, column `fcm_token`

**Q: How do I get the FCM token?**
A: It's automatically generated and logged to console on app startup

**Q: What if the token refreshes?**
A: The app automatically updates both databases with the new token

**Q: Do I need to do anything else?**
A: Just run the SQL script in Supabase and test the app!

## 🎯 You're All Set!

The implementation is complete. Just:
1. Run the SQL in Supabase
2. Test the app
3. Start sending notifications!

---

**Status**: ✅ Ready to Use
**Package**: com.police.stage_policemitr
**Firebase**: hqms-b916a
