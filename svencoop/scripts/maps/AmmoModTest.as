#include "AmmoMod"

//Test the ammo mod code
void MapInit()
{
	AmmoMod::AmmoMod@ pAmmoMod = AmmoMod::AmmoMod();
	
	@AmmoMod::g_ActiveAmmoMod = @pAmmoMod;
	
	pAmmoMod.AmmoCounts[ "9mm" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "buckshot" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "357" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "bolts" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "556" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "ARgrenades" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "rockets" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "uranium" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "Hand Grenade" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "Snarks" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "m40a1" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "Satchel Charge" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "Trip Mine" ] = 99999;
	
	pAmmoMod.AmmoCounts[ "sporeclip" ] = 99999;
	
	pAmmoMod.SetAmmoToMax = true;
}