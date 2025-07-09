# Course Management Module - Technical Manual

## Overview
The Course Management module handles the definition, structure, and administration of all courses, topics, subtopics, and their mapping to programmes, terms, and class groups. It is central to curriculum management and academic planning.

## Architecture
- **Models:**
  - `Course`: Defines a course, its code, department, description, prerequisites, session structure, and links to programmes.
  - `Topic` & `Subtopic`: Hierarchical structure for course content, with ordering and duration.
  - `ProgrammeCourseMapping`: Maps courses to programmes, terms, years, and room types (theory/practical).
  - `Enrollment`: Connects class groups to courses for a specific academic year and term, assigns trainers, and tracks status.
- **Views:**
  - REST API endpoints for CRUD operations on courses, topics, mappings, and enrollments.
  - Custom endpoints for prerequisite trees, attendance statistics, and mass registration templates.
- **Serializers:**
  - Multiple serializers for different use cases (basic, detail, create, update).

## Key Features & Constraints
- **Course Structure:**
  - Courses can have prerequisites (with circular dependency checks).
  - Each course can have multiple topics and subtopics, with enforced ordering and duration validation.
  - Courses are mapped to programmes, terms, and years, supporting flexible curriculum design.
- **Enrollment Management:**
  - Enrollments link class groups to courses, assign trainers, and track status (scheduled, in progress, completed, cancelled).
  - Validation ensures only valid curriculum mappings and trainer availability.
- **Room & Resource Mapping:**
  - Each course-programme mapping specifies required room types for theory and practical sessions.
- **Attendance Analytics:**
  - Attendance rates are calculated per course and enrollment, integrating with the attendance module.
- **Bulk Operations:**
  - Supports mass course registration via Excel templates and bulk upload endpoints.
- **Performance:**
  - Query optimizations with `select_related`, `prefetch_related`, and indexed fields.
- **Security:**
  - Role-based access enforced at API and query level.
  - All sensitive operations require authentication.

## Integration Points
- **School Management:** Links to departments, programmes, class groups, and academic years.
- **User Management:** Assigns trainers and tracks trainee enrollments.
- **Attendance Module:** Feeds course and enrollment data for attendance tracking and analytics.
- **Timetable Management:** Used for scheduling sessions based on enrollments and mappings.

## Data Flow
1. **Course Definition:** Admins define courses, topics, and subtopics.
2. **Curriculum Mapping:** Courses are mapped to programmes, terms, and years.
3. **Enrollment:** Class groups are enrolled in courses for a term/year, trainers are assigned.
4. **Session Scheduling:** Timetable and attendance modules use enrollments to schedule sessions.
5. **Analytics:** Attendance and performance data are aggregated per course and enrollment.

## Error Handling & Logging
- All critical operations are validated before saving.
- Errors are logged with context for debugging.
- User-facing errors are descriptive and actionable.

---
**Last updated:** July 2025
