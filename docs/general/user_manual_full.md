<!-- Company Header: Insert logo, document title, page numbers, and date here when converting to Word -->

# Smart Roster System - Comprehensive User Manual

This document consolidates all user manuals for the Smart Roster backend modules, providing a single, user-friendly reference for administrators, HODs, trainers, and trainees.

---

## Table of Contents
1. Attendance Module
2. Course Management Module
3. School Management Module
4. Timetable Management Module
5. User Management Module
6. Notifications Module
7. Reports & Analytics Module

---

## 1. Attendance Module

[See full details below]

---

# Attendance Module - User Manual

## Overview
The Attendance module allows trainers and trainees to manage and track attendance for all sessions. It supports facial recognition, geolocation validation, feedback, and makeup sessions.

## Key User Workflows

### For Trainers
- **View Upcoming Sessions:**
  - Go to the dashboard or sessions page to see your scheduled sessions.
- **Start a Session:**
  1. Select a scheduled session.
  2. Click 'Start Session'.
  3. Complete facial recognition and allow location access if prompted.
     - *Tip: The system uses your face and location to verify your identity and presence in the correct room. Make sure your face is clearly visible and you are within the geofenced area.*
  4. If successful, the session status changes to 'Active'.
- **End a Session:**
  1. Select the active session.
  2. Click 'End Session'.
  3. Complete facial recognition and location check if required.
     - *Tip: Ending a session too early is not allowed. The system checks that at least 80% of the scheduled time has passed. Absentees are automatically marked.*
  4. Confirm to end. Absentees are automatically marked.
- **Schedule Makeup Session:**
  1. For missed/canceled sessions, click 'Schedule Makeup'.
  2. Review suggested slots and select one.
     - *Tip: The system finds available slots that do not conflict with other sessions, breaks, or room bookings. Only future slots are shown.*
  3. Confirm room and time.
- **View Attendance Analytics:**
  - Access class/session analytics from the dashboard or reports section.
    - *Analytics include attendance rates, punctuality, and session feedback. Use filters to view by course, class group, or date range.*

### For Trainees
- **Check In to Session:**
  1. Go to your dashboard or today's sessions.
  2. Click 'Check In'.
  3. Allow camera and location access.
     - *Tip: The system uses your face and location to verify your attendance. Make sure your face is clearly visible and you are in the correct room.*
  4. Submit your facial image and location.
  5. Receive confirmation of attendance status (present/late).
- **View Attendance History:**
  - Access your attendance records from the dashboard or attendance page.
- **Submit Absence Request:**
  1. For missed sessions, click 'Request Excuse'.
  2. Provide reason and upload documentation if needed.
     - *Tip: Absence requests are reviewed by staff. You will be notified of the outcome.*
  3. Wait for staff verification.
- **Provide Feedback:**
  1. After a session is completed, click 'Give Feedback'.
  2. Rate content, delivery, engagement, and overall experience.
     - *Tip: Feedback is anonymous and helps improve teaching quality. Ratings are aggregated for analytics.*
  3. Optionally add comments.

## Tips & Notes
- Always allow camera and location access for seamless attendance.
- Only the assigned trainer can start/end a session.
- Makeup sessions are only available for missed/canceled classes.
- Feedback is anonymous and helps improve teaching quality.
- *If you have trouble with facial recognition, ensure good lighting and a clear view of your face. For location issues, enable GPS/location services.*

## Troubleshooting
- **Facial Recognition Fails:** Ensure good lighting and face is clearly visible.
- **Location Not Detected:** Enable GPS/location services on your device.
- **Cannot Start/End Session:** Check if you are the assigned trainer and within the allowed time window.
- **Makeup Slot Not Available:** Try checking for slots in the following week or adjust your filters.

---

## 2. Course Management Module

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

## 3. School Management Module

# School Management Module - User Manual

## Overview
The School Management module allows administrators to define and manage the academic structure, including schools, departments, programmes, class groups, academic years, and terms. This structure is used throughout the system for enrollment, scheduling, and reporting.

## Structure Elements
- **School:** The top-level entity; only one per system.
- **Department:** Academic divisions within the school, each led by an HOD.
- **Programme:** Courses of study (e.g., BSc, Diploma) assigned to departments.
- **Class Group:** Cohorts of trainees within a programme and year.
- **Academic Year/Term:** Defines the academic calendar and term periods.

## Key User Workflows

### For Administrators
- **Create/Edit School:**
  1. Go to the School section.
  2. Add or edit the school name, description, and logo.
     - *Tip: Only one school can exist; deletion is not allowed. Edit details as needed for rebranding.*
  3. Only one school can exist; deletion is not allowed.
- **Add Department:**
  1. Go to Departments.
  2. Click 'Add Department'.
  3. Enter department name, assign HOD, and select trainers.
     - *Tip: Assigning an HOD is required. Trainers can belong to multiple departments if needed.*
  4. Save to create the department.
- **Add Programme:**
  1. Go to Programmes.
  2. Click 'Add Programme'.
  3. Enter programme name, code, level, and assign to a department.
     - *Tip: Programme codes must be unique. Assign to the correct department for accurate reporting.*
  4. Save to create the programme.
- **Create Class Group:**
  1. Go to Class Groups.
  2. Click 'Add Class Group'.
  3. Select programme, year, and add trainees.
     - *Tip: Each class group must have a unique name. Trainees can only belong to one class group per year.*
  4. Enter a unique name for the class group.
  5. Save to create the class group.
- **Manage Academic Years & Terms:**
  1. Go to Academic Years.
  2. Add a new year (e.g., 2025/2026).
  3. For each year, add terms with start/end dates.
     - *Tip: Ensure term dates do not overlap. Use the calendar view for easier management.*
  4. Ensure term dates do not overlap.

### For HODs
- **View Department Structure:**
  - Access department, programme, and class group details from the dashboard.
  - *Tip: Use this view to monitor trainer assignments and class group distribution.*
- **Assign Trainers:**
  - Add or remove trainers from the department as needed.
  - *Tip: Ensure trainers have the correct department and teaching load.*

### For Trainers & Trainees
- **View Assignments:**
  - Trainers can view their department and assigned class groups.
  - Trainees can view their class group and programme details.
  - *Tip: This helps users understand their academic context and responsibilities.*

## Tips & Notes
- Only admins can create or edit the school, departments, and academic calendar.
- Each class group must have a unique name.
- Academic years and terms must not overlap.
- Programme and department assignments affect course mapping and scheduling.
- Use the dashboard for a quick overview of the academic structure.

## Troubleshooting
- **Cannot Add School:** Only one school is allowed in the system.
- **Term Date Error:** Ensure term dates do not overlap within the same academic year.
- **Class Group Name Error:** Each class group must have a unique name.
- **Programme Not Visible:** Check department assignment and permissions.
- **Trainer Not Assignable:** Ensure the trainer is registered and not already overloaded.

---

## 4. Timetable Management Module

# Timetable Management Module - User Manual

## Overview
The Timetable Management module allows administrators, HODs, trainers, and trainees to view, manage, and interact with class schedules, room bookings, and trainer availabilities. It ensures conflict-free scheduling and easy access to all timetables.

## Session Types
- **Lecture:** Standard classroom session.
- **Lab:** Practical or hands-on session in a lab environment.
- **Seminar/Workshop:** Special sessions for group activities or guest lectures.
- **Online:** Remote or hybrid sessions (if enabled).

## Key User Workflows

### For Administrators/HODs
- **Add/Edit Room:**
  1. Go to the Rooms section.
  2. Click 'Add Room' or select a room to edit.
  3. Enter room details (name, type, capacity, facilities, geolocation, maintenance).
     - *Tip: Use geolocation for accurate attendance validation and to prevent double-booking.*
  4. Save to create or update the room.
- **Set Trainer Availability:**
  1. Go to Trainer Availabilities.
  2. Select a trainer and add available days/times.
     - *Tip: Accurate availability helps prevent scheduling conflicts and overloads.*
  3. Save to update availability.
- **Create/Edit Timetable:**
  1. Go to the Timetable section.
  2. Click 'Add Session' or select a session to edit.
  3. Select course enrollment, day, time, room, and session type.
     - *Tip: Use draft mode to plan sessions before publishing. The system checks for conflicts in real time.*
  4. Save to schedule the session; system checks for conflicts.
  5. Use draft mode for planning before publishing.
- **Resolve Conflicts:**
  - If a conflict is detected, review suggested alternative rooms, times, or days.
  - *Tip: The system highlights conflicts and suggests the best available options.*
- **Publish Timetable:**
  - Finalize and publish the timetable for access by all users.
  - *Tip: Only published timetables are visible to trainers and trainees. Drafts are private to admins/HODs.*

### For Trainers
- **View My Schedule:**
  - Go to the Timetable or My Sessions section to see your upcoming classes.
  - *Tip: Check your schedule regularly for updates or changes.*
- **Set Availability:**
  - Update your available days/times for scheduling.

### For Trainees
- **View Class Group Schedule:**
  - Go to the Timetable or My Schedule section to see your class group's sessions.
  - *Tip: Use the calendar view for a quick overview of your week.*

## Tips & Notes
- Only admins and HODs can create or edit rooms, availabilities, and timetables.
- All sessions are validated for conflicts before saving.
- Use draft mode to plan timetables before publishing.
- Room geolocation is used for attendance validation.
- Session types help allocate the right resources and facilities.
- Trainers and trainees receive notifications for timetable changes.

## Troubleshooting
- **Scheduling Conflict:**
  - Review the error message and suggested alternatives.
  - Check trainer and room availability.
- **Room Not Available:**
  - Check maintenance schedule and booking limits.
  - Try selecting a different room or time slot.
- **Trainer/Class Group Conflict:**
  - Ensure no overlapping sessions for the same trainer or class group.
  - Update availabilities if needed.
- **Draft Not Visible:**
  - Only published timetables are visible to trainers and trainees.
- **Session Not Saving:**
  - Ensure all required fields are filled and there are no conflicts.

---

## 5. User Management Module

# User Management Module - User Manual

## Overview
The User Management module allows administrators and users to manage user accounts, roles, and profiles. It supports registration, profile completion, facial image upload, and bulk user operations.

## User Roles
- **Trainee:** Student enrolled in a programme/class group.
- **Trainer:** Instructor assigned to courses and class groups.
- **HOD:** Head of Department, manages department structure and trainers.
- **Administrator:** Full system access for user and system management.

## Key User Workflows

### For Administrators
- **Register a New User:**
  1. Go to the Users section.
  2. Click 'Add User'.
  3. Enter user details (email, name, role, etc.).
  4. Assign to department, class group, or programme as needed.
     - *Tip: Assigning users to the correct department/class group ensures accurate scheduling and reporting.*
  5. Save to create the user; an email verification is sent.
- **Bulk User Registration:**
  1. Download the Excel template from the Users section.
  2. Fill in user details for multiple users.
     - *Tip: Follow the template instructions for required columns and formats. Each row is a user.*
  3. Upload the completed file to register users in bulk.
  4. Users receive email invitations to complete registration.
- **Assign Roles & Profiles:**
  1. Edit a user to assign or change their role (trainee, trainer, HOD, etc.).
     - *Tip: Only one primary role per user is allowed, but users can have multiple assignments (e.g., trainer in multiple departments).* 
  2. Complete or update profile details as needed.
- **Manage Facial Recognition:**
  1. For each user, upload a clear facial image.
     - *Tip: Use a recent, well-lit photo with only one face visible. This is required for attendance and security.*
  2. The system processes and stores the face encoding for attendance and security.

### For Users (Trainees, Trainers, HODs, etc.)
- **Complete Profile:**
  1. Log in with your email and password.
  2. Complete your profile details (personal info, academic/professional info).
  3. Upload a clear facial image for attendance verification.
     - *Tip: You cannot mark attendance without a valid facial image on file.*
- **Update Profile:**
  - Edit your profile at any time to update contact info, qualifications, or facial image.
- **Password Reset:**
  - Use the 'Forgot Password' link to reset your password via email.
  - *Tip: Check your spam folder if you do not receive the reset email.*

## Tips & Notes
- Only admins can add or edit users and assign roles.
- Each user must have a unique email address.
- Upload a clear, single-face image for facial recognition.
- Users must verify their email before accessing the system.
- Bulk operations save time for large user groups; review feedback for errors after upload.
- Profile completeness may be required for access to certain features.

## Troubleshooting
- **Cannot Add User:**
  - Ensure the email is unique and all required fields are filled.
  - Check for typos in email addresses.
- **Bulk Upload Error:**
  - Check the Excel file format and required columns.
  - Review error messages for specific row issues.
- **Facial Image Error:**
  - Upload a clear image with only one face visible.
  - Avoid group photos or low-light images.
- **Email Verification Not Received:**
  - Check your spam/junk folder.
  - Contact your admin if the problem persists.
- **Cannot Change Role:**
  - Only admins can change user roles. Contact your admin for assistance.

---

## 6. Notifications Module

# Notifications Module - User Manual

## Overview
The Notifications module keeps users informed about important events, updates, and actions in the system. Notifications can be received in-app, by email, or as push notifications, depending on user preferences.

## Notification Types
- **Attendance Alerts:** Session start/end, absences, late arrivals.
- **Timetable Updates:** Schedule changes, room changes, cancellations.
- **Account & Security:** Password changes, login alerts, profile updates.
- **Reports & Analytics:** New reports available, scheduled report delivery.
- **System Announcements:** Maintenance, new features, policy updates.

## Key User Workflows

### For All Users
- **View Notifications:**
  - Go to the Notifications section or dashboard to see your latest notifications.
  - Unread notifications are highlighted.
  - Click a notification to view details or linked actions (e.g., view report, confirm attendance).
- **Mark as Read/Unread:**
  - Click on a notification to mark it as read.
  - You can mark notifications as unread for follow-up.
- **Delete Notifications:**
  - Remove notifications you no longer need.
- **Set Notification Preferences:**
  1. Go to Notification Settings.
  2. Choose which types of notifications you want to receive (attendance, reports, account, etc.).
  3. Select delivery channels: in-app, email, push.
  4. Save your preferences.
  - *Tip:* You can enable Do Not Disturb for specific hours.

### For Administrators
- **Send Broadcast Notification:**
  1. Go to the Broadcast Notifications section.
  2. Enter the message, select recipients (all users, by role, department, etc.).
  3. Choose notification type and priority.
  4. Send the notification; all targeted users will receive it.
  - *Tip:* Use high priority for urgent system-wide alerts.

## Tips & Notes
- You can control which notifications you receive and how you receive them.
- Important system and account notifications may be mandatory and cannot be disabled.
- Check your notification settings regularly to stay updated.
- Push notifications require enabling permissions in your browser or device.
- Email notifications may go to spam—add the system email to your contacts.
- In-app notifications are always available in the dashboard.

## Troubleshooting
- **Not Receiving Notifications:**
  - Check your preferences and ensure your email is correct.
  - Verify that push/browser permissions are enabled.
  - Check your spam/junk folder for emails.
- **Too Many Notifications:**
  - Adjust your preferences to limit types or channels.
  - Use Do Not Disturb to mute non-urgent notifications during certain hours.
- **Broadcast Not Delivered:**
  - Ensure you have the correct permissions and recipient selection.
  - Check system logs or contact support if the issue persists.
- **Notification Links Not Working:**
  - Ensure you are logged in and have access to the linked resource.

---

## 7. Reports & Analytics Module

# Reports & Analytics Module - User Manual

## Overview
The Reports & Analytics module provides users with access to attendance, performance, and operational reports at all levels. Reports can be viewed online, exported, and are delivered automatically or on demand.

## Report Types
- **Attendance Reports:** Session-wise, course-wise, trainee-wise attendance summaries and trends.
- **Performance Reports:** Grades, assessments, and progress analytics for courses and trainees.
- **Operational Reports:** Resource usage, scheduling efficiency, and system activity.
- **Custom Reports:** User-defined reports based on selected filters and criteria.

## Key User Workflows

### For Administrators/HODs
- **View Reports:**
  1. Go to the Reports section.
  2. Select the report type (course, class group, department, school, etc.).
  3. Filter by date, entity, or other criteria.
     - *Tip: Use multiple filters to narrow down results for specific analysis (e.g., by term, trainer, or attendance threshold).* 
  4. View detailed metrics and analytics.
- **Export Reports:**
  1. In any report, click 'Export'.
  2. Choose format: PDF, Excel, CSV, or JSON.
     - *Tip: Use Excel or CSV for further data analysis; PDF for sharing with stakeholders.*
  3. Download or share the exported file.
- **Schedule Reports:**
  1. Set up scheduled reports for regular delivery (daily, weekly, monthly).
  2. Choose recipients and delivery method (in-app, email, etc.).
     - *Tip: Scheduled reports are useful for recurring meetings or compliance requirements.*
- **Receive Notifications:**
  - Get notified when new reports are available or scheduled reports are delivered.
  - *Tip: Check your notification preferences to ensure you receive report alerts.*

### For Trainers
- **View My Course/Performance Reports:**
  - Access your teaching and attendance reports from the dashboard or Reports section.
  - *Tip: Use these reports to identify attendance issues or performance trends among trainees.*
- **Export/Share Reports:**
  - Export your reports for record-keeping or sharing with management.

### For Trainees
- **View My Attendance Reports:**
  - Go to the Reports section to see your attendance and performance reports.
  - *Tip: Regularly review your reports to track your progress and attendance.*
- **Download Reports:**
  - Export your reports for personal records or academic requirements.

## Tips & Notes
- Use filters to customize reports for specific periods, courses, or groups.
- Scheduled reports help automate regular reporting needs.
- Exported reports can be shared with stakeholders as needed.
- Some reports may require specific permissions; contact your admin if access is restricted.
- Reports are updated in real-time or at scheduled intervals, depending on the type.

## Troubleshooting
- **Report Not Found:**
  - Check your filters and permissions.
  - Try resetting filters to default settings.
- **Export Error:**
  - Ensure you have selected a valid format and have the necessary permissions.
  - Check your internet connection if download fails.
- **No Notification:**
  - Check your notification preferences and email address.
  - Verify that the report is scheduled for delivery.
- **Data Missing or Outdated:**
  - Some reports update periodically; check the last updated timestamp.
  - Contact support if data discrepancies persist.

---
**Last updated:** July 2025

<!-- Company Footer: Insert company info, page numbers, and date here when converting to Word -->
