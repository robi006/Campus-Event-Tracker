# Campus Event Manager — Full Stack Micro Project

A college event management web app built with Next.js, React, Supabase Auth/Postgres, and Vercel-ready deployment.

## Features
- Student signup/login
- Supabase-backed events and registrations
- Student registration with duplicate protection
- My Registered Events
- Admin-only event creation/deletion
- Live registration counts
- Row Level Security (RLS)
- Responsive campus dashboard UI
- Demo fallback when Supabase is not configured

## 1. Create Supabase project
1. Create a project at https://supabase.com
2. Open **SQL Editor**.
3. Paste and run `supabase/schema.sql`.
4. In Supabase **Authentication → URL Configuration**, add your local and Vercel site URLs.

## 2. Configure environment
Copy `.env.example` to `.env.local` and fill:

NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...

Use the Project URL and anon/publishable key from Supabase project settings.

## 3. Create admin account
Register normally in the app. Then run this in Supabase SQL Editor, replacing the email:

update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'admin@example.com');

The Admin tab will appear after the user logs in again.

## 4. Run locally

npm install
npm run dev

Open http://localhost:3000

## 5. Deploy to Vercel
Import the project into Vercel and add the same two environment variables under Project Settings → Environment Variables. Deploy.

Then add the deployed Vercel URL to Supabase Authentication → URL Configuration.

## Demo flow for coordinator
1. Open Events.
2. Create a student account.
3. Open an event and click Register Now.
4. Open My Events and show the registered event.
5. Promote a second account to admin using the SQL above.
6. Login as admin.
7. Open Admin → Add Event.
8. Create an event and delete it to demonstrate CRUD.

## Note
The app intentionally includes a local demo fallback when Supabase environment variables are missing. For the actual micro-project demonstration, configure Supabase so authentication and database operations are live.
