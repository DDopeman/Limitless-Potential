#include "point_checkpoint"
#include "hlsp/trigger_suitcheck"
#include "HLSPClassicMode"
#include "cubemath/trigger_once_mp"
#include "cubemath/trigger_mediaplayer"
#include "hl_weapons/weapons"
#include "hl_weapons/mappings"

void MapInit()
{
 	g_ItemMappings.insertAt(0, g_ClassicWeapons);
	
	RegisterPointCheckPointEntity();
	RegisterTriggerSuitcheckEntity();
	RegisterTriggerOnceMpEntity();
	RegisterTriggerMediaPlayerEntity();
 	RegisterClassicWeapons();
	
	ClassicModeMapInit();
}
