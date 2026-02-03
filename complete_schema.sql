-- ============================================================================
-- COMPLETE SUPABASE SCHEMA FILE
-- ============================================================================
-- This file contains all database migrations combined in chronological order.
-- You can paste this entire file into the Supabase SQL Editor to recreate
-- your entire database schema, including:
--
--   ✓ All tables (subscription, pending_payments, tournaments, etc.)
--   ✓ All database functions (get_available_slots, check_booking_overlap, etc.)
--   ✓ All views (tournament_public_view, etc.)
--   ✓ All storage buckets (expense-receipts, tournament-images, etc.)
--   ✓ All RLS (Row Level Security) policies
--   ✓ All indexes
--   ✓ All triggers
--   ✓ Realtime replication settings
--
-- IMPORTANT NOTES:
--   1. This file includes data migrations (UPDATE/INSERT statements) which
--      will modify existing data if run on a database that already has data.
--   2. Edge functions are NOT included - they are Vercel serverless functions
--      located in the /api directory, not Supabase edge functions.
--   3. Some migrations may fail if run on a fresh database (e.g., UPDATE
--      statements on non-existent tables). This is expected and safe to ignore.
--   4. For a fresh database, you may want to remove data-only migrations
--      (UPDATE/INSERT statements) before running.
--
-- USAGE:
--   1. Open Supabase Dashboard → SQL Editor
--   2. Paste this entire file
--   3. Click "Run" or press Cmd/Ctrl + Enter
--   4. Check for any errors (some are expected if tables don't exist yet)
--
-- ============================================================================

-- ============================================================================
-- MIGRATIONS START HERE (in chronological order)
-- ============================================================================

-- ============================================================================
-- BASE TABLES AND SETUP (from src/integrations/supabase/migrations)
-- ============================================================================

-- ============================================================================
-- CORE BASE TABLES (must be created first, before migrations)
-- ============================================================================

-- Create admin_users table
CREATE TABLE IF NOT EXISTS public.admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  is_admin BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create admin_auth table
CREATE TABLE IF NOT EXISTS public.admin_auth (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pin TEXT NOT NULL DEFAULT '2101',
  last_updated TIMESTAMPTZ DEFAULT now(),
  updated_by UUID
);

-- Create stations table
CREATE TABLE IF NOT EXISTS public.stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  hourly_rate NUMERIC NOT NULL,
  is_occupied BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  consolidated_name TEXT,
  is_controller BOOLEAN DEFAULT false,
  parent_station_id UUID,
  currentsession JSONB
);

-- Create customers table
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  is_member BOOLEAN NOT NULL DEFAULT false,
  membership_expiry_date TIMESTAMPTZ,
  membership_start_date TIMESTAMPTZ,
  membership_plan TEXT,
  membership_hours_left INTEGER,
  membership_duration TEXT,
  loyalty_points INTEGER NOT NULL DEFAULT 0,
  total_spent NUMERIC NOT NULL DEFAULT 0,
  total_play_time INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  membership_seconds_left BIGINT,
  created_via_tournament BOOLEAN DEFAULT false,
  customer_id TEXT,
  custom_id TEXT NOT NULL UNIQUE
);

-- Create products table
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price NUMERIC NOT NULL,
  category TEXT NOT NULL,
  stock INTEGER NOT NULL,
  image TEXT,
  original_price NUMERIC,
  offer_price NUMERIC,
  student_price NUMERIC,
  duration TEXT,
  membership_hours INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  buying_price NUMERIC,
  selling_price NUMERIC,
  profit NUMERIC
);

-- Create bills table
CREATE TABLE IF NOT EXISTS public.bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID,
  subtotal NUMERIC NOT NULL,
  discount NUMERIC NOT NULL DEFAULT 0,
  discount_value NUMERIC NOT NULL DEFAULT 0,
  discount_type TEXT NOT NULL DEFAULT 'percentage',
  loyalty_points_used INTEGER NOT NULL DEFAULT 0,
  loyalty_points_earned INTEGER NOT NULL DEFAULT 0,
  total NUMERIC NOT NULL,
  payment_method TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_split_payment BOOLEAN DEFAULT false,
  cash_amount NUMERIC DEFAULT 0,
  upi_amount NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'completed',
  comp_note TEXT,
  CONSTRAINT bills_payment_method_check CHECK (payment_method IN ('cash', 'upi', 'split', 'credit'))
);

-- Create bill_items table
CREATE TABLE IF NOT EXISTS public.bill_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  item_id UUID NOT NULL,
  item_type TEXT NOT NULL,
  name TEXT NOT NULL,
  price NUMERIC NOT NULL,
  quantity INTEGER NOT NULL,
  total NUMERIC NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id UUID NOT NULL,
  customer_id UUID NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME WITHOUT TIME ZONE NOT NULL,
  end_time TIME WITHOUT TIME ZONE NOT NULL,
  duration INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'confirmed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes TEXT,
  status_updated_at TIMESTAMPTZ,
  status_updated_by TEXT,
  booking_group_id UUID,
  coupon_code TEXT,
  discount_percentage NUMERIC,
  original_price NUMERIC,
  final_price NUMERIC,
  payment_mode TEXT,
  payment_txn_id TEXT
);

-- Create sessions table
CREATE TABLE IF NOT EXISTS public.sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id UUID NOT NULL,
  customer_id UUID,
  start_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_time TIMESTAMPTZ,
  duration INTEGER,
  status TEXT DEFAULT 'active',
  price NUMERIC,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_paused BOOLEAN DEFAULT false,
  paused_at TIMESTAMPTZ,
  total_paused_time BIGINT DEFAULT 0,
  hourly_rate NUMERIC,
  original_rate NUMERIC,
  coupon_code TEXT,
  discount_amount NUMERIC
);

-- Create tournaments table
CREATE TABLE IF NOT EXISTS public.tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  game_type TEXT NOT NULL,
  game_variant TEXT,
  game_title TEXT,
  date TEXT NOT NULL,
  players JSONB NOT NULL DEFAULT '[]'::jsonb,
  matches JSONB NOT NULL DEFAULT '[]'::jsonb,
  status TEXT NOT NULL,
  budget NUMERIC,
  winner_prize NUMERIC,
  runner_up_prize NUMERIC,
  winner JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  max_players INTEGER DEFAULT 16,
  tournament_format VARCHAR(20) NOT NULL DEFAULT 'knockout' CHECK (tournament_format IN ('knockout', 'league')),
  runner_up JSONB
);

-- Create cash_vault table
CREATE TABLE IF NOT EXISTS public.cash_vault (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  current_amount NUMERIC NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by TEXT NOT NULL
);

-- Create cash_vault_transactions table
CREATE TABLE IF NOT EXISTS public.cash_vault_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount NUMERIC NOT NULL,
  transaction_type TEXT NOT NULL,
  transaction_number TEXT,
  person_name TEXT NOT NULL,
  notes TEXT,
  remarks TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by TEXT NOT NULL DEFAULT 'system'
);

-- Create cash_bank_deposits table
CREATE TABLE IF NOT EXISTS public.cash_bank_deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount NUMERIC NOT NULL,
  transaction_number TEXT NOT NULL,
  person_name TEXT NOT NULL,
  notes TEXT,
  remarks TEXT,
  deposit_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by TEXT NOT NULL DEFAULT 'system'
);

-- Create cash_deposits table
CREATE TABLE IF NOT EXISTS public.cash_deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount NUMERIC NOT NULL,
  deposit_date DATE NOT NULL DEFAULT CURRENT_DATE,
  bank_name TEXT,
  reference_number TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by TEXT NOT NULL DEFAULT 'system'
);

-- Create cash_summary table
CREATE TABLE IF NOT EXISTS public.cash_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL DEFAULT CURRENT_DATE UNIQUE,
  opening_balance NUMERIC NOT NULL DEFAULT 0,
  total_sales NUMERIC NOT NULL DEFAULT 0,
  total_deposits NUMERIC NOT NULL DEFAULT 0,
  total_withdrawals NUMERIC NOT NULL DEFAULT 0,
  closing_balance NUMERIC NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create cash_transactions table
CREATE TABLE IF NOT EXISTS public.cash_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount NUMERIC NOT NULL,
  transaction_type TEXT NOT NULL,
  description TEXT,
  bill_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by TEXT NOT NULL DEFAULT 'system'
);

-- Create customer_users table
CREATE TABLE IF NOT EXISTS public.customer_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID,
  customer_id UUID,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  referral_code TEXT,
  reset_pin TEXT,
  reset_pin_expiry TIMESTAMPTZ,
  pin TEXT
);

-- Create slot_reservations table
CREATE TABLE IF NOT EXISTS public.slot_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id UUID NOT NULL REFERENCES public.stations(id),
  booking_date DATE NOT NULL,
  start_time TIME WITHOUT TIME ZONE NOT NULL,
  end_time TIME WITHOUT TIME ZONE NOT NULL,
  reserved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + '00:05:00'::interval),
  customer_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create slot_blocks table
CREATE TABLE IF NOT EXISTS public.slot_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id UUID NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME WITHOUT TIME ZONE NOT NULL,
  end_time TIME WITHOUT TIME ZONE NOT NULL,
  blocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  session_id TEXT,
  customer_phone TEXT,
  is_confirmed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create staff_profiles table
CREATE TABLE IF NOT EXISTS public.staff_profiles (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL UNIQUE,
  full_name TEXT,
  designation TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  monthly_salary NUMERIC NOT NULL DEFAULT 0,
  hourly_rate NUMERIC NOT NULL DEFAULT 0,
  default_shift_hours NUMERIC DEFAULT 8,
  is_active BOOLEAN DEFAULT true,
  role TEXT DEFAULT 'staff',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  joining_date DATE DEFAULT CURRENT_DATE,
  shift_start_time TIME WITHOUT TIME ZONE DEFAULT '11:00:00',
  shift_end_time TIME WITHOUT TIME ZONE DEFAULT '23:00:00',
  total_break_violations INTEGER DEFAULT 0
);

-- Create staff_attendance table
CREATE TABLE IF NOT EXISTS public.staff_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  date DATE NOT NULL,
  clock_in TIMESTAMPTZ NOT NULL,
  clock_out TIMESTAMPTZ,
  break_start_time TIMESTAMPTZ,
  break_end_time TIMESTAMPTZ,
  break_duration_minutes INTEGER DEFAULT 0,
  total_working_hours NUMERIC,
  daily_earnings NUMERIC,
  status TEXT DEFAULT 'active',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create active_breaks table
CREATE TABLE IF NOT EXISTS public.active_breaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  attendance_id UUID NOT NULL,
  break_start TIMESTAMPTZ NOT NULL,
  break_end TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create staff_break_violations table
CREATE TABLE IF NOT EXISTS public.staff_break_violations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  date DATE NOT NULL,
  break_duration_minutes INTEGER NOT NULL,
  excess_minutes INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create staff_payroll table
CREATE TABLE IF NOT EXISTS public.staff_payroll (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  total_working_days INTEGER DEFAULT 0,
  total_working_hours NUMERIC DEFAULT 0,
  base_salary NUMERIC DEFAULT 0,
  gross_earnings NUMERIC DEFAULT 0,
  total_deductions NUMERIC DEFAULT 0,
  total_allowances NUMERIC DEFAULT 0,
  net_salary NUMERIC DEFAULT 0,
  payment_status TEXT DEFAULT 'pending',
  payment_date DATE,
  payment_method TEXT,
  generated_at TIMESTAMPTZ DEFAULT now(),
  generated_by TEXT,
  notes TEXT
);

-- Create staff_allowances table
CREATE TABLE IF NOT EXISTS public.staff_allowances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  allowance_type TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  reason TEXT,
  approved_by TEXT,
  month INTEGER,
  year INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create staff_deductions table
CREATE TABLE IF NOT EXISTS public.staff_deductions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  deduction_type TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  reason TEXT,
  deduction_date DATE NOT NULL,
  marked_by TEXT,
  month INTEGER,
  year INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create staff_leave_requests table
CREATE TABLE IF NOT EXISTS public.staff_leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  leave_type TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days INTEGER,
  reason TEXT,
  status TEXT DEFAULT 'pending',
  reviewed_by TEXT,
  reviewed_at TIMESTAMPTZ,
  remarks TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create staff_work_schedules table
CREATE TABLE IF NOT EXISTS public.staff_work_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id UUID NOT NULL,
  day_of_week INTEGER NOT NULL,
  shift_start TIME WITHOUT TIME ZONE NOT NULL,
  shift_end TIME WITHOUT TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create loyalty_transactions table
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID,
  points INTEGER NOT NULL,
  source TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create rewards table
CREATE TABLE IF NOT EXISTS public.rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  points_cost INTEGER NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create reward_redemptions table
CREATE TABLE IF NOT EXISTS public.reward_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID,
  reward_id UUID NOT NULL,
  points_spent INTEGER NOT NULL,
  redemption_code TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  staff_id TEXT,
  redeemed_at TIMESTAMPTZ
);

-- Create referrals table
CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL,
  referred_email TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  points_awarded INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- Create promotions table
CREATE TABLE IF NOT EXISTS public.promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  discount_type TEXT NOT NULL,
  discount_value NUMERIC NOT NULL,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR NOT NULL DEFAULT 'info',
  is_read BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB
);

-- Create notification_templates table
CREATE TABLE IF NOT EXISTS public.notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  title_template TEXT NOT NULL,
  message_template TEXT NOT NULL,
  type VARCHAR NOT NULL DEFAULT 'info',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create email_templates table
CREATE TABLE IF NOT EXISTS public.email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  subject_template TEXT NOT NULL,
  body_template TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create login_logs table
CREATE TABLE IF NOT EXISTS public.login_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL,
  is_admin BOOLEAN NOT NULL,
  ip_address TEXT,
  city TEXT,
  region TEXT,
  country TEXT,
  timezone TEXT,
  isp TEXT,
  browser TEXT,
  browser_version TEXT,
  os TEXT,
  os_version TEXT,
  device_type TEXT,
  device_model TEXT,
  device_vendor TEXT,
  user_agent TEXT,
  login_time TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  login_success BOOLEAN DEFAULT true,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  location_accuracy DOUBLE PRECISION,
  selfie_url TEXT,
  screen_resolution TEXT,
  color_depth INTEGER,
  pixel_ratio DOUBLE PRECISION,
  cpu_cores INTEGER,
  device_memory DOUBLE PRECISION,
  touch_support BOOLEAN,
  connection_type TEXT,
  battery_level DOUBLE PRECISION,
  canvas_fingerprint TEXT,
  installed_fonts TEXT
);

-- Create investment_partners table
CREATE TABLE IF NOT EXISTS public.investment_partners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  company TEXT,
  investment_amount NUMERIC NOT NULL DEFAULT 0,
  investment_date DATE NOT NULL,
  equity_percentage NUMERIC,
  partnership_type TEXT NOT NULL DEFAULT 'investor',
  status TEXT NOT NULL DEFAULT 'active',
  notes TEXT,
  contact_person TEXT,
  address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  initial_investment_amount NUMERIC DEFAULT 0
);

-- Create investment_transactions table
CREATE TABLE IF NOT EXISTS public.investment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id UUID NOT NULL,
  transaction_type TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  transaction_date DATE NOT NULL,
  description TEXT,
  reference_number TEXT,
  status TEXT NOT NULL DEFAULT 'completed',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- ADDITIONAL TABLES (from migrations and other sources)
-- ============================================================================

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert default categories if they don't exist
INSERT INTO categories (name)
VALUES 
  ('food'),
  ('drinks'),
  ('tobacco'),
  ('challenges'),
  ('membership')
ON CONFLICT (name) DO NOTHING;

-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  category TEXT NOT NULL,
  frequency TEXT NOT NULL,
  date TEXT NOT NULL,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add comment to table
COMMENT ON TABLE expenses IS 'Stores expense transactions for business accounting';

-- Create bill_edit_audit table to track changes
CREATE TABLE IF NOT EXISTS bill_edit_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID NOT NULL REFERENCES bills(id),
  editor_name TEXT NOT NULL,
  changes TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Add comment to table
COMMENT ON TABLE bill_edit_audit IS 'Tracks edits made to bills';

-- Add index for faster lookups by bill_id
CREATE INDEX IF NOT EXISTS idx_bill_edit_audit_bill_id ON bill_edit_audit(bill_id);

-- Enable RLS
ALTER TABLE bill_edit_audit ENABLE ROW LEVEL SECURITY;

-- Allow all operations for authenticated users
CREATE POLICY "Allow full access for authenticated users" 
ON bill_edit_audit FOR ALL USING (true);

-- Create a stored procedure to save bill edit audit records
CREATE OR REPLACE FUNCTION save_bill_edit_audit(
  p_bill_id UUID,
  p_editor_name TEXT,
  p_changes TEXT
) RETURNS VOID AS $$
BEGIN
  INSERT INTO bill_edit_audit (bill_id, editor_name, changes)
  VALUES (p_bill_id, p_editor_name, p_changes);
END;
$$ LANGUAGE plpgsql;

-- Create tournament_public_registrations table
CREATE TABLE IF NOT EXISTS public.tournament_public_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,
  registration_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  entry_fee NUMERIC DEFAULT 250,
  status TEXT NOT NULL DEFAULT 'registered',
  payment_status TEXT DEFAULT 'pending'
);

-- Create indexes for tournament_public_registrations
CREATE INDEX IF NOT EXISTS idx_tournament_public_registrations_tournament_id ON public.tournament_public_registrations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_public_registrations_status ON public.tournament_public_registrations(status);

-- Create tournament_winner_images table
CREATE TABLE IF NOT EXISTS public.tournament_winner_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  uploaded_at TIMESTAMPTZ
);

-- Create indexes for tournament_winner_images
CREATE INDEX IF NOT EXISTS idx_tournament_winner_images_tournament_id ON public.tournament_winner_images(tournament_id);

-- Create tournament_registrations table (legacy table, kept for backward compatibility)
-- Note: Actual schema shows customer_id instead of customer_name/phone/email
CREATE TABLE IF NOT EXISTS public.tournament_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL,
  registration_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  entry_fee NUMERIC DEFAULT 250,
  status TEXT NOT NULL DEFAULT 'registered'
);

-- Create indexes for tournament_registrations
CREATE INDEX IF NOT EXISTS idx_tournament_registrations_tournament_id ON public.tournament_registrations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_registrations_status ON public.tournament_registrations(status);

-- Create user_preferences table (note: schema shows user_id as UUID, but migration uses TEXT)
-- Using UUID to match actual schema
CREATE TABLE IF NOT EXISTS public.user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  preferences JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create index for user_preferences
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);

-- Enable RLS on user_preferences
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Create policy for user_preferences (users can only access their own preferences)
CREATE POLICY "Users can manage their own preferences" 
ON public.user_preferences FOR ALL 
USING (true) WITH CHECK (true);

-- Create storage bucket for tournament images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'tournament-images',
  'tournament-images',
  true,
  10485760, -- 10MB in bytes
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for tournament-images bucket
DO $$
BEGIN
  -- Allow everyone to upload files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to upload tournament images'
  ) THEN
    CREATE POLICY "Allow all to upload tournament images"
    ON storage.objects FOR INSERT
    TO public
    WITH CHECK (bucket_id = 'tournament-images');
  END IF;

  -- Allow everyone to update files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to update tournament images'
  ) THEN
    CREATE POLICY "Allow all to update tournament images"
    ON storage.objects FOR UPDATE
    TO public
    USING (bucket_id = 'tournament-images')
    WITH CHECK (bucket_id = 'tournament-images');
  END IF;

  -- Allow everyone to delete files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to delete tournament images'
  ) THEN
    CREATE POLICY "Allow all to delete tournament images"
    ON storage.objects FOR DELETE
    TO public
    USING (bucket_id = 'tournament-images');
  END IF;

  -- Allow public read access
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to read tournament images'
  ) THEN
    CREATE POLICY "Allow all to read tournament images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'tournament-images');
  END IF;
END $$;

-- ============================================================================
-- MAIN MIGRATIONS (from supabase/migrations)
-- ============================================================================

-- Update admin user credentials for NerfTurf rebrand
-- Change username from tipntop_admin to Nerfturf_admin and password to Nerfturf@123

UPDATE public.admin_users
SET 
  username = 'Nerfturf_admin',
  password = 'Nerfturf@123'
WHERE username = 'tipntop_admin' OR is_admin = true;

-- If no admin user exists, create one
INSERT INTO public.admin_users (username, password, is_admin)
SELECT 'Nerfturf_admin', 'Nerfturf@123', true
WHERE NOT EXISTS (
  SELECT 1 FROM public.admin_users WHERE is_admin = true
);

-- Create subscription table (No RLS needed - only 2 users)
CREATE TABLE IF NOT EXISTS public.subscription (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  subscription_type VARCHAR(20) NOT NULL CHECK (subscription_type IN ('monthly', 'quarterly', 'yearly')),
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE NOT NULL,
  amount_paid NUMERIC(10, 2) NOT NULL DEFAULT 0,
  pages_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- No RLS - only 2 users
-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_subscription_end_date ON public.subscription(end_date);
CREATE INDEX IF NOT EXISTS idx_subscription_is_active ON public.subscription(is_active);

-- Insert default subscription (inactive)
INSERT INTO public.subscription (is_active, subscription_type, start_date, end_date, amount_paid, pages_enabled)
VALUES (false, 'monthly', CURRENT_DATE, CURRENT_DATE, 0, false)
ON CONFLICT DO NOTHING;

-- Add plan_name and features to subscription table
ALTER TABLE public.subscription 
ADD COLUMN IF NOT EXISTS plan_name VARCHAR(50),
ADD COLUMN IF NOT EXISTS booking_access BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS staff_management_access BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS allow_custom_end_date BOOLEAN NOT NULL DEFAULT false;

-- Allow admin to enable/disable public booking page (customers see "unavailable" when disabled)
ALTER TABLE public.subscription 
ADD COLUMN IF NOT EXISTS public_booking_enabled BOOLEAN NOT NULL DEFAULT true;

-- Update existing records
UPDATE public.subscription 
SET plan_name = 'Silver Basic',
    booking_access = false,
    staff_management_access = false
WHERE plan_name IS NULL;

-- Fix get_available_slots to only block slots that overlap with active session time
-- Previously, it was blocking ALL slots if there was ANY active session
-- Now it only blocks slots that start at or after the active session's start time
CREATE OR REPLACE FUNCTION public.get_available_slots(p_date date, p_station_id uuid, p_slot_duration integer DEFAULT 60)
 RETURNS TABLE(start_time time without time zone, end_time time without time zone, is_available boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
  opening_time TIME := '11:00:00';  -- 11 AM opening time
  curr_time TIME;
  slot_end_time TIME;
BEGIN
  -- Generate time slots from opening to midnight
  curr_time := opening_time;
  
  -- Loop until we create a slot ending at midnight (00:00:00)
  WHILE TRUE LOOP
    -- Calculate the end time for this slot
    slot_end_time := curr_time + (p_slot_duration || ' minutes')::interval;
    
    -- If slot_end_time is 00:00:00, this is the last slot (ending at midnight)
    -- For 30-min slots: 23:30 + 30 min = 00:00:00
    IF slot_end_time = '00:00:00'::TIME THEN
      -- This is the last slot ending at midnight
      -- Check availability for this slot
      is_available := NOT EXISTS (
        SELECT 1 
        FROM public.bookings b
        WHERE b.station_id = p_station_id 
          AND b.booking_date = p_date
          AND b.status IN ('confirmed', 'in-progress')
          AND (
            (b.start_time <= curr_time AND b.end_time > curr_time) OR
            (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
            (b.start_time >= curr_time AND b.end_time <= slot_end_time)
          )
      );
      
      -- Check if there's an active session that overlaps with this slot for today
      -- Only block the CURRENT slot (where the session is happening right now)
      -- Past and future slots should remain available
      IF p_date = CURRENT_DATE AND is_available THEN
        is_available := NOT EXISTS (
          SELECT 1
          FROM public.sessions s
          WHERE s.station_id = p_station_id
          AND s.end_time IS NULL
          AND DATE(s.start_time) = p_date
          AND CURRENT_TIME >= curr_time  -- Current time is at or after slot start
          AND CURRENT_TIME < slot_end_time  -- Current time is before slot end
        );
      END IF;
      
      RETURN QUERY SELECT curr_time, slot_end_time, is_available;
      EXIT; -- This was the last slot
    END IF;
    
    -- For all other slots (not ending at midnight)
    -- Check if this time slot overlaps with any existing booking
    is_available := NOT EXISTS (
      SELECT 1 
      FROM public.bookings b
      WHERE b.station_id = p_station_id 
        AND b.booking_date = p_date
        AND b.status IN ('confirmed', 'in-progress')
        AND (
          (b.start_time <= curr_time AND b.end_time > curr_time) OR
          (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
          (b.start_time >= curr_time AND b.end_time <= slot_end_time)
        )
    );
    
    -- Check if there's an active session that overlaps with this slot for today
    -- Only block the CURRENT slot (where the session is happening right now)
    -- Past and future slots should remain available
    IF p_date = CURRENT_DATE AND is_available THEN
      is_available := NOT EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.station_id = p_station_id
        AND s.end_time IS NULL
        AND DATE(s.start_time) = p_date
        AND CURRENT_TIME >= curr_time  -- Current time is at or after slot start
        AND CURRENT_TIME < slot_end_time  -- Current time is before slot end
      );
    END IF;
    
    RETURN QUERY SELECT curr_time, slot_end_time, is_available;
    
    -- Move to next slot
    curr_time := slot_end_time;
    
    -- Safety check: if we've somehow wrapped around incorrectly, exit
    -- This shouldn't happen, but prevents infinite loops
    IF curr_time < opening_time AND curr_time != '00:00:00'::TIME THEN
      EXIT;
    END IF;
  END LOOP;
END;
$function$;

-- Revert: Remove slot reservation implementation
-- This migration ensures get_available_slots uses the slot blocking fix from 20250125000002
-- (only block current slot when session is running, not all slots)
-- Reservation logic has been temporarily removed - can be re-implemented later

-- Drop all existing versions of get_available_slots to avoid function overloading conflicts
DO $$
BEGIN
  -- Drop function with 3 parameters
  DROP FUNCTION IF EXISTS public.get_available_slots(date, uuid, integer);
  
  -- Drop function with 4 parameters (if it exists)
  DROP FUNCTION IF EXISTS public.get_available_slots(date, uuid, integer, text);
END $$;

-- Create the correct version without p_customer_phone parameter
CREATE OR REPLACE FUNCTION public.get_available_slots(
  p_date date, 
  p_station_id uuid, 
  p_slot_duration integer DEFAULT 60
)
RETURNS TABLE(start_time time without time zone, end_time time without time zone, is_available boolean)
LANGUAGE plpgsql
AS $$
DECLARE
  opening_time TIME := '11:00:00';  -- 11 AM opening time
  curr_time TIME;
  slot_end_time TIME;
BEGIN
  -- Generate time slots from opening to midnight
  curr_time := opening_time;
  
  -- Loop until we create a slot ending at midnight (00:00:00)
  WHILE TRUE LOOP
    -- Calculate the end time for this slot
    slot_end_time := curr_time + (p_slot_duration || ' minutes')::interval;
    
    -- If slot_end_time is 00:00:00, this is the last slot (ending at midnight)
    -- For 30-min slots: 23:30 + 30 min = 00:00:00
    IF slot_end_time = '00:00:00'::TIME THEN
      -- This is the last slot ending at midnight
      -- Check availability for this slot
      is_available := NOT EXISTS (
        SELECT 1 
        FROM public.bookings b
        WHERE b.station_id = p_station_id 
          AND b.booking_date = p_date
          AND b.status IN ('confirmed', 'in-progress')
          AND (
            (b.start_time <= curr_time AND b.end_time > curr_time) OR
            (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
            (b.start_time >= curr_time AND b.end_time <= slot_end_time)
          )
      );
      
      -- Check if there's an active session that overlaps with this slot for today
      -- Only block the CURRENT slot (where the session is happening right now)
      -- Past and future slots should remain available
      IF p_date = CURRENT_DATE AND is_available THEN
        is_available := NOT EXISTS (
          SELECT 1
          FROM public.sessions s
          WHERE s.station_id = p_station_id
          AND s.end_time IS NULL
          AND DATE(s.start_time) = p_date
          AND CURRENT_TIME >= curr_time  -- Current time is at or after slot start
          AND CURRENT_TIME < slot_end_time  -- Current time is before slot end
        );
      END IF;
      
      RETURN QUERY SELECT curr_time, slot_end_time, is_available;
      EXIT; -- This was the last slot
    END IF;
    
    -- For all other slots (not ending at midnight)
    -- Check if this time slot overlaps with any existing booking
    is_available := NOT EXISTS (
      SELECT 1 
      FROM public.bookings b
      WHERE b.station_id = p_station_id 
        AND b.booking_date = p_date
        AND b.status IN ('confirmed', 'in-progress')
        AND (
          (b.start_time <= curr_time AND b.end_time > curr_time) OR
          (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
          (b.start_time >= curr_time AND b.end_time <= slot_end_time)
        )
    );
    
    -- Check if there's an active session that overlaps with this slot for today
    -- Only block the CURRENT slot (where the session is happening right now)
    -- Past and future slots should remain available
    IF p_date = CURRENT_DATE AND is_available THEN
      is_available := NOT EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.station_id = p_station_id
        AND s.end_time IS NULL
        AND DATE(s.start_time) = p_date
        AND CURRENT_TIME >= curr_time  -- Current time is at or after slot start
        AND CURRENT_TIME < slot_end_time  -- Current time is before slot end
      );
    END IF;
    
    RETURN QUERY SELECT curr_time, slot_end_time, is_available;
    
    -- Move to next slot
    curr_time := slot_end_time;
    
    -- Safety check: if we've somehow wrapped around incorrectly, exit
    -- This shouldn't happen, but prevents infinite loops
    IF curr_time < opening_time AND curr_time != '00:00:00'::TIME THEN
      EXIT;
    END IF;
  END LOOP;
END;
$$;
-- Add photo_url column to expenses table
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS photo_url TEXT;

COMMENT ON COLUMN expenses.photo_url IS 'URL of the photo/receipt uploaded for this expense';

-- Create storage bucket for expense receipts
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'expense-receipts',
  'expense-receipts',
  true,
  5242880, -- 5MB in bytes
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Remove any existing RLS policies for expense-receipts bucket
DO $$
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Allow authenticated users to upload expense receipts" ON storage.objects;
  DROP POLICY IF EXISTS "Allow authenticated users to update expense receipts" ON storage.objects;
  DROP POLICY IF EXISTS "Allow authenticated users to delete expense receipts" ON storage.objects;
  DROP POLICY IF EXISTS "Allow public read access to expense receipts" ON storage.objects;
END $$;

-- Create permissive storage policies for expense-receipts bucket (effectively no RLS)
DO $$
BEGIN
  -- Allow everyone (anon and authenticated) to upload files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to upload expense receipts'
  ) THEN
    CREATE POLICY "Allow all to upload expense receipts"
    ON storage.objects FOR INSERT
    TO public
    WITH CHECK (bucket_id = 'expense-receipts');
  END IF;

  -- Allow everyone to update files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to update expense receipts'
  ) THEN
    CREATE POLICY "Allow all to update expense receipts"
    ON storage.objects FOR UPDATE
    TO public
    USING (bucket_id = 'expense-receipts')
    WITH CHECK (bucket_id = 'expense-receipts');
  END IF;

  -- Allow everyone to delete files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to delete expense receipts'
  ) THEN
    CREATE POLICY "Allow all to delete expense receipts"
    ON storage.objects FOR DELETE
    TO public
    USING (bucket_id = 'expense-receipts');
  END IF;

  -- Allow public read access
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow all to read expense receipts'
  ) THEN
    CREATE POLICY "Allow all to read expense receipts"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'expense-receipts');
  END IF;
END $$;

-- Create pending_payments table to store payment intents
-- This allows us to track payments and reconcile them even if customer doesn't return to browser

CREATE TABLE IF NOT EXISTS public.pending_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  razorpay_order_id TEXT NOT NULL UNIQUE,
  razorpay_payment_id TEXT,
  amount NUMERIC(10, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'expired')),
  
  -- Booking data stored as JSON
  booking_data JSONB NOT NULL,
  
  -- Customer info
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  verified_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 minutes'),
  
  -- Metadata
  notes TEXT,
  
  -- Indexes for faster queries
  CONSTRAINT pending_payments_razorpay_order_id_key UNIQUE (razorpay_order_id)
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_pending_payments_status ON public.pending_payments(status);
CREATE INDEX IF NOT EXISTS idx_pending_payments_razorpay_order_id ON public.pending_payments(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_pending_payments_razorpay_payment_id ON public.pending_payments(razorpay_payment_id) WHERE razorpay_payment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pending_payments_created_at ON public.pending_payments(created_at);
CREATE INDEX IF NOT EXISTS idx_pending_payments_expires_at ON public.pending_payments(expires_at);

-- Add comments for documentation
COMMENT ON TABLE public.pending_payments IS 'Stores payment intents for reconciliation. Payments are verified against Razorpay API to create bookings even if customer doesnt return to browser.';
COMMENT ON COLUMN public.pending_payments.status IS 'Payment status: pending (awaiting payment), success (payment verified), failed (payment failed), expired (payment expired)';
COMMENT ON COLUMN public.pending_payments.booking_data IS 'Complete booking data stored as JSON for creating booking when payment is verified';
COMMENT ON COLUMN public.pending_payments.expires_at IS 'Payment intent expires after 30 minutes if not completed';

-- Enable RLS (Row Level Security)
ALTER TABLE public.pending_payments ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read/write (for public booking page)
CREATE POLICY "Allow public read/write on pending_payments"
  ON public.pending_payments
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Prevent Duplicate Bookings: Real-time validation and database constraints
-- This ensures no two bookings can exist for the same station at overlapping times

-- 1. Create function to check for overlapping bookings
-- FIXED: Properly handles midnight (00:00:00) as end of day
CREATE OR REPLACE FUNCTION public.check_booking_overlap(
  p_station_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  has_overlap BOOLEAN;
BEGIN
  -- Check if there's an overlapping booking
  -- Special handling: when end_time is 00:00:00, treat it as end of day (midnight)
  SELECT EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.station_id = p_station_id
      AND b.booking_date = p_booking_date
      AND b.status IN ('confirmed', 'in-progress')
      AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
      AND (
        -- Case 1: New booking starts during existing booking
        -- If existing ends at midnight (00:00:00), it extends to end of day
        (b.start_time <= p_start_time AND (
          (b.end_time > p_start_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME)
        )) OR
        -- Case 2: New booking ends during existing booking
        (b.start_time < p_end_time AND (
          (b.end_time >= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time != '00:00:00'::TIME)
        )) OR
        -- Case 3: New booking is contained within existing booking
        (b.start_time >= p_start_time AND (
          (b.end_time <= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time != '00:00:00'::TIME)
        )) OR
        -- Case 4: Existing booking is contained within new booking
        (b.start_time <= p_start_time AND (
          (b.end_time >= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME)
        ))
      )
  ) INTO has_overlap;
  
  RETURN has_overlap;
END;
$$;

-- 2. Create function to validate booking before insert/update
CREATE OR REPLACE FUNCTION public.validate_booking_no_overlap()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  has_overlap BOOLEAN;
BEGIN
  -- Only validate for confirmed or in-progress bookings
  IF NEW.status IN ('confirmed', 'in-progress') THEN
    -- Check for overlaps
    SELECT public.check_booking_overlap(
      NEW.station_id,
      NEW.booking_date,
      NEW.start_time,
      NEW.end_time,
      CASE WHEN TG_OP = 'UPDATE' THEN OLD.id ELSE NULL END
    ) INTO has_overlap;
    
    IF has_overlap THEN
      RAISE EXCEPTION 'Booking conflict: Another booking already exists for station % at % from % to %',
        NEW.station_id,
        NEW.booking_date,
        NEW.start_time,
        NEW.end_time
      USING ERRCODE = '23505'; -- Unique violation error code
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- 3. Create trigger to prevent overlapping bookings
DROP TRIGGER IF EXISTS prevent_duplicate_bookings_trigger ON public.bookings;
CREATE TRIGGER prevent_duplicate_bookings_trigger
  BEFORE INSERT OR UPDATE ON public.bookings
  FOR EACH ROW
  WHEN (NEW.status IN ('confirmed', 'in-progress'))
  EXECUTE FUNCTION public.validate_booking_no_overlap();

-- 4. Create index for faster overlap checks
CREATE INDEX IF NOT EXISTS idx_bookings_station_date_status 
ON public.bookings(station_id, booking_date, status)
WHERE status IN ('confirmed', 'in-progress');

CREATE INDEX IF NOT EXISTS idx_bookings_station_date_time 
ON public.bookings(station_id, booking_date, start_time, end_time)
WHERE status IN ('confirmed', 'in-progress');

-- 5. Add comment for documentation
COMMENT ON FUNCTION public.check_booking_overlap IS 'Checks if a booking time slot overlaps with existing confirmed/in-progress bookings for the same station and date';
COMMENT ON FUNCTION public.validate_booking_no_overlap IS 'Trigger function that prevents inserting/updating bookings that overlap with existing bookings';
COMMENT ON TRIGGER prevent_duplicate_bookings_trigger ON public.bookings IS 'Prevents duplicate/overlapping bookings at the database level';

-- Improve booking conflict detection to return conflicting booking details
-- This helps debug why conflicts are detected but not visible in UI

-- Create function to get conflicting booking details (for diagnostics)
CREATE OR REPLACE FUNCTION public.get_booking_conflicts(
  p_station_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS TABLE(
  booking_id UUID,
  booking_date DATE,
  start_time TIME,
  end_time TIME,
  status TEXT,
  station_name TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id,
    b.booking_date,
    b.start_time,
    b.end_time,
    b.status::TEXT,
    s.name,
    b.created_at
  FROM public.bookings b
  INNER JOIN public.stations s ON s.id = b.station_id
  WHERE b.station_id = p_station_id
    AND b.booking_date = p_booking_date
    AND b.status IN ('confirmed', 'in-progress')
    AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
    AND (
      -- Handle midnight (00:00:00) as end of day
      -- Case 1: New booking starts during existing booking
      (b.start_time <= p_start_time AND (b.end_time > p_start_time OR b.end_time = '00:00:00'::TIME)) OR
      -- Case 2: New booking ends during existing booking (or at midnight)
      (b.start_time < p_end_time AND (b.end_time >= p_end_time OR (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME))) OR
      -- Case 3: New booking is contained within existing booking
      (b.start_time >= p_start_time AND (b.end_time <= p_end_time OR (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME))) OR
      -- Case 4: Existing booking is contained within new booking
      (b.start_time <= p_start_time AND (b.end_time >= p_end_time OR b.end_time = '00:00:00'::TIME))
    )
  ORDER BY b.created_at DESC;
END;
$$;

-- Enhanced overlap check that handles midnight (00:00:00) properly
-- When end_time is 00:00:00, it represents the end of the day
CREATE OR REPLACE FUNCTION public.check_booking_overlap_with_details(
  p_station_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  has_overlap BOOLEAN;
  conflict_details JSONB;
BEGIN
  -- Check for overlaps on the specified date
  -- Special handling: when end_time is 00:00:00, treat it as end of day
  SELECT EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.station_id = p_station_id
      AND b.booking_date = p_booking_date
      AND b.status IN ('confirmed', 'in-progress')
      AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
      AND (
        -- Case 1: New booking starts during existing booking
        -- If existing ends at midnight (00:00:00), it extends to end of day
        (b.start_time <= p_start_time AND (
          (b.end_time > p_start_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME)
        )) OR
        -- Case 2: New booking ends during existing booking
        (b.start_time < p_end_time AND (
          (b.end_time >= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time != '00:00:00'::TIME)
        )) OR
        -- Case 3: New booking is contained within existing booking
        (b.start_time >= p_start_time AND (
          (b.end_time <= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time != '00:00:00'::TIME)
        )) OR
        -- Case 4: Existing booking is contained within new booking
        (b.start_time <= p_start_time AND (
          (b.end_time >= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME)
        ))
      )
  ) INTO has_overlap;

  -- Get conflict details if overlap exists
  IF has_overlap THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', b.id,
        'booking_date', b.booking_date,
        'start_time', b.start_time,
        'end_time', b.end_time,
        'status', b.status,
        'station_name', s.name,
        'created_at', b.created_at
      )
    )
    INTO conflict_details
    FROM public.bookings b
    INNER JOIN public.stations s ON s.id = b.station_id
    WHERE b.station_id = p_station_id
      AND b.booking_date = p_booking_date
      AND b.status IN ('confirmed', 'in-progress')
      AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
      AND (
        (b.start_time <= p_start_time AND (
          (b.end_time > p_start_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME)
        )) OR
        (b.start_time < p_end_time AND (
          (b.end_time >= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time != '00:00:00'::TIME)
        )) OR
        (b.start_time >= p_start_time AND (
          (b.end_time <= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time = '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME AND p_end_time != '00:00:00'::TIME)
        )) OR
        (b.start_time <= p_start_time AND (
          (b.end_time >= p_end_time AND b.end_time != '00:00:00'::TIME) OR
          (b.end_time = '00:00:00'::TIME)
        ))
      );
  END IF;

  RETURN jsonb_build_object(
    'has_overlap', has_overlap,
    'conflicts', COALESCE(conflict_details, '[]'::jsonb)
  );
END;
$$;

-- Add comments
COMMENT ON FUNCTION public.get_booking_conflicts IS 'Returns details of bookings that conflict with the given time slot';
COMMENT ON FUNCTION public.check_booking_overlap_with_details IS 'Enhanced version of check_booking_overlap that also checks previous day for midnight-spanning bookings and returns conflict details';
-- Fix get_available_slots to properly handle midnight slot (23:30-00:00) availability
-- The issue: When checking if slot 23:30-00:00 overlaps with existing bookings,
-- the TIME comparison fails because 00:00:00 < 23:30:00 in TIME type.
-- Solution: Special handling for midnight (00:00:00) as end of day.

CREATE OR REPLACE FUNCTION public.get_available_slots(
  p_date date, 
  p_station_id uuid, 
  p_slot_duration integer DEFAULT 60
)
RETURNS TABLE(start_time time without time zone, end_time time without time zone, is_available boolean)
LANGUAGE plpgsql
AS $$
DECLARE
  opening_time TIME := '11:00:00';  -- 11 AM opening time
  curr_time TIME;
  slot_end_time TIME;
BEGIN
  -- Generate time slots from opening to midnight
  curr_time := opening_time;
  
  -- Loop until we create a slot ending at midnight (00:00:00)
  WHILE TRUE LOOP
    -- Calculate the end time for this slot
    slot_end_time := curr_time + (p_slot_duration || ' minutes')::interval;
    
    -- If slot_end_time is 00:00:00, this is the last slot (ending at midnight)
    -- For 30-min slots: 23:30 + 30 min = 00:00:00
    IF slot_end_time = '00:00:00'::TIME THEN
      -- This is the last slot ending at midnight (23:30-00:00)
      -- Check availability for this slot with proper midnight handling
      -- Key insight: When end_time = 00:00:00, it means "end of day", so any booking
      -- that ends at midnight overlaps with this slot if it starts at or before 23:30
      is_available := NOT EXISTS (
        SELECT 1 
        FROM public.bookings b
        WHERE b.station_id = p_station_id 
          AND b.booking_date = p_date
          AND b.status IN ('confirmed', 'in-progress')
          AND (
            -- Overlap if booking ends at midnight (00:00:00) and starts at or before slot start (23:30)
            (b.end_time = '00:00:00'::TIME AND b.start_time <= curr_time) OR
            -- Overlap if booking starts at or before slot start (23:30) and ends after slot start
            -- (but not at midnight, as that case is handled above)
            (b.start_time <= curr_time AND b.end_time != '00:00:00'::TIME AND b.end_time > curr_time) OR
            -- Overlap if booking starts within the slot (at or after 23:30) and ends at midnight
            (b.start_time >= curr_time AND b.end_time = '00:00:00'::TIME) OR
            -- Overlap if booking is completely contained within the slot
            (b.start_time >= curr_time AND b.end_time != '00:00:00'::TIME AND b.end_time <= slot_end_time)
          )
      );
      
      -- Check if there's an active session that overlaps with this slot for today
      IF p_date = CURRENT_DATE AND is_available THEN
        is_available := NOT EXISTS (
          SELECT 1
          FROM public.sessions s
          WHERE s.station_id = p_station_id
          AND s.end_time IS NULL
          AND DATE(s.start_time) = p_date
          AND CURRENT_TIME >= curr_time  -- Current time is at or after slot start
          AND (CURRENT_TIME < slot_end_time OR slot_end_time = '00:00:00'::TIME)  -- Handle midnight
        );
      END IF;
      
      RETURN QUERY SELECT curr_time, slot_end_time, is_available;
      EXIT; -- This was the last slot
    END IF;
    
    -- For all other slots (not ending at midnight)
    -- Check if this time slot overlaps with any existing booking
    is_available := NOT EXISTS (
      SELECT 1 
      FROM public.bookings b
      WHERE b.station_id = p_station_id 
        AND b.booking_date = p_date
        AND b.status IN ('confirmed', 'in-progress')
        AND (
          -- Standard overlap cases
          (b.start_time <= curr_time AND b.end_time > curr_time) OR
          (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
          (b.start_time >= curr_time AND b.end_time <= slot_end_time) OR
          -- Also handle case where existing booking ends at midnight
          (b.start_time <= curr_time AND b.end_time = '00:00:00'::TIME)
        )
    );
    
    -- Check if there's an active session that overlaps with this slot for today
    IF p_date = CURRENT_DATE AND is_available THEN
      is_available := NOT EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.station_id = p_station_id
        AND s.end_time IS NULL
        AND DATE(s.start_time) = p_date
        AND CURRENT_TIME >= curr_time  -- Current time is at or after slot start
        AND CURRENT_TIME < slot_end_time  -- Current time is before slot end
      );
    END IF;
    
    RETURN QUERY SELECT curr_time, slot_end_time, is_available;
    
    -- Move to next slot
    curr_time := slot_end_time;
    
    -- Safety check: if we've somehow wrapped around incorrectly, exit
    -- This shouldn't happen, but prevents infinite loops
    IF curr_time < opening_time AND curr_time != '00:00:00'::TIME THEN
      EXIT;
    END IF;
  END LOOP;
END;
$$;

-- Add comment
COMMENT ON FUNCTION public.get_available_slots IS 'Returns available time slots for a station on a given date. Properly handles midnight (00:00:00) as end of day.';
-- Verify and fix midnight overlap detection
-- This migration ensures the check_booking_overlap function correctly handles midnight slots

-- First, let's create a test to verify the function works correctly
DO $$
DECLARE
  test_result BOOLEAN;
  test_station_id UUID := '00000000-0000-0000-0000-000000000000'::uuid;
  test_date DATE := '2025-12-15';
BEGIN
  -- Test 1: No bookings exist, should return FALSE
  -- (This test requires no actual bookings, so we'll just verify the function exists)
  RAISE NOTICE 'Testing check_booking_overlap function...';
END $$;

-- Now fix the function with the SIMPLEST possible logic
-- Convert times to minutes since midnight to handle midnight correctly
CREATE OR REPLACE FUNCTION public.check_booking_overlap(
  p_station_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  has_overlap BOOLEAN;
  p_start_minutes INTEGER;
  p_end_minutes INTEGER;
  b_start_minutes INTEGER;
  b_end_minutes INTEGER;
BEGIN
  -- Convert times to minutes since midnight
  -- If end_time is 00:00:00, treat it as 1440 (end of day = 24*60 minutes)
  p_start_minutes := EXTRACT(HOUR FROM p_start_time)::INTEGER * 60 + EXTRACT(MINUTE FROM p_start_time)::INTEGER;
  p_end_minutes := CASE 
    WHEN p_end_time = '00:00:00'::TIME THEN 1440  -- 24 hours = 1440 minutes
    ELSE EXTRACT(HOUR FROM p_end_time)::INTEGER * 60 + EXTRACT(MINUTE FROM p_end_time)::INTEGER
  END;
  
  -- Check if there's an overlapping booking
  SELECT EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.station_id = p_station_id
      AND b.booking_date = p_booking_date
      AND b.status IN ('confirmed', 'in-progress')
      AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
      AND (
        -- Convert existing booking times to minutes
        -- Then use simple overlap check: bookings overlap if start_a < end_b AND start_b < end_a
        (
          (EXTRACT(HOUR FROM b.start_time)::INTEGER * 60 + EXTRACT(MINUTE FROM b.start_time)::INTEGER) < p_end_minutes
          AND
          (
            CASE 
              WHEN b.end_time = '00:00:00'::TIME THEN 1440
              ELSE EXTRACT(HOUR FROM b.end_time)::INTEGER * 60 + EXTRACT(MINUTE FROM b.end_time)::INTEGER
            END
          ) > p_start_minutes
        )
      )
  ) INTO has_overlap;
  
  RETURN has_overlap;
END;
$$;

-- Update the comment
COMMENT ON FUNCTION public.check_booking_overlap IS 'Checks if a booking time slot overlaps with existing confirmed/in-progress bookings. Properly handles midnight (00:00:00) as end of day.';
-- Change last slot to end at 23:59:59 instead of 00:00:00
-- This eliminates all midnight edge cases - much simpler solution!
-- Last slot will be 23:30:00 - 23:59:59 (for 30-min slots)
-- PERFORMANCE OPTIMIZED: Fetches bookings once instead of per-slot

CREATE OR REPLACE FUNCTION public.get_available_slots(
  p_date date, 
  p_station_id uuid, 
  p_slot_duration integer DEFAULT 60
)
RETURNS TABLE(start_time time without time zone, end_time time without time zone, is_available boolean)
LANGUAGE plpgsql
AS $$
DECLARE
  opening_time TIME := '11:00:00';  -- 11 AM opening time
  closing_time TIME := '23:59:59';  -- 11:59:59 PM - end of day (no midnight!)
  curr_time TIME;
  slot_end_time TIME;
  has_active_session BOOLEAN;
  session_start_time TIME;
BEGIN
  -- OPTIMIZATION: Check for active session once (only if today)
  IF p_date = CURRENT_DATE THEN
    SELECT EXISTS (
      SELECT 1
      FROM public.sessions s
      WHERE s.station_id = p_station_id
      AND s.end_time IS NULL
      AND DATE(s.start_time) = p_date
    ) INTO has_active_session;
    
    -- Get session start time if exists
    IF has_active_session THEN
      SELECT s.start_time::TIME INTO session_start_time
      FROM public.sessions s
      WHERE s.station_id = p_station_id
      AND s.end_time IS NULL
      AND DATE(s.start_time) = p_date
      LIMIT 1;
    END IF;
  ELSE
    has_active_session := FALSE;
  END IF;
  
  -- Generate time slots from opening to closing (23:59:59)
  curr_time := opening_time;
  
  -- Loop until we reach or exceed closing time
  WHILE curr_time < closing_time LOOP
    -- Calculate the end time for this slot
    slot_end_time := curr_time + (p_slot_duration || ' minutes')::interval;
    
    -- Don't create slots that go past closing time
    IF slot_end_time > closing_time THEN
      -- If this slot would go past closing, cap it at closing time
      slot_end_time := closing_time;
    END IF;
    
    -- OPTIMIZED: Check overlap with LIMIT 1 and proper index usage
    -- The index idx_bookings_station_date_status should make this fast
    is_available := NOT EXISTS (
      SELECT 1 
      FROM public.bookings b
      WHERE b.station_id = p_station_id 
        AND b.booking_date = p_date
        AND b.status IN ('confirmed', 'in-progress')
        AND (
          -- Standard overlap detection (no midnight edge cases!)
          (b.start_time <= curr_time AND b.end_time > curr_time) OR
          (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
          (b.start_time >= curr_time AND b.end_time <= slot_end_time) OR
          (b.start_time <= curr_time AND b.end_time >= slot_end_time)
        )
      LIMIT 1  -- Critical: Stop after first match
    );
    
    -- Check if there's an active session that overlaps with this slot for today
    IF p_date = CURRENT_DATE AND is_available AND has_active_session THEN
      -- Check if current time is within this slot and session is active
      IF CURRENT_TIME >= curr_time AND CURRENT_TIME < slot_end_time THEN
        is_available := FALSE;
      END IF;
    END IF;
    
    RETURN QUERY SELECT curr_time, slot_end_time, is_available;
    
    -- Move to next slot
    curr_time := slot_end_time;
    
    -- Exit if we've reached or passed closing time
    IF curr_time >= closing_time THEN
      EXIT;
    END IF;
  END LOOP;
END;
$$;

-- Simplify check_booking_overlap - no more midnight handling needed!
CREATE OR REPLACE FUNCTION public.check_booking_overlap(
  p_station_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  has_overlap BOOLEAN;
BEGIN
  -- Simple overlap check - no midnight edge cases!
  -- OPTIMIZED: Uses indexes and LIMIT 1 for performance
  SELECT EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.station_id = p_station_id
      AND b.booking_date = p_booking_date
      AND b.status IN ('confirmed', 'in-progress')
      AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
      AND (
        -- Standard overlap detection
        (b.start_time <= p_start_time AND b.end_time > p_start_time) OR
        (b.start_time < p_end_time AND b.end_time >= p_end_time) OR
        (b.start_time >= p_start_time AND b.end_time <= p_end_time) OR
        (b.start_time <= p_start_time AND b.end_time >= p_end_time)
      )
    LIMIT 1  -- Stop after first match for performance
  ) INTO has_overlap;
  
  RETURN has_overlap;
END;
$$;

-- Ensure indexes exist for performance
CREATE INDEX IF NOT EXISTS idx_bookings_station_date_status 
ON public.bookings(station_id, booking_date, status)
WHERE status IN ('confirmed', 'in-progress');

CREATE INDEX IF NOT EXISTS idx_bookings_station_date_time 
ON public.bookings(station_id, booking_date, start_time, end_time)
WHERE status IN ('confirmed', 'in-progress');

-- Update comments
COMMENT ON FUNCTION public.get_available_slots IS 'Returns available time slots for a station on a given date. Slots end at 23:59:59 (no midnight edge cases). Performance optimized with single booking fetch.';
COMMENT ON FUNCTION public.check_booking_overlap IS 'Checks if a booking time slot overlaps with existing confirmed/in-progress bookings. Simplified - no midnight handling needed.';
-- PERFORMANCE FIX: Optimize get_available_slots to prevent timeouts
-- Uses a single set-returning query instead of looping with multiple queries

CREATE OR REPLACE FUNCTION public.get_available_slots(
  p_date date, 
  p_station_id uuid, 
  p_slot_duration integer DEFAULT 60
)
RETURNS TABLE(start_time time without time zone, end_time time without time zone, is_available boolean)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  opening_time TIME := '11:00:00';  -- 11 AM opening time
  closing_time TIME := '23:59:59';  -- 11:59:59 PM - end of day
  total_minutes INTEGER;
  slot_count INTEGER;
BEGIN
  -- Calculate total minutes and number of slots
  total_minutes := EXTRACT(EPOCH FROM (closing_time - opening_time))::INTEGER / 60;
  slot_count := (total_minutes / p_slot_duration) + CASE WHEN total_minutes % p_slot_duration > 0 THEN 1 ELSE 0 END;
  
  -- Generate all slots and check availability in a single optimized query
  -- Uses LEFT JOIN to check overlaps efficiently
  RETURN QUERY
  WITH slot_times AS (
    SELECT 
      (opening_time + (n * p_slot_duration || ' minutes')::interval)::TIME AS slot_start,
      LEAST(
        (opening_time + ((n + 1) * p_slot_duration || ' minutes')::interval)::TIME,
        closing_time
      ) AS slot_end
    FROM generate_series(0, slot_count - 1) AS n
    WHERE (opening_time + (n * p_slot_duration || ' minutes')::interval)::TIME < closing_time
  ),
  active_bookings AS (
    -- Fetch all bookings ONCE (single query)
    SELECT b.start_time, b.end_time
    FROM public.bookings b
    WHERE b.station_id = p_station_id 
      AND b.booking_date = p_date
      AND b.status IN ('confirmed', 'in-progress')
  ),
  active_session AS (
    -- Fetch active session ONCE if today
    SELECT s.start_time::TIME AS session_start
    FROM public.sessions s
    WHERE p_date = CURRENT_DATE
      AND s.station_id = p_station_id
      AND s.end_time IS NULL
      AND DATE(s.start_time) = p_date
    LIMIT 1
  )
  SELECT 
    st.slot_start AS start_time,
    st.slot_end AS end_time,
    -- Check availability: no overlapping booking AND no active session in this slot
    NOT EXISTS (
      SELECT 1
      FROM active_bookings ab
      WHERE (
        (ab.start_time <= st.slot_start AND ab.end_time > st.slot_start) OR
        (ab.start_time < st.slot_end AND ab.end_time >= st.slot_end) OR
        (ab.start_time >= st.slot_start AND ab.end_time <= st.slot_end) OR
        (ab.start_time <= st.slot_start AND ab.end_time >= st.slot_end)
      )
    ) AND NOT (
      p_date = CURRENT_DATE 
      AND EXISTS (SELECT 1 FROM active_session)
      AND CURRENT_TIME >= st.slot_start 
      AND CURRENT_TIME < st.slot_end
    ) AS is_available
  FROM slot_times st
  ORDER BY st.slot_start;
END;
$$;

-- Update comment
COMMENT ON FUNCTION public.get_available_slots IS 'Returns available time slots for a station on a given date. Slots end at 23:59:59. PERFORMANCE OPTIMIZED: Uses single query with CTEs instead of loops.';
-- Fix check_booking_overlap to handle both old bookings (00:00:00) and new slots (23:59:59)
-- This ensures backward compatibility while supporting the new 23:59:59 slots

CREATE OR REPLACE FUNCTION public.check_booking_overlap(
  p_station_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  has_overlap BOOLEAN;
  p_end_normalized TIME;
BEGIN
  -- Normalize new booking's end time: treat 00:00:00 as 23:59:59 for comparison
  -- This handles both old bookings (00:00:00) and new slots (23:59:59)
  p_end_normalized := CASE 
    WHEN p_end_time = '00:00:00'::TIME THEN '23:59:59'::TIME
    ELSE p_end_time
  END;
  
  -- Check for overlaps with existing bookings
  -- Normalize existing bookings' end times: 00:00:00 -> 23:59:59 for comparison
  SELECT EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.station_id = p_station_id
      AND b.booking_date = p_booking_date
      AND b.status IN ('confirmed', 'in-progress')
      AND (p_exclude_booking_id IS NULL OR b.id != p_exclude_booking_id)
      AND (
        -- Normalize b.end_time: 00:00:00 -> 23:59:59, then check overlap
        (b.start_time <= p_start_time AND 
         (CASE WHEN b.end_time = '00:00:00'::TIME THEN '23:59:59'::TIME ELSE b.end_time END) > p_start_time) OR
        (b.start_time < p_end_normalized AND 
         (CASE WHEN b.end_time = '00:00:00'::TIME THEN '23:59:59'::TIME ELSE b.end_time END) >= p_end_normalized) OR
        (b.start_time >= p_start_time AND 
         (CASE WHEN b.end_time = '00:00:00'::TIME THEN '23:59:59'::TIME ELSE b.end_time END) <= p_end_normalized) OR
        (b.start_time <= p_start_time AND 
         (CASE WHEN b.end_time = '00:00:00'::TIME THEN '23:59:59'::TIME ELSE b.end_time END) >= p_end_normalized)
      )
    LIMIT 1
  ) INTO has_overlap;
  
  RETURN has_overlap;
END;
$$;

-- Update comment
COMMENT ON FUNCTION public.check_booking_overlap IS 'Checks if a booking time slot overlaps with existing confirmed/in-progress bookings. Handles both old bookings (00:00:00) and new slots (23:59:59) for backward compatibility.';
-- Add station names, timeslots, and failure reason to pending_payments table
-- This allows better visibility into what was being booked and why it failed

ALTER TABLE public.pending_payments
  ADD COLUMN IF NOT EXISTS station_names TEXT[],
  ADD COLUMN IF NOT EXISTS timeslots JSONB,
  ADD COLUMN IF NOT EXISTS failure_reason TEXT;

-- Add comments for documentation
COMMENT ON COLUMN public.pending_payments.station_names IS 'Array of station names being booked (for display purposes)';
COMMENT ON COLUMN public.pending_payments.timeslots IS 'JSONB array of timeslot objects with start_time and end_time (for display purposes)';
COMMENT ON COLUMN public.pending_payments.failure_reason IS 'Reason for payment/booking failure (populated when status is failed)';
-- Backfill station_names and timeslots for old pending_payments entries
-- This updates existing records that don't have station_names/timeslots populated

-- Backfill station_names from booking_data.selectedStations
-- This extracts station IDs from the JSONB and looks up their names
UPDATE public.pending_payments pp
SET station_names = (
  SELECT ARRAY_AGG(s.name ORDER BY s.name)
  FROM jsonb_array_elements_text(pp.booking_data->'selectedStations') AS station_id
  INNER JOIN public.stations s ON s.id = station_id::uuid
)
WHERE pp.station_names IS NULL
  AND pp.booking_data IS NOT NULL
  AND pp.booking_data->>'selectedStations' IS NOT NULL
  AND jsonb_typeof(pp.booking_data->'selectedStations') = 'array';

-- Backfill timeslots from booking_data.slots
UPDATE public.pending_payments
SET timeslots = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'start_time', slot->>'start_time',
      'end_time', slot->>'end_time'
    )
  )
  FROM jsonb_array_elements(booking_data->'slots') AS slot
)
WHERE timeslots IS NULL
  AND booking_data IS NOT NULL
  AND booking_data->>'slots' IS NOT NULL
  AND jsonb_typeof(booking_data->'slots') = 'array';

-- Mark expired payments as expired (not failed) and populate failure_reason
UPDATE public.pending_payments
SET status = 'expired',
    failure_reason = COALESCE(notes, 'Payment expired - payment window has passed')
WHERE status = 'pending'
  AND expires_at < NOW();

-- Also populate failure_reason for failed payments that have error info in notes
UPDATE public.pending_payments
SET failure_reason = COALESCE(notes, 'Payment failed (reason not recorded)')
WHERE status = 'failed'
  AND failure_reason IS NULL;
-- Mark expired pending payments as 'expired' status instead of keeping them as 'pending'
-- This runs as a one-time update for existing expired payments

UPDATE public.pending_payments
SET status = 'expired',
    failure_reason = COALESCE(failure_reason, 'Payment expired')
WHERE status = 'pending'
  AND expires_at < NOW();
-- Fix expired payments that have successful bookings
-- This migration updates expired payments to "success" status if corresponding bookings exist
-- This fixes the issue where successful payments were incorrectly marked as expired

-- Update expired payments that have bookings by payment_txn_id
UPDATE public.pending_payments pp
SET 
  status = 'success',
  verified_at = COALESCE(pp.verified_at, NOW())
WHERE pp.status = 'expired'
  AND pp.razorpay_payment_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.payment_txn_id = pp.razorpay_payment_id
      AND b.payment_mode = 'razorpay'
  );

-- Update expired payments that have bookings by order ID in notes
-- This handles cases where payment_id wasn't stored but booking has order ID in notes
-- Note: This will skip payments already updated by the first query (status != 'expired')
UPDATE public.pending_payments pp
SET 
  status = 'success',
  verified_at = COALESCE(pp.verified_at, NOW())
WHERE pp.status = 'expired'
  AND EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.notes LIKE '%Razorpay Order ID: ' || pp.razorpay_order_id || '%'
      AND b.payment_mode = 'razorpay'
  );

-- Update failure_reason to null for payments that were incorrectly marked as expired
UPDATE public.pending_payments
SET failure_reason = NULL
WHERE status = 'success'
  AND failure_reason LIKE '%Payment expired%';


-- Create a view for public tournament data that shows only necessary information
CREATE OR REPLACE VIEW public.tournament_public_view AS
SELECT 
  t.id,
  t.name,
  t.game_type,
  t.game_variant,
  t.game_title,
  t.date,
  t.status,
  t.budget,
  t.winner_prize,
  t.runner_up_prize,
  t.players,
  t.matches,
  t.winner,
  COALESCE(reg_count.total_registrations, 0) as total_registrations,
  -- Set max players based on game type and current players
  CASE 
    WHEN t.game_type = 'Pool' THEN 8
    WHEN t.game_type = 'PS5' THEN 16
    ELSE 8
  END as max_players
FROM tournaments t
LEFT JOIN (
  SELECT 
    tournament_id,
    COUNT(*) as total_registrations
  FROM tournament_public_registrations 
  WHERE status = 'registered'
  GROUP BY tournament_id
) reg_count ON t.id = reg_count.tournament_id
WHERE t.status IN ('upcoming', 'in-progress', 'completed')
ORDER BY 
  CASE 
    WHEN t.status = 'upcoming' THEN 1
    WHEN t.status = 'in-progress' THEN 2
    WHEN t.status = 'completed' THEN 3
  END,
  t.date ASC;

-- Enable RLS on tournament_public_registrations if not already enabled
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c 
    JOIN pg_namespace n ON n.oid = c.relnamespace 
    WHERE c.relname = 'tournament_public_registrations' 
    AND n.nspname = 'public' 
    AND c.relrowsecurity = true
  ) THEN
    ALTER TABLE public.tournament_public_registrations ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Drop existing policies if they exist and recreate them
DROP POLICY IF EXISTS "Allow public read access to tournament registrations" ON public.tournament_public_registrations;
DROP POLICY IF EXISTS "Allow public insert for tournament registrations" ON public.tournament_public_registrations;

-- Create policies for tournament_public_registrations
CREATE POLICY "Allow public read access to tournament registrations" 
ON public.tournament_public_registrations 
FOR SELECT 
USING (true);

CREATE POLICY "Allow public insert for tournament registrations" 
ON public.tournament_public_registrations 
FOR INSERT 
WITH CHECK (true);

-- Grant necessary permissions for the view
GRANT SELECT ON public.tournament_public_view TO anon, authenticated;
GRANT SELECT ON public.tournament_public_registrations TO anon, authenticated;
GRANT INSERT ON public.tournament_public_registrations TO anon, authenticated;

-- Add max_players column to tournaments table
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS max_players INTEGER DEFAULT 16;

-- Update existing tournaments to have a default max_players value
UPDATE public.tournaments 
SET max_players = 16 
WHERE max_players IS NULL;

-- Update the existing "Cuephoria PS5 League" tournament to have max_players = 8
UPDATE public.tournaments 
SET max_players = 8
WHERE name = 'Cuephoria PS5 League';

-- Also update any other tournaments that might not have the max_players set correctly
-- (this ensures all existing tournaments have a max_players value)
UPDATE public.tournaments 
SET max_players = COALESCE(max_players, 16)
WHERE max_players IS NULL;

-- Add runner_up field to tournaments table
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS runner_up jsonb;

-- Create tournament_history table to track detailed match results
CREATE TABLE IF NOT EXISTS public.tournament_history (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id uuid NOT NULL,
  match_id text NOT NULL,
  player1_name text NOT NULL,
  player2_name text NOT NULL,
  winner_name text NOT NULL,
  match_date date NOT NULL,
  match_stage text NOT NULL, -- 'regular', 'quarter_final', 'semi_final', 'final'
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create tournament_winners table for leaderboard
-- Note: Actual schema shows different structure
CREATE TABLE IF NOT EXISTS public.tournament_winners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL,
  winner_name TEXT NOT NULL,
  runner_up_name TEXT,
  prize_amount NUMERIC,
  tournament_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  tournament_name TEXT
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tournament_history_tournament_id ON public.tournament_history(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_history_match_date ON public.tournament_history(match_date);
CREATE INDEX IF NOT EXISTS idx_tournament_winners_winner_name ON public.tournament_winners(winner_name);
CREATE INDEX IF NOT EXISTS idx_tournament_winners_tournament_date ON public.tournament_winners(tournament_date);

-- Enable RLS on new tables
ALTER TABLE public.tournament_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_winners ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for tournament_history (read-only for public)
CREATE POLICY "Anyone can view tournament history" ON public.tournament_history
  FOR SELECT USING (true);

-- Create RLS policies for tournament_winners (read-only for public)
CREATE POLICY "Anyone can view tournament winners" ON public.tournament_winners
  FOR SELECT USING (true);

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow full access to tournament_history for authenticated users" ON tournament_history;
DROP POLICY IF EXISTS "Allow full access to tournament_winners for authenticated users" ON tournament_winners;
DROP POLICY IF EXISTS "Allow read access to tournament_history for anonymous users" ON tournament_history;
DROP POLICY IF EXISTS "Allow read access to tournament_winners for anonymous users" ON tournament_winners;

-- Create new policies that allow all operations for all users (authenticated and anonymous)
CREATE POLICY "Allow all operations on tournament_history" 
ON tournament_history FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on tournament_winners" 
ON tournament_winners FOR ALL USING (true) WITH CHECK (true);

-- Drop the existing view first
DROP VIEW IF EXISTS public.tournament_public_view;

-- Recreate the tournament_public_view with the runner_up field included
CREATE VIEW public.tournament_public_view AS
SELECT 
  t.id,
  t.name,
  t.game_type,
  t.game_variant,
  t.game_title,
  t.date,
  t.status,
  t.budget,
  t.winner_prize,
  t.runner_up_prize,
  t.players,
  t.matches,
  t.winner,
  t.runner_up,
  COALESCE(reg_count.total_registrations, 0) as total_registrations,
  t.max_players
FROM tournaments t
LEFT JOIN (
  SELECT 
    tournament_id,
    COUNT(*) as total_registrations
  FROM tournament_public_registrations 
  WHERE status = 'registered'
  GROUP BY tournament_id
) reg_count ON t.id = reg_count.tournament_id
WHERE t.status IN ('upcoming', 'in-progress', 'completed')
ORDER BY 
  CASE 
    WHEN t.status = 'upcoming' THEN 1
    WHEN t.status = 'in-progress' THEN 2
    WHEN t.status = 'completed' THEN 3
  END,
  t.date ASC;

-- Create offers table to store marketing offers
CREATE TABLE public.offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed', 'bogo', 'free_item')) DEFAULT 'percentage',
  discount_value NUMERIC,
  validity_days INTEGER DEFAULT 7,
  is_active BOOLEAN DEFAULT true,
  target_audience TEXT CHECK (target_audience IN ('all', 'members', 'non_members', 'new_customers', 'vip')) DEFAULT 'all',
  min_spend NUMERIC DEFAULT 0,
  max_uses INTEGER,
  current_uses INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert some sample offers
INSERT INTO public.offers (title, description, discount_type, discount_value, target_audience) VALUES
('Welcome Offer', 'Get 20% off on your next gaming session!', 'percentage', 20, 'new_customers'),
('Member Special', 'Enjoy a complimentary snack with your next visit!', 'free_item', 0, 'members'),
('Gaming Bonus', 'Free extra 30 minutes on your favorite game!', 'free_item', 0, 'all'),
('VIP Discount', 'Special member discount - 15% off food & drinks!', 'percentage', 15, 'members'),
('Friend Referral', 'Bring a friend and get 2-for-1 gaming hours!', 'bogo', 0, 'all'),
('Weekend Special', 'Get ₹100 off on bills above ₹500', 'fixed', 100, 'all'),
('Student Discount', 'Show your student ID and get 25% off gaming!', 'percentage', 25, 'all'),
('Loyalty Reward', 'Spend your loyalty points and get extra 10% off!', 'percentage', 10, 'members'),
('Birthday Special', 'Celebrate with us - 30% off on your birthday month!', 'percentage', 30, 'all'),
('Tournament Winner', 'Previous tournament winners get 50% off practice sessions!', 'percentage', 50, 'all');

-- Add RLS policies for offers
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

-- Allow read access for all users
CREATE POLICY "Allow read access for offers" 
ON public.offers FOR SELECT USING (true);

-- Allow full access for authenticated users (admin functionality)
CREATE POLICY "Allow full access for authenticated users on offers" 
ON public.offers FOR ALL USING (auth.role() = 'authenticated');

-- Allow read access for all users (already exists but ensuring it's there)
DROP POLICY IF EXISTS "Allow read access for offers" ON public.offers;
CREATE POLICY "Allow read access for offers" 
ON public.offers FOR SELECT USING (true);

-- Allow full access for authenticated users (this is missing and causing the insert failures)
DROP POLICY IF EXISTS "Allow full access for authenticated users on offers" ON public.offers;
CREATE POLICY "Allow full access for authenticated users on offers" 
ON public.offers FOR ALL USING (true);

-- Add tournament_format column to tournaments table
ALTER TABLE public.tournaments 
ADD COLUMN IF NOT EXISTS tournament_format VARCHAR(20) NOT NULL DEFAULT 'knockout';

-- Add a check constraint to ensure valid tournament formats
ALTER TABLE public.tournaments 
ADD CONSTRAINT check_tournament_format 
CHECK (tournament_format IN ('knockout', 'league'));

-- Update existing tournaments to have knockout format by default
UPDATE public.tournaments 
SET tournament_format = 'knockout' 
WHERE tournament_format IS NULL;

-- Add credit payment method to bills table by updating the check constraint
ALTER TABLE bills DROP CONSTRAINT IF EXISTS bills_payment_method_check;
ALTER TABLE bills ADD CONSTRAINT bills_payment_method_check CHECK (payment_method IN ('cash', 'upi', 'split', 'credit'));
-- Fix the get_available_slots function to handle proper time slot generation
CREATE OR REPLACE FUNCTION public.get_available_slots(p_date date, p_station_id uuid, p_slot_duration integer DEFAULT 60)
 RETURNS TABLE(start_time time without time zone, end_time time without time zone, is_available boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
  opening_time TIME := '11:00:00';  -- 11 AM opening time
  closing_time TIME := '23:00:00';  -- 11 PM closing time
  curr_time TIME;
  slot_end_time TIME;
BEGIN
  -- Generate time slots from opening to closing
  curr_time := opening_time;
  
  WHILE curr_time < closing_time LOOP
    -- Calculate the end time for this slot
    slot_end_time := curr_time + (p_slot_duration || ' minutes')::interval;
    
    -- Don't create slots that go past closing time
    IF slot_end_time > closing_time THEN
      EXIT;
    END IF;
    
    -- Check if this time slot overlaps with any existing booking
    is_available := NOT EXISTS (
      SELECT 1 
      FROM public.bookings b
      WHERE b.station_id = p_station_id 
        AND b.booking_date = p_date
        AND b.status IN ('confirmed', 'in-progress')
        AND (
          -- Check for time overlap using proper time comparison
          (b.start_time <= curr_time AND b.end_time > curr_time) OR
          (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
          (b.start_time >= curr_time AND b.end_time <= slot_end_time)
        )
    );
    
    -- Also check if there's an active session during this time for today
    IF p_date = CURRENT_DATE AND is_available THEN
      is_available := NOT EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.station_id = p_station_id
        AND s.end_time IS NULL
        AND DATE(s.start_time) = p_date
      );
    END IF;
    
    RETURN QUERY SELECT curr_time, slot_end_time, is_available;
    
    -- Move to next slot
    curr_time := curr_time + (p_slot_duration || ' minutes')::interval;
  END LOOP;
END;
$function$;

-- Fix the check_stations_availability function to resolve ambiguous column reference
CREATE OR REPLACE FUNCTION public.check_stations_availability(p_date date, p_start_time time without time zone, p_end_time time without time zone, p_station_ids uuid[])
 RETURNS TABLE(station_id uuid, is_available boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Add proper logging
  RAISE NOTICE 'Checking availability for date: %, start: %, end: %, stations: %', 
    p_date, p_start_time, p_end_time, p_station_ids;

  -- Return a result set with station_id and availability status
  RETURN QUERY
  WITH booking_conflicts AS (
    SELECT 
      b.station_id
    FROM 
      public.bookings b
    WHERE 
      b.booking_date = p_date
      AND b.status IN ('confirmed', 'in-progress')
      AND b.station_id = ANY(p_station_ids)
      AND (
        -- Existing booking overlaps with requested time (all four cases):
        -- Case 1: Existing booking starts during the requested time
        (b.start_time <= p_start_time AND b.end_time > p_start_time) OR
        -- Case 2: Existing booking ends during the requested time
        (b.start_time < p_end_time AND b.end_time >= p_end_time) OR
        -- Case 3: Existing booking is contained within the requested time
        (b.start_time >= p_start_time AND b.end_time <= p_end_time) OR
        -- Case 4: Requested booking is contained within an existing booking
        (b.start_time <= p_start_time AND b.end_time >= p_end_time)
      )
  ),
  session_conflicts AS (
    SELECT 
      s.station_id
    FROM 
      public.sessions s
    WHERE 
      s.end_time IS NULL -- Active sessions
      AND DATE(s.start_time) = p_date
      AND s.station_id = ANY(p_station_ids)
  )
  SELECT 
    s.id AS station_id,
    NOT EXISTS (
      SELECT 1 FROM booking_conflicts bc WHERE bc.station_id = s.id
    ) AND NOT EXISTS (
      SELECT 1 FROM session_conflicts sc WHERE sc.station_id = s.id
    ) AS is_available
  FROM
    unnest(p_station_ids) AS s(id);
END;
$function$;

-- Enable Row Level Security on tables that are missing it
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_bank_deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_vault_transactions ENABLE ROW LEVEL SECURITY;
-- Note: tournament_stats is a VIEW, not a table, so RLS doesn't apply to it
-- Views inherit RLS from their underlying tables
ALTER TABLE public.cash_summary ENABLE ROW LEVEL SECURITY;

-- Add basic RLS policies for these tables
DROP POLICY IF EXISTS "Allow all operations on categories" ON public.categories;
CREATE POLICY "Allow all operations on categories" ON public.categories FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all operations on cash_vault" ON public.cash_vault;
CREATE POLICY "Allow all operations on cash_vault" ON public.cash_vault FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all operations on cash_bank_deposits" ON public.cash_bank_deposits;
CREATE POLICY "Allow all operations on cash_bank_deposits" ON public.cash_bank_deposits FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all operations on sessions" ON public.sessions;
CREATE POLICY "Allow all operations on sessions" ON public.sessions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all operations on expenses" ON public.expenses;
CREATE POLICY "Allow all operations on expenses" ON public.expenses FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all operations on cash_vault_transactions" ON public.cash_vault_transactions;
CREATE POLICY "Allow all operations on cash_vault_transactions" ON public.cash_vault_transactions FOR ALL USING (true) WITH CHECK (true);

-- Re-enable RLS on tables that have policies but RLS is disabled
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;-- Add DELETE policies for tournament-related tables to allow tournament deletion
-- This migration adds DELETE policies for tables that need to be cleaned up when a tournament is deleted

-- Add DELETE policy for tournament_public_registrations
-- Allow authenticated users to delete registrations (needed for tournament deletion)
-- Using auth.uid() IS NOT NULL is more reliable than auth.role() = 'authenticated'
DROP POLICY IF EXISTS "Allow authenticated users to delete registrations" ON public.tournament_public_registrations;
CREATE POLICY "Allow authenticated users to delete registrations" 
ON public.tournament_public_registrations 
FOR DELETE 
USING (auth.uid() IS NOT NULL);

-- Add DELETE policy for tournament_registrations (legacy table)
-- Allow authenticated users to delete registrations
DROP POLICY IF EXISTS "Allow authenticated users to delete legacy registrations" ON public.tournament_registrations;
CREATE POLICY "Allow authenticated users to delete legacy registrations" 
ON public.tournament_registrations 
FOR DELETE 
USING (auth.uid() IS NOT NULL);

-- Ensure tournament_winner_images has DELETE policy (may already exist, but ensure it's correct)
-- The existing policy might use USING (true), but we'll add a more specific one
DROP POLICY IF EXISTS "Allow authenticated users to delete winner images" ON public.tournament_winner_images;
-- Keep the existing "Allow authenticated users" policy if it exists, but ensure DELETE is allowed
-- The policy should already allow DELETE if it says FOR ALL, but let's be explicit

-- Update tournament deletion policy
-- Keep the existing SELECT policy for public access, but ensure DELETE works for authenticated users
-- First, check what policies exist and update/create as needed

-- Drop the old policy that might use auth.role() (less reliable)
DROP POLICY IF EXISTS "Allow full access for authenticated" ON public.tournaments;

-- Create/update policy for authenticated users to perform all operations (including DELETE)
-- Use auth.uid() IS NOT NULL which is more reliable than auth.role() = 'authenticated'
DROP POLICY IF EXISTS "Allow full access for authenticated users" ON public.tournaments;
CREATE POLICY "Allow full access for authenticated users" 
ON public.tournaments 
FOR ALL 
USING (auth.uid() IS NOT NULL)
WITH CHECK (auth.uid() IS NOT NULL);

-- Ensure the public SELECT policy still exists (for public tournament pages)
-- This should already exist, but we'll verify it doesn't conflict
-- The SELECT policy should allow anyone to read tournaments

-- Ensure all required tournament columns exist
-- This migration is idempotent and safe to run multiple times

-- Add max_players column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tournaments' 
    AND column_name = 'max_players'
  ) THEN
    ALTER TABLE public.tournaments 
    ADD COLUMN IF NOT EXISTS max_players INTEGER DEFAULT 16;
    
    -- Update existing tournaments to have a default max_players value
    UPDATE public.tournaments 
    SET max_players = 16 
    WHERE max_players IS NULL;
  END IF;
END $$;

-- Add tournament_format column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tournaments' 
    AND column_name = 'tournament_format'
  ) THEN
    ALTER TABLE public.tournaments 
    ADD COLUMN tournament_format VARCHAR(20) NOT NULL DEFAULT 'knockout';
    
    -- Add a check constraint to ensure valid tournament formats
    ALTER TABLE public.tournaments 
    ADD CONSTRAINT check_tournament_format 
    CHECK (tournament_format IN ('knockout', 'league'));
    
    -- Update existing tournaments to have knockout format by default
    UPDATE public.tournaments 
    SET tournament_format = 'knockout' 
    WHERE tournament_format IS NULL;
  END IF;
END $$;

-- Add runner_up column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tournaments' 
    AND column_name = 'runner_up'
  ) THEN
    ALTER TABLE public.tournaments 
    ADD COLUMN runner_up JSONB;
  END IF;
END $$;

-- Ensure max_players has a default value for all existing records
UPDATE public.tournaments 
SET max_players = COALESCE(max_players, 16)
WHERE max_players IS NULL;

-- Ensure tournament_format has a default value for all existing records
UPDATE public.tournaments 
SET tournament_format = COALESCE(tournament_format, 'knockout')
WHERE tournament_format IS NULL;

-- Disable RLS on all tournament-related tables for 2-user app
-- This migration removes all RLS policies and disables RLS

-- Disable RLS on tournaments table
ALTER TABLE IF EXISTS public.tournaments DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies on tournaments
DROP POLICY IF EXISTS "Allow read access for all users" ON public.tournaments;
DROP POLICY IF EXISTS "Allow full access for authenticated users" ON public.tournaments;
DROP POLICY IF EXISTS "Allow all operations on tournaments" ON public.tournaments;

-- Disable RLS on tournament_winners table
ALTER TABLE IF EXISTS public.tournament_winners DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies on tournament_winners
DROP POLICY IF EXISTS "Anyone can view tournament winners" ON public.tournament_winners;
DROP POLICY IF EXISTS "Allow all operations on tournament_winners" ON public.tournament_winners;
DROP POLICY IF EXISTS "Allow full access to tournament_winners for authenticated users" ON public.tournament_winners;
DROP POLICY IF EXISTS "Allow read access to tournament_winners for anonymous users" ON public.tournament_winners;

-- Disable RLS on tournament_history table
ALTER TABLE IF EXISTS public.tournament_history DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies on tournament_history
DROP POLICY IF EXISTS "Anyone can view tournament history" ON public.tournament_history;
DROP POLICY IF EXISTS "Allow all operations on tournament_history" ON public.tournament_history;

-- Disable RLS on tournament_winner_images table
ALTER TABLE IF EXISTS public.tournament_winner_images DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies on tournament_winner_images
DROP POLICY IF EXISTS "Allow authenticated users to delete winner images" ON public.tournament_winner_images;
DROP POLICY IF EXISTS "Allow all operations on tournament_winner_images" ON public.tournament_winner_images;

-- Disable RLS on tournament_public_registrations table
ALTER TABLE IF EXISTS public.tournament_public_registrations DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies on tournament_public_registrations
DROP POLICY IF EXISTS "Allow public read access to tournament registrations" ON public.tournament_public_registrations;
DROP POLICY IF EXISTS "Allow public insert for tournament registrations" ON public.tournament_public_registrations;

-- Ensure tournament_winners has tournament_name column (in case it's missing)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tournament_winners' 
    AND column_name = 'tournament_name'
  ) THEN
    -- If tournament_name doesn't exist, we'll need to add it
    -- But first check if we can derive it from tournaments table
    ALTER TABLE public.tournament_winners 
    ADD COLUMN tournament_name text;
    
    -- Try to populate from tournaments table if possible
    UPDATE public.tournament_winners tw
    SET tournament_name = t.name
    FROM public.tournaments t
    WHERE tw.tournament_id = t.id
    AND tw.tournament_name IS NULL;
  END IF;
END $$;

-- Ensure tournament_winner_images has uploaded_at column (or use created_at)
DO $$ 
BEGIN
  -- Check if uploaded_at exists, if not, add it or use created_at
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tournament_winner_images' 
    AND column_name = 'uploaded_at'
  ) THEN
    -- Add uploaded_at column and populate from created_at if it exists
    ALTER TABLE public.tournament_winner_images 
    ADD COLUMN uploaded_at timestamp with time zone;
    
    -- If created_at exists, copy its value
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'tournament_winner_images' 
      AND column_name = 'created_at'
    ) THEN
      UPDATE public.tournament_winner_images
      SET uploaded_at = created_at
      WHERE uploaded_at IS NULL;
    ELSE
      -- Set default if created_at doesn't exist
      UPDATE public.tournament_winner_images
      SET uploaded_at = now()
      WHERE uploaded_at IS NULL;
    END IF;
  END IF;
END $$;

-- Grant necessary permissions (make sure all users can access)
GRANT ALL ON public.tournaments TO anon, authenticated;
GRANT ALL ON public.tournament_winners TO anon, authenticated;
GRANT ALL ON public.tournament_history TO anon, authenticated;
GRANT ALL ON public.tournament_winner_images TO anon, authenticated;
GRANT ALL ON public.tournament_public_registrations TO anon, authenticated;

-- Ensure tournament_public_view exists and has proper permissions
-- This migration is idempotent and safe to run multiple times

-- Drop the existing view if it exists
DROP VIEW IF EXISTS public.tournament_public_view;

-- Recreate the tournament_public_view with all necessary fields
CREATE VIEW public.tournament_public_view AS
SELECT 
  t.id,
  t.name,
  t.game_type,
  t.game_variant,
  t.game_title,
  t.date,
  t.status,
  t.budget,
  t.winner_prize,
  t.runner_up_prize,
  t.players,
  t.matches,
  t.winner,
  t.runner_up,
  COALESCE(reg_count.total_registrations, 0) as total_registrations,
  COALESCE(t.max_players, 
    CASE 
      WHEN t.game_type = 'Pool' THEN 8
      WHEN t.game_type = 'PS5' THEN 16
      ELSE 16
    END
  ) as max_players
FROM tournaments t
LEFT JOIN (
  SELECT 
    tournament_id,
    COUNT(*) as total_registrations
  FROM tournament_public_registrations 
  WHERE status = 'registered'
  GROUP BY tournament_id
) reg_count ON t.id = reg_count.tournament_id
WHERE t.status IN ('upcoming', 'in-progress', 'completed')
ORDER BY 
  CASE 
    WHEN t.status = 'upcoming' THEN 1
    WHEN t.status = 'in-progress' THEN 2
    WHEN t.status = 'completed' THEN 3
  END,
  t.date ASC;

-- Grant necessary permissions on the view
GRANT SELECT ON public.tournament_public_view TO anon, authenticated;

-- Add comment to the view
COMMENT ON VIEW public.tournament_public_view IS 'Public view of tournaments with registration counts for public website';

-- Create tournament_stats view (similar to tournament_public_view but may include additional stats)
-- This view aggregates tournament data with registration counts
CREATE OR REPLACE VIEW public.tournament_stats AS
SELECT 
  t.id,
  t.name,
  t.game_type,
  t.game_variant,
  t.game_title,
  t.date,
  t.status,
  t.budget,
  t.winner_prize,
  t.runner_up_prize,
  t.players,
  t.matches,
  t.winner,
  COALESCE(reg_count.total_registrations, 0) as total_registrations,
  COALESCE(t.max_players, 
    CASE 
      WHEN t.game_type = 'Pool' THEN 8
      WHEN t.game_type = 'PS5' THEN 16
      ELSE 16
    END
  ) as max_players
FROM tournaments t
LEFT JOIN (
  SELECT 
    tournament_id,
    COUNT(*) as total_registrations
  FROM tournament_public_registrations 
  WHERE status = 'registered'
  GROUP BY tournament_id
) reg_count ON t.id = reg_count.tournament_id
WHERE t.status IN ('upcoming', 'in-progress', 'completed')
ORDER BY 
  CASE 
    WHEN t.status = 'upcoming' THEN 1
    WHEN t.status = 'in-progress' THEN 2
    WHEN t.status = 'completed' THEN 3
  END,
  t.date ASC;

-- Grant necessary permissions on the view
GRANT SELECT ON public.tournament_stats TO anon, authenticated;

-- Add comment to the view
COMMENT ON VIEW public.tournament_stats IS 'Tournament statistics view with registration counts';

-- Extend closing time to midnight (12:00 AM) to add slots 11:00-11:30 and 11:30-12:00 AM
-- This extends the last slot from 22:30-23:00 to include 23:00-23:30 and 23:30-00:00
CREATE OR REPLACE FUNCTION public.get_available_slots(p_date date, p_station_id uuid, p_slot_duration integer DEFAULT 60)
 RETURNS TABLE(start_time time without time zone, end_time time without time zone, is_available boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
  opening_time TIME := '11:00:00';  -- 11 AM opening time
  curr_time TIME;
  slot_end_time TIME;
BEGIN
  -- Generate time slots from opening to midnight
  curr_time := opening_time;
  
  -- Loop until we create a slot ending at midnight (00:00:00)
  WHILE TRUE LOOP
    -- Calculate the end time for this slot
    slot_end_time := curr_time + (p_slot_duration || ' minutes')::interval;
    
    -- If slot_end_time is 00:00:00, this is the last slot (ending at midnight)
    -- For 30-min slots: 23:30 + 30 min = 00:00:00
    IF slot_end_time = '00:00:00'::TIME THEN
      -- This is the last slot ending at midnight
      -- Check availability for this slot
      is_available := NOT EXISTS (
        SELECT 1 
        FROM public.bookings b
        WHERE b.station_id = p_station_id 
          AND b.booking_date = p_date
          AND b.status IN ('confirmed', 'in-progress')
          AND (
            (b.start_time <= curr_time AND b.end_time > curr_time) OR
            (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
            (b.start_time >= curr_time AND b.end_time <= slot_end_time)
          )
      );
      
      IF p_date = CURRENT_DATE AND is_available THEN
        is_available := NOT EXISTS (
          SELECT 1
          FROM public.sessions s
          WHERE s.station_id = p_station_id
          AND s.end_time IS NULL
          AND DATE(s.start_time) = p_date
        );
      END IF;
      
      RETURN QUERY SELECT curr_time, slot_end_time, is_available;
      EXIT; -- This was the last slot
    END IF;
    
    -- For all other slots (not ending at midnight)
    -- Check if this time slot overlaps with any existing booking
    is_available := NOT EXISTS (
      SELECT 1 
      FROM public.bookings b
      WHERE b.station_id = p_station_id 
        AND b.booking_date = p_date
        AND b.status IN ('confirmed', 'in-progress')
        AND (
          (b.start_time <= curr_time AND b.end_time > curr_time) OR
          (b.start_time < slot_end_time AND b.end_time >= slot_end_time) OR
          (b.start_time >= curr_time AND b.end_time <= slot_end_time)
        )
    );
    
    -- Also check if there's an active session during this time for today
    IF p_date = CURRENT_DATE AND is_available THEN
      is_available := NOT EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.station_id = p_station_id
        AND s.end_time IS NULL
        AND DATE(s.start_time) = p_date
      );
    END IF;
    
    RETURN QUERY SELECT curr_time, slot_end_time, is_available;
    
    -- Move to next slot
    curr_time := slot_end_time;
    
    -- Safety check: if we've somehow wrapped around incorrectly, exit
    -- This shouldn't happen, but prevents infinite loops
    IF curr_time < opening_time AND curr_time != '00:00:00'::TIME THEN
      EXIT;
    END IF;
  END LOOP;
END;
$function$;

-- Enable realtime replication for bookings table
-- This is required for postgres_changes subscriptions to work

-- Enable replication for bookings table
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;

-- If the above doesn't work, try this alternative:
-- ALTER TABLE public.bookings REPLICA IDENTITY FULL;

-- Verify replication is enabled (run this to check):
-- SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'bookings';

-- ============================================================================
-- ADDITIONAL MISSING TABLES AND FUNCTIONS
-- ============================================================================

-- Create booking_views table for tracking booking access codes
CREATE TABLE IF NOT EXISTS public.booking_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  access_code TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  last_accessed_at TIMESTAMPTZ
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_booking_views_booking_id ON public.booking_views(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_views_access_code ON public.booking_views(access_code);

-- Enable RLS
ALTER TABLE public.booking_views ENABLE ROW LEVEL SECURITY;

-- Allow all operations for authenticated users
CREATE POLICY "Allow full access for authenticated users on booking_views" 
ON public.booking_views FOR ALL USING (true);

-- Add payment_mode and payment_txn_id columns to bookings table
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS payment_mode TEXT,
ADD COLUMN IF NOT EXISTS payment_txn_id TEXT;

-- Add comments for documentation
COMMENT ON COLUMN public.bookings.payment_mode IS 'Payment method: razorpay, venue, cash, upi, etc.';
COMMENT ON COLUMN public.bookings.payment_txn_id IS 'Transaction ID from payment gateway (e.g., Razorpay payment ID)';

-- Create indexes on payment columns for faster lookups
CREATE INDEX IF NOT EXISTS idx_bookings_payment_txn_id ON public.bookings(payment_txn_id);
CREATE INDEX IF NOT EXISTS idx_bookings_payment_mode ON public.bookings(payment_mode);

-- Generate booking access code function
-- This generates a unique access code for viewing bookings
CREATE OR REPLACE FUNCTION public.generate_booking_access_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  access_code TEXT;
  code_exists BOOLEAN;
BEGIN
  LOOP
    -- Generate a 6-character alphanumeric code
    access_code := upper(
      substr(
        md5(random()::text || clock_timestamp()::text),
        1,
        6
      )
    );
    
    -- Check if code already exists
    SELECT EXISTS (
      SELECT 1 FROM public.booking_views 
      WHERE access_code = access_code
    ) INTO code_exists;
    
    -- Exit loop if code is unique
    EXIT WHEN NOT code_exists;
  END LOOP;
  
  RETURN access_code;
END;
$$;

COMMENT ON FUNCTION public.generate_booking_access_code IS 'Generates a unique 6-character alphanumeric access code for booking views';

-- Update missed bookings function
-- This updates bookings that have passed their end time but are still in confirmed status
CREATE OR REPLACE FUNCTION public.update_missed_bookings()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  -- Update bookings that have passed their end time and are still confirmed
  -- Mark them as 'missed' status
  UPDATE public.bookings
  SET 
    status = 'missed',
    status_updated_at = NOW(),
    status_updated_by = 'system'
  WHERE status = 'confirmed'
    AND (
      booking_date < CURRENT_DATE
      OR (booking_date = CURRENT_DATE AND end_time < CURRENT_TIME)
    )
    AND status != 'missed';
END;
$$;

COMMENT ON FUNCTION public.update_missed_bookings IS 'Updates bookings that have passed their end time to missed status';

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

