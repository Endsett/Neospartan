# Supabase Setup Instructions

## Project ID: khuoehbthswhjcowlzsx

### 1. Create/Access Your Supabase Project

1. Go to https://supabase.com
2. Sign in to your account
3. Navigate to your project with ID: `khuoehbthswhjcowlzsx`
   - If this is a new project, create it with this ID
   - If it exists, select it from your dashboard

### 2. Get Your Project Credentials

In your Supabase dashboard:
1. Go to **Project Settings** (gear icon in left sidebar)
2. Scroll down to **API** section
3. You'll find:
   - **Project URL**: Something like `https://khuoehbthswhjcowlzsx.supabase.co`
   - **anon public** key: Starts with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. Update Your .env File

Create a `.env` file in the `app` directory with your credentials:

```env
# Supabase Configuration
SUPABASE_URL=https://khuoehbthswhjcowlzsx.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Gemini API Key
GEMINI_API_KEY=AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk

# Environment
FLUTTER_ENV=development
DEBUG=true
```

### 4. Set Up Database Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Click **New query**
3. Copy and paste the contents of `app/supabase/schema.sql`
4. Click **Run** to execute the schema

### 5. Configure Authentication

1. In Supabase dashboard, go to **Authentication**
2. Click **Providers** tab
3. Enable:
   - **Email**: Already enabled by default
   - **Google**: 
     - Toggle to enable
     - Add your Google OAuth credentials
     - Set redirect URL to: `io.supabase.flutter://callback`

### 6. Run the App

```bash
cd app
flutter pub get
flutter run
```

### 7. Test the Setup

1. Open the app
2. Try to sign up with email
3. Check your Supabase dashboard to see:
   - New user in **Authentication** > **Users**
   - New profile in **Table Editor** > **user_profiles**

### Important Notes

- The project ID `khuoehbthswhjcowlzsx` should be part of your Supabase URL
- Keep your anon key secure - never commit it to version control
- The .env file is already in .gitignore for security
- If you encounter any issues, check the Supabase logs in **Dashboard** > **Logs**

### Troubleshooting

If you get authentication errors:
1. Verify your URL and anon key are correct
2. Check that Row Level Security (RLS) policies are properly set
3. Ensure the user's email is verified (if verification is required)

If database operations fail:
1. Check the schema was applied correctly
2. Verify RLS policies allow the operations
3. Check the database logs for detailed errors
