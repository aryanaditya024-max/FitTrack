# FitTrack: Personal Fitness Tracker for iOS

[![FitTrack iOS CI](https://github.com/aryan/FitTrack/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/aryan/FitTrack/actions)
**Platform:** iOS 17.0+ (iPhone)  
**Language:** Swift 5.9+ / SwiftUI  
**Architecture:** Offline-First MVVM + Repository Pattern + Two-Way Sync Engine  
**Cloud Backend:** Supabase (PostgreSQL with Row Level Security)  

---

## 🏃 Project Overview
**FitTrack** is an offline-first personal fitness tracking application built for iOS. It combines Apple hardware sensor telemetry (steps, active energy, distance via HealthKit and CoreMotion) with local Core Data persistence and optional, resilient cloud backup powered by Supabase PostgreSQL.

### Key Features
1. **Daily Sensor Dashboard:** Real-time daily steps, active energy (calories), and distance walking/running.
2. **HealthKit & CoreMotion Integration:** Native permissions and `HKStatisticsCollectionQuery` daily bucketing with midnight anchors.
3. **Workout Logging:** Full local CRUD (Add, Edit, Delete) with activity filtering and source tracking.
4. **Daily & Weekly Fitness Goals:** Interactive progress rings and active goal management.
5. **Interactive Analytics:** Swift Charts visualizing Day, Week, and Month trends with daily average threshold lines.
6. **Local Notifications:** Daily evening workout reminders and weekly progress recaps via `UNUserNotificationCenter`.
7. **Customizable Settings:** Metric (km) vs. Imperial (mi) unit toggle and notification schedules.
8. **Local-First & Optional Cloud Sync:** Full functionality without an internet connection or account. Seamless background sync when online using client-generated UUIDs, exponential retry backoff, and Last-Write-Wins (LWW) conflict resolution.
9. **Zero Server Secrets on Device:** Row Level Security (RLS) protects user records; only the Public Anon key is bundled.

---

## 🏗️ Architecture & Segregation of Concerns

```
[Apple Watch / iPhone Sensors]
             │
             ▼
   [HealthKit / CoreMotion]
             │ (Sensor Aggregates - source: .sensorHealthKit)
             ▼
    [HealthKitService] ──────► [CDDailyMetricCache] ──────► [ChartsViewModel]
             │                                                     │
             ▼                                                     ▼
    [DashboardViewModel] ◄──────────────────────────────── [SwiftUI Views]
             ▲                                                     ▲
             │                                                     │
   [Local Repositories] ◄──────────────────────────────────────────┘
             │ (Instant Local Writes on Background Context)
             ▼
   [Core Data SQLite DB]
             │
             ├──► [CDSyncQueueItem] (Offline Mutations)
             │            │
             │            ▼
             └──►  [SyncEngine] ◄─── [NWPathMonitor] (Online Detection)
                          │
                          ▼ (Authenticated Bearer JWT)
               [Supabase PostgreSQL] (RLS-Protected)
```

> [!IMPORTANT]
> **Sensor vs. Manual Data Segregation:**  
> Verified hardware sensor metrics (steps, calories, distance) are strictly stamped with `source: .sensorHealthKit`. Manually recorded exercises and workouts are tagged as `source: .manualEntry` and are never injected into HealthKit as raw sensor measurements.

---

## 📁 Project Directory Structure

```
FitTrack/
├── App/
│   ├── FitTrackApp.swift                     # App entry point
│   └── AppState.swift                        # Global state & sync lifecycle coordinator
├── Configuration/
│   ├── Config.xcconfig                       # Public Anon key & Supabase project URL
│   ├── Environment.swift                     # Type-safe configuration loader
│   └── Info.plist                            # HealthKit & CoreMotion privacy keys
├── Core/
│   ├── Constants/                            # App defaults, metrics, and HealthKit types
│   ├── Extensions/                           # Date, Double, and Color extensions
│   └── Utilities/
│       ├── NetworkMonitor.swift              # NWPathMonitor connectivity wrapper
│       └── AppLogger.swift                   # Unified OSLog diagnostics
├── Models/
│   ├── CoreData/
│   │   ├── FitTrack.xcdatamodeld/            # Core Data XML model
│   │   ├── CDWorkout+CoreDataClass.swift
│   │   ├── CDGoal+CoreDataClass.swift
│   │   ├── CDDailyMetricCache+CoreDataClass.swift
│   │   └── CDSyncQueueItem+CoreDataClass.swift
│   ├── Domain/                               # Pure Swift Sendable structs
│   │   ├── Workout.swift
│   │   ├── FitnessGoal.swift
│   │   ├── DailyMetricSummary.swift
│   │   ├── DataSourceType.swift
│   │   └── SyncStatus.swift
│   └── Remote/                               # Codable PostgreSQL DTOs
│       ├── RemoteWorkout.swift
│       ├── RemoteGoal.swift
│       └── RemoteDailyMetric.swift
├── Services/
│   ├── Health/                               # HealthKit & CoreMotion services
│   ├── Storage/                              # CoreDataStack, Repositories, SyncQueue
│   ├── Cloud/                                # Supabase client and auth services
│   ├── Sync/                                 # SyncEngine with Last-Write-Wins
│   └── Notifications/                        # UNUserNotificationCenter scheduling
├── ViewModels/                               # SwiftUI ObservableObject ViewModels
├── Views/
│   ├── MainTabView.swift                     # 5-tab root container
│   ├── Dashboard/                            # Summary metrics, goal rings, HealthKit banner
│   ├── Workouts/                             # Workout history, activity filters, Add/Edit forms
│   ├── Goals/                                # Daily & weekly goal progress
│   ├── Analytics/                            # Swift Charts (Day, Week, Month)
│   ├── Settings/                             # Unit preferences, reminders, cloud account
│   └── Auth/                                 # Supabase Sign In / Sign Up modal
├── Tests/                                    # XCTest test suites
│   ├── CoreDataStackTests.swift
│   ├── WorkoutRepositoryTests.swift
│   ├── GoalRepositoryTests.swift
│   ├── SyncQueueManagerTests.swift
│   ├── HealthKitServiceTests.swift
│   ├── DashboardViewModelTests.swift
│   ├── ChartsViewModelTests.swift
│   ├── SupabaseAuthTests.swift
│   └── SyncEngineTests.swift
├── Backend/supabase/migrations/              # PostgreSQL DDL, RLS, triggers & indexes
└── .github/workflows/ios-ci.yml              # macOS CI automation pipeline
```

---

## 🚀 Getting Started

### 1. Opening the Project in Xcode (macOS)
1. Transfer the `FitTrack` folder to a Mac running macOS 14+ and Xcode 15+.
2. In Xcode, select **File > Open** and open `FitTrack/Package.swift` (or add it to your Xcode workspace).
3. Select an iOS 17+ Simulator (e.g., iPhone 15 Pro) and press **Cmd + R** to run.

### 2. Running Unit Tests
In Xcode, press **Cmd + U** to run all test targets, or via Terminal:
```bash
swift test
```

### 3. Setting Up Supabase Cloud Backend
1. Create a free project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** in your Supabase dashboard and run the migrations in order:
   - `Backend/supabase/migrations/20261029000001_initial_schema.sql`
   - `Backend/supabase/migrations/20261029000002_row_level_security.sql`
   - `Backend/supabase/migrations/20261029000003_triggers_and_indexes.sql`
3. Copy your project URL and **Public Anon Key** into `Configuration/Config.xcconfig`:
   ```xcconfig
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = eyJhbGciOi...
   ```
*(Note: If you run without configuring Supabase, FitTrack automatically operates in local-first demo mode with zero errors).*

---

## 🧪 Automated CI Pipeline
The repository includes an automated GitHub Actions CI pipeline ([`.github/workflows/ios-ci.yml`](.github/workflows/ios-ci.yml)) configured for `macos-14` runners, testing:
- Core Data persistence and migration schemas.
- In-memory repository operations and soft deletion tombstones.
- HealthKit statistical queries and sensor segregation.
- Last-Write-Wins sync engine conflict resolution.
- Supabase DTO serialization.
