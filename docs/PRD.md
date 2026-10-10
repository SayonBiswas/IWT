# ExamHub: Product Requirements Document (PRD)

| | |
|---|---|
| **Product** | ExamHub, Online Exam Management System |
| **Version** | 1.0 |
| **Authors** | Sayon Biswas, Suranjeet Behera |
| **Context** | Internet & Web Technology (IWT) Lab project |
| **Status** | MVP built and deployed (Render) |

---

## 1. Problem Statement

Students preparing for exams need a quick way to practise topic-wise multiple-choice questions, see their scores, and keep study material in one place. Question banks are usually static, so a student who wants to practise a topic that nobody has authored questions for has no option. Administrators, in turn, have no single view of users, questions, and results.

ExamHub solves this by combining:

- a **question bank** stored in a database,
- **on-demand AI question generation** (Google Gemini) for any topic,
- an **exam-taking and scoring flow** with history, and
- lightweight **study utilities** (notes, PDF merging).

## 2. Target Users

| User | Description | Primary needs |
|---|---|---|
| **Student** | College or school learner practising for exams | Take a quick quiz on any topic, see correct answers, track progress, keep notes, merge PDFs |
| **Administrator** | Teacher or platform owner | See all users, topics, questions, and results at a glance |

> The login page describes "Students, Teachers & Admins", but the system currently has only two roles: `student` and `admin`.

## 3. Goals

1. A student can register, log in, and start a practice exam in under one minute.
2. Any topic can be examined, either from the existing database or via AI generation.
3. Every exam attempt is scored instantly and recorded.
4. Students can review their performance over time.
5. Admins can inspect platform data without database access.
6. The app is secure by default (hashed passwords, CSRF protection, rate limiting, hardened cookies, CSP).

### Non-goals (this release)

See [Section 9: Out of Scope](#9-out-of-scope).

## 4. Core Features

### 4.1 Authentication and accounts
- Registration with username, email, and password (with live password-strength meter).
- Login with BCrypt-verified credentials; role-based redirect (admin → admin dashboard, student → dashboard).
- Logout that invalidates the session.

### 4.2 Exam configuration and taking
- Choose a **topic** (free text), **number of questions** (1–50), and **source** (Internal Database or AI Generated).
- Multiple-choice questions with four options (A–D), one correct answer.
- Loading overlay and skeleton cards for perceived performance.

### 4.3 AI question generation
- Gemini generates questions for the requested topic and stores them in the database.
- Runs as an **asynchronous background job**, so the browser is never blocked. A loading page polls for status, with a cancel option.

### 4.4 Results and history
- Immediate score with a per-question breakdown (your answer vs. correct answer).
- Pass threshold of 50%; confetti on pass.
- Persistent exam history and dashboard statistics (exams taken, average score, latest activity).

### 4.5 Smart Notes
- Create, list, and delete personal notes with a title, academic level (School / Bachelors / Masters), and content.
- AI suggestions for notes (see Risks: currently not functional).

### 4.6 PDF Tools
- Upload two or more PDFs and download one merged PDF.

### 4.7 Admin dashboard
- Read-only tables for Users (passwords excluded), Topics, Question Bank, and Student Test Records.

### 4.8 UX
- Light and dark theme toggle, remembered per browser.
- Responsive layout for mobile and desktop.

## 5. MVP Scope

The MVP is **feature-complete as listed in Section 4**. The following define its boundaries:

| Area | In MVP |
|---|---|
| Roles | Student, Admin |
| Question type | Single-answer MCQ, 4 options |
| Question sources | Database, Gemini AI |
| Scoring | Number correct / total; pass at ≥ 50% |
| Admin | View-only dashboard |
| Deployment | Single Docker container (Tomcat 9, Java 21) + PostgreSQL |

## 6. User Stories

### Student
- **US-1** As a student, I want to register an account so that my results are saved.
- **US-2** As a student, I want to log in securely so that only I can see my data.
- **US-3** As a student, I want to pick a topic and number of questions so that I can practise what I need.
- **US-4** As a student, I want AI-generated questions for a topic that is not in the database so that I am never blocked.
- **US-5** As a student, I want to see a progress indicator while AI generates questions, and be able to cancel it, so that I am not left guessing.
- **US-6** As a student, I want my score and the correct answers immediately after submitting so that I can learn from mistakes.
- **US-7** As a student, I want to view my past exams so that I can track improvement.
- **US-8** As a student, I want a dashboard summary (exams taken, average score, latest result) so that I see my progress at a glance.
- **US-9** As a student, I want to save and delete study notes so that my material is organised.
- **US-10** As a student, I want to merge several PDFs into one so that I can combine my notes.
- **US-11** As a student, I want a light/dark theme so that I can study comfortably.

### Administrator
- **US-12** As an admin, I want to see all registered users (without passwords) so that I can monitor the platform.
- **US-13** As an admin, I want to see topics and the question bank so that I can verify content quality.
- **US-14** As an admin, I want to see all students' test records so that I can review performance.

## 7. Success Metrics

| Metric | Target |
|---|---|
| Registration → first exam started | ≥ 60% of new users |
| Database-source exam start time | < 2 seconds |
| AI-generation success rate | ≥ 90% of jobs reach `DONE` |
| AI-generation median time | ≤ 30 seconds |
| Exams completed vs. started | ≥ 80% |
| Login success after valid credentials | 100%; no false lockouts |
| Security | 0 plaintext passwords stored; CSRF validation on all state-changing exam/auth forms |

## 8. Assumptions

- Users have a modern browser with JavaScript enabled.
- The Gemini API key is available through the `GEMINI_API_KEY` environment variable and Gemini is reachable from the host.
- PostgreSQL is the single source of truth; tables (`users`, `topics`, `questions`, `user_results`, `notes`) are created manually.
- Traffic is low (class/lab scale), so a single instance and in-memory caches are acceptable.
- Hosting is HTTPS (secure cookies and HSTS require it).

## 9. Out of Scope

- Timed exams, countdown timers, or auto-submit.
- Question types other than single-answer MCQ (multi-select, short answer, coding).
- Admin editing: creating/editing/deleting users, topics, and questions through the UI.
- Teacher role, classes, assignments, or exam scheduling.
- Password reset, email verification, social login.
- Per-question difficulty selection and analytics.
- Leaderboards and sharing.
- Native mobile apps.
- Horizontal scaling (shared cache/session store).

## 10. Risks and Open Issues

| # | Risk / Issue | Impact | Mitigation |
|---|---|---|---|
| R1 | **AI always generates 10 questions** (prompt is hard-coded) regardless of the count requested | Confusing UX if the user picks 5 | Parametrise the prompt with the requested count |
| R2 | **AI generation replaces the topic's existing questions** and the question bank is shared by all users | One user's regeneration changes content for everyone | Version questions per generation, or only append |
| R3 | Gemini latency, quota, or failure | Exam cannot start | 60 s timeout, user-friendly error, fallback to database source |
| R4 | **Notes AI suggestions call the AI API from the browser** and are blocked by CSP (and have no key) | Feature does not work | Add a server-side endpoint that calls the AI with the server-held key |
| R5 | Result page trusts client-submitted question IDs | A user could submit a custom set of questions | Store the served question IDs in the session and score only those |
| R6 | Admin-only pages check role; student pages only check login | An admin can open student pages (low impact) | Optional: role guard per page |
| R7 | In-memory `QuestionCache`, `JobStore`, and rate-limit data are lost on restart and not shared across instances | Jobs and lockouts reset | Acceptable for MVP; move to Redis if scaled |
| R8 | Some pages print unescaped user content (e.g. note titles, topics) | Stored/reflected XSS risk | Escape output (`<c:out>` / `fn:escapeXml`) |
| R9 | Admin dashboard stat tiles are placeholders ("—") | Incomplete feature | Wire them to real aggregate queries |

## 11. Acceptance Criteria (MVP release)

1. A new user can register, log in, and land on the correct dashboard for their role.
2. A student can start a **database** exam for an existing topic and receive questions within 2 seconds.
3. A student can start an **AI** exam for any topic; the loading page polls the server and redirects to the exam when the job completes, or shows an error and returns to setup on failure or cancel.
4. Submitting an exam shows the score, per-question breakdown, and saves one row in `user_results`.
5. Exam history lists all of the logged-in student's attempts, newest first.
6. A student can create and delete notes; deleting only affects their own notes.
7. Uploading two or more valid PDFs downloads a merged PDF; fewer than two shows an error.
8. The admin dashboard shows users (without the password column), topics, questions, and results; non-admins are redirected to login.
9. Five failed login/register POSTs from one IP trigger a 15-minute lockout response.
10. All pages load with **no Content-Security-Policy violations** in the browser console.