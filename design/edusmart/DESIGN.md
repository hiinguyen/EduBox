---
name: EduSmart
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#434655'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#4648d4'
  on-secondary: '#ffffff'
  secondary-container: '#6063ee'
  on-secondary-container: '#fffbff'
  tertiary: '#006242'
  on-tertiary: '#ffffff'
  tertiary-container: '#007d55'
  on-tertiary-container: '#bdffdb'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#e1e0ff'
  secondary-fixed-dim: '#c0c1ff'
  on-secondary-fixed: '#07006c'
  on-secondary-fixed-variant: '#2f2ebe'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display:
    fontFamily: Plus Jakarta Sans
    fontSize: 3.5rem
    fontWeight: '800'
    lineHeight: 4.25rem
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 2.25rem
    fontWeight: '700'
    lineHeight: 2.75rem
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 1.75rem
    fontWeight: '700'
    lineHeight: 2.25rem
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 1.5rem
    fontWeight: '600'
    lineHeight: 2rem
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 1.25rem
    fontWeight: '600'
    lineHeight: 1.75rem
  body-lg:
    fontFamily: Inter
    fontSize: 1.125rem
    fontWeight: '400'
    lineHeight: 1.75rem
  body-md:
    fontFamily: Inter
    fontSize: 1rem
    fontWeight: '400'
    lineHeight: 1.5rem
  body-sm:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: 1.25rem
  label-md:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: '500'
    lineHeight: 1.25rem
  label-sm:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: '600'
    lineHeight: 1rem
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system establishes a dependable, encouraging, and focused digital learning environment crafted specifically for students, educators, and parents. The visual identity bridges academic clarity with welcoming warmth, pairing a structured, utilitarian layout with soft, humanized geometric touches.

The interface prioritizes cognitive clarity and psychological safety. It reduces academic anxiety through airy negative space, reassuring feedback states, and clear structural hierarchy. The overall style combines Modern Corporate reliability with refined humanist touches—eschewing visual clutter in favor of crisp white surface cards, legible typography, and decisive semantic color coding.

## Colors
The palette balances vibrant educational engagement with purposeful functional semantics:

- **Primary (`#2563EB`)**: Academic Blue anchors core actions, active navigation states, and primary instructional touchpoints. It represents institutional trust and clarity.
- **Secondary (`#6366F1`)**: Intelligent Indigo signifies synthetic intelligence, adaptive learning pathways, automated recommendations, and assistive features.
- **Tertiary (`#10B981`)**: Fresh Emerald highlights mastery, completion badges, score progression, and positive reinforcement.
- **Accent Warning (`#F59E0B`)**: Warm Amber reserves attention for pending deadlines, upcoming assignments, and schedule warnings.
- **Surfaces & Backgrounds**: The foundational canvas rests on Slate 50 (`#F8FAFC`), paired with pure `#FFFFFF` interactive cards and subtle Slate 200 (`#E2E8F0`) structural borders.

## Typography
The system employs a dual-font strategy:
- **Plus Jakarta Sans** introduces warmth, approachability, and character to headlines, section headers, and statistical callouts.
- **Inter** handles content-dense body copy, forms, instructional passages, and functional labels with neutral precision and high legibility across all screen densities.

Headings over 32px automatically step down to their designated mobile variants below the 768px breakpoint to prevent awkward text wrapping on smaller viewports.

## Layout & Spacing
The layout adheres to an 8pt spatial grid system, maintaining structural discipline across varied instructional layouts:

- **Desktop (1024px+)**: 12-column responsive layout with 24px gutters and 32px canvas margins. Maximum readable reading containers are constrained to 720px width.
- **Tablet (768px - 1023px)**: 8-column layout with 20px gutters and 24px margins. Sidebar navigation transitions to a compact collapsible rail.
- **Mobile (<768px)**: 4-column layout with 16px gutters and 16px margins. Multi-column dashboard widgets stack vertically, prioritizing imminent deadlines and immediate lesson modules.

## Elevation & Depth
Depth is established primarily via surface contrast, layered borders, and soft ambient shadows rather than heavy drop shadows.

- **Level 0 (Canvas)**: Background canvas resting at `#F8FAFC`.
- **Level 1 (Card & Module Surfaces)**: Pure `#FFFFFF` surfaces layered with a 1px border stroke of `#E2E8F0` and an ultra-subtle ambient shadow: `0 1px 3px 0 rgba(15, 23, 42, 0.05), 0 1px 2px -1px rgba(15, 23, 42, 0.05)`.
- **Level 2 (Popovers & Modals)**: Floating UI elements utilize an expanded ambient shadow: `0 10px 15px -3px rgba(15, 23, 42, 0.08), 0 4px 6px -4px rgba(15, 23, 42, 0.04)`.
- **Level 3 (Toasts & Floating Overlays)**: `0 20px 25px -5px rgba(15, 23, 42, 0.1), 0 8px 10px -6px rgba(15, 23, 42, 0.04)`.

## Shapes
A roundedness level of 2 defines the visual personality across all containers:
- Standard interactive elements (buttons, inputs, dropdown items) use `rounded` (0.5rem / 8px).
- Content cards, dashboard panels, and data widgets use `rounded-lg` (1rem / 16px).
- Modals, prominent hero modules, and role containers leverage `rounded-xl` (1.5rem / 24px).
- Metric chips, pill counters, and role-switcher toggles utilize fully rounded pill styling (`rounded-full`).

## Components

### Buttons
- **Primary**: Solid `#2563EB` fill, white text, 8px radius (`rounded`), 10px 20px padding. Hover: `#1D4ED8`. Active: scale 0.98. Focus: 2px ring with 2px offset.
- **Secondary / AI Action**: Background `#EEF2FF`, text `#4F46E5`, 1px border `#C7D2FE`. Hover: `#E0E7FF`.
- **Ghost**: Transparent fill, slate text `#475569`. Hover: background `#F1F5F9`.

### Chips & Badges
- **Status Badges**: Semi-transparent tinted backgrounds with solid saturated text (e.g., Emerald completion badge: `#ECFDF5` background, `#047857` text, `#A7F3D0` border).
- **Role Switcher Badges**: Segmented pill controls permitting rapid role context switching between Student, Teacher, and Parent views. Active segment features a crisp white card surface with level 1 shadow.

### Cards
- Constructed with `#FFFFFF` background, `rounded-lg` (16px) corners, and a 1px border in `#E2E8F0`. Padding uses 24px (`space-lg`) on desktop and 16px (`space-md`) on mobile screens. Hover states elevate with an increase in shadow depth and subtle border shift to `#CBD5E1`.

### Form Fields & Inputs
- Height: 44px for accessibility. Background `#FFFFFF`, border 1px `#CBD5E1`, text `#0F172A`. Placeholder `#94A3B8`.
- Focus state: border color `#2563EB` with a corresponding 3px `#DBEAFE` ambient focus ring.

### Lists & Progress Tracks
- List items feature alternating soft hover states (`#F8FAFC`) with integrated trailing status pills.
- Progress bars employ an 8px track height with `#E2E8F0` trough and smooth animated `#10B981` fills.