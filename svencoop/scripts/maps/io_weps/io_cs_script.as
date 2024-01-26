#include "weapon_knife"
#include "weapon_fiveseven"
#include "weapon_p228sil"
#include "weapon_colt"
#include "weapon_dualglock"
#include "weapon_sawedoff_io"
#include "BulletEjection"
#include "../point_checkpoint"

void MapInit()
{
	RegisterWeapon_KNIFE();
	RegisterFIVESEVEN();
	RegisterCOLT();
	RegisterELITES();
	RegisterUSP();
	RegisterSAWEDOFF();
	RegisterPointCheckPointEntity();
}