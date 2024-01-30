#include "weapon_custom/weapon_custom"
#include "point_checkpoint"

void MapInit()
{
    WeaponCustomMapInit();
	RegisterPointCheckPointEntity();
	g_EngineFuncs.CVarSetFloat( "mp_classicmode", 0 );
	g_ClassicMode.SetEnabled( false );
}

void MapActivate()
{
    WeaponCustomMapActivate();
}