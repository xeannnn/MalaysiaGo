# Coding Standards — MalaysiaGO

To keep the codebase consistent across five people working on
different modules, all Dart/Flutter code follows these conventions.

## Naming

| Element | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `passport.dart` |
| Classes / Widgets | `UpperCamelCase` | `PassportHeroCard` |
| Variables / functions | `lowerCamelCase` | `selectedTab`, `buildBody()` |
| Constants | `lowerCamelCase` with `const` | `const totalPieces = 40;` |
| Enums | `UpperCamelCase` type, `lowerCamelCase` values | `enum BottomTab { home, map }` |
| Private members | prefix with `_` | `_MainScreenState`, `_pieceIcons` |

## File Organization

- One widget class per concept, not per file strictly — small, related
  widgets (e.g. `MissionCard` and `RankRow`, both used only by
  `HomeScreen`) can live in the same file as the screen that uses them.
- Shared widgets used by more than one screen go in `lib/widgets/`.
- Shared data classes/enums go in `lib/models.dart`.
- Each screen's file starts with a short doc comment (`///`) describing
  what it renders and its position in the app, e.g.:
  ```dart
  /// Passport screen: hero progress card + grid of collectible pieces.
  ```

## Formatting

- Run **`flutter format .`** (or Android Studio's auto-format,
  `Ctrl+Alt+L`) before committing — this enforces consistent indentation,
  spacing, and trailing commas automatically so we don't argue about
  style in code review.
- Prefer trailing commas on multi-line widget parameters — it keeps
  diffs clean when a parameter is added/removed later and lets the
  formatter lay out widgets one per line.
- Keep widget build methods readable: extract a section into its own
  `Widget` (either a method like `_buildHeader()` or a separate class)
  once a single `build()` method gets long or deeply nested.

## Widgets

- Prefer `StatelessWidget` by default; only use `StatefulWidget` when a
  widget actually owns mutable state (e.g. `MainScreen` holding the
  selected tab).
- Use `const` constructors wherever possible (`const SizedBox(...)`,
  `const Text(...)`) — it's a small but real performance win and Flutter
  lint rules will flag missing ones.
- Avoid deeply nested ternaries or inline logic inside `build()` —
  compute values above the `return` statement instead, e.g.:
  ```dart
  final progress = (currentXp / xpToNextLevel).clamp(0.0, 1.0);
  return Column(...);
  ```

## Comments

- Comment *why*, not *what* — the code already shows what it does.
  ```dart
  // Hardcoded for the demo — replace with real user data once
  // Firebase auth is wired up.
  const collected = 24;
  ```
- Every new screen/widget file gets a one-line doc comment at the top
  explaining its purpose (see File Organization above).

## Linting

- The project uses Flutter's default `analysis_options.yaml`
  (`package:flutter_lints`). Don't disable lint rules to make an error
  disappear — fix the underlying issue, or ask in the team chat if a
  rule seems wrong for a specific case.
- Run `flutter analyze` before opening a Pull Request; it should report
  zero issues.

## Git-related Standards

- No commented-out code left in committed files — delete it (Git
  history keeps the old version if it's ever needed again).
- No `print()` statements left in for debugging — remove them before
  committing, or use proper logging if genuinely needed.
- Commit messages follow the convention described in
  `GIT_WORKFLOW.md` (short, imperative, descriptive).
