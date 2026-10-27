<h1 align="center">cLock-In</h1>

<p align="center">
  <img src="./ClockIn.png" alt="cLock-In logo" width="160"/>
</p>

<p align="center">
  <b>Part clock, part agenda, part diary.</b><br/>
  Plan your day on a 24-hour clock, journal what you finished, and share the moments that matter.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Dart%203.8+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-Express%205-339933?logo=node.js&logoColor=white" alt="Node.js + Express" />
  <img src="https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb&logoColor=white" alt="MongoDB Atlas" />
  <img src="https://img.shields.io/badge/Cloudinary-Images-3448C5?logo=cloudinary&logoColor=white" alt="Cloudinary" />
  <img src="https://img.shields.io/badge/License-ISC-lightgrey" alt="ISC License" />
</p>

---

## Table of contents

- [About](#about)
- [Mission & vision](#mission--vision)
- [Features](#features)
- [How it works](#how-it-works)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Configuration](#configuration)
- [API reference](#api-reference)
- [Project structure](#project-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## About

**cLock-In** turns your daily routine into an interactive, visual schedule. Inspired by the "unemployed clock" from the K-drama *Love Next Door*, it places every task for the day on a single 24-hour dial, so you can see at a glance how your time is spent and what's happening right now.

When you finish a task, it becomes a **journal entry** you can enrich with photos and notes. If you're proud of it, share it to the **Feed**, where friends can like and comment.

cLock-In is a cross-platform **Flutter** app backed by a **Node.js / Express** REST API, **MongoDB Atlas** for data and **Cloudinary** for image storage.

---

## Mission & vision

### Mission
To help people **own their time** by making a day's plan something you can *see*, not just a list you scroll. cLock-In combines planning, reflection and gentle accountability in one calm, beautiful place, so staying on track feels rewarding instead of stressful.

### Vision
A world where everyday routines feel **intentional and shareable**: where a student, a freelancer or a busy parent can glance at one clock, know exactly where their day stands, look back on what they achieved, and celebrate small wins with the people who keep them motivated.

### Core values
- **Clarity over clutter.** One dial, one glance, no noise.
- **Reflection, not just productivity.** Finished tasks become memories, not checkboxes.
- **Encouragement over pressure.** Progress is shared and celebrated, never shamed.
- **Your day, your way.** Custom categories, themes and time formats adapt to you.

---

## Features

### 🕒 The 24-hour Clock
- **Visual day planner.** Every task is drawn as a colored arc on a 24-hour dial, labeled along the curve.
- **Live "now" hand.** Shows the current time and the active task with the time remaining. Tap **Mark done** right from the dial.
- **Tap an arc to edit it.** The dial and the task list stay in sync.
- **Daily progress.** A greeting, today's date, and a "3 of 5 done" progress bar.
- **Smart task list.**
  - Swipe right to complete, swipe left to delete.
  - The task happening now is highlighted.
  - Hide finished tasks to clear the dial.
- **Auto-reset at midnight.** Tasks belong to the day they were created and leave the clock automatically at midnight. Overnight tasks stay until they end.
- **Overlap protection.** You can't double-book a time slot that already has an active task.

### ✍️ Tasks
- Title, category, start/end time (tap-to-pick time pickers), notes and an optional **reminder** (5, 10, 30 or 60 minutes before the task ends).
- Changing the start time automatically shifts the end time to keep the task's duration.
- Overnight tasks are supported ("ends tomorrow").

### 🏷️ Custom categories
- Comes with **School, Work, Self and House**. You can add up to 12 categories of your own.
- Pick from **8 muted color tints** and **16 icons**. Rename, recolor and reorder categories at any time.
- Renaming or recoloring updates every task instantly, without editing the tasks.
- Deleting a category asks where to move its tasks, so nothing is ever lost.

### 📔 Journal
- Every completed task becomes a **journal entry**, grouped by the day you finished it.
- **Swipeable week view** with dots on days that have entries, plus a calendar picker for any date.
- **Search across all entries** by title, category, notes, time or date.
- Add up to **10 photos per entry** (stored on Cloudinary), edit details, or delete.
- **One-tap "Share to feed"** from any entry.

### 💬 Feed
- A social timeline of everyone's shared journal entries.
- Photo carousels with a full-screen, pinch-to-zoom viewer.
- **Double-tap to like**, with an animated heart, and like counts.
- **Comments**, shown in a threaded-style sheet.

### 👤 Profile & settings
- Profile photo, name, username and email, with quick stats (journal entries and posts shared).
- **Light, Dark or System theme**, applied instantly and synced to your account.
- **12-hour or 24-hour time**, applied everywhere: dial, cards, journal, feed and time pickers.
- Notification preferences and ringtone.
- Stays signed in between launches; your session is checked securely at startup.

### 🎨 Design
- A modern Material 3 interface built on a calm **cream / black / grey** palette with muted category tints.
- Floating pill navigation, skeleton loading states and friendly empty states.
- Uses the **Fustat** typeface throughout.
- Built with accessibility in mind: readable contrast in both themes, large tap targets and screen-reader labels.

---

## How it works

```
 Plan                      Do                         Reflect                  Share
┌──────────────┐   ┌───────────────────────┐   ┌───────────────────┐   ┌──────────────────┐
│ Add tasks to │ → │ Follow the live hand; │ → │ Completed tasks   │ → │ Post to the Feed │
│ the 24h dial │   │ mark tasks done       │   │ become journal    │   │ for likes and    │
│ by category  │   │ (swipe or tap)        │   │ entries + photos  │   │ comments         │
└──────────────┘   └───────────────────────┘   └───────────────────┘   └──────────────────┘
```

---

## Tech stack

<details open>
<summary><b>Mobile app (Flutter)</b></summary>

| Area | Package |
|---|---|
| UI framework | Flutter (Dart SDK `^3.8.1`), Material 3 |
| State management | `provider` |
| Networking | `http`, `http_parser`, `mime` |
| Local storage | `shared_preferences` |
| Configuration | `flutter_dotenv` |
| Images | `image_picker` (uploads go through the API to Cloudinary) |
| Typography | `google_fonts` (Fustat) |
| Formatting | `intl` |
| App icons | `flutter_launcher_icons` |

</details>

<details open>
<summary><b>Backend (Node.js API)</b></summary>

| Area | Package |
|---|---|
| Runtime / framework | Node.js, Express 5 |
| Database | MongoDB Atlas via Mongoose 8 |
| Auth | `jsonwebtoken` (JWT, 7-day expiry), `bcryptjs` password hashing |
| File uploads | `multer` (memory storage, 5 MB / image, max 10) |
| Image hosting | Cloudinary |
| Config | `dotenv` |
| Dev tooling | `nodemon` |

</details>

---

## Architecture

```
┌──────────────────────────────┐        HTTPS / JSON         ┌──────────────────────────────┐
│        Flutter app           │  ── Bearer JWT ──────────▶  │      Express REST API        │
│                              │                             │                              │
│  Clock · Journal · Feed ·    │  ◀──────────────────────    │  /api/users  /api/tasks      │
│  Profile                     │                             │  /api/posts  /api/upload     │
│  Provider state (theme,      │                             │                              │
│  time format, categories)    │                             │  Mongoose models:            │
└──────────────────────────────┘                             │  User · Task · Post          │
                                                             └───────┬──────────────┬───────┘
                                                                     │              │
                                                            ┌────────▼─────┐  ┌─────▼────────┐
                                                            │ MongoDB Atlas│  │  Cloudinary  │
                                                            │   (data)     │  │   (images)   │
                                                            └──────────────┘  └──────────────┘
```

- **Data model:**
  - **User:** profile, theme, time format, notification settings and custom categories.
  - **Task:** title, category key, time range, status, photos, public flag and reminder.
  - **Post:** a public copy of a shared task, plus likes and comments.
- **Sharing:** setting a task as public creates or updates its Post, including a snapshot of the category's name, color and icon so every viewer sees it correctly.

---

## Getting started

### Prerequisites
- **Flutter SDK.** The project targets Dart `^3.8.1`; tested with Flutter 3.47.
- **Android Studio** (Android SDK and an emulator) and/or **Xcode** for iOS.
- **Node.js 20+** (LTS recommended) and npm.
- A **MongoDB Atlas** cluster (the free tier is fine).
- A **Cloudinary** account (the free tier is fine).

### 1. Clone
```bash
git clone https://github.com/aneqlique/cLock-In.git
cd cLock-In
```

### 2. Run the backend
```bash
cd clockin/backend
cp .env.example .env      # then fill in the values (see Configuration)
npm install
npm run dev               # nodemon; or `npm start`
```
You should see `Server running on port 8000` and `MongoDB connected (Atlas)`.

> **macOS tip:** port 5000 is taken by the AirPlay Receiver. Use `PORT=8000`.

### 3. Run the mobile app
```bash
cd clockin/mobile
cp .env.example .env      # set HOST (see Configuration)
flutter pub get
flutter run
```

---

## Configuration

### Backend: `clockin/backend/.env`
| Variable | Description | Example |
|---|---|---|
| `MONGO_URI` | MongoDB Atlas connection string | `mongodb+srv://user:pass@cluster.xxxx.mongodb.net/clockin` |
| `JWT_SECRET` | Long random string used to sign tokens | output of `openssl rand -hex 64` |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | `my-cloud` |
| `CLOUDINARY_API_KEY` | Cloudinary API key | `123456789012345` |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | — |
| `PORT` | Port for the API | `8000` |
| `NODE_ENV` | Optional; `development` adds error details to upload errors | `development` |

### Mobile: `clockin/mobile/.env`
| Variable | Description |
|---|---|
| `HOST` | Address of the API server, **without** `/api` and with no trailing slash |

Which `HOST` to use depends on where the app runs:

| Running on | `HOST` |
|---|---|
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://localhost:8000` |
| Physical device (same Wi-Fi) | `http://<your-computer-LAN-IP>:8000` |

> `.env` is bundled into the app, so **never put secrets in the mobile `.env`**. Both `.env` files are gitignored; only the `.env.example` templates are committed.

---

## API reference

All endpoints are prefixed with `/api`. 🔒 means the request needs an `Authorization: Bearer <token>` header.

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/users` | Register a new user |
| `POST` | `/users/login` | Log in; returns a JWT |
| `GET` | `/users` | List users |
| `PUT` | `/users/:id` | Update profile, theme, time format, categories or notification settings |
| `DELETE` | `/users/:id` | Delete a user |
| `GET` | `/tasks` 🔒 | Get the current user's tasks |
| `POST` | `/tasks` 🔒 | Create a task |
| `PUT` | `/tasks/:id` 🔒 | Update a task; setting `setPublic` creates or removes its post |
| `DELETE` | `/tasks/:id` 🔒 | Delete a task |
| `POST` | `/upload` 🔒 | Upload up to 10 images (multipart field `images`); returns Cloudinary URLs |
| `GET` | `/posts` 🔒 | Get all public posts (newest first) |
| `POST` | `/posts` 🔒 | Create, update or remove a post for a task |
| `POST` | `/posts/:postId/like` 🔒 | Like or unlike a post |
| `POST` | `/posts/:postId/comment` 🔒 | Add a comment |
| `GET` | `/posts/:postId/comments` 🔒 | Get a post's comments |

---

## Project structure

```
cLock-In/
├── ClockIn.png
├── README.md
└── clockin/
    ├── backend/                  # Node.js / Express API
    │   ├── config/               # MongoDB + Cloudinary setup
    │   ├── controllers/          # users, tasks, posts, uploads
    │   ├── middleware/           # JWT auth
    │   ├── models/               # User, Task, Post (Mongoose)
    │   ├── routes/
    │   ├── utils/
    │   ├── index.js
    │   └── .env.example
    └── mobile/                   # Flutter app
        ├── lib/
        │   ├── core/
        │   │   ├── config/       # theme (light/dark tokens), routes
        │   │   ├── models/       # ClockTask, TaskCategory
        │   │   ├── services/     # API + user services
        │   │   ├── state/        # theme, time format, categories, sync
        │   │   └── utils/        # date/time formatting
        │   └── presentation/
        │       ├── screens/      # auth, home (clock + journal), diary (feed), settings
        │       └── widgets/      # clock dial, cards, sheets, nav bar, pickers…
        ├── assets/
        └── .env.example
```

---

## Roadmap

- [ ] **Push notifications** for task reminders (reminders are saved, but nothing notifies you yet)
- [ ] **"Missed" view** for unfinished tasks from previous days
- [ ] **Recurring tasks** (daily / weekly routines)
- [ ] **Insights**: weekly time-by-category summaries and streaks
- [ ] **Follow / friends** and a personalized feed
- [ ] **Security hardening**: authorization on user routes, task ownership checks, rate limiting
- [ ] Secure token storage and release signing for app-store builds
- [ ] Automated tests (Flutter widget tests, API integration tests)

---

## Contributing

Contributions, ideas and bug reports are welcome!

1. Fork the repository and create a branch: `git checkout -b feature/my-feature`
2. Make your changes and run `flutter analyze` (mobile) before committing.
3. Commit with a clear message and open a Pull Request describing what changed and why.

Please never commit `.env` files or real credentials.

---

## License

Distributed under the **ISC License**.

---

## Acknowledgments

- Inspired by the "unemployed clock" from the K-drama ***Love Next Door***.
- Built with [Flutter](https://flutter.dev), [Express](https://expressjs.com), [MongoDB Atlas](https://www.mongodb.com/atlas) and [Cloudinary](https://cloudinary.com).

<p align="center"><b>Here we cLock In! ⏰</b></p>
