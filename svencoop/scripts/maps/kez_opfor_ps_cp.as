#include "gaftherman/point_checkpoint_oghs"
#include "HLSPClassicMode"
#include "hl_weapons/weapons"
#include "hl_weapons/mappings"
#include "projectile_shooter_dt"

void MapInit()
{
 	g_ItemMappings.insertAt(0, g_ClassicWeapons);
	
	RegisterPointCheckPointEntity();
 	RegisterClassicWeapons();
	
    g_Module.ScriptInfo.SetAuthor("XD");
    g_Module.ScriptInfo.SetContactInfo("jajjja");

    // Initialise projectile shooter
    ProjectileShooter::Init();
	
	ClassicModeMapInit();
}
