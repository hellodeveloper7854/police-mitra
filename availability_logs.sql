-- Create availability_logs table
CREATE TABLE availability_logs (
    id SERIAL PRIMARY KEY,
    user_email VARCHAR(255) NOT NULL,
    police_station VARCHAR(255),
    date DATE NOT NULL,
    availability_start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add index for performance
CREATE INDEX idx_availability_logs_user_email ON availability_logs(user_email);
CREATE INDEX idx_availability_logs_date ON availability_logs(date);