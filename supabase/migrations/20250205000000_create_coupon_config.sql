-- Coupon config: enable/disable coupons and promotional popup per code.
-- When enabled=false: coupon cannot be applied, no popup, no summary explanation.
CREATE TABLE IF NOT EXISTS public.coupon_config (
  code TEXT PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT true,
  show_popup BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Seed existing coupons and NERFTURFHH (Happy Hours: tables ₹149/hr, PS5 ₹99/hr, Mon–Fri 11 AM–4 PM)
INSERT INTO public.coupon_config (code, enabled, show_popup) VALUES
  ('TES1342', true, false),
  ('NerfTurf25', true, false),
  ('NerfTurf50', true, false),
  ('HH99', true, false),
  ('NIT50', true, false),
  ('ALMA50', true, false),
  ('AXEIST', true, false),
  ('NERFTURFHH', true, true)
ON CONFLICT (code) DO NOTHING;

-- Optional: trigger to bump updated_at
CREATE OR REPLACE FUNCTION public.coupon_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS coupon_config_updated_at ON public.coupon_config;
CREATE TRIGGER coupon_config_updated_at
  BEFORE UPDATE ON public.coupon_config
  FOR EACH ROW EXECUTE FUNCTION public.coupon_config_updated_at();

-- RLS: anon can read (public booking page), authenticated can read and update (booking management)
ALTER TABLE public.coupon_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon read coupon_config" ON public.coupon_config;
CREATE POLICY "Allow anon read coupon_config" ON public.coupon_config FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Allow authenticated read coupon_config" ON public.coupon_config;
CREATE POLICY "Allow authenticated read coupon_config" ON public.coupon_config FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated update coupon_config" ON public.coupon_config;
CREATE POLICY "Allow authenticated update coupon_config" ON public.coupon_config FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
