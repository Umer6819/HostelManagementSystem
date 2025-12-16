-- Drop existing tables if they exist
DROP TABLE IF EXISTS maintenance_issues CASCADE;
DROP TABLE IF EXISTS room_lock_requests CASCADE;

-- Create maintenance_issues table
CREATE TABLE maintenance_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id INTEGER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    issue_type TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    resolution_notes TEXT
);

-- Create room_lock_requests table
CREATE TABLE room_lock_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id INTEGER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    review_notes TEXT,
    lock_until TIMESTAMPTZ
);

-- Create indexes for better query performance
CREATE INDEX idx_maintenance_issues_room_id ON maintenance_issues(room_id);
CREATE INDEX idx_maintenance_issues_reported_by ON maintenance_issues(reported_by);
CREATE INDEX idx_maintenance_issues_status ON maintenance_issues(status);
CREATE INDEX idx_maintenance_issues_priority ON maintenance_issues(priority);

CREATE INDEX idx_room_lock_requests_room_id ON room_lock_requests(room_id);
CREATE INDEX idx_room_lock_requests_requested_by ON room_lock_requests(requested_by);
CREATE INDEX idx_room_lock_requests_status ON room_lock_requests(status);

-- Enable Row Level Security
ALTER TABLE maintenance_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_lock_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for maintenance_issues

-- Allow all authenticated users to read all maintenance issues
CREATE POLICY "Anyone can view maintenance issues"
    ON maintenance_issues
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Allow wardens to insert maintenance issues
CREATE POLICY "Wardens can create maintenance issues"
    ON maintenance_issues
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%warden%'
        )
    );

-- Allow wardens to update their own maintenance issues
CREATE POLICY "Wardens can update their own issues"
    ON maintenance_issues
    FOR UPDATE
    USING (reported_by = auth.uid());

-- Allow admins to update any maintenance issue
CREATE POLICY "Admins can update any maintenance issue"
    ON maintenance_issues
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );

-- Allow admins to delete maintenance issues
CREATE POLICY "Admins can delete maintenance issues"
    ON maintenance_issues
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );

-- RLS Policies for room_lock_requests

-- Allow all authenticated users to read all room lock requests
CREATE POLICY "Anyone can view room lock requests"
    ON room_lock_requests
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Allow wardens to insert room lock requests
CREATE POLICY "Wardens can create room lock requests"
    ON room_lock_requests
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%warden%'
        )
    );

-- Allow wardens to update their own pending requests
CREATE POLICY "Wardens can update their own pending requests"
    ON room_lock_requests
    FOR UPDATE
    USING (requested_by = auth.uid() AND status = 'pending');

-- Allow admins to update any room lock request (for approval/rejection)
CREATE POLICY "Admins can review room lock requests"
    ON room_lock_requests
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );

-- Allow wardens to delete their own pending requests
CREATE POLICY "Wardens can delete their own pending requests"
    ON room_lock_requests
    FOR DELETE
    USING (requested_by = auth.uid() AND status = 'pending');

-- Allow admins to delete any room lock request
CREATE POLICY "Admins can delete any room lock request"
    ON room_lock_requests
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );
