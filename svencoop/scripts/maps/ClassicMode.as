#include "point_checkpoint"

bool blKaleunNoob = KezNoob();

bool KezNoob()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "point_checkpoint", "point_checkpoint" );
    g_Game.PrecacheOther( "point_checkpoint" );
    g_ClassicMode.EnableMapSupport();

    return g_CustomEntityFuncs.IsCustomEntity( "point_checkpoint" );
}