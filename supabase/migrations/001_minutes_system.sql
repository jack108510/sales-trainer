-- Sales Sparring: Minutes & Subscription schema
-- Run against Supabase project: xacehhtgvubcqdoltazg

-- Add minutes + plan to ss_users
ALTER TABLE ss_users 
  ADD COLUMN IF NOT EXISTS plan TEXT DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS minutes_remaining INTEGER DEFAULT 15,
  ADD COLUMN IF NOT EXISTS minutes_total INTEGER DEFAULT 15,
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS minutes_reset_at TIMESTAMPTZ DEFAULT now();

-- Track minute usage per call
CREATE TABLE IF NOT EXISTS ss_call_minutes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  call_id TEXT,
  minutes_used REAL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE ss_call_minutes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own minutes" ON ss_call_minutes
  FOR SELECT USING (auth.uid() = user_id);

-- Function to deduct minutes after a call
CREATE OR REPLACE FUNCTION deduct_minutes(p_user_id UUID, p_minutes REAL, p_call_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE ss_users 
  SET minutes_remaining = GREATEST(0, minutes_remaining - p_minutes)
  WHERE id = p_user_id;
  
  INSERT INTO ss_call_minutes (user_id, call_id, minutes_used)
  VALUES (p_user_id, p_call_id, p_minutes);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reset monthly minutes (called by cron or Stripe webhook)
CREATE OR REPLACE FUNCTION reset_monthly_minutes(p_user_id UUID DEFAULT NULL)
RETURNS void AS $$
BEGIN
  IF p_user_id IS NULL THEN
    -- Reset all users
    UPDATE ss_users 
    SET minutes_remaining = minutes_total,
        minutes_reset_at = now()
    WHERE subscription_status = 'active';
  ELSE
    UPDATE ss_users 
    SET minutes_remaining = minutes_total,
        minutes_reset_at = now()
    WHERE id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
