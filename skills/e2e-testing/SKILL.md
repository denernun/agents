---
name: e2e-testing
description: Use when writing Playwright end-to-end tests for Angular or sites, organizing page objects, collecting traces, or diagnosing flaky CI tests.
metadata:
  origin: ECC (AgentHub adaptation)
---

# Playwright E2E tests

Inspect the existing Playwright version, config, test scripts and Angular startup
command. Extend the current suite. Page objects should model repeated user
interactions; fixtures should isolate test users/data. Prefer role/label locators
and stable test IDs. Use the project's approved test environment and accounts.

## Synchronize on observable behavior

Register response listeners before the action that sends the request. Assert the
rendered result afterward; a response alone does not prove the UI updated.
Do not wait for network idleness: polling/analytics can keep a page busy forever.

```typescript
import { expect, type Page } from '@playwright/test';

export async function searchItems(page: Page, query: string): Promise<void> {
  const responsePromise = page.waitForResponse((response) => {
    const url = new URL(response.url());
    return url.pathname === '/api/search'
      && url.searchParams.get('q') === query
      && response.request().method() === 'GET';
  });
  await page.getByRole('searchbox').fill(query);
  const response = await responsePromise;
  expect(response.ok()).toBeTruthy();
  await expect(page.getByTestId('search-summary')).toHaveText(`Results for ${query}`);
}
```

Adapt the endpoint and UI contract to the product. Use web-first assertions such
as `toHaveCount`, `toBeVisible` and `toHaveText`, rather than asserting an immediate
`count()` snapshot. Locator actions already wait for actionability.

## Configuration and evidence

Merge these fields into the existing config; retain its actual startup script,
port, browser matrix and reporters. Do not assume Angular runs `npm run dev`.

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  outputDir: './test-results',
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  use: {
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
```

Playwright Test manages traces through `use.trace`. For standalone library code,
use `context.tracing.start({ screenshots: true, snapshots: true })` and
`context.tracing.stop({ path: 'trace.zip' })`; do not mix manual tracing with a
runner-managed trace. Video artifacts use the runner's `outputDir`.

## CI and intermittent failures

Use lockfile installs and the repository's test command, install browsers for its
pinned Playwright version, and upload reports/test-results on failure. Match the
project's Node engine and CI action policy. Never upgrade dependencies merely to
copy this example.

Reproduce a flaky case with the installed runner's `--repeat-each=10`. Investigate
shared state, request races, unstable selectors and animation before adding retries.
Quarantined/skipped tests stay visible as missing coverage with an issue and owner;
do not report a skipped critical flow as passing.

Report executed command, environment, passed/failed/skipped counts, retries and
artifact paths. Do not execute real payment/fiscal issuance flows as test fixtures.

Sources: [ECC e2e-testing](https://github.com/affaan-m/ECC/tree/8321021c54d670126ce3b2969d5deb880b4b0c2a/skills/e2e-testing), [Playwright assertions](https://playwright.dev/docs/test-assertions), [tracing](https://playwright.dev/docs/api/class-tracing). MIT; see [LICENSE](LICENSE).
