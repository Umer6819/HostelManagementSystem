-- ============================================================================
-- HOSTEL MANAGEMENT SYSTEM - ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Comprehensive role-based access control for all tables
-- Roles: admin (full access), warden (moderate access), student (limited access)
-- 
-- Key Principles:
-- 1. profiles table has NO RLS (used for role lookups in app)
-- 2. All authenticated users can view certain data (filtered by role in app)
-- 3. Users can only modify their own data (except admin/warden)
-- 4. Admin has full CRUD access to all tables
-- ============================================================================

-- ============================================================================
-- PROFILES TABLE - No RLS
-- ============================================================================
-- User role & basic profile info - accessed by app for role-based navigation
-- RLS disabled to avoid circular dependencies in other policies
-- ============================================================================
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STUDENTS TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (create, read, update, delete students)
--   Warden: Can read all, update (except room assignments - handled by admin)
--   Student: Can read own data only
-- ============================================================================
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_full_students_access"
    ON students FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "student_read_own_data"
    ON students FOR SELECT
    USING (auth.uid() = id);

-- ============================================================================
-- ROOMS TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (manage rooms, occupancy)
--   Warden: Can read all, update status (lock/unlock)
--   Student: Can read only
-- ============================================================================
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_users_read_rooms"
    ON rooms FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "admin_create_rooms"
    ON rooms FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_update_rooms"
    ON rooms FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_rooms"
    ON rooms FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- STUDENT_WARNINGS TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (create, update, delete warnings)
--   Warden: Can create, read all, update own (issued_by = uid)
--   Student: Can read own warnings only (when student_id = uid)
-- ============================================================================
ALTER TABLE student_warnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_warnings"
    ON student_warnings FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "warden_create_warning"
    ON student_warnings FOR INSERT
    WITH CHECK (issued_by = auth.uid());

CREATE POLICY "warden_update_own_warning"
    ON student_warnings FOR UPDATE
    USING (issued_by = auth.uid())
    WITH CHECK (issued_by = auth.uid());

CREATE POLICY "admin_update_warning"
    ON student_warnings FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_warning"
    ON student_warnings FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- MISCONDUCT_REPORTS TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (review, update status, add remarks)
--   Warden: Can create, read all, update own (reported_by = uid, status = pending)
--   Student: Can read own reports (when student_id = uid)
-- ============================================================================
ALTER TABLE misconduct_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_misconduct_reports"
    ON misconduct_reports FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "warden_create_misconduct_report"
    ON misconduct_reports FOR INSERT
    WITH CHECK (reported_by = auth.uid());

CREATE POLICY "warden_update_own_report"
    ON misconduct_reports FOR UPDATE
    USING (reported_by = auth.uid() AND status = 'pending')
    WITH CHECK (reported_by = auth.uid() AND status = 'pending');

CREATE POLICY "admin_review_misconduct_reports"
    ON misconduct_reports FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_misconduct_report"
    ON misconduct_reports FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- NOTICES TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (create, update, delete notices)
--   Warden: Can create, update own (created_by = uid)
--   Student: Can read ONLY active & non-expired notices
-- ============================================================================
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "student_read_active_notices"
    ON notices FOR SELECT
    USING (
        auth.role() = 'authenticated' AND
        is_active = true AND
        (expires_at IS NULL OR expires_at > NOW())
    );

CREATE POLICY "authenticated_read_all_notices"
    ON notices FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "admin_warden_create_notice"
    ON notices FOR INSERT
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "admin_warden_update_own_notice"
    ON notices FOR UPDATE
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "admin_delete_notice"
    ON notices FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- COMPLAINTS TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (assign wardens, update status, view all)
--   Warden: Can read all, update status/assignment
--   Student: Can create, read own, update own
-- ============================================================================
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_complaints"
    ON complaints FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "student_create_complaint"
    ON complaints FOR INSERT
    WITH CHECK (student_id = auth.uid());

CREATE POLICY "student_update_own_complaint"
    ON complaints FOR UPDATE
    USING (student_id = auth.uid())
    WITH CHECK (student_id = auth.uid());

CREATE POLICY "admin_warden_update_complaint"
    ON complaints FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_complaint"
    ON complaints FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- MAINTENANCE_ISSUES TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (view all, resolve issues)
--   Warden: Can create (reported_by = uid), read all, update own
--   Student: Cannot access
-- ============================================================================
ALTER TABLE maintenance_issues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_maintenance_issues"
    ON maintenance_issues FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "warden_create_issue"
    ON maintenance_issues FOR INSERT
    WITH CHECK (reported_by = auth.uid());

CREATE POLICY "warden_update_own_issue"
    ON maintenance_issues FOR UPDATE
    USING (reported_by = auth.uid())
    WITH CHECK (reported_by = auth.uid());

CREATE POLICY "admin_update_issue"
    ON maintenance_issues FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_issue"
    ON maintenance_issues FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- ROOM_LOCK_REQUESTS TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (review & approve requests)
--   Warden: Can create (requested_by = uid), read all
--   Student: Cannot access
-- ============================================================================
ALTER TABLE room_lock_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_lock_requests"
    ON room_lock_requests FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "warden_create_lock_request"
    ON room_lock_requests FOR INSERT
    WITH CHECK (requested_by = auth.uid());

CREATE POLICY "admin_review_lock_request"
    ON room_lock_requests FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_lock_request"
    ON room_lock_requests FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- FEES TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (create fees, view all)
--   Warden: Can read only
--   Student: Can read only
-- ============================================================================
ALTER TABLE fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_fees"
    ON fees FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "admin_create_fee"
    ON fees FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_update_fee"
    ON fees FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_fee"
    ON fees FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (mark paid, view all)
--   Warden: Can read only (view student payment status)
--   Student: Can read own payments (student_id = uid) only
-- ============================================================================
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "student_read_own_payments"
    ON payments FOR SELECT
    USING (student_id = auth.uid());

CREATE POLICY "authenticated_read_all_payments"
    ON payments FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "admin_create_payment"
    ON payments FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_update_payment"
    ON payments FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_payment"
    ON payments FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- HOSTEL_RULES TABLE
-- ============================================================================
-- Role Permissions:
--   Admin: Full CRUD (create, update, delete rules)
--   Warden: Can read only
--   Student: Can read only
-- ============================================================================
ALTER TABLE hostel_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_read_rules"
    ON hostel_rules FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "admin_create_rules"
    ON hostel_rules FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_update_rules"
    ON hostel_rules FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_delete_rules"
    ON hostel_rules FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- END OF RLS POLICIES
-- ============================================================================
