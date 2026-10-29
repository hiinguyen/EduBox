# Product

## Register

product

## Users

Three roles share one Flutter app, gated by role on login:

- **Students** (primary daily users): study on a locked-down Android tablet - read e-books, watch lectures, do exercises, chat with an AI tutor, take timed tests. Context is a classroom or home study session; the device is meant to be distraction-free, so the UI should never compete for attention the way a consumer app would.
- **Teachers**: upload and approve content, create assignments and tests, review results. Context is prep time or between classes - task-focused, not browsing.
- **Parents** (Phase 1 stub): read-only summary of their child's progress and AI chat activity. Low-frequency, low-interaction use.

## Product Purpose

EduBox restricts a student's device to approved educational content only (e-books, videos, exercises, AI tutoring, dictionary, test rooms, teacher materials) and keeps games, app stores, and unapproved installs out of reach. Phase 1 validates the core learning loop on an off-the-shelf Android tablet: a teacher publishes content and assignments, a student studies and submits work, and results become visible to teacher and parent. Success looks like a student completing a real lesson-to-test cycle without needing to leave the app, and a teacher trusting the results enough to act on them.

Phase 2 (locked kiosk mode) and Phase 3 (custom hardware) build on this same app and data model without a rewrite - design decisions here should not assume Phase 1's unlocked tablet is the permanent context.

## Brand Personality

Friendly, encouraging, simple. The tone should feel like a supportive tutor, not an enterprise admin tool and not a gamified app chasing engagement. Warmth and approachability matter most for the student-facing surfaces (library, tutor chat, exercises); teacher and parent surfaces can be calmer and more utilitarian while staying in the same friendly voice.

## Anti-references

Explicitly avoid the gamified EdTech look: no mascots, confetti, streak counters, badges, leaderboards, or other dopamine-loop mechanics. EduBox earns trust through calm competence, not engagement tricks - the product's whole premise is reducing distraction, so its own UI must not re-introduce it.

## Design Principles

- **Calm over engagement**: no streaks, badges, or notification pressure. Every interaction should help the student finish the task in front of them, not pull them into "just one more."
- **Trust through clarity**: teachers and parents act on what this app reports (grades, AI chat logs, progress), so results and status must read unambiguously at a glance - no ambiguous icons or hidden states.
- **One app, three roles, one voice**: Student, Teacher, and Parent surfaces share the same friendly-but-focused personality; only density and task framing shift per role, not tone.
- **Built to extend, not to impress**: Phase 1 ships on an unlocked tablet, but the UI should already read as "this is the one app you're meant to use," anticipating the Phase 2 kiosk lock rather than looking like a demo.
- **Fail loud, never silent**: connectivity issues, AI-tutor unavailability, and sync status must be shown explicitly (per the spec's offline/error-handling rules) - never a silent spinner or a swallowed error.

## Accessibility & Inclusion

WCAG 2.1 AA baseline across all three role surfaces: sufficient color contrast, adequate tap-target sizing for tablet use, and screen-reader support. Students may be younger or using shared/older tablets, so legibility and touch-target forgiveness matter more than density.
