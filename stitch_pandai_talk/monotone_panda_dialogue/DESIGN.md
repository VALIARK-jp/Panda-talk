---
name: Monotone Panda Dialogue
colors:
  surface: '#fdf8f8'
  surface-dim: '#ddd9d8'
  surface-bright: '#fdf8f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3f2'
  surface-container: '#f1edec'
  surface-container-high: '#ebe7e6'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#444748'
  inverse-surface: '#313030'
  inverse-on-surface: '#f4f0ef'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1c1b1b'
  on-primary-container: '#858383'
  inverse-primary: '#c8c6c5'
  secondary: '#5d5f5f'
  on-secondary: '#ffffff'
  secondary-container: '#dfe0e0'
  on-secondary-container: '#616363'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1a1c1c'
  on-tertiary-container: '#838484'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474646'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c6'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#454747'
  background: '#fdf8f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '800'
    lineHeight: '1.3'
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1.6'
  label-bold:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  container-padding: 20px
---

## Brand & Style

This design system is built on the intersection of **Notion-esque clarity** and **mobile-first kinetic energy**. It prioritizes a structured, information-heavy layout that remains breathable and "snappy" through generous whitespace and high-contrast interactions.

The brand personality is **Honest, Playful, and Stripped-back**. By removing the distraction of color, the focus shifts entirely to the content and the "Panda" character accents that provide emotional warmth to an otherwise clinical monotone environment. The UI should feel like a high-end physical stationery set—crisp, tactile, and intentional.

## Colors

The palette is strictly monotone to ensure that the Panda illustrations and user-generated content remain the focal point.

- **Primary Black (#111111):** Used for primary actions (selected states), headings, and heavy borders.
- **Primary White (#FFFFFF):** Used for cards, containers, and text within black elements.
- **Background (#FAFAFA):** A slightly off-white used for the global background to reduce eye strain and distinguish from white card components.
- **Border (#E5E5E5):** A subtle, thin stroke used for non-interactive structural divisions.

## Typography

The chosen typeface is **Plus Jakarta Sans**. Its geometric yet friendly curves perfectly bridge the gap between the structured "Notion" look and the modern "TikTok" mobile aesthetic.

- **Headlines:** Use heavy weights (700-800) with tight letter-spacing to create a bold, impactful presence.
- **Body:** Use a medium weight (500) for better legibility against high-contrast backgrounds.
- **Character:** Use larger font sizes for value match labels to give them "badge-like" importance.

## Layout & Spacing

The layout philosophy follows a **Fluid Grid with Safe Margins**. 

- **Breathing Room:** We utilize a "Wide Margin" approach. Mobile views should maintain a minimum of 20px side padding. 
- **Vertical Rhythm:** Components are separated by large gaps (24px or 40px) to mimic the "feed" feel of modern social apps.
- **Notion-Style Alignment:** Lists and text blocks should align strictly to a left-hand vertical axis, creating a sense of organized documentation.

## Elevation & Depth

This system avoids soft ambient shadows. Instead, it uses **Structural Depth**:

- **Flat Layers:** Depth is communicated through the transition from the `#FAFAFA` background to `#FFFFFF` cards.
- **Thin Outlines:** Use a 1px border (`#E5E5E5`) for static containers.
- **High-Contrast Borders:** Interactive elements use a 1.5px or 2px black border (`#111111`) to signify "touchability" and "selected" states.
- **Z-Index:** Content "pops" through motion and scale rather than blur-based elevation.

## Shapes

The design uses **Exaggerated Rounding** to maintain a friendly, "Panda-like" softness.

- **Cards & Containers:** 1.5rem (24px) for large profile cards and main feed items.
- **Buttons & Chips:** 1rem (16px) for a chunky, tactile feel.
- **Inputs:** 0.75rem (12px) to differentiate from action buttons.

## Components

### Buttons & Selection
- **Selected State:** Solid Black (`#111111`) background with White (`#FFFFFF`) text.
- **Unselected State:** White (`#FFFFFF`) background with Black (`#111111`) text and a 2px Black border.
- **Visual Feedback:** On press, the element should slightly shrink (scale: 0.96) to provide haptic-like feedback.

### Value Match Labels (The Panda Scale)
These labels appear on user profiles to indicate compatibility. They should be styled as bold, high-contrast chips.
- **ほぼ同じパンダ (Identical Panda):** Black background, white text. Accompanied by a twin-panda icon. Represents 90%+ match.
- **なかよしパンダ (Friendly Panda):** Thick black border, white background. Represents 60-89% match.
- **ちぐはぐパンダ (Mismatched Panda):** Thin gray border, white background. Represents 30-59% match.
- **真逆パンダ (Total Opposite Panda):** Thin gray dashed border, text in gray. Represents &lt;30% match. Indicates "Opposites attract."

### Cards
Cards use a White (`#FFFFFF`) background with a thin `#E5E5E5` border. Content inside should have a minimum of 24px internal padding.

### Panda Accents
Panda illustrations are used sparingly:
- **Empty States:** A sleepy panda.
- **Loading:** A rolling panda.
- **Success/Match:** A high-fiving panda.
Illustrations must be strictly black and white line art with solid fills.