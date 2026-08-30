# Git Workflow — MalaysiaGO

This document describes how the MalaysiaGO team uses Git and GitHub to
collaborate on the project: branching, commits, reviews, merging, issue
tracking, and how conflicts and releases are handled.

## 1.  Repository Structure

```
MalaysiaGO/
├── lib/
│   ├── main.dart
│   ├── models.dart
│   ├── widgets/
│   └── screens/
├── android/
├── ios/
├── test/
├── pubspec.yaml
├── README.md
└── GIT_WORKFLOW.md
```

`main` always mirrors what's in this structure in a working state. No
build artifacts (`build/`, `.dart_tool/`) are committed — these are
excluded via `.gitignore` since they're regenerated automatically by
Flutter and would just create noise and merge conflicts.

## 2. Branching Strategy

We use a lightweight feature-branch workflow (a simplified version of
GitHub Flow):

- **`main`** — always contains working, demo-ready code. Nobody commits
  directly to `main`. It only changes through reviewed and merged Pull
  Requests.
- **Feature branches** — every task (a module, a bug fix, a docs update)
  gets its own branch, created from the latest `main`, and is deleted
  after merging.

### Branch naming convention

`<type>/<short-description>`, all lowercase, words separated by hyphens:

| Type | Used for | Example |
|---|---|---|
| `feature/` | New functionality/module | `feature/heritage-quiz` |
| `fix/` | Bug fixes | `fix/passport-grid-overflow` |
| `ui/` | UI/UX-only changes | `ui/home-welcome-card` |
| `test/` | Test writing | `test/mission-card-widget-test` |
| `docs/` | Documentation | `docs/update-readme` |
| `chore/` | Config, dependencies, tooling | `chore/update-flutter-sdk` |

### Current branch-to-member mapping (by role)

| Team Member | Role | Typical branches |
|---|---|---|
| Natasha Adeyah Binti Mohd Lazib | Project Manager | reviews/merges Pull Requests; `docs/` branches |
| Kaiser Tan King Sheng | Requirement Lead | `docs/requirements`, `docs/user-stories` |
| Alston Chung Zheng Lim | Design Lead | `ui/` branches, Figma-to-code alignment |
| Albert Chin Zhi Qian | Coding Development | `feature/heritage-explorer`, `feature/digital-passport`, `feature/heritage-quiz`, `feature/rewards-system`, `feature/travellers-guide` |
| Chung Wei Xean | Testing Lead | `test/` branches, bug-fix verification |

This isn't a strict rule that only one person may ever touch a given
branch type — it's a default so it's predictable where to look for a
given kind of change.

## 3. Roles & Responsibilities in the Git Workflow

Each team member's project role (from the Group Contract Form) carries
specific responsibilities within the Git workflow itself:

**Natasha Adeyah Binti Mohd Lazib — Project Manager**
- Reviews and approves/merges Pull Requests into `main`
- Keeps the GitHub Projects board (sprint backlog) up to date, moving
  items between To Do / In Progress / Done
- Resolves scheduling conflicts when multiple branches touch the same
  area of the app
- Ensures the weekly sync (Section 11) happens and blockers are raised

**Kaiser Tan King Sheng — Requirement Lead**
- Maintains `docs/` branches for requirements, user stories, and the
  Software Requirements Specification (SRS)
- Opens GitHub Issues for any requirement gaps or ambiguities found
  once development is underway
- Reviews Pull Requests for alignment with agreed requirements before
  approval

**Alston Chung Zheng Lim — Design Lead**
- Owns `ui/` branches and any UI/UX-related changes
- Reviews UI-related Pull Requests specifically for visual/UX
  consistency with the Figma mockup
- Flags in a Pull Request comment when implemented UI diverges from
  the design and needs discussion

**Albert Chin Zhi Qian — Coding Development**
- Primary owner of `feature/` branches implementing the app's modules
  (Heritage Explorer, Digital Passport, Heritage Quiz, Achievement &
  Rewards, Traveller's Guide)
- Responsible for keeping feature branches short-lived and merging
  `main` in regularly to avoid large conflicts
- Writes clear Pull Request descriptions so non-coders on the team
  (e.g. Requirement Lead) can still follow what changed

**Chung Wei Xean — Testing Lead**
- Owns `test/` branches and writes unit/widget/integration tests
- Logs bugs found during testing as GitHub Issues, with reproduction
  steps and screenshots
- Verifies bug-fix Pull Requests actually resolve the linked Issue
  before approving
- Confirms `main` builds and passes tests before each milestone/demo

## 4. Day-to-Day Workflow

**Step 1 — Sync before starting anything:**
```
git checkout main
git pull origin main
```

**Step 2 — Create a branch for the task:**
```
git checkout -b feature/passport-screen
```

**Step 3 — Work in small, logical commits** rather than one giant commit
at the end. This makes it possible to review changes properly and to
roll back a single bad change without losing everything else:
```
git add lib/screens/passport_screen.dart
git commit -m "Add passport hero card with progress bar"

git add lib/screens/passport_screen.dart
git commit -m "Add 5-column grid of collectible pieces"
```

**Step 4 — Push the branch to GitHub:**
```
git push -u origin feature/passport-screen
```
(only need `-u origin <branch>` the first time; after that, plain
`git push` works from that branch)

**Step 5 — Open a Pull Request** on GitHub:
- Base: `main` ← Compare: your feature branch
- Title: short summary, e.g. "Add Passport screen UI"
- Description: what changed, why, and a screenshot/GIF if it's a UI
  change (screenshots make review much faster for a visual app like
  this)
- Link the related task from the sprint backlog if applicable, e.g.
  "Closes #12"

**Step 6 — Review.** At least one other team member reviews before
merging (see Section 5). Address any requested changes by pushing more
commits to the same branch — the Pull Request updates automatically.

**Step 7 — Merge.** Once approved, merge into `main` using **Squash and
merge** (see Section 6 for why), then delete the feature branch:
```
git branch -d feature/passport-screen          # delete local branch
git push origin --delete feature/passport-screen  # delete remote branch
```

**Step 8 — Everyone re-syncs** `main` before starting their next task.

## 5. Commit Message Convention

Format: short imperative summary (under ~50 characters), optionally
followed by a blank line and more detail.

Good examples:
- `Add QR scan button to Home quick actions`
- `Fix passport grid not scrolling on smaller screens`
- `Wire up bottom navigation between Home and Passport`
- `Refactor MissionCard to accept a Mission model`

Avoid vague messages like `update`, `fix stuff`, `changes` — they make
the commit history useless when trying to trace back what happened and
when, which matters for both debugging and for demonstrating individual
contribution.

## 6. Code Review Checklist

Before approving a Pull Request, the reviewer checks:

- [ ] The feature works as described (tested locally, or a screenshot/
      video is provided in the PR)
- [ ] No unrelated files are included (e.g. accidental `build/` folder,
      IDE config files)
- [ ] Widget/file naming is consistent with the rest of the codebase
- [ ] No hardcoded secrets or API keys committed
- [ ] For UI branches: matches the Figma mockup reasonably closely
- [ ] For logic branches: edge cases considered (e.g. empty lists, 0
      values)

If changes are requested, the reviewer leaves comments directly on the
Pull Request; the author pushes fixes to the same branch rather than
opening a new one.

## 7. Merge Strategy

We use **Squash and merge** on GitHub for Pull Requests. This combines
all commits from a feature branch into a single, clean commit on `main`
with a summary message — so `main`'s history reads as one entry per
completed feature/task, rather than every small work-in-progress commit
from the branch. Branch history itself (with all the small commits) is
still visible in the closed Pull Request if anyone needs to dig into it.

## 8. Handling Merge Conflicts

Conflicts happen when two branches edit the same lines of the same
file. When Git flags one:

1. Don't panic or force-push over it — talk to the other person whose
   branch conflicts with yours.
2. Pull the latest `main` into your branch:
   ```
   git checkout feature/your-branch
   git merge main
   ```
3. Git marks the conflicting sections in the file with `<<<<<<<`,
   `=======`, `>>>>>>>`. Open the file, decide together which version
   (or combination) is correct, and remove the conflict markers.
4. Stage and commit the resolution:
   ```
   git add <the resolved file>
   git commit -m "Resolve merge conflict in home_screen.dart"
   ```
5. Push and continue.

To minimize conflicts in the first place: keep branches short-lived
(merge within a few days, not weeks), and avoid two people editing the
same screen file at the same time without coordinating first.

## 9. Issue Tracking

We use **GitHub Issues** to track bugs and tasks:
- Bugs found during testing are logged as Issues by the Testing Lead,
  with steps to reproduce and (if relevant) a screenshot
- Each Issue is assigned to whoever is fixing it
- Pull Requests reference the Issue they resolve (e.g. "Fixes #7") so
  it closes automatically on merge

The **Projects** tab (GitHub's built-in Kanban board) is used to track
sprint backlog items across three columns: **To Do**, **In Progress**,
**Done** — mirroring the module list in Section 3.2 of the project
proposal.

## 10. Definition of Done

A task/branch is considered complete when:
- The code builds and runs without errors
- It matches the intended design/requirement
- It has been reviewed and approved by at least one teammate
- It is merged into `main`
- Any related Issue or backlog item is marked complete

## 11. Sync Cadence

The team briefly syncs (in person or via chat) at the start of each
week to review what's in progress, flag any blockers, and confirm who's
picking up which item from the sprint backlog next — aligned with the
weekly breakdown in the project's Gantt chart (Section 2.2 of the
proposal).
