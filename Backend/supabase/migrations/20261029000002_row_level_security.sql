-- ============================================================================
-- FitTrack Migration: 20261029000002_row_level_security.sql
-- Description: Row Level Security (RLS) policies for cross-tenant isolation.
-- ============================================================================

-- 1. Enable Row Level Security on all tables
alter table public.profiles enable row level security;
alter table public.workouts enable row level security;
alter table public.fitness_goals enable row level security;
alter table public.daily_sensor_metrics enable row level security;

-- ============================================================================
-- 2. Profiles Policies
-- ============================================================================
create policy "Users can select own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- ============================================================================
-- 3. Workouts Policies
-- ============================================================================
create policy "Users can select own workouts"
    on public.workouts for select
    using (auth.uid() = user_id);

create policy "Users can insert own workouts"
    on public.workouts for insert
    with check (auth.uid() = user_id);

create policy "Users can update own workouts"
    on public.workouts for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "Users can delete own workouts"
    on public.workouts for delete
    using (auth.uid() = user_id);

-- ============================================================================
-- 4. Fitness Goals Policies
-- ============================================================================
create policy "Users can select own goals"
    on public.fitness_goals for select
    using (auth.uid() = user_id);

create policy "Users can insert own goals"
    on public.fitness_goals for insert
    with check (auth.uid() = user_id);

create policy "Users can update own goals"
    on public.fitness_goals for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "Users can delete own goals"
    on public.fitness_goals for delete
    using (auth.uid() = user_id);

-- ============================================================================
-- 5. Daily Sensor Metrics Policies
-- ============================================================================
create policy "Users can select own sensor metrics"
    on public.daily_sensor_metrics for select
    using (auth.uid() = user_id);

create policy "Users can insert own sensor metrics"
    on public.daily_sensor_metrics for insert
    with check (auth.uid() = user_id);

create policy "Users can update own sensor metrics"
    on public.daily_sensor_metrics for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "Users can delete own sensor metrics"
    on public.daily_sensor_metrics for delete
    using (auth.uid() = user_id);
