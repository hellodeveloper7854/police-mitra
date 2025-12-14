-- Create safety_resources table for Explore Resources section
CREATE TABLE safety_resources (
    id SERIAL PRIMARY KEY,
    type VARCHAR(255) NOT NULL, -- e.g., 'Safety in public places', 'Home safety for children'
    police_station VARCHAR(255), -- Optional: associated police station
    image_link TEXT, -- URL or path to image
    description TEXT NOT NULL, -- Description of the safety tip/resource
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for better performance
CREATE INDEX idx_safety_resources_type ON safety_resources(type);

-- Insert sample data
INSERT INTO safety_resources (type, police_station, image_link, description) VALUES
-- Safety in public places
('Safety in public places', 'Thane Police Station', 'assets/images/school_bus.png', 'Safe school commuting'),
('Safety in public places', 'Thane Police Station', 'assets/images/lost_found.png', 'Lost and found: Steps to safety'),

-- Home safety for children
('Home safety for children', 'Thane Police Station', 'assets/images/childproofing.png', 'Childproofing your home'),
('Home safety for children', 'Thane Police Station', 'assets/images/fire_safety.png', 'Fire safety basics for families'),

-- Online safety
('Online safety', 'Cyber Crime Unit', 'assets/images/online_safety.png', 'Protecting children from online threats'),
('Online safety', 'Cyber Crime Unit', 'assets/images/screen_time.png', 'Managing screen time for kids'),

-- Emergency preparedness
('Emergency preparedness', 'Thane Police Station', 'assets/images/emergency_kit.png', 'Building an emergency preparedness kit'),
('Emergency preparedness', 'Thane Police Station', 'assets/images/family_plan.png', 'Creating a family emergency plan');