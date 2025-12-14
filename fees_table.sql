-- Create fees table
CREATE TABLE fees (
    id SERIAL PRIMARY KEY,
    month VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add fee_id column to existing payments table
ALTER TABLE payments 
ADD COLUMN fee_id INTEGER REFERENCES fees(id) ON DELETE CASCADE;

-- Ensure status is boolean (if it isn't already)
-- ALTER TABLE payments ALTER COLUMN status TYPE BOOLEAN USING (status::boolean);
-- ALTER TABLE payments ALTER COLUMN status SET DEFAULT false;

-- Add indexes for better performance
CREATE INDEX idx_payments_fee_id ON payments(fee_id);
CREATE INDEX idx_payments_status ON payments(status);
