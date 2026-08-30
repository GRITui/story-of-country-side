import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'tests/e2e',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }]],
  timeout: 30_000,
  expect: { timeout: 5000 },
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  // 60 FPS lock: headed chromium with --disable-frame-rate-limit off + requestAnimationFrame check
  projects: [
    {
      name: 'chromium-headed',
      use: {
        ...devices['Desktop Chrome'],
        headless: false,
        viewport: { width: 1280, height: 720 },
        launchOptions: {
          args: ['--disable-dev-shm-usage', '--no-sandbox'],
        },
      },
    },
  ],
  webServer: { command: 'python3 -m http.server 8091', port: 8091, reuseExistingServer: true },
  // No webServer (legacy) — tests use page.setContent() mock Godot canvas per spec:
  // "mock the Godot canvas via headless simulation or via actual Godot Web export if available"
  // If a Godot HTML5 export is present at export/index.html, uncomment below to test against real canvas:
  // webServer: { command: 'python3 -m http.server 8090 --directory export', port: 8090, reuseExistingServer: true },
});
