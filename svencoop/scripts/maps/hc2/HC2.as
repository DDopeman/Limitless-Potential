#include "gaftherman/point_checkpoint"
#include "../HLSPClassicMode"
#include "anti_rush"

const bool blAntiRushEnabled = false; // You can change this to have AntiRush mode enabled or disabled

void MapInit()
{
	RegisterPointCheckPointEntity();
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 1 );
	ANTI_RUSH::EntityRegister( blAntiRushEnabled );
	ClassicModeMapInit();
}
