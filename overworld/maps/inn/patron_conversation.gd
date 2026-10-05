@tool
## A patron in the Emberlight Inn.
##
## The design gives each of the three a plain reply and a (Read Thoughts) reply, and only the
## second one is rewarded -- which is the first thing the game teaches about being a psion. The
## timeline raises the reward as a signal; paying it out is this script's job.
extends InteractionTemplateConversation

## Crowns the Captain and the Warrior hand over.
const CROWNS_REWARD: = 5


func _on_dialogic_signal_event(argument: String) -> void:
	match argument:
		"crowns_5":
			Party.add_crowns(CROWNS_REWARD)
		"potion":
			Inventory.restore().add(Inventory.ItemTypes.POTION)
