-- ============================================================================
-- FitTrack Migration: 20261029000003_triggers_and_indexes.sql
-- Description: Automated updated_at triggers, auto-profile creation, and performance indexes.
-- ============================================================================

-- 1. Automated updated_at Trigger Function
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql security definer;

-- Attach updated_at triggers
drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at before update on public.profiles
    for each row execute function public.handle_updated_at();

drop trigger if exists trg_workouts_updated_at on public.workouts;
create trigger trg_workouts_updated_at before update on public.workouts
    for each row execute function public.handle_updated_at();

drop trigger if exists trg_fitness_goals_updated_at on public.fitness_goals;
create trigger trg_fitness_goals_updated_at before update on public.fitness_goals
    for each row execute function public.handle_updated_at();

drop trigger if exists trg_daily_sensor_metrics_updated_at on public.daily_sensor_metrics;
create trigger trg_daily_sensor_metrics_updated_at before update on public.daily_sensor_metrics
    for each row execute function public.handle_updated_at();

-- 2. Auto-create Profile on Auth Signup Trigger
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, unit_system, reminder_notifications_enabled)
    values (new.id, 'metric', true)
    on conflict (id) do nothing;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
    for each row execute function public.handle_new_user();

-- 3. High-Performance B-Tree Indexes for Sync and Querying
create index if not exists idx_workouts_user_updated
    on public.workouts(user_id, updated_at);

create index if not exists idx_workouts_user_start_date
    on public.workouts(user_id, start_date desc);

create index if not exists idx_goals_user_active
    on public.fitness_goals(user_id, is_active)
    where not is_deleted;

create index if not exists idx_daily_sensor_metrics_user_date
    on public.daily_sensor_metrics(user_id, metric_date desc);
