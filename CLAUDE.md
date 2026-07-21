# CLAUDE.md — Woodchuck USA LinkedIn Outreach

Context and operating instructions for continuing Isaac Rentmeester's LinkedIn
outreach campaign inside Claude Code (or any fresh Claude session).

## Where this project lives

Canonical home (source of truth): this folder —
`/Users/isaacrentmeester/Desktop/Claude/Prospect Finder/LinkedIn-Follow-Up/`
It's a git repo (`git@github.com:IsaacRentmeester/LinkedIn-Follow-Up-.git`).
Work here from now on — NOT the old iCloud `html/` folder.

## Who / what this is

Isaac is an intern at **Woodchuck USA** — premium custom wooden packaging for
product drops, influencer kits, collector's editions, gifting, and kitting.
This project runs an outbound **LinkedIn connection + follow-up campaign** against
a master prospect list: find each company's decision-maker, send a no-note
connection request, and auto-send a personalized intro the moment they accept.

## The moving parts

1. **Master prospect list** — the universe of companies to work through.
   `../Woodchuck_Prospect_List_2026-07-14.xlsx` (in the parent `Prospect Finder/`)
   Sheet `Targets`, 135 rows. Key columns: Company, Website, Contact Name, Title,
   LinkedIn, Contact Status. (The LinkedIn column holds label strings, not URLs.)

2. **Roster / daily automation** — the source of truth for *who gets messaged*.
   `/Users/isaacrentmeester/Documents/Claude/Scheduled/linkedin-followup-robert-cordes/SKILL.md`
   Front-matter name: **"Linkedin Followup - Daily Check"**. Contains the numbered
   ROSTER (each person: name, profile URL, company/role in parentheses, and their
   exact <60-word message) plus the PROCESS the daily run follows.

3. **Scheduled task** — runs the SKILL.md daily (~10 AM local, cron `0 8 * * *`).
   Managed via the scheduled-tasks tools (`list_scheduled_tasks`,
   `update_scheduled_task`). It ONLY messages people in the roster — never
   organic/other connections.

4. **HTML tracker** — the dashboard. Single canonical file in this repo:
   `woodchuck-linkedin-tracker.html`
   It embeds a `SEED_PEOPLE` array (the roster mirror) which is the tracker's
   source of truth. Statuses live in the file, not a database.

5. **Live public link (Vercel)** — auto-deployed from GitHub.
   https://woodchuck-linkedin-tracker.vercel.app
   The Vercel project `woodchuck-linkedin-tracker` (team
   `isaac-rentmeester-s-projects`) is connected to the GitHub repo
   `IsaacRentmeester/LinkedIn-Follow-Up-` (branch `main`). **Every push to `main`
   auto-builds and updates the live link** — no manual redeploy step. A `vercel.json`
   in the repo root rewrites `/` to `woodchuck-linkedin-tracker.html` so the tracker
   serves at the root URL. So the loop is: edit the tracker → commit + push to
   GitHub → Vercel redeploys itself.
   Note: the URL is public (no login) and exposes the full prospect list.

## Intake pipeline (adding new prospects) — the smooth flow

Isaac hands over LinkedIn profile URLs one of two ways:
- **Paste in chat** — he drops one or more `linkedin.com/in/…` URLs directly.
- **Tracker intake queue** — he pastes URLs into the "Add LinkedIn URLs (bulk)"
  box on the tracker (stored under the `Intake queue` tab), then either says
  **"sweep the intake queue"** or clicks **Copy queue for Claude** and pastes them.
  (The page can't write local files, so the Copy button is the bridge — the queue
  lives in his browser's `localStorage`, key `woodchuck_li_intake_v1`.)

For each URL provided, Claude runs this end to end:
1. Open the profile and pull **name, company, current role**.
2. **Relevance gate** — only proceed for packaging / brand / marketing / senior
   decision-makers (founder/owner/CEO/president/COO/head of X). Skip random
   employees. Include everyone's company, even enterprise/celebrity brands.
   (If Isaac ever gives a company instead of a person and no decision-maker
   surfaces on LinkedIn, crawl the company website — About / Team / Leadership —
   to find a relevant-role person, then proceed.)
3. Draft a personalized **<60-word message** from a quick bit of research.
4. **Send the no-note connection request right away** (at intake), on Isaac's
   live, logged-in LinkedIn via the Claude-in-Chrome browser tools — a webpage
   can't do this itself. Requests are sent at intake, NOT deferred to the schedule.
5. Add the person to the ROSTER in SKILL.md with that exact message, and to
   `SEED_PEOPLE` in the tracker with `status:'pending'`.
6. Remove the processed URL from the intake queue (if it came from there).
7. Redeploy the tracker to Vercel.

Then the **daily scheduled task** takes over automatically: it checks each
pending person for acceptance, verifies their role still matches, and
**auto-sends the drafted message the moment they connect back** (no approval
step — Isaac chose hands-off auto-send).

## Daily-run process (what the scheduled task does)

For each roster person: navigate to their profile → determine connection status
(Pending = skip; 1st-degree or free Message button = accepted). **Verify current
role** — if they've left the company or moved to an unrelated role, DO NOT send;
mark held for review. Check the thread for a prior Isaac message (idempotency —
never double-send). If accepted, role still matches, and no prior message: send
their exact roster message once. Then write status back to the tracker.

## Tracker data model

`SEED_PEOPLE` entries: `{name, company, role, url, status}`.
Status values: `hold` → `pending` → `connected` → `messaged` (monotonic —
only ever raise, never lower; `ORDER={hold:0,pending:1,connected:2,messaged:3}`).
Merge/write-back matches by exact `url:` value. Held / role-changed people are set
to `connected` (never `messaged`) and listed under "Needs review" in the run report.
The page auto-refreshes every 30s and persists per-visitor edits to `localStorage`
(keys `woodchuck_li_people_v2`, `woodchuck_li_companies_v2`) — but the embedded
`SEED_PEOPLE` in the file remains the authoritative roster.

## Keeping things in sync (rules)

- SKILL.md roster and `SEED_PEOPLE` must stay consistent (same people, same roles).
- Never lower a status. Edit only the `status:` string when writing back; don't
  touch name/company/url.
- After any change to the tracker: commit + push to GitHub `main`. That push is
  what updates the live Vercel link (auto-deploy) — there is no separate redeploy.

## Current status snapshot (as of 2026-07-21)

53 people in the roster. Tracker counts: 8 messaged, 1 connected (Pete Saari —
held, role changed), ~42 pending, 2 on hold (Aishwarya Iyer and Bill Bryant —
email-gated / need email to connect).

## Open / next work

- Continue working through the remaining master-list companies (include
  enterprise/celebrity), targeting packaging/brand/marketing/senior roles only,
  using the website-crawl fallback where LinkedIn yields no decision-maker.
- Redeploy the tracker after each batch.
