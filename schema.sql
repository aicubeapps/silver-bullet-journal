-- ═══════════════════════════════════════════════════════════
-- ICT Trade Journal — Supabase Schema
-- Run this entire script in Supabase SQL Editor
-- Project: https://supabase.com → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════

-- ── sync_meta ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sync_meta (
  user_id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  last_modified    TIMESTAMPTZ,
  last_device      TEXT,
  pnl_url          TEXT,
  discord_channels JSONB,
  cf_worker_url    TEXT
);
ALTER TABLE sync_meta ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own sync_meta" ON sync_meta
  FOR ALL USING (auth.uid() = user_id);

-- ── trades ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS trades (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at          TIMESTAMPTZ DEFAULT now(),
  status              TEXT,
  is_intraday         BOOLEAN DEFAULT false,
  weekly_link_id      UUID,
  date                TEXT,
  pair                TEXT,
  session             TEXT,
  trade_type          TEXT DEFAULT 'BUY',
  score               NUMERIC,
  grade               TEXT,
  bias_set            TEXT,
  bias_played         TEXT,
  bias_match          TEXT,
  result              TEXT,
  tp2r                TEXT,
  tp15r               TEXT,
  idea_notes          TEXT,
  update_notes        TEXT,
  close_notes         TEXT,
  followup_notes      TEXT,
  entry_price         NUMERIC,
  close_price         NUMERIC,
  sl_price            NUMERIC,
  tp_price            NUMERIC,
  lot_size            NUMERIC,
  open_time           TIMESTAMPTZ,
  close_time          TIMESTAMPTZ,
  tags                JSONB DEFAULT '[]',
  close_tags          JSONB DEFAULT '[]',
  is_paper            BOOLEAN DEFAULT false,
  ai_review           TEXT,
  trade_notes         JSONB DEFAULT '[]',
  checklist_answers   JSONB DEFAULT '{}',
  checklist_kills     JSONB DEFAULT '{}',
  checklist_model     TEXT DEFAULT 'omar',
  wb_entry_id         UUID,
  intra_alignment     TEXT,
  intra_decision      TEXT,
  intra_kill          BOOLEAN DEFAULT false,
  intra_ex_data       JSONB DEFAULT '{}',
  intra_scores        JSONB,
  review_notes        JSONB DEFAULT '[]',
  review_screenshots  JSONB DEFAULT '[]',
  screenshots         JSONB DEFAULT '[]',
  eod_screenshots     JSONB DEFAULT '[]',
  followup_screenshots JSONB DEFAULT '[]',
  signal_id           TEXT,
  signal_template     TEXT,
  signal_htf          TEXT,
  signal_ltf          TEXT,
  signal_direction    TEXT,
  signal_fired_at     TIMESTAMPTZ,
  signal_price        NUMERIC,
  signal_htf_bias     TEXT,
  signal_session      TEXT
);
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own trades" ON trades
  FOR ALL USING (auth.uid() = user_id);

-- ── weeklies ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS weeklies (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT now(),
  week_start   TEXT,
  pair         TEXT,
  bias         TEXT,
  confluence   TEXT,
  grade        TEXT,
  result       TEXT,
  screenshots  JSONB DEFAULT '[]',
  updates      JSONB DEFAULT '[]',
  notes        TEXT,
  tags         JSONB DEFAULT '[]',
  entries      JSONB DEFAULT '[]'
);
ALTER TABLE weeklies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own weeklies" ON weeklies
  FOR ALL USING (auth.uid() = user_id);

-- ── notes ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now(),
  title       TEXT,
  content     TEXT,
  tags        JSONB DEFAULT '[]'
);
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own notes" ON notes
  FOR ALL USING (auth.uid() = user_id);

-- ── accounts ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS accounts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  name        TEXT,
  type        TEXT,
  broker      TEXT,
  currency    TEXT DEFAULT 'USD',
  balance     NUMERIC DEFAULT 0,
  is_active   BOOLEAN DEFAULT true
);
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own accounts" ON accounts
  FOR ALL USING (auth.uid() = user_id);

-- ── trade_account_map ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS trade_account_map (
  trade_id    UUID REFERENCES trades(id) ON DELETE CASCADE,
  account_id  UUID REFERENCES accounts(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  PRIMARY KEY (trade_id, account_id)
);
ALTER TABLE trade_account_map ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own trade_account_map" ON trade_account_map
  FOR ALL USING (auth.uid() = user_id);

-- ── broker_profiles ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS broker_profiles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  name        TEXT,
  settings    JSONB DEFAULT '{}'
);
ALTER TABLE broker_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own broker_profiles" ON broker_profiles
  FOR ALL USING (auth.uid() = user_id);

-- ── asset_specs ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS asset_specs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  symbol      TEXT,
  pip_size    NUMERIC,
  lot_size    NUMERIC,
  currency    TEXT
);
ALTER TABLE asset_specs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own asset_specs" ON asset_specs
  FOR ALL USING (auth.uid() = user_id);

-- ── archive_log ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS archive_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  period_label  TEXT,
  trade_count   INTEGER,
  snapshot      JSONB
);
ALTER TABLE archive_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own archive_log" ON archive_log
  FOR ALL USING (auth.uid() = user_id);

-- ── signals ────────────────────────────────────────────────
-- Populated by EBP Tracker Worker when signals fire.
-- Linked to trades via trades.signal_id.
-- Optional — only needed if using EBP Tracker integration.
CREATE TABLE IF NOT EXISTS signals (
  signal_id        TEXT PRIMARY KEY,
  template_type    TEXT,
  symbol           TEXT,
  htf_tf           TEXT,
  ltf_tf           TEXT,
  direction        TEXT,
  fired_at         TIMESTAMPTZ,
  traded           BOOLEAN DEFAULT false,
  expires_at       TIMESTAMPTZ,
  price_at_signal  NUMERIC,
  htf_bias         TEXT,
  session          TEXT,
  htf_close        NUMERIC
);
ALTER TABLE signals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users read signals" ON signals
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Service role manages signals" ON signals
  FOR ALL USING (auth.role() = 'service_role');

-- ═══════════════════════════════════════════════════════════
-- STORAGE BUCKET
-- Cannot be created via SQL. Do this manually:
-- 1. Go to Storage in your Supabase project
-- 2. Click New Bucket
-- 3. Name: screenshots
-- 4. Set to: Private
-- 5. Click Create
-- ═══════════════════════════════════════════════════════════

-- ── Done ───────────────────────────────────────────────────
-- All tables created with RLS enabled.
-- Sign up in your journal to create your auth.users row.
-- ═══════════════════════════════════════════════════════════
