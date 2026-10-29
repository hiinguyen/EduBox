<!-- SEED: established with the user before implementation; re-run /impeccable document once there's code to capture the actual tokens and components. -->

---
name: EduBox
description: A calm, institutional study space for a locked-down learning tablet.
---

# Design System: EduBox

## Overview

**Creative North Star: "The School Record Room"**

EduBox should feel like the trustworthy paper world a school already runs on: a library card catalog, a report card, a well-kept exercise notebook. These are the artifacts a student, teacher, and parent already recognize as "this is official, this is organized, this is for schoolwork" - without being cold or bureaucratic. The product's whole premise is removing distraction and choice-overload (approved content only, no games, no app stores), so its own interface should read as calm competence rather than compete for attention the way a consumer or gamified app would.

Explicitly rejected: the gamified-EdTech look (mascots, confetti, streak counters, badges, leaderboards) and the generic flat-SaaS-dashboard look (gray cards, default chart colors, anonymous icon tiles). Also rejected: an overcorrected "locked-down kiosk" look (heavy padlock iconography, warning-banner grays) that would feel punitive rather than supportive.

**Key Characteristics:**
- Institutional-but-warm: borrows structure from report cards, library records, and notebooks, not enterprise admin panels.
- Friendly through clarity, not decoration: warmth comes from type, color restraint, and copy tone - not mascots or illustration.
- One voice across three roles (student/teacher/parent); density and task framing shift per role, tone does not.
- Status and state are always named in words, never hidden behind a silent spinner or an ambiguous icon alone.

## Colors

**Color strategy: Restrained.** Tinted paper-toned neutrals carry the surface; one accent color does real work (primary actions, active states, score/status) and is never decorative. This matches an Operate surface used for focused schoolwork, not a Persuade surface competing for attention.

### Primary
- **[to be resolved during implementation]** - a single confident accent (candidates to explore: a deep ink-blue or a muted maroon/oxblood, both read as "institutional record," not "corporate SaaS blue" or "gamified bright primary"). Used for primary actions, active/selected states, and the one place per screen that most needs attention.

### Neutral
- **[to be resolved during implementation]** - a warm, slightly tinted paper-white for backgrounds (not stark white, not the saturated cream/sand AI-default band - tinted toward the primary's own hue at very low chroma).
- **[to be resolved during implementation]** - an ink-toned near-black for body text, hitting WCAG AA contrast (≥4.5:1) against the paper background.
- **[to be resolved during implementation]** - a mid-gray for dividers, disabled states, and secondary metadata (timestamps, byline-style labels).

### Named Rules
**The One Accent Rule.** The primary accent appears in at most one dominant place per screen (the active action, the current status, or the one metric that matters). It is never used as a decorative fill, a gradient, or a background wash.

**The Named State Rule.** Every status (submitted, pending sync, graded, locked, AI unavailable) is shown as a labeled word or short phrase, never as color alone or an unlabeled icon. Color reinforces the label; it never replaces it.

## Typography

**Display Font:** [to be resolved during implementation] - a confident serif or slab in the "report card / library ledger" family (avoid the AI-default display faces: Fraunces, Playfair Display, Cormorant, Lora, Crimson, Newsreader).
**Body Font:** [to be resolved during implementation] - a plain, highly legible humanist sans for body text and UI chrome, chosen for tablet legibility at a range of sizes (students may use shared or older tablets).
**Label/Mono Font:** [to be resolved during implementation] - a simple monospace or stencil-adjacent face for stamped/labeled elements (status tags, IDs, timestamps), evoking a library due-date stamp or ledger entry.

**Character:** Serious enough to feel institutional and trustworthy, plain enough to never feel decorative or playful for its own sake. The pairing should read as "a well-kept school record," not "an editorial magazine" or "a children's app."

### Hierarchy
- **Display** (bold, large): section and subject titles (e.g. a subject's library view, a test's title screen).
- **Headline**: screen titles, assignment names.
- **Title**: card/list-item titles (a book title, a lesson name, an assignment name).
- **Body**: reading content, instructions, chat messages. Cap prose width at 65-75ch where text is the primary content (AI tutor chat, reading material).
- **Label** (small, possibly tracked uppercase): status tags, timestamps, metadata, the stamp-like elements that reinforce the record-room metaphor.

### Named Rules
**The Stamped Status Rule.** Status labels (graded, submitted, pending, locked) use the Label typeface treatment consistently, so they read as a recognizable "stamp" vocabulary across all three roles.

## Layout

[To be resolved during implementation - no code exists yet.] Expect a single-column, list/card-forward structure for student content browsing (library as an organized shelf, not a dense data-grid), and a denser, table-forward structure for teacher assignment/results views. Generous spacing on student-facing screens (calm, uncluttered); tighter, more utilitarian spacing on teacher screens where scanning many rows matters. Designed primarily for tablet landscape and portrait use.

## Elevation & Depth

[To be resolved during implementation.] Lean toward flat-with-tonal-layering rather than heavy shadows - consistent with the paper/record-room metaphor (paper sits on paper, distinguished by tone and thin rules, not drop shadows). A light shadow may be used sparingly for a genuinely floating element (an active modal, the AI tutor chat panel), not for routine cards.

### Named Rules
**The Flat-By-Default Rule.** Surfaces are flat at rest, distinguished by tone, thin rules, or a hairline border - never a default card shadow. Shadow is reserved for an element that is genuinely overlaying the page (dialogs, the tutor chat overlay).

## Shapes

[To be resolved during implementation.] Favor a restrained, mostly-rectilinear form language with small corner radii (evoking index cards, record forms, and ledger pages) over the heavily rounded "friendly app" look - warmth here comes from type and copy tone, not from exaggerated rounding.

## Do's and Don'ts

### Do:
- **Do** name every status in words (submitted, pending sync, graded, AI tutor unavailable) - never color or an icon alone.
- **Do** keep the primary accent to one dominant use per screen.
- **Do** keep the same voice and type system across Student, Teacher, and Parent surfaces; vary density and task framing only.
- **Do** treat connectivity and sync issues as a visible, named state (per the product's offline-first requirements), never a silent failure.

### Don't:
- **Don't** use mascots, confetti, streak counters, badges, or leaderboards anywhere in the product.
- **Don't** default to the AI-cream/sand/paper-template palette or the stock display-serif list (Fraunces, Playfair Display, Cormorant, Lora, Crimson, Newsreader) without a reason specific to this project.
- **Don't** use heavy padlock iconography or warning-banner grays to signal "restricted" - the restriction should feel like a well-organized shelf, not a cell.
- **Don't** add card shadows as a default decorative treatment; depth is tonal, not dropped.
