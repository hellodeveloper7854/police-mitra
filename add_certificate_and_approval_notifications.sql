-- Add new notification types to the check constraint
ALTER TABLE public.notifications
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
ADD CONSTRAINT notifications_type_check
CHECK (type IN ('service_assigned', 'community_post', 'certificate_assigned', 'post_approved', 'post_rejected'));

-- ============================================
-- Certificate Assignment Notification
-- ============================================

-- Function to create notification when certificate is issued
CREATE OR REPLACE FUNCTION create_certificate_assigned_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- When a new certificate is inserted into work_certificates
    INSERT INTO public.notifications (user_email, type, title, message, is_read)
    VALUES (
        NEW.user_email,
        'certificate_assigned',
        'Certificate Generated!',
        'Your certificate (ID: ' || NEW.certificate_id ||
        ') issued on ' || TO_CHAR(NEW.issued_at, 'DD/MM/YYYY') ||
        ' is now available for download.',
        FALSE
    );

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the certificate insertion
        RAISE WARNING 'Failed to create certificate notification: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for certificate generation on work_certificates table
DROP TRIGGER IF EXISTS certificate_assigned_notification_trigger ON public.work_certificates;
CREATE TRIGGER certificate_assigned_notification_trigger
    AFTER INSERT ON public.work_certificates
    FOR EACH ROW
    EXECUTE FUNCTION create_certificate_assigned_notification();

-- ============================================
-- Service Completed Notification (when end_time is set)
-- ============================================

-- Function to create notification when service is marked as completed
CREATE OR REPLACE FUNCTION create_service_completed_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if end_time was just set (service was just completed)
    IF NEW.end_time IS NOT NULL AND (OLD.end_time IS NULL OR OLD.end_time != NEW.end_time) THEN
        INSERT INTO public.notifications (user_email, type, title, message, is_read)
        VALUES (
            NEW.user_email,
            'certificate_assigned',
            'Service Completed!',
            'Your service "' || COALESCE(NEW.service_name, 'Police Service') ||
            '" completed on ' || TO_CHAR(NEW.end_time, 'DD/MM/YYYY') ||
            '. Certificate will be available soon.',
            FALSE
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for service completion on assigned_services table
DROP TRIGGER IF EXISTS service_completed_notification_trigger ON public.assigned_services;
CREATE TRIGGER service_completed_notification_trigger
    AFTER UPDATE ON public.assigned_services
    FOR EACH ROW
    WHEN (OLD.end_time IS NULL AND NEW.end_time IS NOT NULL)
    EXECUTE FUNCTION create_service_completed_notification();

-- ============================================
-- Community Post Approval/Rejection Notification
-- ============================================

-- Function to create notification for the post creator when their post is approved/verified or rejected
CREATE OR REPLACE FUNCTION create_post_status_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if status changed TO approved or verified (both mean the same thing)
    IF (NEW.status = 'approved' OR NEW.status = 'verified') AND
       (OLD.status IS NULL OR (OLD.status != 'approved' AND OLD.status != 'verified')) THEN
        -- Post approved/verified - send positive notification
        INSERT INTO public.notifications (user_email, type, title, message, is_read)
        VALUES (
            NEW.user_email,
            'post_approved',
            'Your Post Was Approved!',
            'Great news! Your community post "' || COALESCE(NEW.title, 'Community Post') ||
            '" has been approved and is now visible to other users.',
            FALSE
        );
    ELSIF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN
        -- Post rejected - send notification with feedback
        INSERT INTO public.notifications (user_email, type, title, message, is_read)
        VALUES (
            NEW.user_email,
            'post_rejected',
            'Your Post Was Not Approved',
            'Your community post "' || COALESCE(NEW.title, 'Community Post') ||
            '" could not be approved at this time.' ||
            CASE
                WHEN NEW.rejection_reason IS NOT NULL THEN
                    ' Reason: ' || NEW.rejection_reason
                ELSE
                    ' Please contact support for more information.'
            END,
            FALSE
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for post status notification
DROP TRIGGER IF EXISTS post_status_notification_trigger ON public.community_posts;
CREATE TRIGGER post_status_notification_trigger
    AFTER UPDATE ON public.community_posts
    FOR EACH ROW
    EXECUTE FUNCTION create_post_status_notification();

-- ============================================
-- Verification
-- ============================================

-- Add comments for documentation
COMMENT ON FUNCTION create_certificate_assigned_notification() IS 'Creates notification when a certificate is generated in work_certificates table';
COMMENT ON FUNCTION create_service_completed_notification() IS 'Creates notification when a service is marked as completed (end_time is set) in assigned_services table';
COMMENT ON FUNCTION create_post_status_notification() IS 'Creates notification for the post creator when their community post is approved or rejected';

-- Verify the triggers are created successfully
SELECT
    'Triggers created successfully' as status,
    proname as trigger_function,
    tgname as trigger_name,
    tgrelid::regclass as table_name
FROM pg_trigger
JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
WHERE pg_proc.proname IN (
    'create_certificate_assigned_notification',
    'create_service_completed_notification',
    'create_post_status_notification'
);
