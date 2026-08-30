# Summer Matsuri Questline — "Village Firefly Festival" (Hotaru Matsuri)

Tone: relaxed, nostalgic, heartwarming. Omotenashi — the village hosts the
festival *together*, and the player is gently folded into that labor of
love. Set: second week of Summer, evening of Day 14. Lead NPC: **Grandma
Chiyo** (candy-shop owner, festival committee chair).

Honorific style: villagers address the player as `<name>-san`; Chiyo says
`<name>-chan` once friendship ≥ 4. Player choices are warm/neutral/playful —
never rude.

---

## 1. Quest data schema

```json
{
  "quest_id": "matsuri_lantern_prep",
  "title": "Preparing the Festival Lanterns",
  "giver": "chiyo",
  "season": "summer",
  "unlock": { "day_min": 8, "friendship_min": 1, "quest_after": null },
  "steps": [
    { "id": "gather_bamboo", "type": "collect", "item": "bamboo", "count": 6 },
    { "id": "gather_paper",  "type": "collect", "item": "washi_paper", "count": 4 },
    { "id": "gather_candle", "type": "collect", "item": "candle", "count": 4 },
    { "id": "deliver_chiyo", "type": "talk", "npc": "chiyo" }
  ],
  "required_items": ["bamboo", "washi_paper", "candle"],
  "reward_items": ["chochin_lantern", "dango", "festival_yukata_recipe"],
  "relationship_delta": { "chiyo": 2, "village": 1 }
}
```

Chain (3 quests, sequential):

| # | quest_id | title | giver | key items | rewards | rel. delta |
|---|---|---|---|---|---|---|
| 1 | `matsuri_lantern_prep` | Preparing the Festival Lanterns | chiyo | bamboo ×6, washi_paper ×4, candle ×4 | chochin_lantern, dango ×2, yukata recipe | chiyo +2 |
| 2 | `matsuri_stall_sos` | The Yakisoba Stall S.O.S. | takeshi | cabbage_daikon_slaw? → `daikon` ×2, `nasu` ×2, firewood ×4 | yakisoba recipe, 500G | takeshi +2, chiyo +1 |
| 3 | `matsuri_firefly_river` | Where the Fireflies Gather | chiyo | `river_sparkle` ×5 (river POI, dusk) | firefly terrarium (home décor), festival finale | chiyo +2, village +2 |

Quest 3 completes at the festival event (Day 14, 19:00–22:00): lanterns lit
along the river path, fireflies spawn ×3 density, stalls open. If the player
never finishes Q1, the festival still happens (smaller, no lantern row) —
**the village never punishes; it just shows what it could have been.**

## 2. Dialogue script (Q1, branching on friendship 0–10)

### First offer — friendship 0–3
```
CHIYO (gentle_smile): Oh, <name>-san! Perfect timing, dear.
  The Firefly Festival is next week, and these old hands
  are slower than the river in August.
CHIYO (chuckling): We need lanterns along the water — chochin,
  the proper kind. Could you gather bamboo, washi paper,
  and candles for me?
  ├─ [Leave it to me!]      → ACCEPT_A (+small rel bonus later)
  ├─ [I can try.]           → ACCEPT_B (neutral)
  └─ [What are they for?]   → LORE_1, then choice again
LORE_1:
CHIYO (nostalgic): When I was small, my grandmother and I lit
  them so the fireflies would have company. ...The river
  looked like a second night sky. I’d like you to see that.
```

### First offer — friendship 4–7
```
CHIYO (gentle_smile): <name>-chan! I saved you the good dango,
  the mugwort ones. Sit, sit.
CHIYO (chuckling): Now — I’ll trade you. Festival lanterns
  need making, and you have young, quick hands.
  ├─ [For dango? Anything.] → ACCEPT_A (+1 chiyo)
  └─ [Tell me what you need.] → ACCEPT_B
```

### First offer — friendship 8–10
```
CHIYO (gentle_smile): There you are, <name>-chan. The festival
  committee voted, you know — this year’s lantern row is yours.
CHIYO (nostalgic): Your grandmother once painted the plum
  blossom on every single one. ...No pressure, dear. (chuckling)
  ├─ [I’ll make her proud.] → ACCEPT_A (+1 chiyo, unlocks painted-lantern skin)
  └─ [The whole row?!]      → ACCEPT_C (playful; chiyo +0, extra barks)
```

### Mid-quest check (partial items)
```
CHIYO (concerned): Bamboo splits easier after a night in the
  river, dear. Don’t rush your fingers — the festival needs
  them too. / Still need: <remaining_list>
```

### Turn-in
```
CHIYO (surprised): Oh my — straight-grained bamboo, and not a
  torn sheet of washi in the stack!
CHIYO (chuckling): We’ll hang them from the bridge to the old
  camphor tree. Come dusk on the fourteenth, and you’ll see.
  [+ chochin_lantern, + dango ×2, + recipe, chiyo +2]
```

### Post-quest festival-night line (if Q1 done)
```
CHIYO (nostalgic): Look at that, <name>-chan. Two night skies —
  one above, one on the water. ...Thank you.
```

## 3. Seasonal barks (Summer, random idle lines)

1. "The cicadas start at five sharp. Noisier than the morning train, and twice as reliable."
2. "Ahh, hot today... The well water’s cold though — best watermelon chiller in the village."
3. "Festival stall food always tastes better eaten standing. That’s just science, dear."
4. "You can smell rain on the wind before the clouds even gather. Old knees never lie."
5. "Evenings are the best part of summer. Everything cools down, even the gossip."
6. "If the fireflies are out over the river, it means the water’s clean. They’re picky little critics."
7. "Shaved ice after fieldwork — kinako for me, matcha for you? Don’t tell the dentist."
8. "The morning-glories climbed the fence again. They know it’s festival season, I swear."
9. "A fan, a shady engawa, and nowhere to be. That’s summer luxury, <name>-san."
10. "Thunderhead’s building over the mountain. Laundry in by three, mark my words."

---

## 4. Implementation notes

- Friendship gates read `FriendshipManager.get_level("chiyo")` (0–10).
- Barks live in `content/dialogue/barks_summer.json`; one-liners, no
  branching, cooldown 90 s per villager.
- Festival-night lighting: CanvasModulate `#2A2E4A` + lantern
  PointLight2D chain (`#F0B860`) along river path; firefly emitter per
  `jp-world-palette-lighting.md` §3.2 at 3× density.
- Player yukata (`player_jp_yukata.png`) unlocks via Q1 reward recipe.
