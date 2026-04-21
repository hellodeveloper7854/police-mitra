-- Create work_certificates table for storing generated certificates
CREATE TABLE IF NOT EXISTS public.work_certificates (
    id SERIAL PRIMARY KEY,
    user_email VARCHAR(255) NOT NULL,
    user_id UUID,
    user_name VARCHAR(255) NOT NULL,
    police_station VARCHAR(255),
    total_hours VARCHAR(50),
    certificate_id VARCHAR(100) UNIQUE NOT NULL,
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    issued_by VARCHAR(255),
    availability_log_ids TEXT[], -- Array of availability log IDs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_work_certificates_user_email ON public.work_certificates(user_email);
CREATE INDEX IF NOT EXISTS idx_work_certificates_certificate_id ON public.work_certificates(certificate_id);
CREATE INDEX IF NOT EXISTS idx_work_certificates_issued_at ON public.work_certificates(issued_at DESC);

-- Enable Row Level Security
ALTER TABLE public.work_certificates ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Users can view their own certificates
CREATE POLICY "Users can view own certificates"
ON public.work_certificates FOR SELECT
USING (auth.uid()::text = user_id::text OR user_email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Users can insert their own certificates
CREATE POLICY "Users can insert own certificates"
ON public.work_certificates FOR INSERT
WITH CHECK (user_email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Admins can view all certificates
CREATE POLICY "Admins can view all certificates"
ON public.work_certificates FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.registrations
        WHERE email = (SELECT email FROM auth.users WHERE id = auth.uid())
        AND role = 'admin'
    )
);

-- Add comments for documentation
COMMENT ON TABLE public.work_certificates IS 'Stores generated work certificates for volunteers';
COMMENT ON COLUMN public.work_certificates.certificate_id IS 'Unique certificate identifier (e.g., MCC-8C1AF3-8791)';
COMMENT ON COLUMN public.work_certificates.availability_log_ids IS 'Array of availability log IDs included in this certificate';
COMMENT ON COLUMN public.work_certificates.total_hours IS 'Total hours calculated for this certificate';
