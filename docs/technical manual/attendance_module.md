# Attendance Module - Technical Manual

## Overview
The Attendance module is responsible for all aspects of session attendance management, including session lifecycle, trainee check-in, facial recognition, geolocation validation, feedback, and analytics. It is a core backend component of the Smart Roster system.

## Architecture
- **Models:**
  - `AttendanceSession`: Represents a scheduled or active session, linked to a timetable, trainer, class group, and room. Tracks session status, adherence, feedback, and makeup sessions.
  - `AttendanceRecord`: Represents a trainee's attendance for a session, including status, geolocation, facial image, and feedback.
- **Services:**
  - `AttendanceSessionService`: Handles session lifecycle (start, end), makeup slot finding, trainer changes, and notifications. Implements business rules and constraints (timing, geolocation, facial recognition).
  - `AttendanceRecordService`: Handles trainee check-in, feedback, and status updates.
- **Views:**
  - REST API endpoints for session and record management, analytics, and feedback. Implements role-based access control.
- **Serializers:**
  - Multiple serializers for different use cases (basic, detail, create, feedback).

## Key Features & Constraints
- **Session Lifecycle:**
  - Sessions move through `scheduled → active → completed/canceled` states.
  - Only assigned trainers can start/end sessions, with geolocation and facial recognition validation.
  - Strict timing windows for starting/ending sessions (e.g., 15 min before, 30 min after start).
- **Attendance Validation:**
  - Trainees check in with facial image and geolocation; system validates presence and identity.
  - Statuses: `present`, `late`, `absent`, `excused`, `pending`.
  - Absence can be excused with documentation and staff verification.
- **Feedback & Analytics:**
  - Trainees provide session feedback (content, delivery, engagement, overall rating).
  - Aggregated feedback metrics are stored on the session.
  - Analytics endpoints for attendance and feedback statistics.
- **Makeup Sessions:**
  - Missed/canceled sessions can be rescheduled as makeup sessions.
  - System finds available slots, avoiding conflicts, breaks, and room clashes.
- **Performance:**
  - Query optimizations with `select_related`, `prefetch_related`, and caching.
  - Batch operations for notifications and record updates.
- **Security:**
  - Role-based access enforced at API and query level.
  - All sensitive operations require authentication.

## Integration Points
- **Timetable Management:** Links to scheduled sessions and room assignments.
- **User Management:** Trainer and trainee roles, facial encodings.
- **Notifications:** Sends notifications on session events.
- **Reporting:** Feeds analytics and reporting modules.

## Data Flow
1. **Session Creation:** Triggered from timetable or manually for makeup.
2. **Session Start:** Trainer starts session (geolocation/facial validation), status changes to `active`.
3. **Trainee Check-in:** Trainee submits image/location, system validates and updates record.
4. **Session End:** Trainer ends session, system marks absentees, aggregates feedback.
5. **Feedback:** Trainees submit feedback, metrics update on session.

## Error Handling & Logging
- All critical operations are wrapped in transactions.
- Errors are logged with context for debugging.
- User-facing errors are descriptive and actionable.

---
**Last updated:** July 2025
