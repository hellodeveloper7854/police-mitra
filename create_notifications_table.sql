-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email VARCHAR NOT NULL,
    type VARCHAR NOT NULL CHECK (type IN ('service_assigned', 'community_post', 'new_resource', 'system_message')),
    title VARCHAR NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_email ON public.notifications(user_email);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- Enable RLS


-- Function to create notification for new service assignment
CREATE OR REPLACE FUNCTION create_service_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (user_email, type, title, message, is_read)
    VALUES (
        NEW.user_email,
        'service_assigned',
        'New Service Assigned',
        'You have been assigned to ' || COALESCE(NEW.service_name, 'a new service') ||
        ' on ' || TO_CHAR(NEW.assigned_date, 'DD/MM/YYYY') ||
        ' at ' || COALESCE(NEW.location, 'the designated location'),
        FALSE
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for new service assignments
DROP TRIGGER IF EXISTS service_assignment_notification_trigger ON public.assigned_services;
CREATE TRIGGER service_assignment_notification_trigger
    AFTER INSERT ON public.assigned_services
    FOR EACH ROW
    EXECUTE FUNCTION create_service_assignment_notification();

-- Function to create notification for new community posts (only for approved/verified posts)
CREATE OR REPLACE FUNCTION create_community_post_notification()
RETURNS TRIGGER AS $$
DECLARE
    target_user RECORD;
BEGIN
    -- Only create notification for approved or verified posts
    IF NEW.status = 'approved' OR NEW.status = 'verified' THEN
        -- Send notification to all verified users except the post creator
        FOR target_user IN
            SELECT email FROM public.registrations
            WHERE verification_status IN ('verified', 'approved', 'approve')
            AND email != NEW.user_email
        LOOP
            INSERT INTO public.notifications (user_email, type, title, message, is_read)
            VALUES (
                target_user.email,
                'community_post',
                'New Community Post',
                'Check out the new post: ' || COALESCE(NEW.title, 'New Post') ||
                ' by ' || COALESCE(NEW.user_name, 'A community member'),
                FALSE
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for new community posts
DROP TRIGGER IF EXISTS community_post_notification_trigger ON public.community_posts;
CREATE TRIGGER community_post_notification_trigger
    AFTER INSERT OR UPDATE ON public.community_posts
    FOR EACH ROW
    EXECUTE FUNCTION create_community_post_notification();

-- Function to create notification for new safety resources
CREATE OR REPLACE FUNCTION create_safety_resource_notification()
RETURNS TRIGGER AS $$
DECLARE
    target_user RECORD;
BEGIN
    -- Send notification to all verified users
    FOR target_user IN
        SELECT email FROM public.registrations
        WHERE verification_status IN ('verified', 'approved', 'approve')
    LOOP
        INSERT INTO public.notifications (user_email, type, title, message, is_read)
        VALUES (
            target_user.email,
            'new_resource',
            'New Safety Resource Available',
            'A new ' || COALESCE(NEW.type, 'safety resource') || ' has been added: ' ||
            COALESCE(NEW.description, 'Check out the new resource'),
            FALSE
        );
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for new safety resources
DROP TRIGGER IF EXISTS safety_resource_notification_trigger ON public.safety_resources;
CREATE TRIGGER safety_resource_notification_trigger
    AFTER INSERT ON public.safety_resources
    FOR EACH ROW
    EXECUTE FUNCTION create_safety_resource_notification();
