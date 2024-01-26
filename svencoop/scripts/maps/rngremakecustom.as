#include "weapon_custom/weapon_custom"
#include "point_checkpoint"

void MapInit()
{
    WeaponCustomMapInit();
	RegisterPointCheckPointEntity();
}

void MapActivate()
{
    WeaponCustomMapActivate();
}