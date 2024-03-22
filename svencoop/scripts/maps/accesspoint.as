// Anti-Rush by Outerbeast
#include "anti_rush"

#include "hl_weapons/weapons"
#include "hl_weapons/mappings"
#include "HLSPClassicMode"
#include "point_checkpoint"

const bool blAntiRushEnable = false; // You can change this to have AntiRush mode enabled or disabled
const float flSurvivalVoteAllow = g_EngineFuncs.CVarGetFloat( "mp_survival_voteallow" );

void MapInit() 
{
	ANTI_RUSH::EntityRegister( blAntiRushEnable );
 
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 1 );
	
 	g_ItemMappings.insertAt(0, g_ClassicWeapons);
	
	RegisterPointCheckPointEntity();
 	RegisterClassicWeapons();
	
	ClassicModeMapInit();
}
