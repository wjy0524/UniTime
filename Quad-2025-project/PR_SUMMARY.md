# Pull Request: Add Async Class Support to Timetable

## Branch
`konghwan` → `main`

## Summary
This PR adds support for asynchronous (async) classes in the timetable feature. Students can now add courses that don't have fixed meeting times (like online courses, self-paced labs, etc.) and see them displayed separately in a dedicated "Async" row at the top of their timetable.

## Changes Overview

### 🎯 Core Features
1. **Async Class Toggle** - New toggle in course form to mark classes as async
2. **Async Row Display** - Dedicated row at top of timetable grid for async courses
3. **Smart Filtering** - Async courses excluded from time-based grid slots
4. **Enhanced Course Cards** - Different display for async vs scheduled courses

### 📁 Files Modified

#### `TimeTableCourseModel.swift`
- Added `isAsync: Bool` property to `TimetableCourse` struct
- Updated initializers with default value `isAsync = false`
- Maintains backward compatibility with existing courses

#### `TimetableView.swift`
- Added async row rendering at top of timetable grid
- Async row spans all day columns with horizontal scrolling
- Only appears when async courses exist
- Updated `CourseDetailCard` to show "Async - No fixed schedule" for async classes

#### `TimetableViewModel.swift`
- Modified `getCourses(for:hour:)` to filter out async courses
- Ensures async courses only appear in dedicated async row
- Maintains existing functionality for scheduled courses

#### `CourseFormView.swift`
- Added `isAsyncClass` toggle in "Class Type" section
- Conditionally hides "Class Times" section when async is enabled
- Updated form validation: async classes don't require time slots
- Auto-clears time slots when converting to async

### 📊 Visual Changes

**Before:**
```
Time │ Mon │ Tue │ Wed │ Thu │ Fri
─────┼─────┼─────┼─────┼─────┼─────
7AM  │     │     │     │     │
8AM  │     │     │     │     │
...
```

**After (with async courses):**
```
Time │         Mon - Tue - Wed - Thu - Fri
─────┼──────────────────────────────────────
Async│ [ADV 319] [CS 342] ... (scrollable)
─────┼─────┼─────┼─────┼─────┼─────
7AM  │     │     │     │     │
8AM  │     │     │     │     │
...
```

## User Experience

### Adding an Async Class
1. Tap "+" → "Add Course Manually"
2. Fill in course details
3. Toggle ON "Async Class (No specific time)"
4. Time slots section disappears
5. Tap "Add" → Course appears in async row

### Converting Between Types
- **To Async**: Toggle on → existing times cleared
- **To Scheduled**: Toggle off → add time slots section appears

## Technical Details

### Data Model
```swift
struct TimetableCourse {
    var isAsync: Bool = false  // NEW
    // ... existing properties
}
```

### Filtering Logic
```swift
// Excludes async courses from time-based grid
func getCourses(for day: Int, hour: Int) -> [TimetableCourse] {
    courses.filter { course in
        !course.isAsync && 
        course.times.contains { /* time matching logic */ }
    }
}
```

## Benefits

✅ **Flexibility** - Support for online and self-paced courses  
✅ **Organization** - All courses in one unified view  
✅ **Visual Clarity** - Clear distinction between async and scheduled  
✅ **User-Friendly** - Simple toggle, no complex configuration  
✅ **Backward Compatible** - Existing courses unaffected  

## Testing Recommendations

### Manual Testing
1. ✓ Add an async course without times
2. ✓ Verify async row appears only when needed
3. ✓ Add multiple async courses, test scrolling
4. ✓ Convert scheduled course to async and back
5. ✓ Edit async course details
6. ✓ Delete async course, verify row disappears
7. ✓ Save and reload app, verify persistence
8. ✓ Export/import with async courses

### Edge Cases
- [ ] Empty timetable → no async row
- [ ] Only async courses → async row only
- [ ] Mix of async and scheduled courses
- [ ] Very long course names in async blocks
- [ ] Multiple async courses (5+) scrolling

## Documentation

Comprehensive documentation added:
- `ASYNC_CLASSES_FEATURE.md` - Feature overview and technical details
- `ASYNC_CLASSES_VISUAL_GUIDE.md` - Visual examples and user flows

## Commits

1. `131cad3` - Add async class support to timetable
2. `264580c` - Improve async class UI/UX
3. `022c34f` - Add comprehensive documentation for async classes feature
4. `42ab2ea` - Add visual guide for async classes feature

## Screenshots

Refer to the image provided showing:
- Async row at top with "ADV 319"
- Regular scheduled classes (E S 319) in time slots
- Clean, consistent design matching app aesthetic

## Breaking Changes

None. This is a purely additive feature with backward compatibility.

## Future Enhancements

Potential improvements for future PRs:
- [ ] Assign async courses to specific days (without times)
- [ ] Add deadline/due date tracking
- [ ] Category filters (async only, scheduled only)
- [ ] Async course notifications/reminders
- [ ] Integration with calendar for flexible deadlines

## Checklist

- [x] Code compiles without errors
- [x] Feature works as described
- [x] No breaking changes to existing functionality
- [x] Documentation added
- [x] Backward compatible
- [x] Follows existing code style
- [x] UI matches app design language
- [x] Data persistence works correctly

## Review Notes

Please pay special attention to:
1. Async row layout and scrolling behavior
2. Form validation logic for async vs scheduled courses
3. Data model changes and persistence
4. Visual consistency with rest of timetable

---

**Author**: Kong Hwan Shin  
**Branch**: `konghwan`  
**Target**: `main`  
**Date**: February 7, 2026