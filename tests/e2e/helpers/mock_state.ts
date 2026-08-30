/**
 * Deterministic JS mirror of Godot autoloads for headed E2E.
 * Mirrors: scripts/autoload/farm_plot_manager.gd SoilState,
 *          scripts/autoload/time_manager.gd,
 *          scripts/autoload/shipping_bin_manager.gd,
 *          scripts/autoload/stamina_manager.gd,
 *          scripts/world/player_avatar.gd (FEET 12x8, move, anim),
 *          Y-sort (sort by footY) — PO-16BIT-QA-5.
 * Keep in sync with GDScript; tests assert same transitions.
 * NPC Localization — canonical EN-JP roster (Issue #160)
 */
export const NPC_CANONICAL = ['Toby','Hanna','Cliff','Nina','Cid','Kai','Leo'] as const;
export const NPC_KATAKANA: Record<string,string> = { Toby:'トビー', Hanna:'ハンナ', Cliff:'クリフ', Nina:'ニーナ', Cid:'シド', Kai:'カイ', Leo:'レオ' };
export const NPC_NAME_MIGRATION: Record<string,string> = {
  'Elder Taro':'Toby','OldMan':'Toby','Hanako':'Hanna','Shopkeeper':'Hanna','Blacksmith':'Cliff','ForgeNPC':'Cliff','Takeshi':'Cliff',
  'Barkeeper':'Nina','TeaNPC':'Nina','Carpenter':'Cid','Fisherman':'Kai','Boy1':'Leo','RivalNPC':'Leo',
};
export function canonicalNPC(name:string){ return NPC_NAME_MIGRATION[name] ?? name; }
export enum SoilState {
  DRY_GRASS = 0,
  TILLED_DRY = 1,
  TILLED_WATERED = 2,
  PLANTED = 3,
  HARVESTABLE = 4,
  WITHERED = 5,
  BLOCKED_ROCK = 6,
  BLOCKED_WOOD = 7,
}
export const SOIL_STATE_NAMES: Record<SoilState, string> = {
  [SoilState.DRY_GRASS]: 'dry_grass',
  [SoilState.TILLED_DRY]: 'tilled_dry',
  [SoilState.TILLED_WATERED]: 'tilled_watered',
  [SoilState.PLANTED]: 'planted',
  [SoilState.HARVESTABLE]: 'harvestable',
  [SoilState.WITHERED]: 'withered',
  [SoilState.BLOCKED_ROCK]: 'blocked_rock',
  [SoilState.BLOCKED_WOOD]: 'blocked_wood',
};

export type CropDef = { crop_id: string; valid_seasons: string[]; days_to_grow: number; regrowable: boolean; regrow_days: number; base_sell_price: number; seed_price: number };
export const CROPS: Record<string, CropDef> = {
  turnip:     { crop_id: 'turnip', valid_seasons: ['Spring','Fall'], days_to_grow: 4, regrowable: false, regrow_days: 0, base_sell_price: 40, seed_price: 10 },
  radish:     { crop_id: 'radish', valid_seasons: ['Spring','Summer'], days_to_grow: 5, regrowable: false, regrow_days: 0, base_sell_price: 55, seed_price: 14 },
  eggplant:   { crop_id: 'eggplant', valid_seasons: ['Summer','Fall'], days_to_grow: 7, regrowable: false, regrow_days: 0, base_sell_price: 90, seed_price: 22 },
  strawberry: { crop_id: 'strawberry', valid_seasons: ['Spring','Summer'], days_to_grow: 6, regrowable: true, regrow_days: 3, base_sell_price: 30, seed_price: 20 },
  rice:    { crop_id: 'rice', valid_seasons: ['Spring'], days_to_grow: 4, regrowable: false, regrow_days: 0, base_sell_price: 35, seed_price: 12 },
};

export type TileMeta = { soilState: string; cropType: string; growthStage: number; daysWatered: number; daysWithoutWater: number; soil_state: SoilState };

type Plot = {
  crop_id: string; days_grown: number; watered_today: boolean; harvest_ready: boolean;
  is_regrowing: boolean; soil_state: SoilState; days_watered: number; days_without_water: number; blocked_type: string;
};

export class FarmPlotManagerMock {
  private plots = new Map<string, Plot>();
  private inventory = new Map<string, number>();
  season = 'Spring';
  gold = 500;
  private shipments = new Map<string, { qty: number; price: number }>();

  key(p: {x:number,y:number}) { return `${p.x},${p.y}`; }
  getPlot(pos: {x:number,y:number}): Plot|undefined { return this.plots.get(this.key(pos)); }
  getSoilState(pos: {x:number,y:number}): SoilState { return this.getPlot(pos)?.soil_state ?? SoilState.DRY_GRASS; }
  getSoilStateName(pos: {x:number,y:number}): string { return SOIL_STATE_NAMES[this.getSoilState(pos)]; }
  getTileMetadata(pos: {x:number,y:number}): TileMeta {
    const pl = this.getPlot(pos);
    if (!pl) return { soilState: 'dry_grass', cropType:'', growthStage:0, daysWatered:0, daysWithoutWater:0, soil_state: SoilState.DRY_GRASS };
    return { soilState: SOIL_STATE_NAMES[pl.soil_state], cropType: pl.crop_id, growthStage: pl.days_grown, daysWatered: pl.days_watered, daysWithoutWater: pl.days_without_water, soil_state: pl.soil_state };
  }
  // inventory helpers
  addItem(id:string, qty:number){ this.inventory.set(id, (this.inventory.get(id)||0)+qty); }
  hasItem(id:string, qty=1){ return (this.inventory.get(id)||0) >= qty; }
  removeItem(id:string, qty:number):boolean{ const cur=this.inventory.get(id)||0; if(cur<qty) return false; const nxt=cur-qty; if(nxt===0) this.inventory.delete(id); else this.inventory.set(id,nxt); return true; }
  getCount(id:string){ return this.inventory.get(id)||0; }

  till(pos:{x:number,y:number}):boolean{
    const pl=this.getPlot(pos);
    if(pl){ if(pl.soil_state===SoilState.BLOCKED_ROCK||pl.soil_state===SoilState.BLOCKED_WOOD) return false; if(pl.crop_id) return false; if(pl.soil_state!==SoilState.DRY_GRASS) return false; }
    const np: Plot = this.plots.get(this.key(pos)) ?? { crop_id:'', days_grown:0, watered_today:false, harvest_ready:false, is_regrowing:false, soil_state: SoilState.DRY_GRASS, days_watered:0, days_without_water:0, blocked_type:'' };
    np.soil_state=SoilState.TILLED_DRY; np.days_without_water=0; this.plots.set(this.key(pos), np); return true;
  }
  setBlocked(pos:{x:number,y:number}, type:'rock'|'wood'){
    const p: Plot={ crop_id:'', days_grown:0, watered_today:false, harvest_ready:false, is_regrowing:false, soil_state: type==='rock'?SoilState.BLOCKED_ROCK:SoilState.BLOCKED_WOOD, days_watered:0, days_without_water:0, blocked_type:type };
    this.plots.set(this.key(pos), p);
  }
  canPlant(pos:{x:number,y:number}, crop_id:string):boolean{
    const def=CROPS[crop_id]; if(!def) return false; const pl=this.getPlot(pos); if(pl && pl.crop_id) return false; return def.valid_seasons.includes(this.season);
  }
  plant(pos:{x:number,y:number}, crop_id:string):boolean{
    if(!this.canPlant(pos,crop_id)) return false;
    const seedId=`${crop_id}_seed`; if(!this.hasItem(seedId)) return false; if(!this.removeItem(seedId,1)) return false;
    let pl=this.getPlot(pos); if(!pl){ pl={ crop_id:'', days_grown:0, watered_today:false, harvest_ready:false, is_regrowing:false, soil_state: SoilState.DRY_GRASS, days_watered:0, days_without_water:0, blocked_type:'' }; this.plots.set(this.key(pos), pl); }
    if(pl.soil_state===SoilState.DRY_GRASS) pl.soil_state=SoilState.TILLED_DRY;
    pl.crop_id=crop_id; pl.days_grown=0; pl.days_watered=0; pl.days_without_water=0; pl.is_regrowing=false; pl.harvest_ready=false; pl.soil_state=SoilState.PLANTED;
    return true;
  }
  water(pos:{x:number,y:number}):boolean{
    const pl=this.getPlot(pos);
    if(!pl) return false;
    if(pl.soil_state===SoilState.BLOCKED_ROCK||pl.soil_state===SoilState.BLOCKED_WOOD||pl.soil_state===SoilState.WITHERED) return false;
    if(pl.harvest_ready||pl.watered_today) return false;
    if(pl.crop_id===''){ // empty tilled soil
      if(pl.soil_state!==SoilState.TILLED_DRY) return false;
      pl.watered_today=true; pl.soil_state=SoilState.TILLED_WATERED; pl.days_without_water=0; return true;
    }
    pl.watered_today=true; if(pl.soil_state===SoilState.TILLED_DRY) pl.soil_state=SoilState.TILLED_WATERED; pl.days_without_water=0; return true;
  }
  waterArea(center:{x:number,y:number}, upgraded=false):number{
    const offs = upgraded ? [{x:-1,y:0},{x:0,y:0},{x:1,y:0}] : [{x:0,y:0}];
    let c=0; for(const o of offs){ if(this.water({x:center.x+o.x, y:center.y+o.y})) c++; } return c;
  }
  harvest(pos:{x:number,y:number}, forced_quality=''): {item_id:string, quality:string, quantity:number, crop_id:string}|null{
    const pl=this.getPlot(pos); if(!pl||!pl.crop_id||!pl.harvest_ready) return null;
    const def=CROPS[pl.crop_id]; if(!def) return null;
    const crop_id=pl.crop_id; const quality=forced_quality||'normal'; const item_id= quality==='normal'?crop_id:`${crop_id}_${quality}`;
    this.addItem(item_id,1);
    if(def.regrowable){ pl.is_regrowing=true; pl.days_grown=0; pl.watered_today=false; pl.harvest_ready=false; pl.soil_state=SoilState.PLANTED; pl.days_without_water=0; }
    else { pl.crop_id=''; pl.days_grown=0; pl.harvest_ready=false; pl.is_regrowing=false; pl.watered_today=false; pl.soil_state=SoilState.TILLED_DRY; pl.days_without_water=0; }
    return { item_id, quality, quantity:1, crop_id };
  }
  shipItem(item_id:string, qty:number, unit_price:number){
    const e=this.shipments.get(item_id)||{qty:0, price:unit_price}; e.qty+=qty; e.price=unit_price; this.shipments.set(item_id,e);
  }
  processPayout():number{
    let total=0; for(const e of this.shipments.values()) total+=e.qty*e.price; this.gold+=total; this.shipments.clear(); return total;
  }
  // Daily tick: mirrors farm_plot_manager.gd _on_day_started
  advanceDay(newSeason?:string){
    if(newSeason) this.season=newSeason;
    const withered: string[]=[];
    for(const [k, pl] of this.plots){
      if(pl.soil_state===SoilState.BLOCKED_ROCK||pl.soil_state===SoilState.BLOCKED_WOOD) continue;
      if(!pl.crop_id){ if(pl.watered_today){ pl.watered_today=false; if(pl.soil_state===SoilState.TILLED_WATERED) pl.soil_state=SoilState.TILLED_DRY; } continue; }
      const def=CROPS[pl.crop_id]; if(!def) continue;
      if(!def.valid_seasons.includes(this.season)){ withered.push(k); continue; }
      if(!pl.harvest_ready && pl.watered_today){ pl.days_grown+=1; pl.days_watered+=1; pl.days_without_water=0; const tgt= pl.is_regrowing?def.regrow_days:def.days_to_grow; if(pl.days_grown>=tgt){ pl.harvest_ready=true; pl.soil_state=SoilState.HARVESTABLE; } }
      else { if(!pl.watered_today && !pl.harvest_ready){ pl.days_without_water+=1; if(pl.days_without_water>2){ withered.push(k); continue; } } }
      if(pl.watered_today){ pl.watered_today=false; if(pl.soil_state===SoilState.TILLED_WATERED) pl.soil_state=SoilState.TILLED_DRY; }
      if(!pl.harvest_ready && pl.soil_state===SoilState.HARVESTABLE) pl.soil_state=SoilState.PLANTED;
      else if(pl.harvest_ready) pl.soil_state=SoilState.HARVESTABLE;
    }
    for(const k of withered){ const pl=this.plots.get(k)!; pl.crop_id=''; pl.days_grown=0; pl.harvest_ready=false; pl.is_regrowing=false; pl.watered_today=false; pl.soil_state=SoilState.WITHERED; pl.days_without_water=0; }
    // Shipping payout at 06:00 next morning
    this.processPayout();
  }
  reset(){ this.plots.clear(); this.inventory.clear(); this.shipments.clear(); this.gold=500; this.season='Spring'; }
}

// Stamina mock — scripts/autoload/stamina_manager.gd
export class StaminaMock {
  current=100; max=100;
  spend(amount:number):boolean{
    if(amount<=0) return true;
    if(this.current < amount){ this.current=0; return false; }
    this.current-=amount; if(this.current===0) return true; return true;
  }
  restoreFull(){ this.current=this.max; }
  getMultiplier():number{ return this.current<=0?0.5:1.0; }
  isCollapsed():boolean{ return this.current<=0; }
}

// Collision helpers — 12x8 feet per scripts/world/player_avatar.gd FEET_* and farm_scene.gd _wire_avatar_collision
export type Rect = { x:number, y:number, w:number, h:number };
export function feetRect(pos:{x:number,y:number}, feetW=12, feetH=8): Rect { return { x: pos.x - feetW/2, y: pos.y - feetH, w: feetW, h: feetH }; }
export function rectsIntersect(a:Rect,b:Rect):boolean { return !(a.x+a.w <= b.x || b.x+b.w <= a.x || a.y+a.h <= b.y || b.y+b.h <= a.y); }
export function rectEncloses(outer:Rect, inner:Rect):boolean { return inner.x>=outer.x && inner.y>=outer.y && inner.x+inner.w<=outer.x+outer.w && inner.y+inner.h<=outer.y+outer.h; }
export function wouldCollide(pos:{x:number,y:number}, bounds:Rect|null, blocked:Rect[]):boolean {
  const feet=feetRect(pos);
  if(bounds && !rectEncloses(bounds, feet)) return true;
  for(const r of blocked) if(rectsIntersect(feet,r)) return true;
  return false;
}
export function tryMove(from:{x:number,y:number}, desired:{x:number,y:number}, bounds:Rect|null, blocked:Rect[]): {x:number,y:number} {
  if(!wouldCollide(desired,bounds,blocked)) return desired;
  const tryX={x:desired.x, y:from.y}, tryY={x:from.x, y:from.y};
  const canX=!wouldCollide(tryX,bounds,blocked), canY=!wouldCollide(tryY,bounds,blocked);
  if(canX&&!canY) return tryX;
  if(canY&&!canX) return tryY;
  if(canX&&canY) return Math.abs(desired.x-from.x)>Math.abs(desired.y-from.y)?tryX:tryY;
  return from;
}
// Y-sort — sort by footY (y), stable for same Y — farm_scene.gd _dynamic_layer.y_sort_enabled
export type Entity = { id:string; y:number; x?:number };
export function ySort(entities: Entity[]): Entity[] {
  return [...entities].sort((a,b)=> a.y - b.y || a.id.localeCompare(b.id));
}
