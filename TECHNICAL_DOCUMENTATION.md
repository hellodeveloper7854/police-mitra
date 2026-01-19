# Police Mitra - Technical Documentation

## Overview
Police Mitra is a community policing application that connects citizens with their local police stations. The application enables citizen registration, service assignment, availability tracking, and feedback collection.

## Project Information
- **Project Name**: Police Mitra (Polismitr)
- **Version**: 1.0.0+3
- **Last Updated**: January 2026

---

## Frontend Tech Stack

### Framework & Language
- **Flutter**: ^3.3.3
  - Cross-platform mobile application framework
  - Supports Android, iOS, and Web
- **Dart SDK**: >=3.3.3 <4.0.0
  - Programming language for Flutter development

### Core Dependencies

#### Navigation & Routing
- **go_router**: ^14.2.0
  - Declarative routing solution for Flutter
  - Handles deep linking and navigation

#### State Management & Data Persistence
- **shared_preferences**: ^2.2.2
  - Local data persistence
  - Stores user session, email, and verification status

#### Networking & API Integration
- **http**: ^1.2.1
  - HTTP requests for REST API integration
  - Handles communication with backend services

#### Utilities
- **intl**: ^0.19.0
  - Internationalization and localization
  - Date/time formatting and number formatting

- **url_launcher**: ^6.2.6
  - Opens URLs in browser/make phone calls
  - Launch external applications

- **share_plus**: ^7.0.0
  - Share content across platforms
  - Content sharing functionality

- **encrypt**: ^5.0.3
  - Encryption utilities
  - Data security and cryptographic operations

#### UI Components
- **cupertino_icons**: ^1.0.6
  - iOS-style icons

### Development Tools
- **flutter_lints**: ^3.0.0
  - Code quality and linting rules

- **flutter_launcher_icons**: ^0.13.1
  - Generate app icons for Android and iOS

- **flutter_native_splash**: ^2.4.0
  - Splash screen configuration

### Assets
- **Images**: assets/images/
  - Logo: assets/images/logo.png

---

## Backend Tech Stack

### Framework & Runtime
- **Node.js**: JavaScript runtime
- **Express.js**: ^5.1.0
  - Web application framework
  - RESTful API server
  - Middleware for routing and request handling

### Database
- **PostgreSQL**: ^8.16.3 (pg - Node.js PostgreSQL client)
  - Relational database management system
  - Connection pooling for efficient database connections
  - Supports complex queries and transactions

### Security & Configuration
- **dotenv**: ^17.2.3
  - Environment variable management
  - Secure credential storage
  - Configuration management

- **cors**: ^2.8.5
  - Cross-Origin Resource Sharing middleware
  - API security and access control

### Development Tools
- **nodemon**: ^3.1.11
  - Auto-restart development server
  - Hot-reload during development

### Backend API Architecture

#### Server Configuration
- **Port**: 3000 (configurable via environment variable)
- **Database Connection Pool**: Maximum 20 concurrent connections
- **Connection Timeout**: 2000ms
- **Idle Timeout**: 30000ms

#### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Health check - Server status |
| GET | `/api/test-connection` | Database connection test |
| GET | `/api/tables` | List all database tables |
| GET | `/api/registrations` | Get all registrations (limit 10) |
| GET | `/api/registrations/:id` | Get registration by ID |
| GET | `/api/registrations/station/:stationName` | Get registrations by police station |
| POST | `/api/registrations` | Create new registration |
| PUT | `/api/registrations` | Update registration details |
| PUT | `/api/registrations/availability` | Update availability status |
| POST | `/api/login` | User authentication |
| POST | `/api/user-credentials` | Create user credentials |
| GET | `/api/assigned-services/:userEmail` | Get assigned services for user |
| PUT | `/api/assigned-services/:serviceId` | Update service status |
| GET | `/api/feedbacks/:policeStation` | Get feedbacks by police station |
| POST | `/api/feedbacks` | Create feedback |
| GET | `/api/availability-logs` | Get availability logs |
| GET | `/api/availability-logs/latest` | Get latest availability log |
| POST | `/api/availability-logs` | Create availability log |
| PUT | `/api/availability-logs/end-time` | Update availability log end time |
| GET | `/api/station-contacts` | Get station contacts |
| GET | `/api/stats` | Get database statistics |

---

## Database Schema

### Database Management System
- **PostgreSQL** (Relational Database)

### Connection Parameters (Environment Variables)
- **DB_HOST**: Database host address
- **DB_PORT**: Database port (default: 5432)
- **DB_NAME**: Database name
- **DB_USER**: Database user
- **DB_PASSWORD**: Database password

### Database Tables

#### 1. **registrations**
Stores citizen registration information
- `id`: Primary key (auto-increment)
- `full_name`: Full name of citizen
- `email`: Email address (unique identifier)
- `mobile_number`: Contact number
- `date_of_birth`: Date of birth
- `gender`: Gender
- `police_station`: Assigned police station
- `occupation`: Occupation
- `participation_area`: Area of participation
- `identity_numbers`: Identity proof details
- `permanent_address`: Permanent address
- `current_address`: Current address
- `qualification`: Educational qualification
- `available_time`: Available time for service
- `blood_group`: Blood group
- `willing_to_work`: Willingness to work
- `verification_status`: Verification status (pending/verified/rejected)
- `registration_date`: Registration timestamp
- `current_availability_status`: Current availability status

#### 2. **user_credentials**
Stores user login credentials
- `email`: Email address (foreign key to registrations)
- `password`: Encrypted password
- `created_at`: Account creation timestamp

#### 3. **assigned_services**
Tracks services assigned to citizens
- `id`: Primary key
- `user_email`: User email (foreign key)
- `service_type`: Type of service
- `status`: Service status (pending/in_progress/completed)
- `assigned_at`: Assignment timestamp
- `completed_at`: Completion timestamp
- `police_station`: Assigning police station

#### 4. **feedbacks**
Collects feedback from citizens
- `id`: Primary key
- `user_email`: User email (foreign key)
- `police_station`: Police station
- `rating`: Rating given
- `comment`: Feedback text
- `submitted_at`: Submission timestamp

#### 5. **availability_logs**
Tracks citizen availability
- `id`: Primary key
- `user_email`: User email (foreign key)
- `police_station`: Police station
- `date`: Date of availability
- `availability_start_time`: Start time
- `end_time`: End time (nullable)
- `created_at`: Log creation timestamp

#### 6. **station_contacts**
Stores police station contact information
- `id`: Primary key
- `police_station`: Police station name
- `contact_number`: Contact number
- `email`: Station email
- `address`: Station address

---

## Deployment Information

### Backend Deployment
- **Production URL**: `https://policemitrabackend.thanepolice.in`
- **API Base Path**: `/api`
- **Full API URL**: `https://policemitrabackend.thanepolice.in/api`
- **Server Environment**: Production (Node.js + Express + PostgreSQL)
- **Deployment Type**: Cloud-hosted backend service

### Frontend Deployment
- **Platform**: Mobile application (Android/iOS)
- **Web Support**: Enabled (kIsWeb support in code)
- **API Integration**: Connects to production backend URL

### API Configuration (lib/services/api_service.dart:8-25)
The application uses a production API endpoint:
```dart
// Production API Base URL
https://policemitrabackend.thanepolice.in/api
```

---

## API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "count": 10
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

---

## Security Features

### Encryption
- **Data Encryption**: Using `encrypt` package for sensitive data
- **Password Security**: Passwords stored in database (backend handling encryption)

### Authentication
- Email/password based authentication
- Session management using SharedPreferences
- Verification status tracking

### API Security
- CORS enabled for cross-origin requests
- Environment-based configuration
- Input sanitization and validation

---

## Development Setup

### Frontend Setup
```bash
# Install Flutter dependencies
flutter pub get

# Run on specific device
flutter run

# Build for release (Android)
flutter build apk

# Build for release (iOS)
flutter build ios
```

### Backend Setup
```bash
# Navigate to backend directory
cd policemitraappbackend

# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start
```

### Environment Configuration
Backend requires `.env` file with:
```
DB_HOST=your_database_host
DB_PORT=your_database_port
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASSWORD=your_database_password
PORT=3000
```

---

## Key Features Implementation

### 1. User Registration Flow
- Frontend: Registration form validation and submission
- Backend: Data storage in `registrations` and `user_credentials` tables
- Database: Relational integrity with email as unique identifier

### 2. Availability Tracking
- Start/Stop availability timer
- Real-time status updates
- Historical availability logs in database

### 3. Service Assignment
- Police can assign services to citizens
- Status tracking (pending → in-progress → completed)
- Email-based user identification

### 4. Feedback System
- Rating and comment collection
- Police station-specific feedback
- Timestamp tracking

---

## File Structure

### Frontend Structure
```
lib/
├── main.dart                 # App entry point
├── screens/                  # Screen widgets
│   ├── other_helplines_screen.dart
│   ├── cyber_security_screen.dart
│   └── settings_screen.dart
├── services/
│   └── api_service.dart     # API integration layer
└── utils/
    └── crypto_helper.dart   # Encryption utilities
```

### Backend Structure
```
policemitraappbackend/
├── server.js                # Main server file (Express + PostgreSQL)
├── package.json             # Backend dependencies
├── .env                     # Environment variables (not in git)
└── node_modules/            # Dependencies
```

---

## Performance Optimizations

### Database
- Connection pooling (max 20 connections)
- Indexed queries for fast lookups
- Efficient query patterns with parameterized queries

### Frontend
- Local caching with SharedPreferences
- Async/await patterns for non-blocking operations
- State management optimization

### API
- RESTful design for scalability
- JSON response format for efficient data transfer
- Error handling middleware

---

## Maintenance & Monitoring

### Logging
- Server console logging for debugging
- Error tracking with try-catch blocks
- Response status code monitoring

### Database Health
- Connection test endpoint: `/api/test-connection`
- Statistics endpoint: `/api/stats`
- Table listing endpoint: `/api/tables`

---


