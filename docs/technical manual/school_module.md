# School Management Module - Technical Manual

## Overview
The School Management module defines and manages the academic structure of the institution, including schools, departments, programmes, class groups, academic years, and terms. It is foundational for all academic and administrative operations.

## Architecture
- **Models:**
  - `School`: Represents the institution, with a single instance enforced. Tracks departments, logo, and key statistics.
  - `Department`: Academic departments under a school, each with a head (HOD) and trainers.
  - `Programme`: Academic programmes under departments, with code, level, and class groups.
  - `ClassGroup`: Represents a cohort of trainees for a specific year and programme.
  - `AcademicYear`: Academic years (e.g., 2024/2025), with active status and linked terms.
  - `Term`: Academic terms (e.g., Term 1, Term 2), with start/end dates and validation for overlaps.
- **Views:**
  - REST API endpoints for CRUD operations on all models.
  - Custom endpoints for retrieving related data (e.g., terms for an academic year).
- **Serializers:**
  - Serializers for each model, supporting detail and list views.

## Key Features & Constraints
- **Single School Instance:**
  - Only one school can exist in the system; deletion is prevented.
- **Department & Programme Structure:**
  - Departments are linked to a school; each has a HOD and trainers.
  - Programmes are unique per department and can have multiple class groups.
- **Class Groups:**
  - Each class group is linked to a programme and year, with a unique name and list of trainees.
- **Academic Calendar:**
  - Academic years and terms are strictly validated for date overlaps and active status.
  - Terms are linked to academic years and have duration and current status properties.
- **Statistics & Aggregation:**
  - Properties for total departments, programmes, class groups, trainees, and trainers at each level.
- **Performance:**
  - Query optimizations with aggregation and indexed fields.
- **Security:**
  - Role-based access enforced at API and query level.
  - All sensitive operations require authentication.

## Integration Points
- **Course Management:** Departments and programmes are used for course mapping and enrollment.
- **User Management:** Assigns HODs, trainers, and trainees to departments, programmes, and class groups.
- **Timetable & Attendance:** Academic years, terms, and class groups are used for scheduling and attendance tracking.

## Data Flow
1. **School/Department Setup:** Admin creates the school, departments, and assigns HODs/trainers.
2. **Programme & Class Group Creation:** Programmes are defined under departments; class groups are created for each cohort.
3. **Academic Calendar:** Academic years and terms are created and managed.
4. **Integration:** Other modules use this structure for course mapping, enrollment, and scheduling.

## Error Handling & Logging
- All critical operations are validated before saving.
- Errors are logged with context for debugging.
- User-facing errors are descriptive and actionable.

---
**Last updated:** July 2025
