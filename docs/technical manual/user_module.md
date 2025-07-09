# User Management Module - Technical Manual

## Overview
The User Management module handles all aspects of user identity, authentication, roles, and profiles. It supports role-based access, facial recognition, and profile management for trainees, trainers, HODs, and administrators.

## Architecture
- **Models:**
  - `CustomUser`: Extends Django's user model with email login, roles, gender, phone, ID, address, and facial recognition fields.
  - `TraineeProfile`, `TrainerProfile`, `HODProfile`, `DPAcademicsProfile`: One-to-one profiles for each user role, with role-specific fields (e.g., trainee status, teaching load, department assignment).
- **Views:**
  - REST API endpoints for user CRUD, registration, profile management, and bulk operations.
  - Endpoints for facial image upload and verification.
- **Serializers:**
  - Serializers for user creation, update, detail, and each profile type.

## Key Features & Constraints
- **Role-Based Access:**
  - Users have roles: trainee, trainer, HOD, DP Academics, admin, etc.
  - Role-specific profile models and permissions.
- **Authentication & Registration:**
  - Email-based login, password validation, and email verification.
  - Bulk registration via Excel upload, with email notifications.
- **Facial Recognition:**
  - Users can register a facial image; encoding is stored for attendance and security.
  - Dlib-based face encoding and validation (single face per image enforced).
- **Profile Management:**
  - Each user has a detailed profile with academic, professional, and contact info.
  - Trainee and trainer profiles track status, qualifications, and teaching load.
- **Security:**
  - Password validation, email verification, and role-based permissions.
  - All sensitive operations require authentication.
- **Performance:**
  - Query optimizations and bulk operations for mass registration.

## Integration Points
- **School Management:** Assigns users to departments, programmes, and class groups.
- **Attendance Module:** Uses face encodings for attendance validation.
- **Course Management:** Assigns trainers to courses and enrollments.

## Data Flow
1. **User Registration:** Admins or users register via API or bulk upload.
2. **Profile Completion:** Users complete their profile and upload a facial image.
3. **Role Assignment:** Admins assign roles and link users to departments, class groups, etc.
4. **Authentication:** Users log in with email and password; email verification required.
5. **Integration:** User data is used by other modules for scheduling, attendance, and analytics.

## Error Handling & Logging
- All critical operations are validated before saving.
- Errors are logged with context for debugging.
- User-facing errors are descriptive and actionable.

---
**Last updated:** July 2025
