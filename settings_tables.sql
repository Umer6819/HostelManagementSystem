-- Create hostel rules table (drop if exists to avoid conflicts)
DROP TABLE IF EXISTS hostel_rules CASCADE;
CREATE TABLE hostel_rules (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create or recreate notices table
DROP TABLE IF EXISTS notices CASCADE;
CREATE TABLE notices (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);

-- Add indexes for better performance
CREATE INDEX idx_hostel_rules_active ON hostel_rules(is_active);
CREATE INDEX idx_hostel_rules_priority ON hostel_rules(priority DESC);
CREATE INDEX idx_notices_active ON notices(is_active);
CREATE INDEX idx_notices_priority ON notices(priority DESC);
CREATE INDEX idx_notices_expires ON notices(expires_at);

-- RLS policies for hostel_rules
ALTER TABLE hostel_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active rules"
    ON hostel_rules FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admins can insert rules"
    ON hostel_rules FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can update rules"
    ON hostel_rules FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can delete rules"
    ON hostel_rules FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- RLS policies for notices
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active notices"
    ON notices FOR SELECT
    USING (is_active = true AND (expires_at IS NULL OR expires_at > NOW()));

CREATE POLICY "Admins can insert notices"
    ON notices FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can update notices"
    ON notices FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can delete notices"
    ON notices FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );
