Scriptname ELSAutopsyScript extends Quest  Conditional
{A script containing various functions which handle the new autopsy minigame}

;*****************
; AUTOPSY HANDLER
;*****************
;
; This script contains a collection of functions that centralise the new autopsy mechanic and make it easy as pie to hook into, without any scripting required.
;
; AUTOPSY:
;	This mechanic was originally designed for the Sisters of the Dead radiant quests, but its usage can be extended beyond that (more on that later).
;	The quest centres around inspecting the corpse of a dead NPC, noting down any symptoms you find, and cross referencing them with a book of diseases and their symptoms to deduce what killed the NPC.
;	By interacting with a valid NPC, a new option will appear: "Inspect Body". This will bring the player to a new message box menu, with info about the NPC and various avenues of investigation to go through.
;	The heirachy of the menu is as follows:
;																						Root
;										Inspect Exterior								 ||							Inspect Interior
; Inspect Fur (Khajiit only)  Inspect Skin   Inspect Mouth   Inspect Ears   Inspect Eyes || Inspect Heart   Inspect Lungs   Inspect Brain   Inspect Stomach   Inspect Liver

; 	Each part of the body can be either non-symptomatic, or display a choice of different symptoms. A list of all the possible messages can be found here: https://docs.google.com/spreadsheets/d/1nXZIjRC0YaeHLDjvGHFPiceIn7OJxMCqfwQMbO6OjmQ/edit#gid=0
;	This mechanic can be made to work on any NPC, but by default will only work on NPCs that are set up for it.
;
; USAGE:
;	BASIC USAGE:
;		To implement a basic autopsy-ready NPC in the world all you need are two keywords:
;			- ELSAutopsyAble: this keyword is what the autopsy perk looks for in a target in order to add the "Inspect Body".
;			- ELSAutopsy[Cause of death]: this keyword specifies what the collection of symptoms will be.
;		Once added to the NPC, the player will be able to interact with the corpse and investigate their cause of death.
;
;	ADVANCED USAGE:
;		The main function that the perk uses with the basic keyword system, HandleAutopsy, is really a step-by-step collection of functions that process the minigame.
;		Each individual function is external use ready, so you can have full customisation over this minigame without having to alter this script at all.
;		
;		FUNCTIONS:
;			- HandleAutopsy(ObjectReference akVictim, string sCauseOfDeath = "keyword")
;				This function is a wrapper for the whole process of setting up the minigame.
;				- akVictim: the ObjectReference of the corpse being inspected
;				- sCauseOfDeath (optional): the string that specifies what collection of symptoms will be used. If none specified, it'll default to trying to read off a string from the keywords of the victim using ProcessKeywords
			
;				A list of potential causes of death can be found below
;
;			- FillVictimAlias(ObjectReference akVictim)
;				This function sets the Victim alias to the specified object reference. This is primarily used for text replacement in the message box menu.
;				It also sets the bVictimKhajiit variable to true or false depending on the race of the victim. This is used by the message box menu to choose whether to display the "Inspect the fur" option or not.
			
;			- ClearAutopsyMessages()
;				This function resets all the autopsyActual variables to their default, healthy state.
;				This prevents symptoms from the last victim being carried over to the next.

;			- ProcessKeywords(Form akForm)
;				This converts the symptom keywords on the target Form into cause of death strings that can be read by HandleAutopsy.
;				E.g. an NPC with ELSAutopsyDiseaseRiverRot will supply "river rot" into the cause of death of HandleAutopsy

;			- OverrideMessage(string sMessageID, int iMessageValue = -1, Message akMessageOverride = none)
;				This function is used to provide the specific symptomatic messages attached to each cause of death.
;				- sMessageID: the message that this is replacing, e.g. "fur" or "heart"
;				- iMessageValue (optional): the index of the array for that message type that's overriding the default message, e.g. OverrideMessage("heart", 1) will replace the healthy heart message with the message that's occupying number 1 in the akaIHeart array, in this case the heart symptom for vampirism
;				- akMessageOverride (optional): the message that's overriding the default healthy message. This can be used in lieu of iMessageValue to  inject custom override messages into the minigame. More details on this can be found in the EXTENSION section

;				Note that either iMessageValue or akMessageOverride must be used. If a value for both is supplied, the function will default to akMessageOverride

;			- DisplayAutopsy()
;					Once all the other functions have run, this is used to display the actual message box menu itself.

;		EXTENSION:
;			- You can create specific causes of death for certain quests/dungeons/encounters without touching this script simply by overriding messages with specific messages rather than from the message arrays in this script.
;			- For example, perhaps a quest involved an NPC who was killed by a specific kind of poison. As it's only used in that quest, you don't want to add it to this script.
;			- In this case, I'd recommend the following steps:
;				1) add the ELSAutopsyAbleSpecial keyword to the NPC. This will add the Inspect Body option but won't call HandleAutopsy like ELSAutopsyAble.
;				2) ELSAutopsyAbleSpecial will attempt to start quests in the ELSAutopsyNode in the Script Event SM Event Node with the victim's ObjectReference as akRef1.
;				3) Add a new quest to the ELSAutopsyNode, and use the GetEventData to conditionalise it so that it only starts if akRef1 is the NPC in question.
;				4) In this new quest, use the Event OnStoryScript.
;				5) Inside the event, call FillVictimAlias, ClearAutopsyMessages and then use OverrideMessage to inject your quest specific messages into the menu.
;				6) Then use DisplayAutopsy to show the menu.

;	CAUSES OF DEATH
;		"keyword" = uses victim's keywords to supply cause of death
;		"rand" = selects a random disease as the cause of death
;		"river rot"
;		"sanguinare vampiris"

;************
; PROPERTIES
;************

Perk Property akAutopsyPerk Auto ; the perk that handles adding the "Inspect Body" activation option

; keywords to handle the LD friendly approach of creating autopsy-friendly bodies
Keyword Property akKeywordRiverRot Auto
Keyword Property akKeywordSanguinare Auto
Keyword Property akKeywordFire Auto
Keyword Property akKeywordArrow Auto
Keyword Property akKeywordAssassination Auto
Keyword Property akKeywordBlade Auto
Keyword Property akKeywordBlunt Auto
Keyword Property akKeywordIce Auto
Keyword Property akKeywordShock Auto

; these are used for the bVictimKhajiit variable
Race Property KhajiitRace Auto
Race Property KhajiitRaceVampire Auto

ReferenceAlias Property akVictimAlias Auto ; the victim that is being autopsied

; the default, non-symptomatic, messages
Message Property akRootDefault Auto
Message Property akExteriorDefault Auto
Message Property akInteriorDefault Auto
Message Property akEFurDefault Auto
Message Property akESkinDefault Auto
Message Property akEMouthDefault Auto
Message Property akEEarsDefault Auto
Message Property akEEyesDefault Auto
Message Property akIHeartDefault Auto
Message Property akILungsDefault Auto
Message Property akIBrainDefault Auto
Message Property akIStomachDefault Auto
Message Property akILiverDefault Auto

; symptomatic messages
Message Property akEMouth1 Auto
Message Property akEEyes1 Auto
Message Property akIHeart1 Auto
Message Property akEFur2 Auto
Message Property akIStomach2 Auto
Message Property akILiver2 Auto

; the lists of possible messages that can be picked from
Message[] akaRoot 
Message[] akaEFur
Message[] akaESkin
Message[] akaEMouth
Message[] akaEEars
Message[] akaEEyes
Message[] akaIHeart
Message[] akaILungs
Message[] akaIBrain
Message[] akaIStomach
Message[] akaILiver

String[] saCauseOfDeathDiseaseRand ; the collection of possible diseases that can be chosen from. Doesn't include special diseases like Sanguinare Vampiris

; the actual messages that are displayed in the tree after the processing and overriding
Message akRootActual ; 1000
Message akEFurActual ; 1110
Message akESkinActual ; 1120
Message akEMouthActual ; 1130
Message akEEarsActual ; 1140
Message akEEyesActual ; 1150
Message akIHeartActual ; 1210
Message akILungsActual ; 1220
Message akIBrainActual ; 1230
Message akIStomachActual ; 1240
Message akILiverActual ; 1250

bool bVictimKhajiit conditional ; this is used to conditionalise whether the "Inspect the fur" option will be available
int i ; used for message box heirachy logic

;******
; SETUP
;******

Event OnInit()
	Game.GetPlayer().AddPerk(akAutopsyPerk) ; adds the autopsy perk to the player which allows for the "Inspect Body" activation option
	
	; this sets up the arrays that can be used for overrides and the like. 0 is always the default, healthy option. For other IDs, use this sheet for reference: https://docs.google.com/spreadsheets/d/1nXZIjRC0YaeHLDjvGHFPiceIn7OJxMCqfwQMbO6OjmQ/edit#gid=0
	akaRoot = new Message[1]
		akaRoot[0] = akRootDefault
	akaEFur = new Message[3]
		akaEFur[0] = akEFurDefault
		akaEFur[2] = akEFur2
	akaESkin = new Message[1]
		akaESkin[0] = akESkinDefault
	akaEMouth = new Message[2]
		akaEMouth[0] = akEMouthDefault
		akaEMouth[1] = akEMouth1
	akaEEars = new Message[1]
		akaEEars[0] = akEEarsDefault
	akaEEyes = new Message[2]
		akaEEyes[0] = akEEyesDefault
		akaEEyes[1] = akEEyes1
	akaIHeart = new Message[2]
		akaIHeart[0] = akIHeartDefault
		akaIHeart[1] = akIHeart1
	akaILungs = new Message[1]
		akaILungs[0] = akILungsDefault
	akaIBrain = new Message[1]
		akaIBrain[0] = akIBrainDefault
	akaIStomach = new Message[3]
		akaIStomach[0] = akIStomachDefault
		akaIStomach[2] = akIStomach2
	akaILiver = new Message[3]
		akaILiver[0] = akILiverDefault
		akaILiver[2] = akILiver2
		
	saCauseOfDeathDiseaseRand = new String[1]
		saCauseOfDeathDiseaseRand[0] = "river rot"
EndEvent

;*****************
; GLOBAL FUNCTIONS
;*****************
Function HandleAutopsy(ObjectReference akVictim, string sCauseOfDeath = "keyword") ; this is the main function that the perk uses to set up the autopsy minigame
	FillVictimAlias(akVictim)
	ClearAutopsyMessages()
	string sCauseActual
	
	if(sCauseOfDeath == "keyword") ; by default this function processes the cause of death
		sCauseActual = ProcessKeywords(akVictim)
	elseif(sCauseOfDeath == "rand disease")
		sCauseActual = saCauseOfDeathDiseaseRand[Utility.RandomInt(0, saCauseOfDeathDiseaseRand.Length)]
	else
		sCauseActual = sCauseOfDeath
	endif
	
	if(sCauseActual == "sanguinare vampiris")
		OverrideMessage("mouth", 1)
		OverrideMessage("eyes", 1)
		OverrideMessage("heart", 1)
	elseif(sCauseActual == "river rot")
		OverrideMessage("fur", 2)
		OverrideMessage("stomach", 2)
		OverrideMessage("liver", 2)
	endif
	DisplayAutopsy()
EndFunction

Function DisplayAutopsy()
	i = akRootActual.Show()
	MessageBoxHandler("root")
	
EndFunction

Function MessageBoxHandler(string sMessageBox)
	if(sMessageBox == "root")
		if(i == 0)
			i = akExteriorDefault.Show()
			MessageBoxHandler("exterior")
		elseif(i == 1)
			i = akInteriorDefault.Show()
			MessageBoxHandler("interior")
		endif
	endif
	
		if(sMessageBox == "exterior")
			if(i == 0)
				i = akEFurActual.Show()
				MessageBoxHandler("exterior")
			elseif(i == 1)
				i = akESkinActual.Show()
				MessageBoxHandler("exterior")
			elseif(i == 2)
				i = akEMouthActual.Show()
				MessageBoxHandler("exterior")
			elseif(i == 3)
				i = akEEarsActual.Show()
				MessageBoxHandler("exterior")
			elseif(i == 4)
				i = akEEyesActual.Show()
				MessageBoxHandler("exterior")
			elseif(i == 5)
				i = akRootActual.Show()
				MessageBoxHandler("root")
			endif
		endif
	
			
		if(sMessageBox == "interior")
			if(i == 0)
				i = akIHeartActual.Show()
				MessageBoxHandler("interior")
			elseif(i == 1)
				i = akILungsActual.Show()
				MessageBoxHandler("interior")
			elseif(i == 2)
				i = akIBrainActual.Show()
				MessageBoxHandler("interior")
			elseif(i == 3)
				i = akIStomachActual.Show()
				MessageBoxHandler("interior")
			elseif(i == 4)
				i = akILiverActual.Show()
				MessageBoxHandler("interior")
			elseif(i == 5)
				i = akRootActual.Show()
				MessageBoxHandler("root")
			endif
		endif
		
EndFunction

Function FillVictimAlias(ObjectReference akVictim)
	self.Start() ; might not be necessary, but I suspect it lets the alias fill properly
	akVictimAlias.ForceRefTo(akVictim)
	Actor akVictimActor = akVictim as Actor
	If(akVictimActor.GetRace() == KhajiitRace || akVictimActor.GetRace() == KhajiitRaceVampire)
		bVictimKhajiit = true
	else
		bVictimKhajiit = false
	endif
	self.Stop()
EndFunction

Function OverrideMessage(string sMessageID, int iMessageValue = -1, Message akMessageOverride = none)
	
	if(akMessageOverride != none)
		if(sMessageID == "root")
			akRootActual = akMessageOverride
		elseif(sMessageID == "fur")
			akEFurActual = akMessageOverride
		elseif(sMessageID == "skin")
			akESkinActual = akMessageOverride
		elseif(sMessageID == "mouth")
			akEMouthActual = akMessageOverride
		elseif(sMessageID == "ears")
			akEEarsActual = akMessageOverride
		elseif(sMessageID == "eyes")
			akEEyesActual = akMessageOverride
		elseif(sMessageID == "heart")
			akIHeartActual = akMessageOverride
		elseif(sMessageID == "lungs")
			akILungsActual = akMessageOverride
		elseif(sMessageID == "brain")
			akIBrainActual = akMessageOverride
		elseif(sMessageID == "stomach")
			akIStomachActual = akMessageOverride
		elseif(sMessageID == "liver")
			akILiverActual = akMessageOverride
		endif
		return
	elseif(iMessageValue != -1)
		if(sMessageID == "root")
			akRootActual = akaRoot[iMessageValue]
		elseif(sMessageID == "fur")
			akEFurActual = akaEFur[iMessageValue]
		elseif(sMessageID == "skin")
			akESkinActual = akaESkin[iMessageValue]
		elseif(sMessageID == "mouth")
			akEMouthActual = akaEMouth[iMessageValue]
		elseif(sMessageID == "ears")
			akEEarsActual = akaEEars[iMessageValue]
		elseif(sMessageID == "eyes")
			akEEyesActual = akaEEyes[iMessageValue]
		elseif(sMessageID == "heart")
			akIHeartActual = akaIHeart[iMessageValue]
		elseif(sMessageID == "lungs")
			akILungsActual = akaILungs[iMessageValue]
		elseif(sMessageID == "brain")
			akIBrainActual = akaIBrain[iMessageValue]
		elseif(sMessageID == "stomach")
			akIStomachActual = akaIStomach[iMessageValue]
		elseif(sMessageID == "liver")
			akILiverActual = akaILiver[iMessageValue]
		endif
		return
	endif
EndFunction

Function ClearAutopsyMessages()
	akRootActual = akaRoot[0]
	akEFurActual = akaEFur[0]
	akESkinActual = akaESkin[0]
	akEMouthActual = akaEMouth[0]
	akEEarsActual = akaEEars[0]
	akEEyesActual = akaEEyes[0]
	akIHeartActual = akaIHeart[0]
	akILungsActual = akaILungs[0]
	akIBrainActual = akaIBrain[0]
	akIStomachActual = akaIStomach[0]
	akILiverActual = akaILiver[0]
EndFunction

string Function ProcessKeywords(Form akForm)
	if(akForm.HasKeyword(akKeywordSanguinare))
		return "sanguinare vampiris"
	elseif(akForm.HasKeyword(akKeywordRiverRot))
		return "river rot"
	endif
EndFunction
