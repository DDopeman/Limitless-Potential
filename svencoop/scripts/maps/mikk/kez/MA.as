#include "../cs16/BulletEjection"
#include "../MA/weapon_as50g"
#include "../MA/weapon_m4a1scope"
#include "../MA/weapon_pila"
#include "../MA/weapon_m60"
#include "../MA/weapon_tar21"
#include "../MA/weapon_ethereal"
#include "../MA/weapon_skull1"
#include "../MA/weapon_skull5"

void MapInit()
{
	RegisterAS();
	RegisterM4();
	RegisterWeapon_PILA();
	RegisterWeapon_M60();
	RegisterTAR();
	RegisterWeapon_ET();
	RegisterWeapon_SK1();
	RegisterSK5();
}