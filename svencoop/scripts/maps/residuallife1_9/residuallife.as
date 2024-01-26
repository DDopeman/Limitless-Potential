#include "data_global"
#include "env_model_coop"
#include "../hl_weapons/weapons"
#include "../hl_weapons/mappings"
#include "../point_checkpoint"
#include "../HLSPClassicMode"

void MapInit()
{
	RegisterDataGlobal();
	RegisterEnvModelCoop();
 	RegisterClassicWeapons();
 	g_ItemMappings.insertAt(0, g_ClassicWeapons);
	RegisterPointCheckPointEntity();
	ClassicModeMapInit();
}