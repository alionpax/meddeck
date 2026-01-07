# Copilot / AI Agent Instructions for MedDeck

Purpose
- Help AI coding agents get productive quickly: architecture, key files, local run/deploy commands, and project-specific conventions.

High level architecture (big picture)
- Flutter app (client) — `lib/` contains UI, routing, and data layer. Entry: `lib/main.dart` → `lib/app.dart` (routes and ShellRoute with bottom nav).
- Data layer: `lib/data/repo/deck_repo.dart` (interface) and `lib/data/repo/firestore_deck_repo.dart` (Firestore implementation used app-wide).
- Server-side: Firebase Functions (`functions/src/index.ts`) watch `decks/{deckId}` to trigger Cloud Run PPT→PNG conversion.
- Converter service: Cloud Run app in `backend/ppt_converter/` (Dockerfile + `index.js`) that runs LibreOffice + `pdftoppm` and uploads slides to Cloud Storage.
- Firebase project config lives in `lib/firebase_options.dart` and `firebase.json` (projectId: `meddeck-4cb95`).

Important patterns & conventions
- Use `DeckRepo` for repository abstraction; prefer `FirestoreDeckRepo()` across the app (see comment in `lib/app.dart`).
- Firestore schema expectations (fields read/written by app + functions):
  - `status`: `pending | approved | rejected`
  - `slideImageUrls`: array of signed URLs (presence is used as idempotency check)
  - `slideCount`, `coverImageUrl`, `pptPath`, `bucket`, `conversionStatus`, `conversionError`, `convertedAt`
- Conversion pipeline guarantees:
  - Functions are idempotent: `onDeckApproved` returns early if `slideImageUrls` exists.
  - Functions perform "URL-only writeback": they do not reupload images; the converter uploads and returns storage paths, and functions write signed URLs back to Firestore.
- Admin flow: `/review` route (absolute path) uses `FirestoreDeckRepo().listPendingDecks()`; use `setStatus` to change deck status.
- Auth: `AuthGate` listens to `FirebaseAuth.instance.authStateChanges()`; admin role is NOT implemented — add a users/{uid}.role lookup if needed.
- Offline data: Hive box name is `offline` (see `lib/main.dart`).

Local development & commands
- Flutter client:
  - Prepare: `flutter pub get`
  - Run: `flutter run` (or use VS Code Flutter launch configs)
  - Static analysis: `flutter analyze`
- Functions (emulator + build):
  - Build TypeScript: `cd functions && npm run build`
  - Start emulator: `cd functions && npm run serve` (runs `tsc` then `firebase emulators:start --only functions`).
  - Deploy functions: `cd functions && npm run deploy` (requires Firebase credentials).
  - Note: `functions/package.json` requires `node` engine `24`.
- Converter service (Cloud Run):
  - Build locally: `docker build -t meddeck-ppt-converter ./backend/ppt_converter` (requires `pdftoppm` and libreoffice in image; production Dockerfile already installs them).
  - Health endpoints: `/health`, `/healthz`, `/diag` (useful for smoke checks).
  - The Cloud Run URL is configured in `functions/src/index.ts` as `CONVERTER_URL` — update if you deploy a different service.

Debugging tips
- To reproduce conversion failures locally: run the converter container, point `CONVERTER_URL` at it (or mock the call), and run `functions` emulator; see logs for `conversionStatus` and `conversionError` fields on Firestore documents.
- Converter output content and signed-URL generation lives in `backend/ppt_converter/index.js` (look at `slideImageUrls` and destination naming `filePath/slides/slide_001.png`).
- When changing Firestore fields or doc layout, update both `lib/data/repo/firestore_deck_repo.dart` (parsing logic) and `functions/src/index.ts` (expected keys and update() calls).

Code style & linting
- Uses `package:flutter_lints` via `analysis_options.yaml`.
- Functions use TypeScript + ESLint; `npm run lint` is a placeholder in `functions/package.json` (lint disabled by default).

Helpful files to inspect (quick map)
- App/routing: `lib/app.dart` (ShellRoute, routes, bottom nav logic)
- Data model & repo: `lib/data/models/`, `lib/data/repo/deck_repo.dart`, `lib/data/repo/firestore_deck_repo.dart`
- Auth screens: `lib/features/auth/*` (`AuthGate`, `login`, `signup`)
- Admin review UI: `lib/features/review/review_screen.dart` and `slide_upload_screen.dart`
- Functions: `functions/src/index.ts` (onDeckApproved handler)
- Converter: `backend/ppt_converter/index.js`, `backend/ppt_converter/Dockerfile`
- Bootstrap scripts: `bootstrap_meddeck.ps1` shows project scaffolding commands (useful for understanding file generation expectations).

What NOT to change without coordination
- Firebase project constants in `lib/firebase_options.dart` and `firebase.json` (they are environment-specific; update only if migrating projects).
- `CONVERTER_URL` in `functions/src/index.ts` unless you control the Cloud Run service.

If anything is unclear
- Ask: which environment (local emulator, staging, production) you want to modify; specify relevant files (functions vs converter vs Flutter client) and I will suggest exact, minimal edits.

---
If you'd like, I can open a follow-up PR with this file (or merge into an existing `.github/copilot-instructions.md` if you have one) — tell me whether to commit as-is or adjust wording/details.