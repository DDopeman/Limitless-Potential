#include "replace_weapon_sprites"
#include "point_checkpoint"
#include "game_hudsprite"
#include "../HLSPClassicMode"// Stock script, no need to put it in the mappack

bool ShouldRestartBlackOps(const string& in szMapName){return szMapName != "ops_intro";}

void MapInit()
{
	REPLACE_WEAPON_SPRITES::SetReplacements( "blackops", "640hud1;640hud2;640hud3;640hud4;640hud5;640hud6;640hud7;crosshairs", "weapon_crowbar;weapon_9mmhandgun;weapon_357;weapon_9mmAR;weapon_m16;weapon_shotgun;weapon_crossbow;weapon_rpg;weapon_handgrenade" );
	POKECHECKPOINT::RegisterPointCheckPointEntity();
	RegisterGameHudSpriteEntity();
	// Global CVars
	g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 0 );
	ClassicModeMapInit();
	if( !ShouldRestartBlackOps( g_Engine.mapname ) ) { g_ClassicMode.SetShouldRestartOnChange( false ); }
}

