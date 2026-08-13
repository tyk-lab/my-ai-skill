---
name: "playwright-interactive"
description: "Cross-agent browser and Electron automation with Playwright. Use to inspect, debug, test, or visually verify local web and Electron apps; choose the browser-control tool, Playwright CLI, project test runner, or a standard Playwright script available to the current agent."
---

# Playwright Interactive

Use Playwright to inspect and verify browser or Electron behavior. Keep the workflow tool-agnostic: different agents expose different browser controls, terminals, and persistent sessions.

## Select the available execution path

1. Prefer a browser-control or Playwright tool exposed to the current agent.
2. Otherwise use the project's existing Playwright test runner or `playwright-cli`.
3. Otherwise run a short Node.js Playwright script from the target workspace when Playwright is already available there.
4. For visual-only checks without Playwright access, use the agent's browser or computer-control capability and state the limitation.

Do not require `js_repl`, `codex.emitImage`, Codex configuration, or any other agent-specific feature. Do not install dependencies or browsers unless the user has authorized the change.

## Prepare the target

- Work from the target application's workspace.
- Inspect `package.json`, existing test configuration, and project instructions before choosing commands.
- Reuse the project's normal dev-server and test commands.
- Confirm the target URL or Electron entry point before automating it.
- If a local service is needed, wait until its port responds before navigating.

When Playwright is unavailable, report the missing prerequisite and offer the least invasive setup command. Do not treat an unavailable tool as an application failure.

## Run the verification loop

1. List the requested behaviors, visible claims, important controls, and meaningful states to verify.
2. Launch or connect to the target with the selected execution path.
3. Exercise critical flows with normal user-like input: click, keyboard, touch, or equivalent supported automation APIs.
4. Verify visible outcomes as well as page state; inspection-only APIs do not replace interaction tests.
5. After a renderer-only change, reload the existing page when supported. Relaunch after Electron main-process, preload, startup, or environment changes.
6. Capture screenshots or traces using the active tool's native artifact mechanism when they help diagnose or support a result.
7. Run a short exploratory pass after scripted checks for interactive applications.

## Visual and viewport checks

- Inspect the initial viewport before scrolling.
- Check every required state, including a meaningful post-interaction state.
- Look for clipping, overflow, hidden controls, poor contrast, broken layering, unstable animations, and unreadable text.
- At the relevant minimum viewport or window size, verify that required controls and content fit without unintended clipping.
- For Electron, inspect the initially launched window before resizing it.

## Finish safely

- Close browser contexts, browser processes, and Electron processes started by the current task.
- Keep externally owned sessions running unless the user asks to stop them.
- Report the tested flows, visual checks, artifacts if any, and unverified items with their reason.

## Common failures

- Missing Playwright package or browser binary: report the exact prerequisite; install only with authorization.
- Connection refused: confirm the dev server is running and use the intended local URL.
- Stale page or Electron process: reload for renderer changes; relaunch when process ownership or startup code changed.
- Tool capability mismatch: switch to another available execution path instead of requiring a particular agent runtime.
