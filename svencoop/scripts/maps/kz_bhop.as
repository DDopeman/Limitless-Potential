#include "HLSPClassicMode"
#include "kezaeiv/kez_movement"


void MapInit()
{
		ClassicModeMapInit();
		g_EngineFuncs.CVarSetFloat( "mp_classicmode", 1 );
		RegisterAutoBhopping();
		
}
