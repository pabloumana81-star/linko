# linko

A new Flutter project.

## Backend configuration

LinkO uses Supabase as its production backend. Phase 1 keeps the existing MVP
screens on their shared in-memory repository while exposing backend-ready,
asynchronous repositories for authentication, professionals, service requests,
conversations, quotations, and ratings.

Mock mode is the default and does not require credentials:

```sh
flutter run -d macos
```

To configure Supabase, copy the environment template and replace its example
values locally. Never commit the resulting `.env` file.

```sh
cp .env.example .env
```

Start the app with those values as Dart environment definitions:

```sh
flutter run -d macos --dart-define-from-file=.env
```

The supported definitions are:

- `BACKEND_MODE`: `mock` or `supabase`.
- `SUPABASE_URL`: Supabase project URL.
- `SUPABASE_ANON_KEY`: public anonymous project key.
- `AUTH_REDIRECT_URL`: deep link used after OTP, Google, or Apple sign-in.

Supabase initialization is skipped entirely in mock mode. In Supabase mode,
missing or invalid configuration produces a safe startup error instead of
starting a partially configured application.

The initial Supabase adapters expect the following tables or views:
`profiles`, `professional_profiles`, `service_requests`,
`conversation_messages`, `quotations`, `ratings`, `timeline_events`, and
`professional_rating_summaries`. Atomic workflow mutations use the
`update_request_status`, `send_quotation`, `accept_quotation`, and
`submit_service_rating` database functions. Migrations for requests,
conversations, quotations, ratings, and timeline data remain outside this
sprint.

### Supabase authentication

Authentication supports local guest access, email OTP/magic links, Google,
and Apple. No password flow is used. Before testing Supabase mode:

1. Enable Email, Google, and Apple under Supabase Authentication providers.
2. Add the value of `AUTH_REDIRECT_URL` to the allowed redirect URLs.
3. Configure the same deep-link scheme in each target platform before testing
   OAuth outside macOS.
4. Supply provider client IDs and secrets only in the Supabase dashboard;
   never store them in this repository.

Supabase restores its persisted session during backend initialization. LinkO
uses the authenticated user metadata only to seed `profiles` the first time;
subsequent logins load the persisted display name, avatar, and active mode from
that table. Guest profiles remain in memory and are cleared when the
application closes.

### User profiles migration

Apply the profile schema before running authenticated Supabase mode:

```sh
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

The migration at
`supabase/migrations/202608010001_create_profiles.sql` creates `profiles`, its
row-level security policies, automatic `updated_at` handling, and an Auth
trigger that creates the profile for new users. The app also performs a safe
get-or-create after login, covering users that existed before the migration.
Only the authenticated owner can read or update their profile. This sprint
does not persist requests, conversations, quotations, ratings, or timeline
data.

## Quality assurance

Run the complete QA suite from the project root:

```sh
./qa.sh
```

The script runs Flutter analysis, unit and widget tests, and the complete
macOS integration test. It stops immediately if any check fails.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
