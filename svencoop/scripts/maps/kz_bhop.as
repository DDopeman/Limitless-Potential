#include "HLSPClassicMode"
#include "singularity/autohop_playeruse"


void MapInit()
{
		ClassicModeMapInit();
		g_EngineFuncs.CVarSetFloat( "mp_classicmode", 1 );
		RegisterAutoBhopping();
		
}
