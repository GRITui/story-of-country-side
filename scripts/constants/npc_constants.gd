class_name NPCConstants
## Canonical EN-JP roster — single source of truth (refactor data #1)

const NPC_TOBY  := "Toby"   # トビー Village Elder
const NPC_HANNA := "Hanna"  # ハンナ General Store Owner
const NPC_CLIFF := "Cliff"  # クリフ Blacksmith
const NPC_NINA  := "Nina"   # ニーナ Tavern/Tea Host
const NPC_CID   := "Cid"    # シド Carpenter
const NPC_KAI   := "Kai"    # カイ Fisher
const NPC_LEO   := "Leo"    # レオ Junior Farm Hand / Rival

const KATAKANA := {
	NPC_TOBY: "トビー",
	NPC_HANNA: "ハンナ",
	NPC_CLIFF: "クリフ",
	NPC_NINA: "ニーナ",
	NPC_CID: "シド",
	NPC_KAI: "カイ",
	NPC_LEO: "レオ",
}

const ARCHETYPE := {
	NPC_TOBY: "Village Elder / Chief",
	NPC_HANNA: "General Store Owner",
	NPC_CLIFF: "Town Blacksmith",
	NPC_NINA: "Tavern / Tea Host",
	NPC_CID: "Carpenter / Builder",
	NPC_KAI: "Lively Fisher",
	NPC_LEO: "Junior Farm Hand / Rival",
}

const ALL_CANONICAL: Array[String] = [NPC_TOBY, NPC_HANNA, NPC_CLIFF, NPC_NINA, NPC_CID, NPC_KAI, NPC_LEO]

## Backward compat migration (save files) — legacy -> canonical
const NPC_NAME_MIGRATION: Dictionary = {
	"Elder Taro": NPC_TOBY,
	"OldMan": NPC_TOBY,
	"Toby": NPC_TOBY,
	"Hanako": NPC_HANNA,
	"Shopkeeper": NPC_HANNA,
	"Hanna": NPC_HANNA,
	"Blacksmith": NPC_CLIFF,
	"ForgeNPC": NPC_CLIFF,
	"Takeshi": NPC_CLIFF,
	"Cliff": NPC_CLIFF,
	"Barkeeper": NPC_NINA,
	"TeaNPC": NPC_NINA,
	"Nina": NPC_NINA,
	"Carpenter": NPC_CID,
	"Cid": NPC_CID,
	"Fisherman": NPC_KAI,
	"Kai": NPC_KAI,
	"Boy1": NPC_LEO,
	"RivalNPC": NPC_LEO,
	"Leo": NPC_LEO,
}

static func canonical(npc_name: String) -> String:
	return NPC_NAME_MIGRATION.get(npc_name, npc_name)

static func katakana(npc_name: String) -> String:
	return KATAKANA.get(canonical(npc_name), "")

static func is_canonical(npc_name: String) -> bool:
	return ALL_CANONICAL.has(canonical(npc_name))
