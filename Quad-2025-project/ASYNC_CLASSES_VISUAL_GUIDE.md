# Async Classes - Visual Guide

## Feature Overview
This guide shows the visual changes when adding async classes to the timetable.

---

## Before: Traditional Timetable (Time-Based Classes Only)

```
┌──────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Time │   Mon   │   Tue   │   Wed   │   Thu   │   Fri   │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ 7AM  │         │         │         │         │         │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ 8AM  │         │         │         │         │         │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ 9AM  │         │         │         │         │         │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ 10AM │         │         │         │         │         │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ 11AM │         │ ES 319  │         │ ES 319  │         │
│      │         │ 11:00-  │         │ 11:00-  │         │
│      │         │ 12:30PM │         │ 12:30PM │         │
│      │         │ EER 1.5 │         │ EER 1.5 │         │
└──────┴─────────┴─────────┴─────────┴─────────┴─────────┘
```

---

## After: With Async Classes Support

```
┌──────┬─────────────────────────────────────────────────────┐
│ Time │              Mon - Tue - Wed - Thu - Fri            │
├──────┼─────────────────────────────────────────────────────┤
│Async │ ┌─────────┐                                         │
│      │ │ ADV 319 │  ← Scrollable if multiple async courses │
│      │ │Advanced │                                          │
│      │ └─────────┘                                         │
├──────┼─────────┬─────────┬─────────┬─────────┬─────────────┤
│ Time │   Mon   │   Tue   │   Wed   │   Thu   │   Fri     │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────────┤
│ 7AM  │         │         │         │         │           │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────────┤
│ 8AM  │         │         │         │         │           │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────────┤
│ 9AM  │         │         │         │         │           │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────────┤
│ 10AM │         │         │         │         │           │
├──────┼─────────┼─────────┼─────────┼─────────┼─────────────┤
│ 11AM │         │ ES 319  │         │ ES 319  │           │
│      │         │ 11:00-  │         │ 11:00-  │           │
│      │         │ 12:30PM │         │ 12:30PM │           │
│      │         │ EER 1.5 │         │ EER 1.5 │           │
└──────┴─────────┴─────────┴─────────┴─────────┴─────────────┘
```

**Key Points:**
- Async row only appears when async courses exist
- Spans all day columns
- Horizontally scrollable for multiple courses
- Positioned above time-based schedule

---

## Course Form Changes

### Before: All Courses Required Times
```
┌─────────────────────────────────────┐
│ Course Information                  │
│ ┌─────────────────────────────────┐ │
│ │ Course Name: [             ]    │ │
│ │ Course Code: [             ]    │ │
│ │ Instructor:  [             ]    │ │
│ │ Location:    [             ]    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Class Times                         │
│ ┌─────────────────────────────────┐ │
│ │ [+ Add Time Slot]               │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [Cancel]  [Add]             │
└─────────────────────────────────────┘
```

### After: Optional Times for Async Classes
```
┌─────────────────────────────────────┐
│ Course Information                  │
│ ┌─────────────────────────────────┐ │
│ │ Course Name: [             ]    │ │
│ │ Course Code: [             ]    │ │
│ │ Instructor:  [             ]    │ │
│ │ Location:    [             ]    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Class Type                          │
│ ┌─────────────────────────────────┐ │
│ │ ☑ Async Class (No specific time)│ │
│ │                                 │ │
│ │ ℹ This course has no fixed     │ │
│ │   schedule and can be completed│ │
│ │   at any time.                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ⚠️ Class Times section hidden       │
│    when async is enabled            │
│                                     │
│         [Cancel]  [Add]             │
└─────────────────────────────────────┘
```

---

## Course List Display

### Regular Course Card
```
┌─────────────────────────────────────────┐
│ ● ES 319                                │
│                                         │
│ Engineering Science                     │
│                                         │
│ 👤 Dr. Smith                            │
│ 📍 EER 1.508                            │
│                                         │
│ ┌─────┐ 11:00AM - 12:30PM              │
│ │ Tue │                                 │
│ └─────┘                                 │
│ ┌─────┐ 11:00AM - 12:30PM              │
│ │ Thu │                                 │
│ └─────┘                                 │
└─────────────────────────────────────────┘
```

### Async Course Card
```
┌─────────────────────────────────────────┐
│ ● ADV 319                               │
│                                         │
│ Advanced Digital Media                  │
│                                         │
│ 👤 Dr. Johnson                          │
│ 📍 Online                               │
│                                         │
│ 🕐 Async - No fixed schedule           │
│                                         │
└─────────────────────────────────────────┘
```

---

## User Flow

### Adding an Async Class

```
1. Tap "+" button
          ↓
2. Select "Add Course Manually"
          ↓
3. Fill in course details
   - Name: Advanced Digital Media
   - Code: ADV 319
   - Instructor: Dr. Johnson
   - Location: Online
          ↓
4. Toggle ON: "Async Class"
          ↓
5. Notice: Time slots section disappears
          ↓
6. Tap "Add"
          ↓
7. Course appears in async row at top of timetable
```

### Converting Between Async and Scheduled

```
Scheduled → Async:
1. Tap course to edit
2. Toggle ON "Async Class"
3. Existing times are cleared
4. Save changes

Async → Scheduled:
1. Tap async course to edit
2. Toggle OFF "Async Class"
3. Add time slots section appears
4. Add meeting times
5. Save changes
```

---

## Technical Details

### Data Structure

**Before:**
```swift
struct TimetableCourse {
    var id: UUID
    var name: String
    var code: String
    var times: [CourseTime]  // Required, must not be empty
    ...
}
```

**After:**
```swift
struct TimetableCourse {
    var id: UUID
    var name: String
    var code: String
    var times: [CourseTime]  // Can be empty if isAsync
    var isAsync: Bool        // NEW: Indicates async class
    ...
}
```

### Filtering Logic

**Regular Time Slot:**
```swift
// Only shows non-async courses with matching time
func getCourses(for day: Int, hour: Int) -> [TimetableCourse] {
    courses.filter { course in
        !course.isAsync &&  // Exclude async courses
        course.times.contains { time in
            time.day == day && hour == time.startTime / 60
        }
    }
}
```

**Async Row:**
```swift
// Shows all async courses
let asyncCourses = viewModel.courses.filter { $0.isAsync }
```

---

## Benefits

✅ **Flexibility**: Students can add online/async courses to their schedule  
✅ **Organization**: All courses in one place, both scheduled and async  
✅ **Visual Clarity**: Clear distinction between timed and async classes  
✅ **Consistency**: Same editing interface, just with toggle  
✅ **Backward Compatible**: Existing courses work without changes  

---

## Use Cases

### Example 1: Online Course
- Course: ADV 319 (Digital Media)
- Type: Fully online, watch lectures anytime
- Schedule: No fixed meeting times
- Solution: Mark as async

### Example 2: Self-Paced Lab
- Course: CS 342 (Software Lab)
- Type: Complete assignments on your schedule
- Schedule: No class meetings
- Solution: Mark as async

### Example 3: Hybrid Course
- Course: BIO 301 (Biology)
- Type: In-person lectures + async homework
- Schedule: Mon/Wed 10-11am + flexible assignments
- Solution: Keep as scheduled (lectures are timed)

---

## Design Principles

1. **Minimal Disruption**: Async row only appears when needed
2. **Consistent Styling**: Matches existing course block design
3. **Clear Indication**: Easy to identify async vs scheduled
4. **Flexible Layout**: Scrollable for multiple async courses
5. **Intuitive Controls**: Simple toggle to mark as async

---

## Implementation Highlights

### Files Modified
- `TimeTableCourseModel.swift` - Added isAsync property
- `TimetableView.swift` - Added async row rendering
- `TimetableViewModel.swift` - Updated filtering logic
- `CourseFormView.swift` - Added async toggle UI

### Commits
1. Add async class support to timetable
2. Improve async class UI/UX
3. Add comprehensive documentation

### Branch
`konghwan` (feature branch)