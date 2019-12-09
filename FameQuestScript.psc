Scriptname FameQuestScript extends Quest  conditional

;****************************
; FAME AND REPUTATION HANDLER
;****************************

; This is the main script that manages both Fame and Reputation. Scripts and quests that implement this system

; FAME:
;	Fame is a measure of how well known the player is in a province. It is always positive and should not be damage, only improved.
; 	This serves as a more organic replacement for Skyrim's level-locked content that is specific to each province.

; REPUTATION:
;	Reputation is a measure of how well-regarded the player is. The more negative the player's Reputation is, the worse they're regarded and vice versa.
;	While I intended Reputation to function as a measure of how the world views the player, it can easily be tweaked to be more like a Karma system.
;	This is designed to influence NPC interactions,

; USAGE:

;	SETTING UP THE SYSTEM FOR YOUR PROVINCE:

;		Most of the configuration for your province will take place in defining the properties for this script.
;		You'll want to define all of this script's properties to forms that are specific to your province.
;		As a general rule, rename the BSK part of all of this .esp's forms to your province ID
;		Here's a list of the things you'll need to change:
;			Properties:
;			 - FameWorldspace = your province's worldspace
;			 - FameLocation = your province's master location
;			 - BSKFameandHandler = [ID]FameandReputationHandler (the renamed version of this quest)
;			 - pFame = [ID]Fame
;			 - pReputation = [ID]Reputation
;			 - FrameKeyword = [ID]FrameChange
;			 - ReputationKeyword = [ID]ReputationChange
;			 -
;			Misc.
;			 - BSKReputationMonitor = [ID]ReputationMonitor (found in the Script Event SM Event Node)
;			 - BSKFameMonitor = [ID]FameMonitor (found in the Script Event SM Event Node)


;	GETTING VALUES IN OTHER SCRIPTS:

;		Referencing Fame and Reputation in other scripts is easy if you add this script as a property.
;		Simply add {FameQuestScript Property [name] Auto} and set the property to {[ID]FameandReputationHandler}
;		Now, you can use the global values for Fame and Reputation by using {[name].[GlobalFunction]} (e.g. fameHandler.GetFame())

;		I'd recommend that you always use the functions from this script rather than modifying the global values directly.
;		This is because the functions in this script are set up so that they broadcast changes to either value to the Story Manager
;		If you don't broadcast the change, quests that depend on certain values of Fame and Reputation won't fire correctly.

;	FIRING QUESTS FROM FAME AND REPUTATION:

;		If you want quests to start when a certain Fame/Reputation value has been reached you'll need to use the Story Manager.
;		Simply add your quest to the [ID]ReputationHandler/[ID]FameMonitor in the Script Event SM Event Node, and add a conditiion to check the global value of Fame/Reputation.




Actor Property PlayerRef  Auto  
WorldSpace Property FameWorldspace  Auto
Location Property FameLocation  Auto    
Quest Property BSKFameandReputationHandler  Auto  
GlobalVariable Property pFame  Auto  
GlobalVariable Property pReputation  Auto  
Keyword Property FameKeyword  Auto  
Keyword Property ReputationKeyword  Auto  


;***********
; DEBUG WORK
;***********

; requires SKSE
	Event OnInit()
		RegisterForSingleUpdate(0.05)
	EndEvent

	Event OnUpdate()
		if(Input.IsKeyPressed(45))
			Debug.Notification("Reputation: " + GetReputation())
			Debug.Notification("Fame: " + GetFame())
		elseif(Input.IsKeyPressed(47))
			ImproveFame(5)
			Debug.Notification("Fame: " + GetFame())
		endif
		RegisterForSingleUpdate(0.05)
	EndEvent
	
	
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

	Function ImproveReputation(int amount)
		int oldReputationInt = GetReputation()
		SetReputation(oldReputationInt + amount)
	EndFunction

	Function DamageReputation(int amount)
		int oldReputationInt = GetReputation()
		SetReputation(oldReputationInt - amount)
	EndFunction

	int Function GetReputation()
		return pReputation.GetValueInt()
	EndFunction

	int Function GetFame()
		return pFame.GetValueInt()
	EndFunction
	
	Function SetReputation(int amount)
		pReputation.SetValueInt(amount)
		BroadcastReputation()
	EndFunction
	
	Function SetFame(int amount)
		pFame.SetValueInt(amount)
		BroadcastFame()
	EndFunction

	bool Function IsMoral()
		if(GetReputation() >= 0)
			return true
		else
			return false
		endif
	EndFunction

	; these are important! If you modify the global values without calling this you risk quests that read off Fame and Reputation not firing correctly.
	Function BroadcastReputation()
		ReputationKeyword.SendStoryEvent(aiValue1 = GetReputation())
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
		if(akCriminal == PlayerRef)
			if(akCriminal.GetWorldSpace() == FameWorldspace || akCriminal.GetCurrentLocation() == FameLocation)
				; stealing
				if(aiCrime == 0)
					DamageReputation(2)
				; pickpocketing
				elseif(aiCrime == 1)
					DamageReputation(2)
				; trespassing
				elseif(aiCrime == 2)
					DamageReputation(4)
				; assault
				elseif(aiCrime == 3)
					DamageReputation(10)
				; murder
				elseif(aiCrime == 4)
					; I prefer to handle murder in the OnStoryKillActor function as it provides more detail.
				endif
			endif
		endif
	EndEvent

	Event OnStoryKillActor(ObjectReference akVictim, ObjectReference akKiller, Location akLocation, int aiCrimeStatus, int aiRelationshipRank)
		; checks to see if it's a crime (0: victim doesn't have a crime faction, 1: crime hasn't been reported, 2: crime has been reported)
		if(akKiller == PlayerRef)
			if(akKiller.GetWorldSpace() == FameWorldspace || akKiller.GetCurrentLocation() == FameLocation)
				if(aiCrimeStatus == 2) ; change to (aiCrimeStatus != 0) for Karma system
					; killed Lover
					if(aiRelationshipRank == 4)
						DamageReputation(35)
					; killed Ally
					elseif(aiRelationshipRank == 4)
						DamageReputation(30)
					; killed Confidant
					elseif(aiRelationshipRank == 4)
						DamageReputation(25)
					; killed Friend
					elseif(aiRelationshipRank == 4)
						DamageReputation(20)
					; killed Acquaintance
					elseif(aiRelationshipRank == 4)
						DamageReputation(15)
					; killed Rival
					elseif(aiRelationshipRank == 4)
						DamageReputation(10)
					; killed Foe
					elseif(aiRelationshipRank == 4)
						DamageReputation(8)
					; killed Enemy (this doesn't mean an actual hostile enemy, just an NPC who's relationship with the player is as an enemy)
					elseif(aiRelationshipRank == 4)
						DamageReputation(6)
					; killed Archnemesis
					elseif(aiRelationshipRank == 4)
						DamageReputation(5)
					else
						DamageReputation(15)
					endif
				; adding fame for killing enemies that are at least 5 levels higher than the player
				elseif(aiCrimeStatus == 0)
					
					Actor actorVictim = akVictim as actor
					Actor actorKiller = akKiller as actor

					if(actorVictim.GetLevel() > actorKiller.GetLevel() + 5)
						; the amount of fame added is scaled to the amount of levels higher the enemy is
						ImproveFame(((actorVictim.GetLevel() / actorKiller.GetLevel()) * 10) as int)
					endif
				endif
			endif
		endif
	EndEvent

	; not currently working :(
	Event OnStoryIncreaseLevel(int aiNewLevel)
		Debug.MessageBox("Registered Level")
		ImproveFame(10)
	EndEvent







 


