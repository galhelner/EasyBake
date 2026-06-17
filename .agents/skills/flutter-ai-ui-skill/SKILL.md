---
name: flutter-ai-ui-skill
description: Enforces professional UI/UX capabilities, Material 3 specifications, fluid micro-interactions, and pristine widget architecture for Flutter layouts in EasyBake.
aliases: [ui-skill]
---

# Flutter UI/UX Production Guardrails

Whenever you are asked to generate, modify, or review UI code for the EasyBake app, you must strictly apply these design rules:

## 1. Feature-First Architecture & Layout Separation
- Always follow the existing feature-first architecture (`lib/features/<feature_name>/`).
- Place screens in `presentation/pages/` and extract sub-components into `presentation/widgets/`.
- NEVER dump complex UI trees into a single massive `build` method. Split the UI into multiple isolated, modular `StatelessWidget` classes.
- Use `const` constructors aggressively on all immutable widgets to optimize performance.

## 2. Localization & RTL (Directionality) Support
- **ALWAYS use translations** for any user-facing strings. Instantiate `final l10n = AppLocalizations.of(context)!;` at the beginning of the `build` method and use `l10n.yourStringKey`. Do NOT hardcode strings in the UI.
- Ensure the design supports both LTR and RTL directions.
- Use directional APIs: `EdgeInsetsDirectional`, `AlignmentDirectional`, `Positioned.directional`, and `BorderDirectional` instead of absolute left/right properties.

## 3. Brand Colors & Theming
- Keep the exact same design language and colors. Do not invent new colors.
- Common primary/brand colors found in the app include:
  - Light/Background: `Color(0xFFF6FAFF)`, `Color(0xFFDDEBFF)`, `Color(0xFFF5F7FA)`
  - Primary Blues/Accents: `Color(0xFF8BB3D6)`, `Color(0xFF2E4E69)`, `Color(0xFF2F5D7E)`, `Color(0xFF315C84)`
  - Text/Dark Elements: `Color(0xFF0F3559)`, `Color(0xFF17324B)`
- Re-use existing `TextStyle` color properties or `Theme.of(context)` when appropriate.

## 4. Spacing & Responsive Polish
- Align all structural layouts to a strict 8dp dynamic grid system (`8.0`, `16.0`, `24.0`, `32.0` padding/margins).
- Use `SizedBox` for explicit spacer intervals.
- Ensure layouts leverage `LayoutBuilder` or `MediaQuery` variants if a screen requires scaling fluidly.

## 5. Visual Flourish & Component Aesthetics
- Give containers modern Material 3 silhouettes: rounded corners (`BorderRadius.circular(16.0)`) and soft, natural drop shadows (`BoxShadow` with low opacity offsets).
- Instead of raw loading indicators, implement elegant placeholder state structures (`Shimmer` loading layouts) when parsing asynchronous data streams.

## 6. Verification and Analysis Guidelines
- **NEVER** run `flutter test` to check changes or compile correctness.
- **ALWAYS** run `flutter analyze` instead to verify code correctness and check for static analysis issues.

## 7. Git & Version Control Guidelines
- **NEVER** perform git operations that modify repository state (such as `git add`, `git commit`, `git push`, or `git checkout`).