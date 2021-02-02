Scriptname ELSSysRepHandler extends Quest
{A script containing various functions for handling reputation or fame values}
;****************************
; FAME AND REPUTATION HANDLER
;****************************

; This is the main script that manages both Fame and Reputation. Scripts and quests that implement this system will need to utilise the global functions contained within the script.

; FAME:
;	Fame is a measure of how well known the player is in a province. It is always positive and should not be damage, only improved.
; 	This serves as a more organic replacement for Skyrim's level-locked content that is specific to each province.

; REPUTATION:
;	Reputation is a measure of how well-regarded the player is. The more negative the player's Reputation is, the worse they're regarded and vice versa.
;	While I intended Reputation to function as a measure of how the world views the player, it can easily be tweaked to be more like a karma/morality system.
;	This is designed to influence NPC interactions,

; USAGE:

;	SETTING UP THE SYSTEM FOR YOUR PROVINCE:

;		Most of the configuration for your province will take place in defining the properties for this script.
;		You'll want to define all of this script's properties to forms that are specific to your province.
;		As a general rule, rename the BSK part of all of this .esp's forms to your province ID
;		Here's a list of the things you'll need to change:
;			 -
;			Misc.
;			 - BSKReputationMonitor = [ID]ReputationMonitor (found in the Script Event SM Event Node)
;			 - BSKFameMonitor = [ID]FameMonitor (found in the Script Event SM Event Node)


;	GETTING VALUES IN OTHER SCRIPTS:

;		Referencing Fame and Reputation in other scripts is easy if you add this script as a property.
;		Simply add {ELSSysRepHandler Property [name] Auto} and set the property to {[ID]FameandReputationHandler}
;		Now, you can use the global functions for Fame and Reputation by using {[name].[GlobalFunction]} (e.g. fameHandler.GetFame())

;		I'd recommend that you always use the functions from this script rather than modifying the global values directly.
;		This is because the functions in this script are set up so that they broadcast changes to either value to the Story Manager
;		If you don't broadcast the change, quests that depend on certain values of Fame and Reputation won't fire correctly.

;	FIRING QUESTS FROM FAME AND REPUTATION:

;		If you want quests to start when a certain Fame/Reputation value has been reached you'll need to use the Story Manager.
;		Simply add your quest to the [ID]ReputationHandler/[ID]FameMonitor in the Script Event SM Event Node, and add a conditiion to check the global value of Fame/Reputation.

; EXTENDING THIS FURTHER
;	While these ideas aren't implemented with the code they should be perfectly doable with a few tweaks.
;	 - Follower Fame and Reputation that changes as the adventure with the player.
;	 - Regional Fame and Reputation
;	 - Allowing the player to see their Fame and Reputation (without debug)
;	 - More generic listeners like passing speech checks and talking to certain characters
;	 - More nuanced interactions between the player and factions with faction specific reputation
;	 - More nuanced interactions between factions and other factions with those specific reputation values
;	 - Internal player "archetypes"
;	 - player appearance temporarily affects reputation or fame

GlobalVariable Property ELSRHKhajRep Auto
GlobalVariable Property ELSRHImpRep Auto
GlobalVariable Property ELSFame Auto
Keyword Property FameKeyword Auto
Keyword Property ReputationKeyword Auto

;***********
; DEBUG WORK
;***********

; probably requires SKSE
	Event OnInit()
		RegisterForSingleUpdate(0.05)
	EndEvent

	Event OnUpdate()
		; 'x'
		if(Input.IsKeyPressed(45))
			Debug.Notification("Riverhold Imperial Reputation: " + GetReputation("rhimp"))
			Debug.Notification("Fame: " + GetFame())
		; 'v'
		elseif(Input.IsKeyPressed(47))
			ModReputation("rhimp", 5)
			Debug.Notification("Riverhold Imperial Reputation: " + GetReputation("rhimp"))
		endif
		RegisterForSingleUpdate(0.05)
	EndEvent
	
;*****
;IDs
;*****

;KEY: REPUTATION TYPE = "string id", "broadcast id"
;

; CITIES:
;	Riverhold Khajiit = "rhkahj", "1"
;	Riverhold Imperials = "rhimp", "2"
	
;******************
; GLOBAL FUNCTIONS
;******************

; these are the functions you should call in other quests and scripts to properly hook into the system

	Function ModFame(int amount, bool blockMessage = false)
		int oldFame = GetFame()
		SetFame(oldFame + amount, blockMessage)
	EndFunction
	
	; fame has no limit, can never be negative
	int Function SetFame(int amount, bool blockMessage = false)
		string oldFameStatus = GetFameStatus()
	
		if(amount < 0)
			ELSFame.SetValueInt(0)
			BroadcastFame()
			if(oldFameStatus != GetFameStatus() && blockMessage == false)
				messageFame()
			endif
			return 0
		else
			ELSFame.SetValueInt(amount)
			BroadcastFame()
			if(oldFameStatus != GetFameStatus() && blockMessage == false)
				messageFame()
			endif
			return amount
		endif
		
		
	EndFunction
	
	int Function GetFame()
		return ELSFame.GetValueInt()
	EndFunction
	
	
	Function ModReputation(string id, int amount, bool blockMessage = false)
		int oldRep = GetReputation(id)
		SetReputation(id, oldRep + amount, blockMessage)
	EndFunction
	
	int Function GetReputation(string id)
		if(id == "rhkhaj" || id == "1")
			return ELSRHKhajRep.GetValueInt()
		elseif(id == "rhimp" || id == "2")
			return ELSRHImpRep.GetValueInt()
		else
			return 0
			debug.Trace("ELS: Reputation id not found", 2)
		endif
	EndFunction
	
	; reputation is clamped between -100 and 100
	int Function SetReputation(string id, int amount, bool blockMessage = false)
		string oldRepStatus = GetReputationStatus(id)
		int amountReal = amount
		
		if(amount < -100)
			amountReal = -100
		elseif(amount > 100)
			amountReal = 100
		endif
	
		if(id == "rhkhaj" || id == "1")
			ELSRHKhajRep.SetValueInt(amountReal)
		elseif(id == "rhimp" || id == "2")
			ELSRHImpRep.SetValueInt(amountReal)
		else
			debug.Trace("ELS: Reputation id not found", 2)
		endif
		
		if(oldRepStatus != GetReputationStatus(id) && blockMessage == false)
			messageReputation(id)
		endif
		
		BroadcastReputation(id)
		return amount
	EndFunction
	
	string Function GetFameStatus()
		int fame = GetFame()
		
		if(fame <= 25)
			return "vagrant"
		elseif(fame <= 50)
			return "traveller"
		elseif(fame <= 75)
			return "adventurer"
		elseif(fame <= 100)
			return "hero"
		elseif(fame <= 125)
			return "savior"
		elseif(fame <= 150)
			return "legend"
		elseif(fame <= 175)
			return "mythic"
		elseif(fame <= 200)
			return "god-like"
		endif
	EndFunction
	
	string Function GetReputationStatus(string id)
		int rep = GetReputation(id)
		
		if(rep <= -75)
			return "villified"
		elseif(rep <= -50)
			return "hated"
		elseif(rep <= -25)
			return "shunned"
		elseif(rep <= -5)
			return "dislkied"
		elseif(rep <= 5 && rep >= -4)
			return "unknown"
		elseif(rep <= 25)
			return "liked"
		elseif(rep <= 50)
			return "accepted"
		elseif(rep <= 75)
			return "loved"
		elseif(rep > 75)
			return "idolized"
		endif
	EndFunction
	
	Function messageFame()
		Debug.MessageBox("You are now a " + GetFameStatus() + " to the people of Elsweyr.")
	EndFunction
	
	Function messageReputation(string id)
		Debug.MessageBox("People have taken note of your actions...\n\n" + "You are now " + GetReputationStatus(id) + " by " + LocalizeReputationFaction(id) + ".")
	EndFunction
	
	; these are important! If you modify the global values without calling this you risk quests that read off Fame and Reputation not firing correctly.
	; aiValue1 always stores the value being broadcast, aiValue2 stores the reputation type
	Function BroadcastFame()
		FameKeyword.SendStoryEvent(aiValue1 = GetFame())
	EndFunction
	
	Function BroadcastReputation(string id)
		ReputationKeyword.SendStoryEvent(aiValue1 = GetReputation(id), aiValue2 = StringIDToInt(id))
	EndFunction
	
	string Function LocalizeReputationFaction(string id)
		if(id == "rhkhaj" || id == "1")
			return "the Khajiit of Riverhold"
		elseif(id == "rhimp" || id == "2")
			return "the Imperials of Riverhold"
		endif
	EndFunction
	
	int Function StringIDToInt(string id)
		if(id == "rhkhaj")
			return 1
		elseif(id == "rhimp")
			return 2
		else
			return 0
		endif
	EndFunction
	
	string Function IntIDToString(int id)
		if(id == 1)
			return "rhkhaj"
		elseif(id == 2)
			return "rhimp"
		else
			return "null"
		endif
	EndFunction
