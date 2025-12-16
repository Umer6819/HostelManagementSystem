-- Drop if exists (for iterative development)
DROP TABLE IF EXISTS notices CASCADE;

-- Notices table (aligned with app model/service)
CREATE TABLE notices (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  priority INT NOT NULL DEFAULT 0,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_notices_expires_at ON notices(expires_at);
CREATE INDEX idx_notices_is_active ON notices(is_active);
CREATE INDEX idx_notices_priority ON notices(priority DESC);
CREATE INDEX idx_notices_created_at ON notices(created_at DESC);

-- RLS
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read active, non-expired notices
CREATE POLICY "Read active non-expired notices"
  ON notices FOR SELECT
  USING (
    auth.role() = 'authenticated' AND
    is_active = true AND
    (expires_at IS NULL OR expires_at > NOW())
  );

-- Admins can read all notices
CREATE POLICY "Admins can read all notices"
  ON notices FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role ILIKE '%admin%'
    )
  );

-- Admins can insert
CREATE POLICY "Admins can create notices"
  ON notices FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role ILIKE '%admin%'
    )
  );

-- Wardens can create notices
CREATE POLICY "Wardens can create notices"
  ON notices FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role ILIKE '%warden%'
    )
  );

-- Admins can update
CREATE POLICY "Admins can update notices"
  ON notices FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role ILIKE '%admin%'
    )
  );

-- Wardens can update their own notices
CREATE POLICY "Wardens can update own notices"
  ON notices FOR UPDATE
  USING (created_by = auth.uid());

-- Admins can delete
CREATE POLICY "Admins can delete notices"
  ON notices FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role ILIKE '%admin%'
    )
  );

-- Wardens can delete their own notices
CREATE POLICY "Wardens can delete own notices"
  ON notices FOR DELETE
  USING (created_by = auth.uid());

-- Wardens can read their own notices (even if inactive/expired)
CREATE POLICY "Wardens can read own notices"
  ON notices FOR SELECT
  USING (created_by = auth.uid());
