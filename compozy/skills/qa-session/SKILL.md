---
name: qa-session
description: Use when running an interactive QA session — listen to user-reported problems, reproduce them with headless Chrome, take screenshots as evidence, and file GitHub issues
---

# QA Session

Run an interactive QA session. The user describes problems. You reproduce them with headless Chrome, capture evidence, and file GitHub issues that are durable, user-focused, and use the project's domain language.

## For Each Issue the User Raises

### 1. Listen and Lightly Clarify

Let the user describe the problem in their own words. Ask at most 2-3 short clarifying questions focused on:

- What they expected vs what actually happened
- Steps to reproduce (if not obvious)
- Whether it's consistent or intermittent
- The URL or page where the problem occurs

Do NOT over-interview. If the description is clear enough to reproduce, move on.

### 2. Explore the Codebase in the Background

While talking to the user, kick off an Agent (`subagent_type=Explore`) in the background to understand the relevant area. The goal is NOT to find a fix — it's to:

- Learn the domain language used in that area (check `UBIQUITOUS_LANGUAGE.md` if it exists)
- Understand what the feature is supposed to do
- Identify the user-facing behavior boundary

This context helps you write a better issue — but the issue itself should NOT reference specific files, line numbers, or internal implementation details.

### 3. Reproduce with Headless Chrome

**Before filing, always attempt to reproduce the issue using headless Chrome.**

#### Detect the Browser Testing Setup

Check for existing browser testing infrastructure in this order:

1. **Playwright** (preferred):
   ```bash
   # Check if Playwright is available
   npx playwright --version 2>/dev/null
   ```
   If available, use Playwright for reproduction.

2. **Puppeteer** (fallback):
   ```bash
   npx puppeteer --version 2>/dev/null
   ```

3. **If neither is installed**, ask the user:
   ```
   No headless browser tool found. Want me to install Playwright to reproduce this visually?
   ```
   If yes: `npm install -D @playwright/test && npx playwright install chromium`

#### Write a Reproduction Script

Create a temporary reproduction script that:
- Launches headless Chromium
- Navigates to the relevant page
- Performs the user's described steps
- Takes screenshots at each key step
- Captures console errors and network failures
- Records the final state

```typescript
// Example reproduction script pattern (Playwright)
import { chromium } from 'playwright';

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

// Navigate
await page.goto('http://localhost:<port>/<path>');

// Capture initial state
await page.screenshot({ path: 'evidence/01-initial-state.png', fullPage: true });

// Perform reproduction steps
await page.click('<selector>');
await page.waitForTimeout(1000);
await page.screenshot({ path: 'evidence/02-after-action.png', fullPage: true });

// Capture console errors
page.on('console', msg => {
  if (msg.type() === 'error') console.log('CONSOLE ERROR:', msg.text());
});

// Capture network failures
page.on('requestfailed', req => {
  console.log('NETWORK FAIL:', req.url(), req.failure()?.errorText);
});

await browser.close();
```

**Adapt the script to the specific issue** — the above is a pattern, not a template to copy verbatim. Match selectors, URLs, and actions to what the user described.

#### Run and Analyze

```bash
# Create evidence directory
mkdir -p evidence

# Run the reproduction script
npx tsx /tmp/reproduce-issue.ts
```

Read the output carefully:
- **Reproduced**: Screenshots show the problem. Include them in the issue.
- **Not reproduced**: Screenshots show expected behavior. Note this in the issue — the problem may be environment-specific, intermittent, or require specific state.
- **Error during reproduction**: The script itself failed. Debug the script, don't file the issue yet.

#### Screenshot Management

Save screenshots with descriptive names:
```
evidence/
├── issue-login-broken-01-initial.png
├── issue-login-broken-02-after-click.png
└── issue-login-broken-03-final-state.png
```

### 4. Assess Scope: Single Issue or Breakdown?

Before filing, decide whether this is one issue or needs multiple:

**Break down when:**
- The fix spans multiple independent areas
- There are clearly separable concerns that different people could work on in parallel
- The user describes something with multiple distinct failure modes

**Keep as a single issue when:**
- It's one behavior that's wrong in one place
- The symptoms are all caused by the same root behavior

### 5. File the GitHub Issue(s)

Create issues with `gh issue create`. Do NOT ask the user to review first — just file and share URLs.

#### For a Single Issue

```bash
gh issue create --title "<concise title>" --body "$(cat <<'EOF'
## What happened

[Describe the actual behavior the user experienced, in plain language]

## What I expected

[Describe the expected behavior]

## Evidence

[If reproduced with headless Chrome, include screenshot references and console errors]

**Screenshots captured**: [list screenshot filenames or embed if the repo supports it]
**Console errors**: [any JS console errors captured during reproduction]
**Network failures**: [any failed network requests]

## Steps to reproduce

1. [Concrete, numbered steps a developer can follow]
2. [Use domain terms from the codebase, not internal module names]
3. [Include relevant inputs, flags, or configuration]

## Reproduction status

[One of:]
- **Reproduced** with headless Chrome — see screenshots above
- **Not reproduced** — attempted with headless Chrome but could not trigger the behavior. May be environment-specific or intermittent.
- **Visual-only** — requires human visual inspection; headless Chrome screenshots captured for reference

## Additional context

[Any extra observations from the user or from codebase exploration that help frame the issue — use domain language but don't cite files]
EOF
)"
```

#### For a Breakdown (Multiple Issues)

Create issues in dependency order (blockers first) so you can reference real issue numbers.

```bash
gh issue create --title "<specific sub-issue title>" --body "$(cat <<'EOF'
## Parent issue

#<parent-issue-number> or "Reported during QA session"

## What's wrong

[Describe this specific behavior problem — just this slice]

## What I expected

[Expected behavior for this specific slice]

## Evidence

[Screenshots and console errors specific to this sub-issue]

## Steps to reproduce

1. [Steps specific to THIS issue]

## Blocked by

- #<issue-number> or "None — can start immediately"

## Additional context

[Observations relevant to this slice]
EOF
)"
```

**Breakdown rules:**
- Prefer many thin issues over few thick ones — each should be independently fixable and verifiable
- Mark blocking relationships honestly
- Create issues in dependency order so you can reference real issue numbers
- Maximize parallelism — multiple agents should be able to grab different issues simultaneously

#### Rules for All Issue Bodies

- **No file paths or line numbers** — these go stale
- **Use the project's domain language** (check `UBIQUITOUS_LANGUAGE.md` if it exists)
- **Describe behaviors, not code** — "the sync service fails to apply the patch" not "applyPatch() throws on line 42"
- **Reproduction steps are mandatory** — if you can't determine them, ask the user
- **Keep it concise** — a developer should be able to read the issue in 30 seconds
- **Include reproduction status** — always state whether headless Chrome could reproduce it
- **Never mention AI, Claude, or automation** — write as a human QA engineer

### 6. Continue the Session

After filing, print all issue URLs (with blocking relationships summarized) and ask: **"Next issue, or are we done?"**

Keep going until the user says they're done. Each issue is independent — don't batch them.

## Headless Chrome Quick Reference

### Starting a Dev Server

Before reproducing, ensure the application is running:

```bash
# Check if already running
curl -s http://localhost:3000/api/health > /dev/null 2>&1 && echo "Running" || echo "Not running"

# If not running, start in background
npm run dev &
# Wait for it to be ready
npx wait-on http://localhost:3000 --timeout 30000
```

### Common Playwright Patterns

**Wait for navigation:**
```typescript
await page.goto(url, { waitUntil: 'networkidle' });
```

**Wait for specific element:**
```typescript
await page.waitForSelector('[data-testid="dashboard"]', { timeout: 10000 });
```

**Fill forms:**
```typescript
await page.fill('input[name="email"]', 'test@example.com');
await page.fill('input[name="password"]', 'password123');
await page.click('button[type="submit"]');
```

**Capture console errors:**
```typescript
const errors: string[] = [];
page.on('console', msg => {
  if (msg.type() === 'error') errors.push(msg.text());
});
```

**Check for visual regressions (element screenshot):**
```typescript
const element = await page.locator('.problematic-component');
await element.screenshot({ path: 'evidence/component-state.png' });
```

### Cleanup

Always clean up after reproduction:
```bash
# Remove temporary scripts
rm -f /tmp/reproduce-issue.ts

# Keep evidence directory — it's referenced in issues
# evidence/ stays until issues are resolved
```

## When Headless Chrome Can't Help

Some issues can't be reproduced with headless Chrome:
- **Performance issues** — "it's slow" requires profiling, not screenshots
- **Mobile-specific bugs** — headless Chrome defaults to desktop viewport (but you can set mobile viewport)
- **Authentication-dependent** — may need specific auth tokens or sessions
- **Race conditions** — may not trigger reliably in automated reproduction

For these, note in the issue that headless reproduction was attempted but the issue requires a different verification approach. Suggest the appropriate alternative (profiling tools, mobile testing, manual verification).
