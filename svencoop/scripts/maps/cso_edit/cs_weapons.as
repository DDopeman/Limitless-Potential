#include "cs_weps/weapon_csknife"
#include "cs_weps/weapon_csdeagle"
#include "cs_weps/weapon_mp5navy"
#include "cs_weps/weapon_hegrenade"
#include "cs_weps/weapon_c4"
#include "cs_weps/weapon_m4a1"
#include "cs_weps/weapon_ak47"
#include "cs_weps/weapon_fiveseven"

void RegisterAll()
{
	CS16_57::Register();
	CS16_KNIFE::Register();
	CS16_DEAGLE::Register();
	CS16_MP5::Register();
	CS16_HEGRENADE::Register();
	CS16_C4::Register();
	CS16_M4A1::Register();
	CS16_AK47::Register();
}