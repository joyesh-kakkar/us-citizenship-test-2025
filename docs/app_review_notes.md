# App Review Information — Notes field

Paste the text below into App Store Connect →
App Version → App Review Information → Notes.
Also send it as a reply in the review thread alongside the screen recording.

---

Demo account: not required. The app has no login, no account, and no
user-generated content. Every feature is available immediately on first
launch.

1. SCREEN RECORDING
A screen recording captured on a physical iPhone is attached to this reply.
It begins with the app launching and shows the typical study flow: home
screen, a full 20-question practice test through to the score, flashcards,
and browsing questions by category.

2. PURPOSE AND TARGET AUDIENCE
Citizenship Exam Prep 2025 helps immigrants preparing for the U.S.
naturalization civics interview. The 2025 USCIS civics test draws 20
questions from a bank of 128; the applicant must answer 12 correctly to
pass. Studying 128 questions from a printed PDF is hard to do well, so the
app turns the official question bank into practice tests, flashcards, and a
readiness score that shows which questions still need work. It is free,
needs no account, and works entirely offline.

3. SETUP AND ACCESSING THE MAIN FEATURES
No setup, login, or credentials of any kind. The app opens on the home
screen, which offers:
- "Start a quiz" — a practice quiz drawn from the question bank
- "Practice tests" — 20 numbered 20-question tests, scored against the real
  12-of-20 passing threshold; a test left part-way through can be resumed
- "Study all questions" — the full bank browsable by category
- "Flashcards" — self-paced review of every question
- "Fix your misses" — replays only the questions answered wrong before
- "Favorites", "Statistics", and "Search all questions"
- "Settings" — dark mode, reset progress, and the study-scope choice below

Study scope (in Settings): "All 128" is the default. "Starred 20" is the
official USCIS 65/20 accommodation — applicants aged 65 or older who have
been permanent residents for 20 years or more study a 20-question subset,
marked with an asterisk in the USCIS materials. The setting changes which
questions the quizzes and tests draw from.

4. EXTERNAL SERVICES, TOOLS, OR PLATFORMS
None. The app makes no network requests at all. All question content is
bundled in the app binary and read from local assets. There is no analytics
SDK, no authentication provider, no payment processing, no advertising, and
no AI or machine-learning service. Progress is stored only on the device
(UserDefaults) and never leaves it. The app requests no permissions and
collects no data.

5. REGIONAL DIFFERENCES
None. The app behaves identically in every region and on every device. The
content is the U.S. naturalization civics test, which is the same worldwide;
there is no geo-targeting, no region-gated feature, and no server that could
vary a response.

6. THIRD-PARTY AND REGULATED MATERIAL
All questions and official answers are taken from the USCIS publication
"128 Civics Questions and Answers (2025 version)" (uscis.gov), a U.S.
government work in the public domain, which may be reproduced without
permission or license. The incorrect multiple-choice options were written
for this app and are not USCIS material; the app states this on its Settings
screen. The app is an independent study aid. It is not affiliated with,
endorsed by, or sponsored by USCIS or any U.S. government agency, it makes
no claim to be an official source, and it provides no legal or immigration
advice. It is not operated in a regulated industry and handles no user data.

CHANGES SINCE THE PREVIOUS SUBMISSION (build 1)
- Fixed the practice-test grading and question-pool scoping.
- Added question search and the ability to resume an unfinished test.
- Moved the study-scope choice (All 128 / Starred 20) into Settings.
