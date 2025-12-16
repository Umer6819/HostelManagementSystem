# Room Monitoring Feature - Database Setup Instructions

## Overview
This document provides instructions for setting up the database tables required for the Room Monitoring feature (B. Room Monitoring) which includes:
1. View room occupancy
2. Report room maintenance issues
3. Request room lock (admin approval)

## Prerequisites
- Access to your Supabase project dashboard
- Admin privileges to execute SQL commands

## Setup Steps

### Step 1: Execute the SQL Script
1. Navigate to your Supabase project dashboard
2. Go to the SQL Editor
3. Open the file: `room_monitoring_tables.sql`
4. Copy all contents and paste into the SQL editor
5. Click "Run" to execute the script

### Step 2: Verify Tables Created
After running the script, verify that the following tables were created:
- `maintenance_issues` - Stores maintenance issue reports
- `room_lock_requests` - Stores room lock requests

### Step 3: Verify Indexes
Check that the following indexes were created for performance:
- `idx_maintenance_issues_room_id`
- `idx_maintenance_issues_reported_by`
- `idx_maintenance_issues_status`
- `idx_maintenance_issues_priority`
- `idx_room_lock_requests_room_id`
- `idx_room_lock_requests_requested_by`
- `idx_room_lock_requests_status`

### Step 4: Verify RLS Policies
Ensure Row Level Security (RLS) policies are enabled and the following policies exist:

#### Maintenance Issues Policies:
- "Anyone can view maintenance issues" (SELECT)
- "Wardens can create maintenance issues" (INSERT)
- "Wardens can update their own issues" (UPDATE)
- "Admins can update any maintenance issue" (UPDATE)
- "Admins can delete maintenance issues" (DELETE)

#### Room Lock Requests Policies:
- "Anyone can view room lock requests" (SELECT)
- "Wardens can create room lock requests" (INSERT)
- "Wardens can update their own pending requests" (UPDATE)
- "Admins can review room lock requests" (UPDATE)
- "Wardens can delete their own pending requests" (DELETE)
- "Admins can delete any room lock request" (DELETE)

## Table Schemas

### maintenance_issues
```
id UUID PRIMARY KEY
room_id UUID (references rooms)
reported_by UUID (references profiles)
issue_type TEXT
description TEXT
status TEXT (pending, in_progress, resolved)
priority TEXT (low, medium, high, urgent)
created_at TIMESTAMPTZ
resolved_at TIMESTAMPTZ
resolved_by UUID (references profiles)
resolution_notes TEXT
```

### room_lock_requests
```
id UUID PRIMARY KEY
room_id UUID (references rooms)
requested_by UUID (references profiles)
reason TEXT
status TEXT (pending, approved, rejected)
created_at TIMESTAMPTZ
reviewed_at TIMESTAMPTZ
reviewed_by UUID (references profiles)
review_notes TEXT
lock_until TIMESTAMPTZ
```

## Features Enabled

### For Wardens:
1. **View Room Occupancy**
   - See all rooms with current occupancy vs capacity
   - Visual progress indicators with color coding
   - Percentage calculations

2. **Report Maintenance Issues**
   - Select room from dropdown
   - Specify issue type (Plumbing, Electrical, Furniture, etc.)
   - Add detailed description
   - Set priority level (Low, Medium, High, Urgent)
   - Track status (Pending, In Progress, Resolved)

3. **Request Room Lock**
   - Select room to lock
   - Provide reason for lock request
   - Optional: Set lock duration (lock until date/time)
   - Track approval status (Pending, Approved, Rejected)

### For Admins:
1. **Review Room Lock Requests**
   - View all lock requests with status filtering
   - Approve or reject requests
   - Add review notes
   - Accessible via Rooms tab → "View Room Lock Requests" button

2. **Manage Maintenance Issues**
   - View all reported issues
   - Update issue status
   - Add resolution notes
   - Track by priority and status

## Testing

### Test Maintenance Issue Creation:
1. Open the app as a warden
2. Go to "Room Monitoring" tab
3. Click "Report New Issue"
4. Fill in all fields and submit
5. Verify the issue appears in the list

### Test Room Lock Request:
1. Open the app as a warden
2. Go to "Room Monitoring" tab
3. Click "Request Room Lock"
4. Fill in reason and optional lock duration
5. Submit request
6. Verify request appears in the list

### Test Admin Approval:
1. Open admin dashboard
2. Go to "Rooms" tab
3. Click "View Room Lock Requests"
4. Select a pending request
5. Approve or reject with notes
6. Verify status updates

## Troubleshooting

### Issue: RLS Policy Error
**Problem:** Policies fail with "FOR ALL" error
**Solution:** The SQL script uses separate INSERT/UPDATE/DELETE policies with proper WITH CHECK and USING clauses

### Issue: Room Not Found
**Problem:** Dropdown shows no rooms
**Solution:** Ensure rooms exist in the `rooms` table first

### Issue: Warden Can't Create Issue
**Problem:** Permission denied when creating maintenance issue
**Solution:** Verify the user's profile has role containing "warden" (case-insensitive via ILIKE)

## Notes
- All timestamps are stored in UTC
- Room IDs are stored as UUID strings in maintenance_issues and room_lock_requests tables
- The Room model uses integer IDs, so conversions (toString()) are needed when querying
- Priority colors: Urgent=Red, High=Orange, Medium=Yellow, Low=Gray
- Status colors: Pending=Orange, In Progress=Blue, Resolved=Green, Approved=Green, Rejected=Red
