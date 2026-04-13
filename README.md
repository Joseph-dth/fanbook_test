# One Pager Website

Static landing page project. There is no build step.

## Main Entry

- Primary page: `src/index.html`
- Assets: `src/images/`
- Other experimental pages: `src/claude.html`, `src/antigravity.html`

## Local Preview

From the repo root:

```bash
python3 -m http.server 8000
```

Then open:

```text
http://127.0.0.1:8000/src/index.html
```

## Current Page Structure

`src/index.html` currently includes:

- Sticky top nav with hamburger drawer
- Video hero with YouTube background
- Second intro hero with 樊登 portrait
- Three feature cards
- Comparison section for `樊登說書` vs `免費 Podcast`
- Domain showcase cards
- Subscription note section
- Email giveaway modal

## Important Implementation Notes

- The page is plain HTML/CSS/JS in a single file.
- The email giveaway modal is front-end only for now.
- Modal trigger:
  - Opens after `15s`, or
  - Opens if the `親子家庭` domain card stays in view for `2s`
- Modal persistence is currently disabled for testing:
  - `persistGiveawayDismissal = false`
- If a real email endpoint is added later, wire it into `.email-capture-form` in `src/index.html`.

## Editing Guidance

- Keep the existing warm gold / cream visual language.
- Preserve mobile behavior; most sections already have custom responsive tuning.
- The comparison section and domain cards already have subtle animation layers. Avoid adding looping or flashy motion.
