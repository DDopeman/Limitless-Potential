#include "HLSPClassicMode"
#include "point_checkpoint"

#include "cso_edit/csobaseweapon"
#include "cso_edit/csocommon"

#include "cso_edit/weapon_balrog9"
#include "cso_edit/weapon_dualsword"

#include "cso_edit/weapon_qbarrel"
#include "cso_edit/weapon_volcano"
#include "cso_edit/weapon_mk3a1"
#include "cso_edit/weapon_m3"
#include "cso_edit/weapon_m400"

#include "cso_edit/weapon_ethereal"
#include "cso_edit/weapon_plasmagun"
#include "cso_edit/weapon_m95"
#include "cso_edit/weapon_savery"

#include "cso_edit/weapon_at4ex"

#include "cso_edit/weapon_csom79"
#include "cso_edit/weapon_m82"
#include "cso_edit/weapon_desperado"
#include "cso_edit/weapon_gunkata"


#include "cso_edit/cs_weapons"

void MapInit()
{
	ClassicModeMapInit();
	RegisterPointCheckPointEntity();
	g_EngineFuncs.CVarSetFloat( "mp_classicmode", 1 );
	
	
	
	cso_balrog9::Register();
	cso_dualsword::Register();

	cso_qbarrel::Register();
	cso_volcano::Register();
	cso_mk3a1::Register();
	cso_m3::Register();

	cso_ethereal::Register();
	cso_plasmagun::Register();
	cso_m95::Register();
	cso_savery::Register();
	cso_m400::Register();

	cso_at4ex::Register();
	cso_desperado::Register();
	cso_gunkata::Register();
	
	cso_m79::Register();
	cso_m82::Register();
	
	
	CS16_57::MAX_CARRY = 420;
	CS16_57::MAX_CLIP = 15;
	CS16_57::DAMAGE = 20;
	CS16_57::RPM = 0.09f;
	CS16_57::DEFAULT_GIVE = 30;
	CS16_57::AMMO_TYPE = "cs16_9mm";
	
	CS16_C4::TIMER = 15;
	CS16_C4::MAX_CARRY = 2;
	
	CS16_HEGRENADE::MAX_CARRY = 8;
	CS16_HEGRENADE::DAMAGE = 300;
	CS16_HEGRENADE::TIMER = 3;
	CS16_HEGRENADE::DEFAULT_GIVE = 2;
	//
	CS16_DEAGLE::MAX_CARRY = 49;
	CS16_DEAGLE::MAX_CLIP = 7;
	CS16_DEAGLE::RPM = 0.215f;
	CS16_DEAGLE::DAMAGE = 90;
	CS16_DEAGLE::DEFAULT_GIVE = 7;
	CS16_DEAGLE::AMMO_TYPE = "cs16_.338lapua";
	
	CS16_MP5::MAX_CARRY = 420;
	CS16_MP5::MAX_CLIP = 60;
	CS16_MP5::DAMAGE = 18;
	CS16_MP5::RPM = 0.075f;
	CS16_MP5::DEFAULT_GIVE = 60;
	CS16_MP5::AMMO_TYPE = "cs16_9mm";
	
	CS16_AK47::MAX_CARRY = 180;
	CS16_AK47::MAX_CLIP = 30;
	CS16_AK47::DAMAGE = 35;
	CS16_AK47::RPM = 0.092f;
	CS16_AK47::DEFAULT_GIVE = 60;
	CS16_AK47::AMMO_TYPE = "cs16_7.62nato";
	
	CS16_M4A1::MAX_CARRY = 300;
	CS16_M4A1::MAX_CLIP = 30;
	CS16_M4A1::DAMAGE2 = 30;
	CS16_M4A1::DAMAGE = 24;
	CS16_M4A1::RPM = 0.074f;
	CS16_M4A1::DEFAULT_GIVE = 60;
	CS16_M4A1::AMMO_TYPE = "cs16_5.56nato";
	
	
	RegisterAll();
}
