## VanGo Parent App – Architecture Snapshot

This Flutter client authenticates families with Supabase and syncs day-to-day ride data through the custom VanGo backend.

- **Configuration** – `lib/services/app_config.dart` loads `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `BACKEND_BASE_URL` via `--dart-define` or `.env`. Every API call fails fast if these values are missing.
- **Auth** – `AuthService` wraps Supabase email/password + SMS OTP flows, while `BackendClient` piggybacks on the Supabase JWT for downstream REST calls.
- **Data access** – `ParentDataService` is the single integration point for child profiles, notifications, messaging, and attendance. All new flows should reuse the helpers here instead of calling the backend directly.
- **Models** – DTOs live under `lib/models`. Notable examples: `ChildProfile`, `DriverProfile`, `RideStatus`, and `NotificationItem`.

The latest merge pass eliminated duplicate child-creation logic and rebuilt `RideStatus` so both onboarding and dashboard experiences share a consistent contract with the backend/API schema.
