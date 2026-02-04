-- Allow anon to update coupon_config so enable/disable persists when dashboard
-- is used without Supabase Auth (e.g. shared anon key). Fixes "state not saving on refresh".
DROP POLICY IF EXISTS "Allow anon update coupon_config" ON public.coupon_config;
CREATE POLICY "Allow anon update coupon_config" ON public.coupon_config
  FOR UPDATE TO anon USING (true) WITH CHECK (true);
