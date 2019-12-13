Scriptname fameHandler extends Quest  Conditional
;****************************
; FAME AND REPUTATION HANDLER
;****************************

; This is the main script that manages both Fame and Reputation. Scripts and quests that implement this system

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
;		Simply add {FameQuestScript Property [name] Auto} and set the property to {[ID]FameandReputationHandler}
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


Actor Property PlayerRef  Auto  
WorldSpace Property FameWorldspace  Auto
Location Property FameLocation  Auto    
Quest Property BSKFameandReputationHandler  Auto  
GlobalVariable Property pFame  Auto  
GlobalVariable Property pReputation  Auto     
GlobalVariable Property DuneRep  Auto  
GlobalVariable Property OrcrestRep  Auto   
GlobalVariable Property RiverholdRep  Auto  
GlobalVariable Property RimmenRep  Auto  
GlobalVariable Property DesertBanditRep  Auto  
GlobalVariable Property BaandariRep  Auto  
GlobalVariable Property ZhanKhajRep  Auto  
Keyword Property FameKeyword  Auto  
Keyword Property ReputationKeyword  Auto  

int Property crimeRegion Auto

;****
;ID'S
;****

; REGIONS:
; key = REPUTATION TYPE = "string id", "broadcast id"

;	DUNE = "dune", "1"
; 	ORCREST = "orcrest", "2"
;	RIVERHOLD = "riverhold", "3"
;	RIMMEN = "rimmen", "4"
; FACTIONS:
;	Ma'a-di-khaj = "maadikhaj", "5"
;	Baandari = "baandari", "6"
;	Zhan-khaj = "zhankhaj", "7"



;***********
; DEBUG WORK
;***********

; probably requires SKSE
;	Event OnInit()
;		RegisterForSingleUpdate(0.05)
;	EndEvent

;	Event OnUpdate()
		; 'x'
;		if(Input.IsKeyPressed(45))
;			Debug.Notification("Reputation: " + GetReputation())
;			Debug.Notification("Fame: " + GetFame())
		; 'v'
;		elseif(Input.IsKeyPressed(47))
;			ImproveFame(5)
;			Debug.Notification("Fame: " + GetFame())
;		endif
;		RegisterForSingleUpdate(0.05)
;	EndEvent
	
	
;******************
; GLOBAL FUNCTIONS
;******************

; these are the functions you should call in other quests and scripts to properly hook into the system.

	Function ImproveFame(int amount)
		int oldFameInt = GetFame()
		SetFame(oldFameInt + amount)
	EndFunction

	; shouldn't really be used as fame always increases
	Function DamageFame(int amount)
		int oldFameInt = GetFame()
		SetFame(oldFameInt - amount)
	EndFunction

	Function ImproveReputation(string id, int amount)
		int oldReputationInt = GetReputation(id)
		SetReputation(id, oldReputationInt + amount)
	EndFunction

	Function DamageReputation(string id, int amount)
		int oldReputationInt = GetReputation(id)
		SetReputation(id, oldReputationInt - amount)
	EndFunction

	int Function GetReputation(string id)
		if(id == "dune")
			return DuneRep.GetValueInt()
		elseif(id == "orcrest")
			return OrcrestRep.GetValueInt()
		elseif(id == "riverhold")
			return RiverholdRep.GetValueInt()
		elseif(id == "rimmen")
			return RimmenRep.GetValueInt()
		elseif(id == "maadikhaj")
			return DesertBanditRep.GetValueInt()
		elseif(id == "baandari")
			return BaandariRep.GetValueInt()
		elseif(id == "zhankhaj")
			return ZhanKhajRep.GetValueInt()
		else 
			return 0
		endif
	EndFunction

	int Function GetFame()
		return pFame.GetValueInt()
	EndFunction
	
	Function SetReputation(string id, int amount)
		if(id == "dune")
			DuneRep.SetValueInt(amount)
			BroadcastReputation(id, 1)
		elseif(id == "orcrest")
			OrcrestRep.SetValueInt(amount)
			BroadcastReputation(id, 2)
		elseif(id == "riverhold")
			RiverholdRep.SetValueInt(amount)
			BroadcastReputation(id, 3)
		elseif(id == "rimmen")
			RimmenRep.SetValueInt(amount)
			BroadcastReputation(id, 4)
		elseif(id == "maadikhaj")
			DesertBanditRep.SetValueInt(amount)
			BroadcastReputation(id, 5)
		elseif(id == "baandari")
			BaandariRep.SetValueInt(amount)
			BroadcastReputation(id, 6)
		elseif(id == "zhankhaj")
			ZhanKhajRep.SetValueInt(amount)
			BroadcastReputation(id, 7)
		endif
	EndFunction
	
	Function SetFame(int amount)
		pFame.SetValueInt(amount)
		BroadcastFame()
	EndFunction

	; these are important! If you modify the global values without calling this you risk quests that read off Fame and Reputation not firing correctly.
	; aiValue1 always stores the value being broadcast, aiValue2 stores the reputation type
	Function BroadcastReputation(string id, int intID)
		ReputationKeyword.SendStoryEvent(aiValue1 = GetReputation(id), aiValue2 = intID)
	EndFunction

	Function BroadcastFame()
		FameKeyword.SendStoryEvent(aiValue1 = GetFame())
	EndFunction

;*******************
; GENERIC LISTENERS
;*******************

; these listen out for generic events such as murder, stealing, etc. and modify reputation and fame accordingly.
; feel free to tailor these events as you like.

	Event OnStoryCrimeGold(ObjectReference akVictim, ObjectReference akCriminal, Form akFaction, int aiGoldAmount, int aiCrime)
		; DUNE
		if(crimeRegion == 1)
			; stealing
			if(aiCrime == 0)
				DamageReputation("dune", 2)
			; pickpocketing
			elseif(aiCrime == 1)
				DamageReputation("dune", 2)
			; trespassing
			elseif(aiCrime == 2)
				DamageReputation("dune", 4)
			; assault
			elseif(aiCrime == 3)
				DamageReputation("dune", 10)
			; murder
			elseif(aiCrime == 4)
				; I prefer to handle murder in the OnStoryKillActor function as it provides more detail.
			endif
		endif

		; ORCREST
		if(crimeRegion == 2)
			; stealing
			if(aiCrime == 0)
				DamageReputation("orcrest", 2)
			; pickpocketing
			elseif(aiCrime == 1)
				DamageReputation("orcrest", 2)
			; trespassing
			elseif(aiCrime == 2)
				DamageReputation("orcrest", 4)
			; assault
			elseif(aiCrime == 3)
				DamageReputation("orcrest", 10)
			; murder
			elseif(aiCrime == 4)
				; I prefer to handle murder in the OnStoryKillActor function as it provides more detail.
			endif
		endif

		; RIVERHOLD
		if(crimeRegion == 3)
			; stealing
			if(aiCrime == 0)
				DamageReputation("riverhold", 2)
			; pickpocketing
			elseif(aiCrime == 1)
				DamageReputation("riverhold", 2)
			; trespassing
			elseif(aiCrime == 2)
				DamageReputation("riverhold", 4)
			; assault
			elseif(aiCrime == 3)
				DamageReputation("riverhold", 10)
			; murder
			elseif(aiCrime == 4)
				; I prefer to handle murder in the OnStoryKillActor function as it provides more detail.
			endif
		endif

		; RIMMEN
		if(crimeRegion == 4)
			; stealing
			if(aiCrime == 0)
				DamageReputation("rimmen", 2)
			; pickpocketing
			elseif(aiCrime == 1)
				DamageReputation("rimmen", 2)
			; trespassing
			elseif(aiCrime == 2)
				DamageReputation("rimmen", 4)
			; assault
			elseif(aiCrime == 3)
				DamageReputation("rimmen", 10)
			; murder
			elseif(aiCrime == 4)
				; I prefer to handle murder in the OnStoryKillActor function as it provides more detail.
			endif
		endif

		BSKFameandReputationHandler.SetStage(0)
		crimeRegion = 0
	EndEvent

	Event OnStoryKillActor(ObjectReference akVictim, ObjectReference akKiller, Location akLocation, int aiCrimeStatus, int aiRelationshipRank)
		
		; checks to see if it's a crime (0: victim doesn't have a crime faction, 1: crime hasn't been reported, 2: crime has been reported)
		if(aiCrimeStatus == 2) ; change to (aiCrimeStatus != 0) for Karma system

			; DUNE
			if(crimeRegion == 1)
				; killed Lover
				if(aiRelationshipRank == 4)
					DamageReputation("dune", 35)
				; killed Ally
				elseif(aiRelationshipRank == 3)
					DamageReputation("dune", 30)
				; killed Confidant
				elseif(aiRelationshipRank == 2)
					DamageReputation("dune", 25)
				; killed Friend
				elseif(aiRelationshipRank == 1)
					DamageReputation("dune", 20)
				; killed Acquaintance
				elseif(aiRelationshipRank == 0)
					DamageReputation("dune", 15)
				; killed Rival
				elseif(aiRelationshipRank == -1)
					DamageReputation("dune", 10)
				; killed Foe
				elseif(aiRelationshipRank == -2)
					DamageReputation("dune", 8)
				; killed Enemy (this doesn't mean an actual hostile enemy, just an NPC who's relationship with the player is as an enemy)
				elseif(aiRelationshipRank == -3)
					DamageReputation("dune", 6)
				; killed Archnemesis
				elseif(aiRelationshipRank == -4)
					DamageReputation("dune", 5)
				else
					DamageReputation("dune", 15)
				endif
			endif

			; ORCREST
			if(crimeRegion == 2)
				; killed Lover
				if(aiRelationshipRank == 4)
					DamageReputation("orcrest", 35)
				; killed Ally
				elseif(aiRelationshipRank == 3)
					DamageReputation("orcrest", 30)
				; killed Confidant
				elseif(aiRelationshipRank == 2)
					DamageReputation("orcrest", 25)
				; killed Friend
				elseif(aiRelationshipRank == 1)
					DamageReputation("orcrest", 20)
				; killed Acquaintance
				elseif(aiRelationshipRank == 0)
					DamageReputation("orcrest", 15)
				; killed Rival
				elseif(aiRelationshipRank == -1)
					DamageReputation("orcrest", 10)
				; killed Foe
				elseif(aiRelationshipRank == -2)
					DamageReputation("orcrest", 8)
				; killed Enemy (this doesn't mean an actual hostile enemy, just an NPC who's relationship with the player is as an enemy)
				elseif(aiRelationshipRank == -3)
					DamageReputation("orcrest", 6)
				; killed Archnemesis
				elseif(aiRelationshipRank == -4)
					DamageReputation("orcrest", 5)
				else
					DamageReputation("orcrest", 15)
				endif
			endif

			; RIVERHOLD
			if(crimeRegion == 3)
				; killed Lover
				if(aiRelationshipRank == 4)
					DamageReputation("riverhold", 35)
				; killed Ally
				elseif(aiRelationshipRank == 3)
					DamageReputation("riverhold", 30)
				; killed Confidant
				elseif(aiRelationshipRank == 2)
					DamageReputation("riverhold", 25)
				; killed Friend
				elseif(aiRelationshipRank == 1)
					DamageReputation("riverhold", 20)
				; killed Acquaintance
				elseif(aiRelationshipRank == 0)
					DamageReputation("riverhold", 15)
				; killed Rival
				elseif(aiRelationshipRank == -1)
					DamageReputation("riverhold", 10)
				; killed Foe
				elseif(aiRelationshipRank == -2)
					DamageReputation("riverhold", 8)
				; killed Enemy (this doesn't mean an actual hostile enemy, just an NPC who's relationship with the player is as an enemy)
				elseif(aiRelationshipRank == -3)
					DamageReputation("riverhold", 6)
				; killed Archnemesis
				elseif(aiRelationshipRank == -4)
					DamageReputation("riverhold", 5)
				else
					DamageReputation("riverhold", 15)
				endif
			endif

			; RIMMEN
			if(crimeRegion == 4)
				; killed Lover
				if(aiRelationshipRank == 4)
					DamageReputation("rimmen", 35)
				; killed Ally
				elseif(aiRelationshipRank == 3)
					DamageReputation("rimmen", 30)
				; killed Confidant
				elseif(aiRelationshipRank == 2)
					DamageReputation("rimmen", 25)
				; killed Friend
				elseif(aiRelationshipRank == 1)
					DamageReputation("rimmen", 20)
				; killed Acquaintance
				elseif(aiRelationshipRank == 0)
					DamageReputation("rimmen", 15)
				; killed Rival
				elseif(aiRelationshipRank == -1)
					DamageReputation("rimmen", 10)
				; killed Foe
				elseif(aiRelationshipRank == -2)
					DamageReputation("rimmen", 8)
				; killed Enemy (this doesn't mean an actual hostile enemy, just an NPC who's relationship with the player is as an enemy)
				elseif(aiRelationshipRank == -3)
					DamageReputation("rimmen", 6)
				; killed Archnemesis
				elseif(aiRelationshipRank == -4)
					DamageReputation("rimmen", 5)
				else
					DamageReputation("rimmen", 15)
				endif
			endif

			BSKFameandReputationHandler.SetStage(0)
			crimeRegion = 0
		endif

		; adding fame for killing enemies that are at least 5 levels higher than the player
		if(aiCrimeStatus == 0)

			Actor actorVictim = akVictim as actor
			Actor actorKiller = akKiller as actor

			if(actorVictim.GetLevel() > actorKiller.GetLevel() + 5)
				; the amount of fame added is scaled to the amount of levels higher the enemy is
				ImproveFame(((actorVictim.GetLevel() / actorKiller.GetLevel()) * 10) as int)
			endif
		endif
	EndEvent




