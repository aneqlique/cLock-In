# Recent Updates - Social Timeline & Task Filtering

## Changes Made (November 1, 2025)

### 🔧 Bug Fixes

#### 1. Fixed Like Toggle Error (500)
**File:** `backend/controllers/postController.js`
- Added `mongoose` import at the top
- Fixed `toggleLike` function to properly handle ObjectId conversion
- Added initialization check for `likedBy` array

**Issue:** Like button was throwing 500 error
**Solution:** Properly imported mongoose and used `new mongoose.Types.ObjectId(userId)` instead of inline require

---

### 🎨 UI Improvements

#### 2. Timeline Screen Layout
**File:** `mobile/lib/presentation/screens/diary/diarytl_screen.dart`

**Changes:**
- Moved logo to be inline with AppBar (same row)
- Removed vertical spacing between posts (changed from 8 to 0)
- Changed border style: removed top border, kept only bottom border (0.5px between posts, 1px for last post)
- Background color: Changed to `Color(0xFFEAE6E0)` with `Color(0xFF898989)` borders

**Result:** Cleaner, more compact timeline feed with better visual separation

---

### 📅 Task List Date Filtering

#### 3. Show Only Today's Completed Tasks
**Files:** 
- `backend/models/Task.js` - Added `completedAt` field
- `backend/controllers/taskController.js` - Set `completedAt` when status changes to completed
- `mobile/lib/presentation/screens/home/task_list_view.dart` - Complete filtering overhaul

**New Features:**

**a) Default View - Today's Tasks Only**
- Task list now shows ONLY tasks completed today by default
- Uses `completedAt` timestamp (falls back to `updatedAt` if not available)

**b) Calendar Date Picker**
- Calendar icon in AppBar is now clickable
- Opens date picker to view tasks from any past date
- Shows selected date in header (e.g., "11/1/2025 Tasks")
- Refresh button appears when viewing a specific date to return to "Today"

**c) Smart Search Across All Dates**
- Search bar now searches through ALL completed tasks (not just selected date)
- Search by:
  - Task title
  - Category
  - Description
  - Time range
  - **Date** (e.g., search "10/25/2024" to find tasks from that day)

**d) Multi-Day Task Support**
- Tasks with time ranges spanning multiple days are included on all relevant dates
- Example: Task completed "today to tomorrow" will appear on both today's and tomorrow's list
- Handles natural language like "today", "tomorrow" in timeRange field

---

### 🗂️ State Management Updates

**New State Variables:**
```dart
List<Map<String, dynamic>> _allCompleted = [];  // All completed tasks
DateTime? _selectedDate;                          // Currently selected date
```

**New Methods:**
```dart
_filterByDate()      // Filters tasks by completion date
_pickDate()          // Opens calendar picker
_resetToToday()      // Resets view to today's tasks
_isSameDay()         // Date comparison helper
```

---

## How It Works

### Task Completion Flow
1. User marks task as completed
2. Backend sets `completedAt` to current timestamp
3. If `setPublic` is enabled, post is created on timeline
4. Task is stored with completion date

### Viewing Tasks
1. **Default:** See today's completed tasks
2. **Calendar:** Click calendar icon → pick date → see tasks from that date
3. **Search:** Type anything → searches ALL dates
4. **Reset:** Click refresh icon to return to today

### Multi-Day Tasks
- Tasks completed today that span to tomorrow show up on both days
- System checks `timeRange` field for "today", "tomorrow" keywords
- Automatically includes task on all relevant dates

---

## Database Schema Updates

### Task Model
```javascript
completedAt: { type: Date }  // NEW: Timestamp when task was marked complete
```

---

## API Endpoints (No Changes)
All existing endpoints work as before. The filtering happens client-side for performance.

---

## Testing Checklist

- [x] Like button works without errors
- [x] Timeline shows correct spacing
- [x] Logo is inline with appbar
- [x] Today's tasks display by default
- [x] Calendar picker opens and filters correctly
- [x] Search works across all dates
- [x] Date search works (e.g., "11/1/2025")
- [x] Reset button returns to today
- [x] Multi-day tasks appear on relevant dates

---

## Notes

- Old tasks without `completedAt` will use `updatedAt` as fallback
- Search is case-insensitive
- Date format in search: M/D/YYYY (e.g., 11/1/2025)
- Timeline requires backend restart to apply mongoose fix
