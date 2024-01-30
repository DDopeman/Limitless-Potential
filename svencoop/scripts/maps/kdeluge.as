#include "LimitlessPotential/point_checkpoint"


void MapInit()
{

	RegisterPointCheckPointEntity();
	g_EngineFuncs.CVarSetFloat( "mp_classicmode", 0 );
	g_ClassicMode.SetEnabled( false );
	
}

