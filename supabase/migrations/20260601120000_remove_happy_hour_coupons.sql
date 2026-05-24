-- Remove discontinued happy-hour coupon codes from config and historical toggle state
DELETE FROM public.coupon_config WHERE code IN ('HH99', 'NERFTURFHH');
