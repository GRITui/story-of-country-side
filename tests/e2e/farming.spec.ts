import { test, expect } from '@playwright/test';
test.describe('Milestone 2.0 Farming Foundation',()=>{
  test.beforeEach(async ({page})=>{ await page.goto('/'); await page.waitForSelector('canvas',{timeout:10000}); });
  test('a) non-blank canvas on spawn', async ({page})=>{
    const ok = await page.evaluate(()=>{ const c=document.querySelector('canvas') as HTMLCanvasElement; if(!c) return false; const ctx=c.getContext('2d')!; const d=ctx.getImageData(0,0, c.width, c.height).data; return Array.from(d).some(v=>v!==0); });
    expect(ok).toBeTruthy();
  });
  test('b) KeyD moves avatar', async ({page})=>{
    const getPos = async()=> await page.evaluate(()=>(window as any).getPlayerPos?.() ?? (window as any).playerPos ?? {x:0,y:0});
    const p0 = await getPos(); await page.keyboard.down('KeyD'); await page.waitForTimeout(300); await page.keyboard.up('KeyD'); const p1 = await getPos(); expect(p1.x).toBeGreaterThan(p0.x);
  });
  test('c) Hoe dry_grass->tilled_dry', async ({page})=>{
    const before = await page.evaluate(()=> (window as any).FarmPlotManager?.get_soil_state_name?.({x:2,y:2}) ?? 'dry_grass');
    await page.evaluate(()=> (window as any).FarmPlotManager?.till?.({x:2,y:2}));
    const after = await page.evaluate(()=> (window as any).FarmPlotManager?.get_soil_state_name?.({x:2,y:2}));
    expect(before).toBe('dry_grass'); expect(after).toBe('tilled_dry');
  });
  test('d) Water tilled_dry->tilled_watered', async ({page})=>{
    await page.evaluate(()=> (window as any).FarmPlotManager?.till?.({x:3,y:3}));
    await page.evaluate(()=> (window as any).FarmPlotManager?.water?.({x:3,y:3}));
    const s = await page.evaluate(()=> (window as any).FarmPlotManager?.get_soil_state_name?.({x:3,y:3}));
    expect(s).toBe('tilled_watered');
  });
});
