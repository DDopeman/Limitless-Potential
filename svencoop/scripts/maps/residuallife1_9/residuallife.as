#include "../kmkz/func_savestate"
#include "../kmkz/func_loadstate"
#include "../kmkz/env_model_coop"
#include "../kmkz/trigger_changesky2"
#include "../kmkz/utils"

#include "../point_checkpoint"
#include "../HLSPClassicMode"
#include "../hl_weapons/weapons"
#include "../hl_weapons/mappings"
#include "../point_checkpoint"


void LoadSettings() 
{
	// Language settings. Change to LANGUAGE_ENGLISH For english language.
	
	iLanguage = LANGUAGE_ENGLISH; //LANGUAGE_ENGLISH or LANGUAGE_SPANISH
	
	// Change level sprite settings. Disabled by default.

	ChangeLevelSpriteAllow =false;
	
	// func_savestate settings
	
	SaveAllowed =			true;
	SaveVoteAlowed = 		true;	// "false" value allows to directly save at the slot chosen|| "true" value calls a vote to chose if you all want to save in that slot or not.
	SaveVotePercentage =	70; 	// chose a value between 0 and 100 as percentage to pass the vote.
	SaveVoteTime =			2;
	// func_loadstate settings
	
	LoadAllowed =			true;
	LoadVoteAlowed =		true; 	// "false" value allows to directly load the map from the slot chosen|| "true"  calls a vote to chose if you all want to load map from that slot or not.
	LoadVotePercentage =	70; 	// chose a value between 0 and 100 as percentage to pass the vote.
	LoadVoteTime =			2;
	
	
	//---------------------------------------------------------------------------//
	
	if (ChangeLevelSpriteAllow == false){g_EntityFuncs.FireTargets("cl_sprite", null, null, USE_OFF, 0.0f, 5.0f);}	
}

void MapInit()
{
	RegisterFuncSavestate();
	RegisterFuncLoadstate();
	RegisterFuncGlobal();
	RegisterEnvModelCoop();
	RegisterGameSpriteText();
	RegisterGameSpriteTextButton();
	g_CustomEntityFuncs.RegisterCustomEntity( "CChangeSky", "trigger_changesky2" );
	LoadSettings();
	
	g_ItemMappings.insertAt(0, g_ClassicWeapons);
	
	RegisterPointCheckPointEntity();
 	RegisterClassicWeapons();
	
	ClassicModeMapInit();
}