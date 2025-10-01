-- Create feedbacks table
CREATE TABLE IF NOT EXISTS feedbacks (
    id BIGSERIAL PRIMARY KEY,
    user_email TEXT NOT NULL,
    police_station TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on user_email for faster queries
CREATE INDEX IF NOT EXISTS idx_feedbacks_user_email ON feedbacks(user_email);

-- Create index on police_station for faster queries
CREATE INDEX IF NOT EXISTS idx_feedbacks_police_station ON feedbacks(police_station);

-- Create index on submitted_at for sorting
CREATE INDEX IF NOT EXISTS idx_feedbacks_submitted_at ON feedbacks(submitted_at DESC);

-- Add comment to table
COMMENT ON TABLE feedbacks IS 'Stores user feedback with ratings and comments';

-- Add comments to columns
COMMENT ON COLUMN feedbacks.id IS 'Unique identifier for each feedback';
COMMENT ON COLUMN feedbacks.user_email IS 'Email of the user who submitted the feedback';
COMMENT ON COLUMN feedbacks.police_station IS 'Police station associated with the user';
COMMENT ON COLUMN feedbacks.rating IS 'Rating given by user (1-5 stars)';
COMMENT ON COLUMN feedbacks.comment IS 'Optional comment provided by the user';
COMMENT ON COLUMN feedbacks.submitted_at IS 'Timestamp when feedback was submitted';
COMMENT ON COLUMN feedbacks.created_at IS 'Timestamp when record was created';