
#include "point_checkpoint"

void MapInit()
{	
	// Map support is enabled here by default.
	// So you don't have to add "mp_survival_supported 1" to the map config
	g_SurvivalMode.EnableMapSupport();
}

void ActivateSurvival( CBaseEntity@ pActivator, CBaseEntity@ pCaller,
	USE_TYPE useType, float flValue )
{
	g_SurvivalMode.Activate();
}

void DisableSurvival( CBaseEntity@ pActivator, CBaseEntity@ pCaller, 
	USE_TYPE useType, float flValue )
{
    g_SurvivalMode.Disable();
}