@echo off
REM ============================================================
REM  Script chay ung dung Study Library tren Chrome (Web)
REM  Firebase project: my-docs-manager-9cdf8
REM
REM  Supabase Dashboard -> Settings -> API
REM  GOOGLE_SERVER_CLIENT_ID chi can cho Android/iOS, khong can cho Web
REM ============================================================

set SUPABASE_URL=https://hnyzjxyfqpwetclfnuef.supabase.co
set SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhueXpqeHlmcXB3ZXRjbGZudWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4NzMxMzIsImV4cCI6MjEwNzQ0OTEzMn0.OblUhfKvJELsQS-ED8Oqdb7b7qRdoZcY7UrezaAK7Nw

flutter run -d chrome ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY% ^
  --dart-define=FIREBASE_FUNCTIONS_REGION=us-central1
