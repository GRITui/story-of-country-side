extends RefCounted
## Heart event dialogue content — Squad Gamma (#53).
## Distinct voices per GiftPreferenceTable characterization:
## Elena florist (loves flowers, hates fish), Colton miner (loves ore, hates flowers),
## Sana rancher (loves wool/milk, hates gems), etc.
## Registered via RelationshipManager.register_heart_event_dialogue.

const DIALOGUES: Dictionary = {
	"Elena": {
		2: "Oh! You remembered I like sweet peas? You're sweeter than any bloom in my shop, you know that?",
		4: "The other day I was arranging wild flowers and kept thinking — I wish you were there to see them. You make colors feel brighter.",
		6: "Sometimes I catch myself saving the prettiest snow truffle just for you. Isn't that silly? You've rooted yourself right in my heart.",
		8: "Elena tucks a pressed sweet pea into your palm: 'For luck. Come back to the flower shop soon — it feels empty when you're not there.'",
		10: "Elena whispers, her hands trembling around a bouquet: 'Every flower I grow, I grow thinking of you. Will you stay by my side, through every season?'",
	},
	"Colton": {
		2: "You brought me iron ore? Huh. Most folks bring me weeds — I mean flowers. You actually pay attention... Thanks.",
		4: "Been thinking — the mines are less lonely when I know someone up top remembers my name. That's you, by the way.",
		6: "Listen, I don't say this easy, but — you feel like a good seam of copper in a dead tunnel. Rare. Worth digging toward.",
		8: "Colton wipes his hands on his coat and offers a polished stone: 'Found this deep down. Thought you should have it. Don't read too much into it... unless you want to.'",
		10: "Colton stares at his boots, then at you: 'Ain't got fancy words. But I'd share my last lantern oil with you. That's gotta mean something.'",
	},
	"Sana": {
		2: "Wool! Oh, you remembered — you know I can't stand those shiny rocks folks try to gift me. This is actually useful, thank you!",
		4: "Watching you help with the animals — you've got gentle hands. The goats trust you, and goats don't trust just anyone.",
		6: "I saved you the first fresh goat milk this morning without even thinking. Guess you've become part of my routine — my favorite part.",
		8: "Sana laughs, leaning on the fence: 'The animals like you more than they like me some days. I think they're trying to tell me something.'",
		10: "Sana takes your hand, calloused and warm: 'This ranch, this life — it's better with you in it. Will you build it with me?'",
	},
	"Marcus": {
		2: "Sturgeon? For me? You know your fish — I'm impressed. Most people bring me flowers and wonder why I look disappointed.",
		4: "Sunrise over the water's my favorite time. You should come by the dock tomorrow — we could watch it together.",
		6: "I carved you a little wooden trout. It's rough, but — like you, it reminds me why I love the water.",
	},
	"Priya": {
		2: "Cauliflower! Fresh and perfect — you really listened. The kitchen smells like home when I cook with this.",
		4: "I tested a new corn chowder recipe today and kept wishing you were here to taste it first.",
		6: "Priya sets a woven basket down: 'I packed your favorites. You make every harvest feel like a celebration.'",
	},
	"Tobias": {
		2: "A diamond? You shouldn't have — well, actually, you absolutely should have. This is exquisite.",
		4: "The snow doesn't feel so cold when I know someone warm is thinking of me. That's you, isn't it?",
		6: "Tobias places a four-leaf clover in your hand: 'I found this on a winter walk and thought of you. Luck like you is rare.'",
	},
}

## Called by RelationshipManager._ready. Registers all dialogue lines.
static func register_all(manager) -> void:
	for npc_name in DIALOGUES.keys():
		var by_level: Dictionary = DIALOGUES[npc_name]
		for heart_level in by_level.keys():
			var text: String = by_level[heart_level]
			manager.register_heart_event_dialogue(npc_name, heart_level, text)
