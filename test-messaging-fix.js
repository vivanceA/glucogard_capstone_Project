const { createClient } = require('@supabase/supabase-js');

// You'll need to replace these with your actual Supabase credentials
const supabaseUrl = process.env.SUPABASE_URL || 'your-supabase-url';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-supabase-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testMessagingFunctions() {
  console.log('Testing messaging functions...\n');

  try {
    // Test 1: Check if we can access doctors table
    console.log('1. Testing doctors table access...');
    const { data: doctors, error: doctorsError } = await supabase
      .from('doctors')
      .select('user_id, specialization')
      .limit(5);

    if (doctorsError) {
      console.error('❌ Error accessing doctors table:', doctorsError.message);
    } else {
      console.log(`✅ Successfully accessed doctors table. Found ${doctors?.length || 0} doctors`);
    }

    // Test 2: Check if we can access profiles table
    console.log('\n2. Testing profiles table access...');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('user_id, full_name, role')
      .eq('role', 'doctor')
      .limit(5);

    if (profilesError) {
      console.error('❌ Error accessing profiles table:', profilesError.message);
    } else {
      console.log(`✅ Successfully accessed profiles table. Found ${profiles?.length || 0} doctor profiles`);
    }

    // Test 3: Check if we can access messages table
    console.log('\n3. Testing messages table access...');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('id, sender_id, receiver_id, message_text')
      .limit(5);

    if (messagesError) {
      console.error('❌ Error accessing messages table:', messagesError.message);
    } else {
      console.log(`✅ Successfully accessed messages table. Found ${messages?.length || 0} messages`);
    }

    // Test 4: Test the get_recent_conversations function
    console.log('\n4. Testing get_recent_conversations function...');
    if (profiles && profiles.length > 0) {
      const testUserId = profiles[0].user_id;
      const { data: conversations, error: conversationsError } = await supabase.rpc('get_recent_conversations', {
        p_user_id: testUserId
      });

      if (conversationsError) {
        console.error('❌ Error calling get_recent_conversations:', conversationsError.message);
      } else {
        console.log(`✅ Successfully called get_recent_conversations. Found ${conversations?.length || 0} conversations`);
      }
    } else {
      console.log('⚠️  Skipping conversation test - no users found');
    }

    // Test 5: Test the get_conversation_messages function
    console.log('\n5. Testing get_conversation_messages function...');
    if (messages && messages.length > 0) {
      const testMessage = messages[0];
      const { data: conversationMessages, error: conversationMessagesError } = await supabase.rpc('get_conversation_messages', {
        p_user1_id: testMessage.sender_id,
        p_user2_id: testMessage.receiver_id,
        p_limit: 10,
        p_offset: 0
      });

      if (conversationMessagesError) {
        console.error('❌ Error calling get_conversation_messages:', conversationMessagesError.message);
      } else {
        console.log(`✅ Successfully called get_conversation_messages. Found ${conversationMessages?.length || 0} messages`);
      }
    } else {
      console.log('⚠️  Skipping conversation messages test - no messages found');
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

// Run the test
testMessagingFunctions(); 