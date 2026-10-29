-- ============================================================================
-- FitTrack Migration: 20261029000001_initial_schema.sql
-- Description: Core tables for profiles, workouts, fitness goals, and daily sensor metrics.
-- ============================================================================

create extension if not exists "uuid-ossp";

-- 1. Profiles Table (Linked to auth.users)
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    unit_system text not null default 'metric' check (unit_system in ('metric', 'imperial')),
    reminder_notifications_enabled boolean not null default true,
    reminder_time time without time zone default '20:00:00',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 2. Workouts Table (Local-first with client UUIDs & tombstones)
create table if not exists public.workouts (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    activity_type text not null,
    start_date timestamptz not null,
    end_date timestamptz not null,
    duration double precision not null check (duration >= 0),
    distance double precision not null default 0 check (distance >= 0),
    calories_burned double precision not null default 0 check (calories_burned >= 0),
    source text not null check (source in ('manual_entry', 'healthkit_import')),
    is_deleted boolean not null default false,
    version bigint not null default 1,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 3. Fitness Goals Table
create table if not exists public.fitness_goals (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    metric_type text not null check (metric_type in ('steps', 'active_energy', 'distance', 'workout_duration')),
    target_value double precision not null check (target_value > 0),
    frequency text not null check (frequency in ('daily', 'weekly')),
    start_date timestamptz not null,
    end_date timestamptz,
    is_active boolean not null default true,
    is_deleted boolean not null default false,
    version bigint not null default 1,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 4. Daily Sensor Metrics Table (Aggregated sensor readings, segregated from manual logs)
create table if not exists public.daily_sensor_metrics (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    metric_date date not null,
    step_count integer not null default 0 check (step_count >= 0),
    distance_meters double precision not null default 0 check (distance_meters >= 0),
    active_energy_kcal double precision not null default 0 check (active_energy_kcal >= 0),
    source text not null default 'sensor_healthkit',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_user_metric_date unique(user_id, metric_date)
);
