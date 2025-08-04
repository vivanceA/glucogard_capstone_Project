-- Fix patient-doctor visibility issues
-- Run this script in your Supabase SQL editor

-- 1. Add RLS policy to allow patients to view doctors
DROP POLICY IF EXISTS "Patients can view doctors" ON doctors;
CREATE POLICY "Patients can view doctors" ON doctors
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'patient'
    )
  );

-- 2. Add RLS policy to allow doctors to view other doctors (for potential referrals)
DROP POLICY IF EXISTS "Doctors can view other doctors" ON doctors;
CREATE POLICY "Doctors can view other doctors" ON doctors
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'doctor'
    )
  );

-- 3. Update the existing "Doctors can read own data" policy to be more comprehensive
DROP POLICY IF EXISTS "Doctors can read own data" ON doctors;
CREATE POLICY "Doctors can read own data" ON doctors
  FOR SELECT USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'doctor'
    ) OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'patient'
    )
  );

-- 4. Ensure RLS is enabled on doctors table
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

-- 5. Add RLS policy for profiles to allow patients to view doctor profiles
DROP POLICY IF EXISTS "Patients can view doctor profiles" ON profiles;
CREATE POLICY "Patients can view doctor profiles" ON profiles
  FOR SELECT USING (
    role = 'doctor' OR
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'doctor'
    )
  );

-- 6. Update the existing profiles policy to be more comprehensive
DROP POLICY IF EXISTS "Users can view profiles" ON profiles;
CREATE POLICY "Users can view profiles" ON profiles
  FOR SELECT USING (
    user_id = auth.uid() OR 
    role = 'doctor' OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'doctor'
    )
  );

-- 7. Test the policies by checking if patients can now see doctors
-- (This is just for verification - you can run this separately)
SELECT 
  'RLS Policies Updated Successfully' as status,
  COUNT(*) as total_doctors,
  COUNT(CASE WHEN p.role = 'doctor' THEN 1 END) as doctor_profiles
FROM profiles p
WHERE p.role = 'doctor'; 