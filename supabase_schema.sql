-- ============================================================
-- Life OS — Supabase PostgreSQL Schema
-- Version: 3.0.0
-- Generated: 2026-09-09
--
-- Run this in the Supabase SQL editor (Dashboard > SQL Editor)
-- All tables use Row Level Security (RLS) — users can only
-- access their own rows.
-- ============================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ────────────────────────────────────────────────────────────
-- HELPER FUNCTION: updated_at trigger
-- ────────────────────────────────────────────────────────────
create or replace function handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ────────────────────────────────────────────────────────────
-- 1. WALLETS
-- ────────────────────────────────────────────────────────────
create table if not exists wallets (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  icon          text not null default 'account_balance_wallet',
  color_hex     text not null default '#0284C7',
  balance_cents bigint not null default 0,
  is_default    boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table wallets enable row level security;
create policy "wallets_own" on wallets for all using (auth.uid() = user_id);
create trigger wallets_updated_at before update on wallets
  for each row execute function handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 2. FINANCE TRANSACTIONS
-- ────────────────────────────────────────────────────────────
create table if not exists finance_transactions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  wallet_id     uuid references wallets(id) on delete set null,
  amount_cents  bigint not null,
  type          text not null check (type in ('income', 'expense', 'transfer')),
  category      text not null default 'Other',
  description   text,
  date          date not null default current_date,
  tags          text[] default '{}',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table finance_transactions enable row level security;
create policy "transactions_own" on finance_transactions for all using (auth.uid() = user_id);
create trigger transactions_updated_at before update on finance_transactions
  for each row execute function handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 3. TASKS
-- ────────────────────────────────────────────────────────────
create table if not exists tasks (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  title         text not null,
  description   text,
  is_completed  boolean not null default false,
  priority      text not null default 'medium' check (priority in ('low', 'medium', 'high', 'critical')),
  due_date      date,
  tags          text[] default '{}',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table tasks enable row level security;
create policy "tasks_own" on tasks for all using (auth.uid() = user_id);
create trigger tasks_updated_at before update on tasks
  for each row execute function handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 4. HABITS
-- ────────────────────────────────────────────────────────────
create table if not exists habits (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  title           text not null,
  frequency       text not null default 'daily' check (frequency in ('daily', 'weekly', 'custom')),
  category        text not null default 'General',
  streak_current  int not null default 0,
  streak_longest  int not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

alter table habits enable row level security;
create policy "habits_own" on habits for all using (auth.uid() = user_id);
create trigger habits_updated_at before update on habits
  for each row execute function handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 5. HABIT COMPLETIONS
-- ────────────────────────────────────────────────────────────
create table if not exists habit_completions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  habit_id        uuid not null references habits(id) on delete cascade,
  completed_date  date not null default current_date,
  created_at      timestamptz not null default now(),
  unique(user_id, habit_id, completed_date)
);

alter table habit_completions enable row level security;
create policy "habit_completions_own" on habit_completions for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- 6. FOCUS SESSIONS
-- ────────────────────────────────────────────────────────────
create table if not exists focus_sessions (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  task_id           uuid references tasks(id) on delete set null,
  duration_seconds  int not null,
  break_type        text default 'short',
  started_at        timestamptz not null,
  ended_at          timestamptz,
  created_at        timestamptz not null default now()
);

alter table focus_sessions enable row level security;
create policy "focus_sessions_own" on focus_sessions for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- 7. WATER LOGS
-- ────────────────────────────────────────────────────────────
create table if not exists water_logs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  amount_ml     int not null,
  daily_goal_ml int not null default 2000,
  logged_at     timestamptz not null default now(),
  created_at    timestamptz not null default now()
);

alter table water_logs enable row level security;
create policy "water_logs_own" on water_logs for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- 8. MOOD LOGS
-- ────────────────────────────────────────────────────────────
create table if not exists mood_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  mood_level  int not null check (mood_level between 1 and 5),
  note        text,
  logged_at   timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

alter table mood_logs enable row level security;
create policy "mood_logs_own" on mood_logs for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- 9. SECURE NOTES (titles only — content remains local)
-- ────────────────────────────────────────────────────────────
create table if not exists secure_notes_meta (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  color_tag   text,
  is_archived boolean not null default false,
  is_pinned   boolean not null default false,
  note_type   text not null default 'text',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

alter table secure_notes_meta enable row level security;
create policy "secure_notes_meta_own" on secure_notes_meta for all using (auth.uid() = user_id);
create trigger secure_notes_meta_updated_at before update on secure_notes_meta
  for each row execute function handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 10. EMERGENCY CARD
-- ────────────────────────────────────────────────────────────
create table if not exists emergency_cards (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid not null references auth.users(id) on delete cascade unique,
  blood_type              text,
  allergies               text,
  medical_notes           text,
  emergency_contacts_json jsonb default '[]',
  updated_at              timestamptz not null default now()
);

alter table emergency_cards enable row level security;
create policy "emergency_cards_own" on emergency_cards for all using (auth.uid() = user_id);
create trigger emergency_cards_updated_at before update on emergency_cards
  for each row execute function handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 11. VAULT FILES (metadata only — encrypted blobs remain local)
-- ────────────────────────────────────────────────────────────
create table if not exists vault_files (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  file_type     text not null,
  size_bytes    bigint not null default 0,
  is_encrypted  boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table vault_files enable row level security;
create policy "vault_files_own" on vault_files for all using (auth.uid() = user_id);
create trigger vault_files_updated_at before update on vault_files
  for each row execute function handle_updated_at();

-- ────────────────────────────────────────────────────────────
-- 12. AI CHAT HISTORY
-- ────────────────────────────────────────────────────────────
create table if not exists ai_chat_messages (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  session_id  uuid not null,
  role        text not null check (role in ('user', 'model')),
  content     text not null,
  created_at  timestamptz not null default now()
);

alter table ai_chat_messages enable row level security;
create policy "ai_chat_messages_own" on ai_chat_messages for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- INDEXES for performance
-- ────────────────────────────────────────────────────────────
create index if not exists idx_transactions_user_date on finance_transactions(user_id, date desc);
create index if not exists idx_tasks_user_due on tasks(user_id, due_date);
create index if not exists idx_habits_user on habits(user_id);
create index if not exists idx_habit_completions_user_date on habit_completions(user_id, completed_date desc);
create index if not exists idx_water_logs_user_date on water_logs(user_id, logged_at desc);
create index if not exists idx_mood_logs_user_date on mood_logs(user_id, logged_at desc);
create index if not exists idx_ai_chat_user_session on ai_chat_messages(user_id, session_id, created_at);
