# ExamHub: Software Requirements Specification (SRS)

| | |
|---|---|
| **Product** | ExamHub, Online Exam Management System |
| **Version** | 1.0 |
| **Related document** | [PRD.md](PRD.md) |
| **Stack** | Java 21, JSP / Servlet 4.0 (Tomcat 9), PostgreSQL, Maven, Docker, Google Gemini |

**Keywords:** "shall" = mandatory requirement. Each requirement has an ID and is written to be directly testable.

---

## 1. Introduction

### 1.1 Purpose
This document specifies the functional and non-functional requirements of ExamHub so that the system can be built, tested, and verified against clear criteria.

### 1.2 Scope
ExamHub is a web application where students take multiple-choice exams from a database or AI-generated question bank, review results, keep notes, and merge PDFs, while administrators monitor platform data.

### 1.3 Definitions

| Term | Meaning |
|---|---|
| Topic | A named subject (`topics.tname`) that groups questions |
| Job | An asynchronous AI question-generation task tracked by `JobStore` |
| Nonce | A per-request random value allowing specific inline scripts under CSP |
| Pass | Score ≥ 50% of total questions |

## 2. Overall Description

### 2.1 User roles and permissions

| Capability | Anonymous | Student | Admin |
|---|:---:|:---:|:---:|
| View login / register | ✅ | ✅ | ✅ |
| Take exams, view history, notes, PDF tools | ❌ | ✅ | ✅ (not part of admin nav) |
| View admin dashboard | ❌ | ❌ | ✅ |

Roles are stored in `users.role`. A null role is treated as `student`.

### 2.2 Operating environment
- Server: Apache Tomcat 9 on JDK 21, packaged as `ROOT.war` in a Docker image.
- Database: PostgreSQL (JDBC driver 42.7.3).
- Client: Modern evergreen browser with JavaScript enabled.
- External service: Google Gemini API (`google-genai` SDK 1.55.0, model `gemini-3-flash-preview`).

### 2.3 Configuration (environment variables)

| Variable | Purpose | Default (dev only) |
|---|---|---|
| `DB_URL` | JDBC URL | `jdbc:postgresql://localhost:5432/Project` |
| `DB_USER` | DB username | `postgres` |
| `DB_PASSWORD` | DB password | local placeholder |
| `GEMINI_API_KEY` | Gemini API key | none (required for AI) |

## 3. Data Requirements

### 3.1 Tables

| Table | Columns (as used by the code) |
|---|---|
| `users` | `username` (unique), `password` (BCrypt hash), `email`, `role` |
| `topics` | `tid` (PK), `tname` |
| `questions` | `qid` (PK), `qno`, `qtext`, `qopts` (text[4]), `qans` (`A`–`D`), `tid` (FK → topics) |
| `user_results` | `username`, `topic`, `score`, `total_questions`, `test_date` |
| `notes` | `nid` (PK), `username`, `title`, `content`, `level`, `created_at` |

### 3.2 Data rules
- **DR-1** `users.username` shall be unique.
- **DR-2** Passwords shall be stored only as BCrypt hashes (cost factor 12).
- **DR-3** `questions.qopts` shall contain exactly four options mapped to A, B, C, D by index.
- **DR-4** `questions.qans` shall be one of `A`, `B`, `C`, `D`.
- **DR-5** `notes.level` shall be one of `school`, `bachelors`, `masters`.
- **DR-6** `user_results.test_date` shall be set by the server at insertion time.

## 4. Functional Requirements

### 4.1 Registration (`register.jsp`)

| ID | Requirement |
|---|---|
| FR-REG-1 | The system shall accept username, password, and email via POST. |
| FR-REG-2 | Username shall be 3–30 characters and contain only letters, digits, and underscores. |
| FR-REG-3 | Password shall be 8–72 characters and contain at least one digit or special character. |
| FR-REG-4 | Email shall match the pattern `x@y.zz`, with no whitespace and a TLD of at least 2 characters, and be ≤ 100 characters. |
| FR-REG-5 | Email shall be stored trimmed and lower-cased; username trimmed. |
| FR-REG-6 | On a validation failure the system shall show the specific error message and not create a user. |
| FR-REG-7 | On success the system shall store the BCrypt hash, show a confirmation, and redirect to login. |
| FR-REG-8 | On a database error (e.g. duplicate username) the system shall show a generic failure message and log details server-side only. |
| FR-REG-9 | The client shall display a live password-strength meter. This is advisory and does not replace server validation. |

### 4.2 Login and logout (`login.jsp`, `logout.jsp`)

| ID | Requirement |
|---|---|
| FR-AUTH-1 | The system shall authenticate with username and password using `BCrypt.checkpw`. |
| FR-AUTH-2 | On success the system shall invalidate the old session, create a new one (session-fixation defence), and store `username` and `role`. |
| FR-AUTH-3 | Admins shall be redirected to `admin_dashboard.jsp`; all others to `dashboard.jsp`. |
| FR-AUTH-4 | On failure the system shall show "Invalid Username or Password!" without revealing which was wrong. |
| FR-AUTH-5 | Logout shall invalidate the session, send no-cache headers, and redirect to login. |
| FR-AUTH-6 | Unauthenticated access to any protected page shall redirect to `login.jsp`. |
| FR-AUTH-7 | Sessions shall expire after 30 minutes of inactivity. |

### 4.3 Exam setup (`setup.jsp`, `generateQuestion.jsp`)

| ID | Requirement |
|---|---|
| FR-SET-1 | The user shall choose a source (`database` default, or `ai`), a topic (required, ≤ 100 chars), and question count (1–50, default 10). |
| FR-SET-2 | The page shall display the number of topics available in the database. |
| FR-SET-3 | Submitting shall disable the button and show a loading state. |
| FR-SET-4 | If any of topic, count, or source is missing, the user shall be redirected to setup. |

**Database source**

| ID | Requirement |
|---|---|
| FR-DB-1 | The system shall look up the topic case-insensitively (exact match first, then partial `ILIKE %topic%`). |
| FR-DB-2 | If the topic is not found or has zero questions, the user shall see an error and return to setup. |
| FR-DB-3 | On success the system shall store `currentTid`, `currentTopic`, and `totalQuestions` in the session and redirect to `exam.jsp`. |

**AI source**

| ID | Requirement |
|---|---|
| FR-AI-1 | The system shall resolve the topic (or create a new one) and delete the topic's existing questions, then invalidate its cache entry. |
| FR-AI-2 | The system shall start a background job and immediately redirect to `loading.jsp?jobId=…` without waiting for Gemini. |
| FR-AI-3 | The background job shall call Gemini with a 60 s timeout and no database connection held during the call. |
| FR-AI-4 | The response shall be parsed into question number, text, four options, and answer (A–D). Markdown artefacts (`**`, code fences) shall be stripped. |
| FR-AI-5 | If zero questions are parsed, the job shall end in `ERROR`. |
| FR-AI-6 | Parsed questions shall be batch-inserted into `questions` for the topic's `tid`. |
| FR-AI-7 | Job states shall be `PENDING`, `DONE`, `ERROR`, `CANCELLED`. Jobs shall expire 10 minutes after their last state is set. |

### 4.4 Loading and job status (`loading.jsp`, `jobStatus.jsp`)

| ID | Requirement |
|---|---|
| FR-JOB-1 | `loading.jsp` shall redirect to setup if the job ID is missing or unknown. |
| FR-JOB-2 | The page shall poll `jobStatus.jsp` every 2 s (3 s retry after a network error) for up to 35 polls, then show a timeout message and return to setup. |
| FR-JOB-3 | `jobStatus.jsp` shall return JSON: `pending`, `done`, `error` (with message), or `cancelled`, with `Cache-Control: no-store`. |
| FR-JOB-4 | On `done` the server shall set `currentTid` in the session and remove the job; the client shall redirect to `exam.jsp`. |
| FR-JOB-5 | On `error` the client shall alert the message and return to setup. |
| FR-JOB-6 | Cancel (`?cancel=1`) shall mark the job cancelled, interrupt its thread, and return the user to setup. |
| FR-JOB-7 | `jobStatus.jsp` shall return 401 for unauthenticated callers and 400 for a missing job ID. |

### 4.5 Taking the exam (`exam.jsp`)

| ID | Requirement |
|---|---|
| FR-EX-1 | If the topic, count, or `currentTid` is missing in the session, redirect to setup. |
| FR-EX-2 | The system shall select up to `min(count, 50)` random questions for the topic. |
| FR-EX-3 | Questions shall be cached per topic and tid for 10 minutes; the cache shall hold at most 100 entries. |
| FR-EX-4 | Each question shall render four radio options (A–D) named `q<qid>`, and every question shall be required. |
| FR-EX-5 | The form shall include the CSRF token and POST to `result.jsp`. |
| FR-EX-6 | A loading overlay shall be shown until the page `load` event, then replaced by the form. |
| FR-EX-7 | The correct answer shall never be included in the HTML sent to the browser. |

### 4.6 Results (`result.jsp`)

| ID | Requirement |
|---|---|
| FR-RES-1 | The system shall read submitted `q<qid>` parameters, load the matching questions, and compare each answer to `qans` (trimmed, case-insensitive). |
| FR-RES-2 | The score shall equal the number of correct answers. |
| FR-RES-3 | The system shall insert one row into `user_results` (username, topic, score, total, now). |
| FR-RES-4 | The page shall show `Score: X / Total`, and a table with: number, question, user's answer text, correct answer text, ✅/❌. |
| FR-RES-5 | The total shall be the requested count from the session, or the number of answered questions if unavailable. |
| FR-RES-6 | Confetti shall display when score ≥ 50% of total. |
| FR-RES-7 | If no question parameters are submitted, redirect to setup. |
| FR-RES-8 | If saving the result fails, the user shall see an error message but still see their score. |

### 4.7 Dashboard and history (`dashboard.jsp`, `exam_history.jsp`)

| ID | Requirement |
|---|---|
| FR-DASH-1 | The dashboard shall show: total exams taken, average score % (`score/total × 100`, ignoring zero totals), and the latest result (topic, date, %). |
| FR-DASH-2 | With no history the dashboard shall show an empty-state message. |
| FR-DASH-3 | The history page shall list the user's attempts, newest first, with date, topic, score, and Pass/Fail (pass at ≥ 50%). |
| FR-DASH-4 | Users shall only ever see their own results. |

### 4.8 Smart Notes (`notes.jsp`)

| ID | Requirement |
|---|---|
| FR-NOTE-1 | The user shall create a note with title (required, ≤ 200 chars), content (required), and level (default `bachelors`). |
| FR-NOTE-2 | The list shall show the user's notes newest first with level label and timestamp. |
| FR-NOTE-3 | Delete shall remove a note only if `nid` is numeric and belongs to the logged-in user. |
| FR-NOTE-4 | After save or delete the system shall redirect (Post/Redirect/Get) and show a one-time success or error message. |
| FR-NOTE-5 | *(Planned)* AI suggestions shall be produced by a server-side endpoint using a server-held API key. The current browser-side call is non-functional (see §7). |

### 4.9 PDF Tools (`pdf_tools.jsp`)

| ID | Requirement |
|---|---|
| FR-PDF-1 | The user shall upload multiple files via click or drag-and-drop; the client shall reject non-PDF files and files over 20 MB. |
| FR-PDF-2 | The server shall accept only parts named `pdfFiles` with content type `application/pdf` and a non-zero size. |
| FR-PDF-3 | Fewer than 2 valid PDFs shall produce the error "Please upload at least 2 PDF files." |
| FR-PDF-4 | The server shall merge in upload order and return `merged_output.pdf` as an attachment. |
| FR-PDF-5 | Max file size 20 MB; max request size 60 MB (enforced by multipart config). |
| FR-PDF-6 | Merge failure shall show a generic error and log details server-side. |

### 4.10 Admin dashboard (`admin_dashboard.jsp`)

| ID | Requirement |
|---|---|
| FR-ADM-1 | Access shall require `role = admin`; otherwise redirect to login. |
| FR-ADM-2 | The page shall show four read-only tables: Users (username, email, role; **never** password), Topics, Question Bank (qid, qno, qtext, qans, tid), and Student Test Records. |
| FR-ADM-3 | Database errors shall show a generic message and log details server-side. |
| FR-ADM-4 | Stat tiles (Total Users, AI API Requests, Questions in DB, Global Avg Score) currently show "—" and shall be implemented with aggregate queries. |

### 4.11 Navigation and theming (`navbar.jsp`, `static/main.js`)

| ID | Requirement |
|---|---|
| FR-NAV-1 | Students see Dashboard, Exams, Notes, PDF Tools, Logout; admins see Overview, Database, Users, Logout; guests see Login/Register. |
| FR-NAV-2 | The active page link shall be highlighted. |
| FR-NAV-3 | A theme toggle shall switch light/dark and persist the choice in `localStorage` (`eh-theme`). |

## 5. Business Rules

- **BR-1** Pass mark is 50%: `score ≥ total / 2`.
- **BR-2** Maximum 50 questions per exam.
- **BR-3** Each question has exactly one correct option.
- **BR-4** Topic names are matched case-insensitively and may match partially.
- **BR-5** Generating AI questions for an existing topic replaces that topic's questions.
- **BR-6** A user may only read or delete their own notes and see their own history.

## 6. Non-Functional Requirements

### 6.1 Security

| ID | Requirement |
|---|---|
| NFR-SEC-1 | All SQL shall use prepared statements with bound parameters. |
| NFR-SEC-2 | Session cookies shall be `HttpOnly`, `Secure`, and `SameSite=Strict`; session tracking by cookie only. |
| NFR-SEC-3 | CSRF tokens shall be generated per session, validated on POST for the mapped URLs, and rotated after each successful validation. |
| NFR-SEC-4 | Login and register POSTs shall be rate-limited: after 5 failed attempts from an IP, further POSTs return HTTP 429 for 15 minutes. |
| NFR-SEC-5 | Responses shall include a Content-Security-Policy using per-request nonces for inline scripts (no `unsafe-inline` for scripts), plus `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, HSTS, `Referrer-Policy`, and `Permissions-Policy`. |
| NFR-SEC-6 | Internal errors shall be logged server-side; users see generic messages. |
| NFR-SEC-7 | User-supplied text shall be HTML-escaped when rendered. *(Not yet fully met; see §7.)* |
| NFR-SEC-8 | Secrets shall be supplied only through environment variables, never committed. |

### 6.2 Performance

| ID | Requirement |
|---|---|
| NFR-PERF-1 | A database-source exam shall load in ≤ 2 s under normal load. |
| NFR-PERF-2 | AI generation shall time out after 60 s; the client gives up after ~70 s. |
| NFR-PERF-3 | The database connection pool shall hold at most 10 connections and validate connections before reuse. |
| NFR-PERF-4 | AI calls shall not hold HTTP threads or database connections while waiting. |

### 6.3 Reliability and availability
- **NFR-REL-1** Job and cache stores shall evict expired entries automatically (every 5 min for jobs, 10 min for questions).
- **NFR-REL-2** A failure of one request shall not corrupt shared state (connections are always released in `finally`).

### 6.4 Usability and accessibility
- **NFR-UX-1** The UI shall be responsive from 360 px to desktop widths.
- **NFR-UX-2** Forms shall use `label` elements, native validation, and clear error messages.
- **NFR-UX-3** Colour contrast shall remain readable in both themes.

### 6.5 Maintainability and portability
- **NFR-MNT-1** AI logic shall remain isolated in `AIUtils`; JSPs shall not contain Gemini calls.
- **NFR-MNT-2** The application shall build with `mvn clean package` to a single WAR and run in the provided Dockerfile.

## 7. Known Gaps in the Current Implementation

These are places where the code does not yet meet the requirements above, listed so they can be tracked and tested.

| # | Gap | Related requirement |
|---|---|---|
| G1 | The AI prompt always requests 10 questions, ignoring the user's count | FR-SET-1 |
| G2 | `result.jsp` scores whatever `q<id>` parameters are posted, not the questions actually served | FR-RES-1, FR-EX-4 |
| G3 | `result.jsp` throws an NPE on `totalRequested / 2.0` when the session value is null | FR-RES-5, FR-RES-6 |
| G4 | CSRF filter is mapped only to `/login.jsp`, `/register.jsp`, `/exam.jsp`; forms in `setup.jsp`, `notes.jsp`, and `pdf_tools.jsp` carry a token that is never validated | NFR-SEC-3 |
| G5 | Notes AI suggestions call `api.anthropic.com` from the browser; blocked by `connect-src 'self'` and no key is available client-side | FR-NOTE-5 |
| G6 | Unescaped output of user-controlled values (topic, note titles, usernames, error text in `exam_history.jsp` / `exam.jsp`) | NFR-SEC-7, NFR-SEC-6 |
| G7 | `exam.jsp` uses a cache keyed by topic and tid, so all users share one question set for 10 minutes and "random" is per cache refill, not per user | FR-EX-2 |
| G8 | Admin stat tiles are placeholders | FR-ADM-4 |
| G9 | Rate limiter counts any HTTP 200 POST response as a failure, and redirects (success) clear the counter | NFR-SEC-4 |
| G10 | The deployed `loading.jsp` (with a "Force Redirect" button) differs from the repository version | maintainability |

## 8. Acceptance Test Matrix

| Req. group | Test | Expected |
|---|---|---|
| FR-REG | Register with username `ab` | Error: 3–30 characters |
| FR-REG | Register with password `abcdefgh` (no digit/special) | Error: needs number or special character |
| FR-REG | Valid registration | Row in `users` with `$2a$12$…` hash; redirect to login |
| FR-AUTH | Login with wrong password | Generic invalid message; no session |
| FR-AUTH | Access `dashboard.jsp` logged out | Redirect to login |
| FR-AUTH | Student opens `admin_dashboard.jsp` | Redirect to login |
| NFR-SEC-4 | 5 failed logins, then a 6th | HTTP 429 with wait time |
| FR-DB | Database exam on a topic with questions | Exam page with requested number of questions |
| FR-DB | Database exam on unknown topic | Error alert, back to setup |
| FR-AI / FR-JOB | AI exam on new topic | Loading page polls every 2 s, redirects to exam when done |
| FR-JOB-6 | Click Cancel during generation | Returned to setup; job marked cancelled |
| FR-RES | Answer all questions and submit | Score, breakdown, one new `user_results` row |
| FR-DASH | After 2 exams | Dashboard shows 2 exams and correct average |
| FR-NOTE | Delete another user's `nid` via crafted POST | No row deleted |
| FR-PDF | Upload 1 PDF / 2 PDFs / a `.png` | Error / merged download / file rejected |
| FR-ADM | Open admin dashboard as admin | Four tables; no password column |
| NFR-SEC-5 | Load every page with DevTools open | No CSP violations in console |