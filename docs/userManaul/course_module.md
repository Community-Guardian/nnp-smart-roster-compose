# Course Management Module - User Manual

## Overview
The Course Management module allows administrators, HODs, trainers, and trainees to view, manage, and interact with courses, topics, and enrollments. It supports curriculum planning, enrollment, and analytics.

## Key User Workflows

### For Administrators/HODs
- **Add a New Course:**
  1. Go to the Courses section.
  2. Click 'Add Course'.
  3. Enter course details (name, code, department, description, prerequisites, session structure).
     - *Tip: Prerequisites are other courses that must be completed before this one. You can select multiple prerequisites if needed. The system prevents circular dependencies.*
  4. Save to create the course.
- **Define Topics/Subtopics:**
  1. Select a course.
  2. Go to the Topics tab.
  3. Add topics and subtopics, specifying order and duration.
     - *Tip: Topics are the main units of study within a course. Subtopics break down topics into smaller lessons. The order determines the sequence in which they are taught.*
- **Map Course to Programme:**
  1. Go to Programme Mappings.
  2. Select programme, term, year, and course.
     - *Tip: This links the course to a specific programme and academic period, ensuring only valid courses are scheduled for each group.*
  3. Specify room types and credit hours.
     - *Room types (e.g., lab, lecture hall) ensure the right facilities are used. Credit hours reflect the course's weight in the curriculum.*
  4. Save mapping.
- **Enroll Class Group:**
  1. Go to Enrollments.
  2. Select class group, course, academic year, and term.
     - *Tip: A class group is a cohort of students in a programme and year. Enrollment links them to a course for a specific term.*
  3. Assign a trainer.
     - *Only trainers from the relevant department and with available teaching hours can be assigned. The system checks for conflicts and overloads.*
  4. Save enrollment.
- **Bulk Course Registration:**
  1. Download the Excel template from the Courses section.
  2. Fill in course details and topics.
     - *Tip: Each row represents a course. Topics can be entered as JSON or in a structured format as per the template instructions.*
  3. Upload the completed file to register multiple courses at once.
     - *The system validates all entries and provides feedback on errors for correction.*
- **View Analytics:**
  - Access course and enrollment analytics from the dashboard or reports section.
    - *Analytics include attendance rates, enrollment numbers, and performance trends. You can filter by course, class group, or term for detailed insights.*

### For Trainers
- **View Assigned Courses:**
  - Go to the Courses section to see courses you are teaching.
- **View Topics & Content:**
  - Select a course to view its topics and subtopics.
- **View Enrollment Details:**
  - See which class groups and trainees are enrolled in your courses.
  - *Tip: This helps trainers plan lessons and monitor student progress.*

### For Trainees
- **View Enrolled Courses:**
  - Go to the Courses section to see your current courses.
- **View Course Content:**
  - Select a course to view topics, subtopics, and descriptions.
  - *Tip: Reviewing course content helps you prepare for upcoming lessons and assessments.*

## Tips & Notes
- Only admins and HODs can add or edit courses and mappings.
- Prerequisites are enforced; you cannot enroll in a course without completing required prerequisites.
- Use the analytics section to monitor attendance and performance per course.
- *If you encounter errors during enrollment or registration, check that all mappings and prerequisites are correctly set up.*

## Troubleshooting
- **Cannot Add Course:** Ensure all required fields are filled and the course code is unique.
- **Enrollment Validation Error:** Check that the course is mapped to the programme, term, and year.
- **Trainer Assignment Error:** Ensure the trainer belongs to the correct department and has available teaching hours.
- **Bulk Registration Error:** Review the Excel template instructions and correct any highlighted errors before re-uploading.

---
**Last updated:** July 2025
