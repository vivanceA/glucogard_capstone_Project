#!/bin/bash

echo "🔧 Setting up EAS secrets for GlucoGard APK builds..."
echo ""

# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    echo -n "$prompt [$default]: "
    read input
    
    if [ -z "$input" ]; then
        input="$default"
    fi
    
    echo "$var_name=$input"
}

echo "Please provide your actual environment variables:"
echo ""

# Get Supabase URL
supabase_url=$(prompt_with_default "Enter your Supabase project URL" "https://gwjempkkmwnezminxa.supabase.co" "EXPO_PUBLIC_SUPABASE_URL")

# Get Supabase Anon Key
supabase_key=$(prompt_with_default "Enter your Supabase anon key" "your-actual-anon-key" "EXPO_PUBLIC_SUPABASE_ANON_KEY")

# Get API URL
api_url=$(prompt_with_default "Enter your API URL" "http://localhost:8000" "EXPO_PUBLIC_API_URL")

# Get Web Dashboard URL
web_dashboard_url=$(prompt_with_default "Enter your web dashboard URL" "https://localhost:8081/web-dashboard" "EXPO_PUBLIC_WEB_DASHBOARD_URL")

# Get Research Portal URL
research_portal_url=$(prompt_with_default "Enter your research portal URL" "https://localhost:8081/research-portal" "EXPO_PUBLIC_RESEARCH_PORTAL_URL")

# Get Google Cloud Vision API Key
google_vision_key=$(prompt_with_default "Enter your Google Cloud Vision API Key" "your-google-vision-key" "EXPO_PUBLIC_GOOGLE_CLOUD_VISION_API_KEY")

# Get Spoonacular API Key
spoonacular_key=$(prompt_with_default "Enter your Spoonacular API Key" "your-spoonacular-key" "EXPO_PUBLIC_SPOONACULAR_API_KEY")

# Get Clarifai API Key
clarifai_key=$(prompt_with_default "Enter your Clarifai API Key" "your-clarifai-key" "EXPO_PUBLIC_CLARIFAI_API_KEY")

# Get Gemini API Key
gemini_key=$(prompt_with_default "Enter your Gemini API Key" "your-gemini-key" "EXPO_PUBLIC_GEMINI_API_KEY")

echo ""
echo "🔐 Setting up EAS secrets..."

# Set secrets for all build profiles
echo "Setting up secrets for development, preview, and production builds..."

# Development secrets
npx eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_URL --value "$supabase_url" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_ANON_KEY --value "$supabase_key" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_API_URL --value "$api_url" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_WEB_DASHBOARD_URL --value "$web_dashboard_url" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_RESEARCH_PORTAL_URL --value "$research_portal_url" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_GOOGLE_CLOUD_VISION_API_KEY --value "$google_vision_key" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_SPOONACULAR_API_KEY --value "$spoonacular_key" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_CLARIFAI_API_KEY --value "$clarifai_key" --type development
npx eas secret:create --scope project --name EXPO_PUBLIC_GEMINI_API_KEY --value "$gemini_key" --type development

# Preview secrets
npx eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_URL --value "$supabase_url" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_ANON_KEY --value "$supabase_key" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_API_URL --value "$api_url" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_WEB_DASHBOARD_URL --value "$web_dashboard_url" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_RESEARCH_PORTAL_URL --value "$research_portal_url" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_GOOGLE_CLOUD_VISION_API_KEY --value "$google_vision_key" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_SPOONACULAR_API_KEY --value "$spoonacular_key" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_CLARIFAI_API_KEY --value "$clarifai_key" --type preview
npx eas secret:create --scope project --name EXPO_PUBLIC_GEMINI_API_KEY --value "$gemini_key" --type preview

# Production secrets
npx eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_URL --value "$supabase_url" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_SUPABASE_ANON_KEY --value "$supabase_key" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_API_URL --value "$api_url" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_WEB_DASHBOARD_URL --value "$web_dashboard_url" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_RESEARCH_PORTAL_URL --value "$research_portal_url" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_GOOGLE_CLOUD_VISION_API_KEY --value "$google_vision_key" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_SPOONACULAR_API_KEY --value "$spoonacular_key" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_CLARIFAI_API_KEY --value "$clarifai_key" --type production
npx eas secret:create --scope project --name EXPO_PUBLIC_GEMINI_API_KEY --value "$gemini_key" --type production

echo ""
echo "✅ Environment variables have been set up as EAS secrets!"
echo ""
echo "🚀 You can now build your APK with:"
echo "   npx eas build --platform android --profile preview"
echo "   or"
echo "   npx eas build --platform android --profile production"
echo ""
echo "📱 The APK will include all your environment variables securely!" 