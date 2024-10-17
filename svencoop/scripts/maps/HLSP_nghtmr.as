#include "point_checkpoint"
#include "hlsp/trigger_suitcheck"
#include "HLSPClassicMode"
#include "cubemath/trigger_once_mp"
#include "cubemath/trigger_mediaplayer"
#include "hl_weapons_nghtmr/mappings"
#include "hl_weapons_nghtmr/weapons"

void MapInit()
{
 	g_ItemMappings.insertAt(0, g_ClassicWeapons);
	
	RegisterPointCheckPointEntity();
	RegisterTriggerSuitcheckEntity();
	RegisterTriggerOnceMpEntity();
	RegisterTriggerMediaPlayerEntity();
 	RegisterClassicWeapons();
	
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 1 );
	
	ClassicModeMapInit();
}