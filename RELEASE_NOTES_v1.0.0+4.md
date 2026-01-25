# Police Mitra App - Release Notes v1.0.0+4

**Release Date**: January 25, 2026
**Version**: 1.0.0+4
**Build Number**: 4

---

## 🚀 Overview

This release includes critical bug fixes, new features, and improvements to enhance the user experience and system reliability.

---

## ✨ New Features

### 1. Password Reset Functionality
- **Forgot Password**: Users can now reset their password from the login screen
  - Email-based password reset
  - New password with strength validation
  - Real-time password strength indicators (min 8 chars, uppercase, lowercase, special char)
- **Settings Password Reset**: Authenticated users can change their password from settings
  - Requires current password verification
  - Same strength validation applied
- **Backend Integration**: New API endpoint `PUT /api/user-credentials/reset-password`

### 2. All Police Stations Contact Directory
- **Complete Directory**: View contacts for ALL police stations (not just assigned station)
- **Grouped Display**: Contacts organized by station name
- **Alphabetical Order**: Stations sorted alphabetically for easy navigation
- **Direct Access**: One-tap calling to police officers
- **Backend Enhancement**: Updated `/api/station-mobile-contacts` endpoint

---

## 🐛 Bug Fixes

### 1. Availability Status Display Issue
- **Problem**: Frontend showed "Not Available" even when backend had status as "available"
- **Root Cause**:
  - Backend `/api/registrations` endpoint was not selecting `current_availability_status` column
  - Dashboard required both status check AND active availability log
- **Solution**:
  - Added `current_availability_status` to backend SELECT query
  - Updated frontend to handle data inconsistencies gracefully
  - Shows "Available" even if log is missing (displays "Active" without timer)
- **Files Modified**:
  - `policemitraappbackend/server.js` (line 97)
  - `lib/screens/dashboard_screen.dart`

### 2. User Registration Not Found Error
- **Problem**: `getUserRegistration()` returned null for existing users (test@gmail.com)
- **Root Cause**:
  - Backend endpoint `/api/registrations` had `LIMIT 10` constraint
  - Didn't handle email query parameter properly
  - User not in latest 10 registrations couldn't be found
- **Solution**:
  - Created new mobile-specific endpoint: `/api/mobileregistrations`
  - Handles email parameter filtering at database level
  - No LIMIT when searching by specific email
  - Returns all user fields including availability status
- **Files Modified**:
  - `policemitraappbackend/server.js` (new endpoint)
  - `lib/services/api_service.dart`

### 3. Station Contacts Not Displaying
- **Problem**: Contact Police screen showed "No station contacts available"
- **Root Cause**: Endpoint mismatch
  - Frontend called: `/api/station-mobile-contacts`
  - Backend only had: `/api/station-contacts`
- **Solution**: Added new backend endpoint `/api/station-mobile-contacts`
- **Files Modified**:
  - `policemitraappbackend/server.js`
  - `lib/services/api_service.dart`

### 4. JSON Parsing Type Casting Error
- **Problem**: `TypeError: Instance of '_JsonMap': type '_JsonMap' is not a subtype of type 'List<dynamic>'`
- **Root Cause**: Frontend assumed response would always be wrapped object, but backend sometimes returned direct array
- **Solution**: Updated `getUserRegistration()` to handle both response formats
  - Format 1: `{ success: true, data: [...] }`
  - Format 2: `[...]` (direct array)
- **Files Modified**:
  - `lib/services/api_service.dart` (line 239-302)

---

## 🔧 Technical Improvements

### Backend Changes

#### 1. New Endpoints
```javascript
// Password Reset
PUT /api/user-credentials/reset-password
Body: { email, newPassword }

// Mobile User Registration
GET /api/mobileregistrations?email={email}

// Station Mobile Contacts
GET /api/station-mobile-contacts
```

#### 2. Enhanced Queries
- Added `current_availability_status` to registration queries
- Email filtering in mobile registrations endpoint
- Optimized station contacts query (ORDER BY police_station ASC)

### Frontend Changes

#### 1. New API Methods
```dart
// Password Reset
static Future<Map<String, dynamic>?> resetPassword(String email, String newPassword)

// Station Contacts (updated)
static Future<List<dynamic>> getStationContacts()
```

#### 2. Enhanced Error Handling
- Robust JSON parsing (handles Map and List responses)
- Graceful handling of missing availability logs
- Comprehensive debug logging with emoji markers
- Better type safety with runtime checks

#### 3. UI Improvements
- Password strength indicators in reset screens
- Success/error feedback with colored SnackBars
- Grouped station contacts display
- User-friendly error messages

---

## 📱 API Endpoints Reference

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/login` | User authentication |
| PUT | `/api/user-credentials/reset-password` | Reset password |
| GET | `/api/mobileregistrations?email=X` | Get user by email (mobile) |
| GET | `/api/station-mobile-contacts` | Get all station contacts |
| PUT | `/api/registrations/availability` | Update availability status |
| POST | `/api/availability-logs` | Create availability log |
| PUT | `/api/availability-logs/end-time` | End availability session |

---

## 🔄 Database Changes

### Tables Referenced
- `user_credentials` - Password updates
- `registrations` - User data, availability status
- `station_contacts` - Police station contact directory
- `availability_logs` - User availability tracking

---

## 📝 Testing Checklist

- [x] Password reset from login screen
- [x] Password reset from settings
- [x] Availability status displays correctly
- [x] User registration retrieval by email
- [x] All station contacts display
- [x] JSON parsing for different response formats
- [x] Error handling and user feedback

---

## 🚦 Known Issues

None at this time.

---

## 📅 Upcoming Features (Roadmap)

1. **Email Verification**: Send reset code via email for password reset
2. **Session Management**: Implement JWT tokens for better security
3. **Password Hashing**: Add bcrypt/hashing for secure password storage
4. **Push Notifications**: Notify users of new service assignments
5. **Offline Mode**: Cache data for offline access

---

## 📞 Support

For issues or questions, contact:
- **Backend**: https://policemitrabackend.thanepolice.in
- **Database**: PostgreSQL
- **API Base URL**: https://policemitrabackend.thanepolice.in/api

---

## 🏷️ Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0+4 | Jan 25, 2026 | Password reset, bug fixes, station contacts |
| 1.0.0+3 | - | Previous release |
| 1.0.0+2 | - | Initial release |

---

**Built with ❤️ for Thane Police**
Flutter App - Police Mitra
