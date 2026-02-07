# Async Classes Feature

## Overview
This feature allows users to add asynchronous (async) classes to their timetable. Async classes are courses that don't have fixed meeting times and can be completed on the student's own schedule.

## What's New

### 1. Async Class Toggle in Course Form
When adding or editing a course, users can now toggle "Async Class (No specific time)" to mark it as an async course.

**Key behaviors:**
- When async toggle is enabled, the time slots section is hidden
- Async classes don't require any meeting times to be added
- Users can still specify course name, code, instructor, location, and color

### 2. Async Row in Timetable Grid
When there are async classes in the timetable, a special "Async" row appears at the top of the grid.

**Features:**
- Only appears when at least one async course exists
- Spans across all day columns (Mon-Fri)
- Shows async courses as horizontal scrollable blocks
- Each course block displays course code and name
- Clicking on an async course opens it for editing
- Consistent styling with regular course blocks

### 3. Enhanced Course List Display
In the "Enrolled Courses" section below the timetable grid:
- Async courses show "Async - No fixed schedule" with a clock icon
- Regular courses continue to show their time slots as before

## Technical Implementation

### Model Changes (`TimeTableCourseModel.swift`)
- Added `isAsync: Bool` property to `TimetableCourse` struct
- Default value is `false` for backward compatibility
- Updated all initializers and factory methods

### View Changes (`TimetableView.swift`)
- Added async row rendering in `timetableGrid` view
- Async courses displayed with horizontal scrolling
- Positioned at top of grid, above time-based rows
- Filtered out from regular time slots

### ViewModel Changes (`TimetableViewModel.swift`)
- Updated `getCourses(for:hour:)` to exclude async courses from time-based grid
- Async courses are only shown in the dedicated async row

### Form Changes (`CourseFormView.swift`)
- Added `isAsyncClass` state variable
- Toggle control in "Class Type" section
- Conditional rendering of time slots section
- Updated form validation: async classes don't require times
- Persists async flag when saving courses

## User Experience

### Adding an Async Class
1. Tap "+" button in timetable header
2. Select "Add Course Manually"
3. Fill in course information (name, code, etc.)
4. Toggle ON "Async Class (No specific time)"
5. Notice that "Class Times" section disappears
6. Tap "Add" to save

### Viewing Async Classes
- Async classes appear in the "Async" row at the top of the timetable
- They're also listed in "Enrolled Courses" with an "Async" indicator
- Can scroll horizontally if multiple async courses exist

### Editing Async Classes
- Tap on an async course block (in async row or course list)
- Edit details as needed
- Toggle async setting on/off to convert between async and scheduled classes

## Design Consistency
The async class feature maintains visual consistency with the rest of the app:
- Uses the same color scheme as regular courses
- Course blocks have similar styling and rounded corners
- Follows the existing timetable grid layout pattern
- Integrates seamlessly with share and export features

## Data Persistence
- Async flag is saved in UserDefaults along with other course data
- Backward compatible: existing courses default to `isAsync = false`
- Works with JSON and CSV import/export (async flag included)

## Branch Information
This feature was developed on the `konghwan` branch.

## Future Enhancements
Potential improvements for future iterations:
- Allow async courses to be assigned to specific days (without times)
- Add deadline/due date tracking for async courses
- Separate async courses by category or subject
- Filter view to show only async or only scheduled courses