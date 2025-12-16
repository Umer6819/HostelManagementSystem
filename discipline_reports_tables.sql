-- Drop existing tables if they exist
DROP TABLE IF EXISTS misconduct_reports CASCADE;
DROP TABLE IF EXISTS student_warnings CASCADE;

-- Create student_warnings table
CREATE TABLE student_warnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    issued_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'minor' CHECK (severity IN ('minor', 'moderate', 'severe')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true
);

-- Create misconduct_reports table
CREATE TABLE misconduct_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    incident_type TEXT NOT NULL,
    description TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'moderate' CHECK (severity IN ('minor', 'moderate', 'severe')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Admin remarks
    admin_remarks TEXT,
    admin_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    
    action_taken TEXT
);

-- Create indexes for better query performance
CREATE INDEX idx_student_warnings_student_id ON student_warnings(student_id);
CREATE INDEX idx_student_warnings_issued_by ON student_warnings(issued_by);
CREATE INDEX idx_student_warnings_is_active ON student_warnings(is_active);
CREATE INDEX idx_student_warnings_expires_at ON student_warnings(expires_at);

CREATE INDEX idx_misconduct_reports_student_id ON misconduct_reports(student_id);
CREATE INDEX idx_misconduct_reports_reported_by ON misconduct_reports(reported_by);
CREATE INDEX idx_misconduct_reports_status ON misconduct_reports(status);
CREATE INDEX idx_misconduct_reports_severity ON misconduct_reports(severity);
CREATE INDEX idx_misconduct_reports_admin_id ON misconduct_reports(admin_id);

-- Enable Row Level Security
ALTER TABLE student_warnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE misconduct_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies for student_warnings

-- Allow all authenticated users to read all warnings (visible to wardens and admins)
CREATE POLICY "Anyone can view student warnings"
    ON student_warnings
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Allow wardens to issue warnings
CREATE POLICY "Wardens can issue warnings"
    ON student_warnings
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%warden%'
        )
    );

-- Allow wardens to update their own warnings
CREATE POLICY "Wardens can update their own warnings"
    ON student_warnings
    FOR UPDATE
    USING (issued_by = auth.uid());

-- Allow admins to update any warning
CREATE POLICY "Admins can update any warning"
    ON student_warnings
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );

-- Allow admins to delete warnings
CREATE POLICY "Admins can delete warnings"
    ON student_warnings
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );

-- RLS Policies for misconduct_reports

-- Allow all authenticated users to read all reports
CREATE POLICY "Anyone can view misconduct reports"
    ON misconduct_reports
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Allow wardens to create misconduct reports
CREATE POLICY "Wardens can create misconduct reports"
    ON misconduct_reports
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%warden%'
        )
    );

-- Allow wardens to update their own pending reports
CREATE POLICY "Wardens can update their own reports"
    ON misconduct_reports
    FOR UPDATE
    USING (reported_by = auth.uid() AND status = 'pending');

-- Allow admins to update any report (to add remarks and change status)
CREATE POLICY "Admins can review misconduct reports"
    ON misconduct_reports
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );

-- Allow admins to delete reports
CREATE POLICY "Admins can delete misconduct reports"
    ON misconduct_reports
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role ILIKE '%admin%'
        )
    );
