#include "weapons"
#include "swap/SwapWeapons"
#include "../point_checkpoint"
#include "../HLSPClassicMode"

void MapInit()
{

	//Helper method to register all weapons
	RegisterAll();

	SwapWeapons::config ='maps/oghs_cs16/swap/SwapWeapons.json';
    SwapWeapons::MapInit();
	
	RegisterPointCheckPointEntity();
	ClassicModeMapInit();

	
}