const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');

(async () => {
  const outputDir = path.resolve(__dirname, '../artifacts/videos');
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

  // Start static server for real assets
  const server = spawn('python3', ['-m', 'http.server', '8091'], { cwd: path.resolve(__dirname,'..'), stdio: 'inherit' });
  await new Promise(r=>setTimeout(r,1500));

  // wait-on
  for(let i=0;i<20;i++){
    try{ await fetch('http://localhost:8091/demo/index.html'); break; }catch{ await new Promise(r=>setTimeout(r,300)); }
  }

  const browser = await chromium.launch({
    headless: false,
    args: ['--use-gl=egl','--enable-webgl','--no-sandbox','--disable-dev-shm-usage']
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    recordVideo: { dir: outputDir, size: { width: 1280, height: 720 } }
  });

  const page = await context.newPage();

  await page.goto('http://localhost:8091/demo/index.html', { waitUntil: 'networkidle' });
  // wait for assets load no 404
  await page.waitForTimeout(800);
  // 1. Start Game
  await page.click('#start-game-btn, .btn-new-game');
  await page.waitForTimeout(1000);
  await page.click('canvas');
  await page.waitForTimeout(300);

  // Scenario A: Walk
  await page.keyboard.down('KeyD');
  await page.waitForTimeout(1500);
  await page.keyboard.up('KeyD');
  await page.keyboard.down('KeyS');
  await page.waitForTimeout(1000);
  await page.keyboard.up('KeyS');
  await page.waitForTimeout(400);

  // Scenario B: Hoe
  await page.keyboard.press('Digit1');
  await page.waitForTimeout(300);
  await page.keyboard.press('Space');
  await page.waitForTimeout(800);

  // Scenario C: Water
  await page.keyboard.press('Digit2');
  await page.waitForTimeout(300);
  await page.keyboard.press('Space');
  await page.waitForTimeout(800);

  // Scenario D: Interact NPC dialog
  await page.keyboard.press('KeyE');
  await page.waitForTimeout(2500);

  // slight pan left
  await page.keyboard.down('KeyA');
  await page.waitForTimeout(800);
  await page.keyboard.up('KeyA');
  await page.waitForTimeout(500);

  await page.close();
  await context.close();
  await browser.close();
  server.kill();

  const vids = fs.readdirSync(outputDir).filter(f=>f.endsWith('.webm'));
  console.log(`✅ Video recorded successfully in: ${outputDir}`);
  console.log(vids.map(v=>` - ${path.join(outputDir,v)} (${(fs.statSync(path.join(outputDir,v)).size/1e6).toFixed(2)} MB)`).join('\n'));
  if(!vids.length) { console.error('No video found'); process.exit(1); }
})();
