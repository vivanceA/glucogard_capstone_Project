-- =====================================================
-- GlucoGard AI - Complete Database Setup Script
-- This script creates all necessary tables, policies, and functions
-- Run this in your Supabase SQL Editor to set up the complete database
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CORE TABLES
-- =====================================================

-- Profiles table for user information
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role text CHECK (role IN ('patient', 'doctor')) NOT NULL,
  full_name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Add unique constraint to profiles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'unique_user_profile' 
        AND table_name = 'profiles'
    ) THEN
        ALTER TABLE profiles ADD CONSTRAINT unique_user_profile UNIQUE (user_id);
    END IF;
END $$;

-- Patients table for patient-specific data
CREATE TABLE IF NOT EXISTS patients (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  age integer,
  gender text,
  weight numeric,
  height numeric,
  created_at timestamptz DEFAULT now()
);

-- Doctors table for healthcare provider data
CREATE TABLE IF NOT EXISTS doctors (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  specialization text,
  created_at timestamptz DEFAULT now()
);

-- Health submissions table for assessment data
CREATE TABLE IF NOT EXISTS health_submissions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id uuid REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  answers jsonb NOT NULL,
  status text CHECK (status IN ('pending', 'reviewed')) DEFAULT 'pending',
  submitted_at timestamptz DEFAULT now()
);

-- Risk predictions table for AI assessments
CREATE TABLE IF NOT EXISTS risk_predictions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id uuid REFERENCES health_submissions(id) ON DELETE CASCADE NOT NULL,
  risk_score integer CHECK (risk_score >= 0 AND risk_score <= 100) NOT NULL,
  risk_category text CHECK (risk_category IN ('low', 'moderate', 'critical')) NOT NULL,
  raw_prediction jsonb,
  generated_at timestamptz DEFAULT now()
);

-- Recommendations table for health advice
CREATE TABLE IF NOT EXISTS recommendations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id uuid REFERENCES health_submissions(id) ON DELETE CASCADE NOT NULL,
  doctor_id uuid REFERENCES doctors(id) ON DELETE SET NULL,
  content text NOT NULL,
  type text CHECK (type IN ('lifestyle', 'clinical')) NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- =====================================================
-- 2. DIABETES MANAGEMENT TABLES
-- =====================================================

-- Blood sugar readings table
CREATE TABLE IF NOT EXISTS blood_sugar_readings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  reading_value numeric NOT NULL,
  reading_type text CHECK (reading_type IN ('fasting', 'post_meal', 'random')) NOT NULL,
  recorded_at timestamptz DEFAULT now(),
  notes text
);

-- Medication reminders table
CREATE TABLE IF NOT EXISTS medication_reminders (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  medication_name text NOT NULL,
  dosage text NOT NULL,
  frequency text NOT NULL,
  reminder_time time NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Diabetes tasks table
CREATE TABLE IF NOT EXISTS diabetes_tasks (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  task_name text NOT NULL,
  task_type text CHECK (task_type IN ('blood_sugar', 'medication', 'exercise', 'diet', 'other')) NOT NULL,
  completed boolean DEFAULT false,
  due_date date,
  created_at timestamptz DEFAULT now()
);

-- Daily activity tracking table
CREATE TABLE IF NOT EXISTS daily_activities (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  activity_date date NOT NULL,
  activity_type text CHECK (activity_type IN ('exercise', 'diet', 'medication', 'blood_sugar', 'other')) NOT NULL,
  activity_data jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- =====================================================
-- 3. COMMUNICATION TABLES
-- =====================================================

-- Messages table for patient-doctor communication
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. APPOINTMENTS TABLE
-- =====================================================

-- Appointments table for doctor-patient bookings
CREATE TABLE IF NOT EXISTS appointments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    appointment_date date NOT NULL,
    appointment_time time NOT NULL,
    appointment_type text NOT NULL CHECK (appointment_type IN ('consultation', 'follow-up', 'emergency', 'routine')),
    status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no-show')),
    notes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- =====================================================
-- 5. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_sugar_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE diabetes_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 6. ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Profiles policies
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Patients policies
DROP POLICY IF EXISTS "Patients can read own data" ON patients;
CREATE POLICY "Patients can read own data"
  ON patients
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Patients can update own data" ON patients;
CREATE POLICY "Patients can update own data"
  ON patients
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Patients can insert own data" ON patients;
CREATE POLICY "Patients can insert own data"
  ON patients
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Doctors can read patient data" ON patients;
CREATE POLICY "Doctors can read patient data"
  ON patients
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'doctor'
    )
  );

-- Doctors policies
DROP POLICY IF EXISTS "Doctors can read own data" ON doctors;
CREATE POLICY "Doctors can read own data"
  ON doctors
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Doctors can update own data" ON doctors;
CREATE POLICY "Doctors can update own data"
  ON doctors
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Doctors can insert own data" ON doctors;
CREATE POLICY "Doctors can insert own data"
  ON doctors
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Health submissions policies
DROP POLICY IF EXISTS "Patients can read own submissions" ON health_submissions;
CREATE POLICY "Patients can read own submissions"
  ON health_submissions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM patients
      WHERE patients.id = health_submissions.patient_id
      AND patients.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Patients can insert own submissions" ON health_submissions;
CREATE POLICY "Patients can insert own submissions"
  ON health_submissions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM patients
      WHERE patients.id = health_submissions.patient_id
      AND patients.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Doctors can read all submissions" ON health_submissions;
CREATE POLICY "Doctors can read all submissions"
  ON health_submissions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'doctor'
    )
  );

-- Diabetes management policies
DROP POLICY IF EXISTS "Users can manage their own diabetes data" ON blood_sugar_readings;
CREATE POLICY "Users can manage their own diabetes data" ON blood_sugar_readings
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own medication reminders" ON medication_reminders;
CREATE POLICY "Users can manage their own medication reminders" ON medication_reminders
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own diabetes tasks" ON diabetes_tasks;
CREATE POLICY "Users can insert their own diabetes tasks" ON diabetes_tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own diabetes tasks" ON diabetes_tasks;
CREATE POLICY "Users can manage their own diabetes tasks" ON diabetes_tasks
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own daily activities" ON daily_activities;
CREATE POLICY "Users can manage their own daily activities" ON daily_activities
  FOR ALL USING (auth.uid() = user_id);

-- Messages policies
DROP POLICY IF EXISTS "Users can read their own messages" ON messages;
CREATE POLICY "Users can read their own messages" ON messages
  FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

DROP POLICY IF EXISTS "Users can send messages" ON messages;
CREATE POLICY "Users can send messages" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
  );

DROP POLICY IF EXISTS "Users can update their sent messages" ON messages;
CREATE POLICY "Users can update their sent messages" ON messages
  FOR UPDATE USING (
    auth.uid() = sender_id
  );

DROP POLICY IF EXISTS "Users can mark received messages as read" ON messages;
CREATE POLICY "Users can mark received messages as read" ON messages
  FOR UPDATE USING (
    auth.uid() = receiver_id
  );

-- Appointments policies
DROP POLICY IF EXISTS "Doctors can view their own appointments" ON appointments;
CREATE POLICY "Doctors can view their own appointments"
    ON appointments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM doctors
            WHERE doctors.id = appointments.doctor_id
            AND doctors.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Patients can view their own appointments" ON appointments;
CREATE POLICY "Patients can view their own appointments"
    ON appointments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = appointments.patient_id
            AND patients.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Doctors can create appointments" ON appointments;
CREATE POLICY "Doctors can create appointments"
    ON appointments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM doctors
            WHERE doctors.id = appointments.doctor_id
            AND doctors.user_id = auth.uid()
        )
    );

-- =====================================================
-- 7. INDEXES FOR PERFORMANCE
-- =====================================================

-- Core tables indexes
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id);
CREATE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id);

-- Health data indexes
CREATE INDEX IF NOT EXISTS idx_health_submissions_patient_id ON health_submissions(patient_id);
CREATE INDEX IF NOT EXISTS idx_health_submissions_status ON health_submissions(status);
CREATE INDEX IF NOT EXISTS idx_health_submissions_submitted_at ON health_submissions(submitted_at);
CREATE INDEX IF NOT EXISTS idx_risk_predictions_submission_id ON risk_predictions(submission_id);
CREATE INDEX IF NOT EXISTS idx_risk_predictions_category ON risk_predictions(risk_category);
CREATE INDEX IF NOT EXISTS idx_recommendations_submission_id ON recommendations(submission_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_doctor_id ON recommendations(doctor_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_type ON recommendations(type);

-- Diabetes management indexes
CREATE INDEX IF NOT EXISTS idx_blood_sugar_user_date ON blood_sugar_readings(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_medication_reminders_user_active ON medication_reminders(user_id, active);
CREATE INDEX IF NOT EXISTS idx_diabetes_tasks_user_completed ON diabetes_tasks(user_id, completed);
CREATE INDEX IF NOT EXISTS idx_daily_activities_user_date ON daily_activities(user_id, activity_date DESC);

-- Communication indexes
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(sender_id, receiver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(receiver_id, is_read) WHERE is_read = FALSE;

-- Appointment indexes
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_date ON appointments(doctor_id, appointment_date);

-- =====================================================
-- 8. FUNCTIONS
-- =====================================================

-- Function to get daily activity summary for calendar
CREATE OR REPLACE FUNCTION get_daily_activity_summary(
  p_user_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE (
  day_date DATE,
  has_blood_sugar BOOLEAN,
  has_medication BOOLEAN,
  has_tasks BOOLEAN,
  tasks_completed INTEGER,
  total_tasks INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.day_date,
    COALESCE(bs.has_blood_sugar, FALSE) as has_blood_sugar,
    COALESCE(m.has_medication, FALSE) as has_medication,
    COALESCE(t.has_tasks, FALSE) as has_tasks,
    COALESCE(t.tasks_completed, 0) as tasks_completed,
    COALESCE(t.total_tasks, 0) as total_tasks
  FROM (
    SELECT generate_series(
      DATE(p_year || '-' || p_month || '-01'),
      DATE(p_year || '-' || p_month || '-01') + INTERVAL '1 month - 1 day',
      INTERVAL '1 day'
    )::DATE as day_date
  ) d
  LEFT JOIN (
    SELECT 
      DATE(recorded_at) as day_date,
      TRUE as has_blood_sugar
    FROM blood_sugar_readings
    WHERE user_id = p_user_id
      AND EXTRACT(YEAR FROM recorded_at) = p_year
      AND EXTRACT(MONTH FROM recorded_at) = p_month
  ) bs ON d.day_date = bs.day_date
  LEFT JOIN (
    SELECT 
      DATE(created_at) as day_date,
      TRUE as has_medication
    FROM medication_reminders
    WHERE user_id = p_user_id
      AND active = TRUE
      AND EXTRACT(YEAR FROM created_at) = p_year
      AND EXTRACT(MONTH FROM created_at) = p_month
  ) m ON d.day_date = m.day_date
  LEFT JOIN (
    SELECT 
      DATE(created_at) as day_date,
      TRUE as has_tasks,
      COUNT(*) FILTER (WHERE completed = TRUE) as tasks_completed,
      COUNT(*) as total_tasks
    FROM diabetes_tasks
    WHERE user_id = p_user_id
      AND EXTRACT(YEAR FROM created_at) = p_year
      AND EXTRACT(MONTH FROM created_at) = p_month
    GROUP BY DATE(created_at)
  ) t ON d.day_date = t.day_date
  ORDER BY d.day_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get conversation messages
CREATE OR REPLACE FUNCTION get_conversation_messages(
  p_user1_id UUID,
  p_user2_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  receiver_id UUID,
  message_text TEXT,
  message_type TEXT,
  is_read BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE,
  sender_name TEXT,
  receiver_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.sender_id,
    m.receiver_id,
    m.message_text,
    m.message_type,
    m.is_read,
    m.created_at,
    p1.full_name as sender_name,
    p2.full_name as receiver_name
  FROM messages m
  LEFT JOIN profiles p1 ON m.sender_id = p1.user_id
  LEFT JOIN profiles p2 ON m.receiver_id = p2.user_id
  WHERE (m.sender_id = p_user1_id AND m.receiver_id = p_user2_id)
     OR (m.sender_id = p_user2_id AND m.receiver_id = p_user1_id)
  ORDER BY m.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread message count
CREATE OR REPLACE FUNCTION get_unread_message_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM messages
    WHERE receiver_id = p_user_id AND is_read = FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
  p_user_id UUID,
  p_sender_id UUID
)
RETURNS VOID AS $$
BEGIN
  UPDATE messages
  SET is_read = TRUE, updated_at = NOW()
  WHERE receiver_id = p_user_id 
    AND sender_id = p_sender_id 
    AND is_read = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent conversations
CREATE OR REPLACE FUNCTION get_recent_conversations(p_user_id UUID)
RETURNS TABLE (
  other_user_id UUID,
  other_user_name TEXT,
  other_user_role TEXT,
  last_message TEXT,
  last_message_time TIMESTAMP WITH TIME ZONE,
  unread_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH conversation_partners AS (
    SELECT DISTINCT
      CASE 
        WHEN sender_id = p_user_id THEN receiver_id
        ELSE sender_id
      END as other_user_id
    FROM messages
    WHERE sender_id = p_user_id OR receiver_id = p_user_id
  ),
  last_messages AS (
    SELECT 
      cp.other_user_id,
      m.message_text,
      m.created_at,
      ROW_NUMBER() OVER (PARTITION BY cp.other_user_id ORDER BY m.created_at DESC) as rn
    FROM conversation_partners cp
    JOIN messages m ON (
      (m.sender_id = p_user_id AND m.receiver_id = cp.other_user_id) OR
      (m.sender_id = cp.other_user_id AND m.receiver_id = p_user_id)
    )
  ),
  unread_counts AS (
    SELECT 
      receiver_id as other_user_id,
      COUNT(*) as unread_count
    FROM messages
    WHERE receiver_id = p_user_id AND is_read = FALSE
    GROUP BY receiver_id
  )
  SELECT 
    lm.other_user_id,
    p.full_name as other_user_name,
    p.role as other_user_role,
    lm.message_text as last_message,
    lm.created_at as last_message_time,
    COALESCE(uc.unread_count, 0) as unread_count
  FROM last_messages lm
  JOIN profiles p ON lm.other_user_id = p.user_id
  LEFT JOIN unread_counts uc ON lm.other_user_id = uc.other_user_id
  WHERE lm.rn = 1
  ORDER BY lm.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get doctor appointments
CREATE OR REPLACE FUNCTION get_doctor_appointments(p_doctor_user_id uuid, p_date date DEFAULT NULL)
RETURNS TABLE (
    id uuid,
    patient_name text,
    patient_email text,
    appointment_date date,
    appointment_time time,
    appointment_type text,
    status text,
    notes text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        p.full_name as patient_name,
        u.email as patient_email,
        a.appointment_date,
        a.appointment_time,
        a.appointment_type,
        a.status,
        a.notes
    FROM appointments a
    JOIN doctors d ON a.doctor_id = d.id
    JOIN patients pt ON a.patient_id = pt.id
    JOIN profiles p ON pt.user_id = p.user_id
    JOIN auth.users u ON pt.user_id = u.id
    WHERE d.user_id = p_doctor_user_id
    AND (p_date IS NULL OR a.appointment_date = p_date)
    ORDER BY a.appointment_date DESC, a.appointment_time ASC;
END;
$$;

-- Function to get patient appointments
CREATE OR REPLACE FUNCTION get_patient_appointments(p_patient_user_id uuid, p_date date DEFAULT NULL)
RETURNS TABLE (
    id uuid,
    doctor_name text,
    doctor_specialization text,
    appointment_date date,
    appointment_time time,
    appointment_type text,
    status text,
    notes text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        p.full_name as doctor_name,
        d.specialization as doctor_specialization,
        a.appointment_date,
        a.appointment_time,
        a.appointment_type,
        a.status,
        a.notes
    FROM appointments a
    JOIN patients pt ON a.patient_id = pt.id
    JOIN doctors d ON a.doctor_id = d.id
    JOIN profiles p ON d.user_id = p.user_id
    WHERE pt.user_id = p_patient_user_id
    AND (p_date IS NULL OR a.appointment_date = p_date)
    ORDER BY a.appointment_date DESC, a.appointment_time ASC;
END;
$$;

-- Function to get doctor ID from user ID
CREATE OR REPLACE FUNCTION get_doctor_id_from_user_id(user_uuid uuid)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT id FROM doctors WHERE user_id = user_uuid;
$$;

-- =====================================================
-- 9. TRIGGERS
-- =====================================================

-- Trigger to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
  v_full_name TEXT;
BEGIN
  -- Extract data from the new auth.users record
  v_role := NEW.raw_user_meta_data->>'role';
  v_full_name := NEW.raw_user_meta_data->>'full_name';
  
  -- Default to 'patient' if role is not specified
  IF v_role IS NULL OR v_role NOT IN ('patient', 'doctor') THEN
    v_role := 'patient';
  END IF;
  
  -- Default name if not provided
  IF v_full_name IS NULL THEN
    v_full_name := 'New User';
  END IF;

  INSERT INTO public.profiles (user_id, role, full_name)
  VALUES (NEW.id, v_role, v_full_name);

  -- Insert into role-specific table based on the role
  IF v_role = 'patient' THEN
    INSERT INTO public.patients (user_id)
    VALUES (NEW.id);
  ELSIF v_role = 'doctor' THEN
    INSERT INTO public.doctors (user_id)
    VALUES (NEW.id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- COMPLETE SETUP MESSAGE
-- =====================================================

-- This will show a success message when the script completes
DO $$
BEGIN
  RAISE NOTICE 'GlucoGard database setup completed successfully!';
  RAISE NOTICE 'All tables, policies, functions, and triggers have been created.';
  RAISE NOTICE 'You can now use the app for registration and login.';
END $$; 