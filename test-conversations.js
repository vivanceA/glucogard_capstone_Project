const { createClient } = require('@supabase/supabase-js');

// You'll need to replace these with your actual Supabase credentials
const supabaseUrl = process.env.SUPABASE_URL || 'your-supabase-url';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-supabase-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testConversations() {
  console.log('Testing conversations and messages...\n');

  try {
    // Test 1: Check if there are any messages in the database
    console.log('1. Checking messages table...');
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('*')
      .limit(10);

    if (messagesError) {
      console.error('❌ Error accessing messages table:', messagesError.message);
    } else {
      console.log(`✅ Found ${messages?.length || 0} messages in database`);
      if (messages && messages.length > 0) {
        console.log('Sample message:', messages[0]);
      }
    }

    // Test 2: Check if there are any users with profiles
    console.log('\n2. Checking profiles table...');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('user_id, full_name, role')
      .limit(10);

    if (profilesError) {
      console.error('❌ Error accessing profiles table:', profilesError.message);
    } else {
      console.log(`✅ Found ${profiles?.length || 0} profiles in database`);
      if (profiles && profiles.length > 0) {
        console.log('Sample profiles:', profiles.slice(0, 3));
      }
    }

    // Test 3: Test the get_recent_conversations function
    console.log('\n3. Testing get_recent_conversations function...');
    if (profiles && profiles.length > 0) {
      const testUserId = profiles[0].user_id;
      console.log(`Testing with user ID: ${testUserId}`);
      
      const { data: conversations, error: conversationsError } = await supabase.rpc('get_recent_conversations', {
        p_user_id: testUserId
      });

      if (conversationsError) {
        console.error('❌ Error calling get_recent_conversations:', conversationsError.message);
      } else {
        console.log(`✅ Found ${conversations?.length || 0} conversations for user`);
        if (conversations && conversations.length > 0) {
          console.log('Sample conversation:', conversations[0]);
        }
      }
    } else {
      console.log('⚠️  Skipping conversation test - no users found');
    }

    // Test 4: Manual conversation query
    console.log('\n4. Manual conversation query...');
    if (messages && messages.length > 0 && profiles && profiles.length > 0) {
      const testUserId = profiles[0].user_id;
      console.log(`Testing manual query for user ID: ${testUserId}`);
      
      // Get all messages for this user
      const { data: userMessages, error: userMessagesError } = await supabase
        .from('messages')
        .select('*')
        .or(`sender_id.eq.${testUserId},receiver_id.eq.${testUserId}`)
        .order('created_at', { ascending: false });

      if (userMessagesError) {
        console.error('❌ Error with manual message query:', userMessagesError.message);
      } else {
        console.log(`✅ Found ${userMessages?.length || 0} messages for user`);
        
        if (userMessages && userMessages.length > 0) {
          // Get unique conversation partners
          const conversationPartners = new Set();
          userMessages.forEach(msg => {
            if (msg.sender_id === testUserId) {
              conversationPartners.add(msg.receiver_id);
            } else {
              conversationPartners.add(msg.sender_id);
            }
          });
          
          console.log(`✅ Found ${conversationPartners.size} conversation partners`);
          console.log('Conversation partners:', Array.from(conversationPartners));
        }
      }
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

// Run the test
testConversations(); 