-- Create notification_replies table for storing user replies
CREATE TABLE IF NOT EXISTS notification_replies (
    id SERIAL PRIMARY KEY,
    notification_id INTEGER REFERENCES community_notifications(id) ON DELETE CASCADE,
    recipient_id INTEGER REFERENCES notification_recipients(id) ON DELETE CASCADE,
    user_email VARCHAR(255) NOT NULL,
    reply_text TEXT NOT NULL,
    replied_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_notification_replies_notification_id
ON notification_replies(notification_id);

CREATE INDEX IF NOT EXISTS idx_notification_replies_user_email
ON notification_replies(user_email);

CREATE INDEX IF NOT EXISTS idx_notification_replies_recipient_id
ON notification_replies(recipient_id);

-- Create a composite index to quickly check if a user has replied to a notification
CREATE INDEX IF NOT EXISTS idx_notification_replies_notification_user
ON notification_replies(notification_id, user_email);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_notification_replies_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_notification_replies_updated_at
BEFORE UPDATE ON notification_replies
FOR EACH ROW
EXECUTE FUNCTION update_notification_replies_updated_at();

-- Add comment
COMMENT ON TABLE notification_replies IS 'Stores replies from users to community notifications';
COMMENT ON COLUMN notification_replies.notification_id IS 'Reference to the community notification';
COMMENT ON COLUMN notification_replies.recipient_id IS 'Reference to the notification recipient';
COMMENT ON COLUMN notification_replies.user_email IS 'Email of the user who replied';
COMMENT ON COLUMN notification_replies.reply_text IS 'The reply message from the user';
COMMENT ON COLUMN notification_replies.replied_at IS 'Timestamp when the reply was sent';
