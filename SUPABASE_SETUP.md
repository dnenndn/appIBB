# Supabase Integration Guide

## Overview
Your IBB Factory Monitoring app is now configured to use **Supabase** as the database backend instead of mock data. This guide walks you through the setup process.

---

## Step 1: Create a Supabase Project

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Sign up or log in with your account
3. Click **"New Project"**
4. Fill in the project details:
   - **Name**: `ibb-factory-app` (or your preferred name)
   - **Database Password**: Create a strong password
   - **Region**: Select closest to your location
5. Click **"Create new project"** and wait for it to initialize (5-10 minutes)

---

## Step 2: Get Your Credentials

1. Navigate to **Settings** → **API** in your Supabase dashboard
2. Copy the following values:
   - **Project URL** (under `Project URL`)
   - **Anon Key** (under `Project API keys` → `anon`)

---

## Step 3: Add Credentials to Your App

1. Open `lib/core/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   class SupabaseConfig {
     // Example: https://your-project.supabase.co
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     
     // Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

---

## Step 4: Import Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Copy the entire contents of `database_schema.sql` from your project root
4. Paste into the SQL Editor
5. Click **"Run"**
6. Wait for all tables to be created (you should see 9 tables created)

---

## Step 5: Create Users for Authentication

1. In Supabase, go to **Authentication** → **Users**
2. Click **"Add user"**
3. Create test users with their email and password:
   - `manager@factory.com` / `Manager@123`
   - `supervisor@factory.com` / `Super@123`
   - `engineer@factory.com` / `Engineer@123`

> **Important**: The passwords you set here must match the users you create in Supabase Auth.

---

## Step 6: Enable Row Level Security (RLS)

For production, enable Row Level Security:

1. Go to **Authentication** → **Policies**
2. For each table (machines, alerts, shifts, etc.), create policies:
   ```sql
   -- Example: Allow authenticated users to read machines
   CREATE POLICY "Enable read for authenticated users" ON machines
     FOR SELECT
     TO authenticated
     USING (true);
   ```

---

## Step 7: Run Your App

1. Get dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

3. Login with one of your test users:
   - Email: `manager@factory.com`
   - Password: `Manager@123`

---

## Architecture Overview

### Service Layer (`lib/core/services/supabase_service.dart`)
- Centralized Supabase client
- Methods for authentication, machines, alerts, shifts, parameters
- Real-time subscription support

### Repository Layer (`lib/core/repositories/data_repositories.dart`)
- Clean abstraction between UI and Supabase
- Fallback to mock data on errors (useful for development)
- `MachineRepository`, `AlertRepository`, `ShiftRepository`

### UI Integration
- **Login Screen**: Authenticates via `SupabaseService.login()`
- **Dashboard**: Fetches machines via `MachineRepository.getAllMachines()`
- **Alerts Screen**: Fetches alerts via `AlertRepository.getActiveAlerts()`
- **Historical Data**: Uses `ShiftRepository.getShifts()`

---

## Database Schema

### Main Tables
1. **users** - Authentication and user info
2. **machines** - Factory equipment (kilns, dryers)
3. **parameters** - Measurable metrics (temperature, flow, etc.)
4. **machine_parameters** - Current values for each machine-parameter pair
5. **parameter_thresholds** - Alert thresholds
6. **alerts** - Alert events with severity and status
7. **alert_history** - Audit trail of alert changes
8. **shifts** - Production shift data
9. **shift_machine_metrics** - Per-machine metrics for each shift

### Views
- `v_machine_status` - Machine overview with alert counts
- `v_shift_summary` - Shift performance summary
- `v_threshold_violations` - Active threshold violations

---

## Switching Between Supabase and Mock Data

### Use Supabase (Production)
```dart
final machines = await MachineRepository().getAllMachines(useMockDataOnError: true);
```

### Fallback to Mock Data (Development/Offline)
If Supabase is unreachable, the repositories automatically fall back to mock data.
Set `useMockDataOnError: false` to force error handling.

---

## Real-Time Updates

The app supports real-time updates through Supabase subscriptions:

```dart
final channel = SupabaseService().subscribeMachineChanges('kiln_01');
// Machine status updates will be pushed automatically
```

---

## Troubleshooting

### "Invalid Supabase credentials"
- Check that URL and anon key are correct in `supabase_config.dart`
- Verify they're copied without extra spaces

### "User not found" at login
- Ensure you created the user in Supabase Authentication
- Check email and password match

### "Tables don't exist"
- Verify you ran the SQL schema in the SQL Editor
- Check that all 9 tables appear in the Tables list

### "Connection timeout"
- Check your internet connection
- Verify your Supabase project is active
- Check your region selection

---

## Next Steps

1. **Add Row Level Security (RLS)** for production security
2. **Set up Realtime permissions** for live data updates
3. **Create API routes** for complex business logic
4. **Add backup policies** for data safety
5. **Monitor usage** in Supabase dashboard

---

## Useful Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Guide](https://supabase.com/docs/reference/flutter/introduction)
- [SQL Schema Best Practices](https://www.postgresql.org/docs/)
- [Row Level Security in Supabase](https://supabase.com/docs/guides/auth/row-level-security)

---

**Last Updated**: November 25, 2025
**Supabase Package Version**: ^1.10.0
