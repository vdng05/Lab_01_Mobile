@echo off
REM ============================================================
REM  Script chạy ứng dụng Study Library trên Windows Desktop
REM  Firebase project: my-docs-manager-9cdf8
REM
REM  Điền SUPABASE_URL và SUPABASE_PUBLISHABLE_KEY (anon key)
REM  từ Supabase Dashboard → Settings → API
REM  GOOGLE_SERVER_CLIENT_ID không bắt buộc cho Windows
REM  (Windows dùng signInWithProvider popup thay vì GoogleSignIn)
REM ============================================================

set SUPABASE_URL=https://hnyzjxyfqpwetclfnuef.supabase.co
set SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhueXpqeHlmcXB3ZXRjbGZudWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4NzMxMzIsImV4cCI6MjEwNzQ0OTEzMn0.OblUhfKvJELsQS-ED8Oqdb7b7qRdoZcY7UrezaAK7Nw

flutter run -d windows --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY% ^
  --dart-define=FIREBASE_FUNCTIONS_REGION=us-central1

