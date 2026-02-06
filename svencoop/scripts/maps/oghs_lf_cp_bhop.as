#include "gaftherman/point_checkpoint_oghs"
#include "HLSPClassicMode"
#include "hl_weapons/weapons"
#include "hl_weapons/mappings"
#include "singularity/autohop_playeruse"

void MapInit()
{
 	g_ItemMappings.insertAt(0, g_ClassicWeapons);
	
	RegisterPointCheckPointEntity();
 	RegisterClassicWeapons();
	RegisterAutoBhopping();

	
	ClassicModeMapInit();
}
