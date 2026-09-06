# isro_study_companion
# ISRO Study Companion

A new Flutter project.
> **Study → Practice → Analyze → Revise → Improve**

## Getting Started
A production-ready cross-platform examination companion application designed for technical examinations such as ISRO ECE. Built with Flutter & Dart, supporting Web, Windows Desktop, Android, and iOS-ready architecture with an offline-first Firebase cloud backend and strict source-grounded RAG AI.

This project is a starting point for a Flutter application.
---

A few resources to get you started if this is your first Flutter project:
## Key Features

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
1. **Source-Grounded AI Only (RAG)**:
   - Evaluates only user-uploaded PDFs, documents, question papers, question images, notes, and user-provided URLs.
   - Never hallucinates questions. Insufficient sources display an exact count warning rather than fabricating extra questions.
   - Every question, formula, flashcard, and explanation includes verified source attribution with clickable "View Source" inspection.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
2. **Exam Testing Engine**:
   - Custom Tests and Auto-Generated Tests.
   - Per-question countdown timers (Easy 60s, Medium 90s, Hard 120s customizable) + overall timer option.
   - Auto-advance and question locking when time expires.
   - Configurable positive marking (+1, +2, +4) and negative marking (-0.25, -0.33, -0.5, -1) with toggle switch.
   - Mandatory Pre-test Summary screen.
   - Interactive Question Palette (Answered, Unanswered, Marked for Review, Time Up).

3. **Multi-Device Offline-First Synchronization**:
   - Works seamlessly across Windows Desktop, Android, Web, and iOS.
   - Real-time status indicator: `✓ Synced`, `⟳ Syncing...`, `⚠ Offline`.
   - Local dirty queue buffers offline actions and flushes them automatically to Cloud Firestore upon reconnection.

4. **Companion Modules**:
   - **Syllabus**: 14 foundational ECE subjects (Mathematics, Network Theory, Signals & Systems, Electronic Devices, Analog/Digital Electronics, Communications, EM Theory, Control Systems, Microprocessors, Computer Org, VLSI, Power Electronics, Measurements).
   - **Study Timer**: Pomodoro & Stopwatch with timestamp accuracy across sleep/backgrounding.
   - **Upload Hub & OCR Verification**: 6 upload modalities including question photo OCR with a human review modal (Edit, Approve, Reject).
   - **Personal Source Library**: Search, filter, rename, delete, and inspect indexed chunks.
   - **Mistake Notebook**: Automatically logs wrong answers with review notes and resolution marking.
   - **Revision Hub**: Smart sessions dynamically generated from weak topics and mistakes.
   - **Flashcards**: Spaced repetition cards with 3D flip animation.
   - **Formula Bank**: LaTeX math formulas organized by Subject and Topic with search and favorites.
   - **Performance Analytics**: Visual consistency bar charts, topic mastery classification (Strong ≥75%, Average 55-74%, Weak <55%), and daily study goals.
   - **Global Search**: Unified search across Notes, Questions, Sources, Formulas, Mistakes, and Flashcards.

---

## Architecture

```
lib/
├── core/
│   ├── constants/        # App constants, defaults, 14-subject starter syllabus
│   ├── theme/            # Technical educational light & dark themes
│   ├── routing/          # GoRouter with desktop sidebar & mobile navigation
│   ├── errors/           # Friendly exception handler (no raw error dumps)
│   ├── utils/            # LaTeX math renderer, Text chunker
│   ├── services/         # LocalStorageService, SyncService, Providers
│   └── widgets/          # ResponsiveScaffold, SyncStatusBadge
│
├── data/
│   ├── models/           # User, Syllabus, Source, Question, Test, Mistake, Flashcard, Formula
│   ├── repositories/     # Auth, Syllabus, Notes, Sources, Questions, Tests, Mistakes, etc.
│   └── datasources/      # RAGService (Strict Grounding Engine)
│
└── features/
    ├── authentication/   # Login, Register, Password Reset
    ├── dashboard/        # Streak, Progress, Weak Topics, Study Recommendations
    ├── timer/            # Stopwatch & Pomodoro with Subject-Topic association
    ├── syllabus/         # Interactive 14-subject ECE hierarchy
    ├── notes/            # Searchable notes with LaTeX formulas
    ├── uploads/          # Central Upload Hub (Photo, PDF, Paper, Note, URL, Text)
    ├── source_library/   # "My Study Materials" chunk inspector
    ├── question_bank/    # Question repository with source verification
    ├── ai_test/          # Test builder with strict count validation
    ├── test_engine/      # Per-question countdown runner
    ├── test_results/     # Detailed results and source-grounded question review
    ├── mistakes/         # Mistake Notebook
    ├── revision/         # Spaced revision sessions
    ├── flashcards/       # Interactive flip cards
    ├── formula_bank/     # LaTeX formula bank
    ├── performance/      # Charts and daily goal trackers
    ├── settings/         # Themes, daily targets, and account management
    └── search/           # Global unified search modal
```

---

## Setup & Running Instructions

### 1. Prerequisites
- Flutter SDK 3.47+ (Dart 3.13+)
- Node.js 18+ (for Cloud Functions deployment)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Running the App
- **Web (Chrome / Edge)**:
  ```bash
  flutter run -d chrome
  ```
- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **Android**:
  ```bash
  flutter run -d android
  ```

### 4. Building Production Artifacts
- **Web**: `flutter build web`
- **Windows**: `flutter build windows`
- **Android APK**: `flutter build apk`

---

## Firebase Configuration

1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password, Google).
3. Enable **Cloud Firestore** and deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
4. Enable **Firebase Storage** and deploy rules:
   ```bash
   firebase deploy --only storage
   ```
5. Deploy Cloud Functions:
   ```bash
   cd functions
   npm install
   npm run build
   firebase deploy --only functions
   ```
