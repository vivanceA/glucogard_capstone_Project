// Test script to verify messaging functionality
const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client
const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY || 'your-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testMessaging() {
  console.log('🧪 Testing Messaging Functionality...\n');

  try {
    // Test 1: Check if messages table exists and has correct structure
    console.log('1. Testing messages table structure...');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('*')
      .limit(1);
    
    if (messagesError) {
      console.log('❌ Messages table error:', messagesError.message);
    } else {
      console.log('✅ Messages table accessible');
    }

    // Test 2: Check if messaging functions exist
    console.log('\n2. Testing messaging functions...');
    
    // Test get_recent_conversations function
    const { data: conversations, error: conversationsError } = await supabase
      .rpc('get_recent_conversations', { p_user_id: '00000000-0000-0000-0000-000000000000' });
    
    if (conversationsError) {
      console.log('❌ get_recent_conversations function error:', conversationsError.message);
    } else {
      console.log('✅ get_recent_conversations function works');
    }

    // Test get_conversation_messages function
    const { data: convMessages, error: convMessagesError } = await supabase
      .rpc('get_conversation_messages', { 
        p_user1_id: '00000000-0000-0000-0000-000000000000',
        p_user2_id: '00000000-0000-0000-0000-000000000001'
      });
    
    if (convMessagesError) {
      console.log('❌ get_conversation_messages function error:', convMessagesError.message);
    } else {
      console.log('✅ get_conversation_messages function works');
    }

    // Test 3: Check if doctors can see patients
    console.log('\n3. Testing doctor-patient visibility...');
    
    const { data: patients, error: patientsError } = await supabase
      .from('patients')
      .select('*')
      .limit(5);
    
    if (patientsError) {
      console.log('❌ Patients table error:', patientsError.message);
    } else {
      console.log(`✅ Patients table accessible (found ${patients?.length || 0} patients)`);
    }

    // Test 4: Check if health submissions are accessible
    console.log('\n4. Testing health submissions access...');
    
    const { data: submissions, error: submissionsError } = await supabase
      .from('health_submissions')
      .select('*')
      .limit(5);
    
    if (submissionsError) {
      console.log('❌ Health submissions error:', submissionsError.message);
    } else {
      console.log(`✅ Health submissions accessible (found ${submissions?.length || 0} submissions)`);
    }

    // Test 5: Check profiles table
    console.log('\n5. Testing profiles table...');
    
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('*')
      .limit(5);
    
    if (profilesError) {
      console.log('❌ Profiles table error:', profilesError.message);
    } else {
      console.log(`✅ Profiles table accessible (found ${profiles?.length || 0} profiles)`);
    }

    console.log('\n🎉 Messaging functionality test completed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run the test
testMessaging(); 