const { createClient } = require('@supabase/supabase-js');

// Replace with your actual Supabase URL and anon key
const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function testCalendarFunction() {
  try {
    console.log('Testing calendar function...');
    
    // Test the database function
    const { data, error } = await supabase.rpc('get_user_calendar_data', {
      p_user_id: 'test-user-id', // Replace with a real user ID
      p_start_date: '2025-07-01',
      p_end_date: '2025-07-31'
    });

    if (error) {
      console.error('Database function error:', error);
    } else {
      console.log('Database function result:', data);
    }
  } catch (error) {
    console.error('Test failed:', error);
  }
}

testCalendarFunction(); 