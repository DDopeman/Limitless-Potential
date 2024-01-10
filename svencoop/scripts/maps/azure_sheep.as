#include "point_checkpoint"
#include "hlsp/trigger_suitcheck"

#include "anti_rush"

#include "azuresheep/monster_barniel"
#include "azuresheep/monster_kate"

#include "anggaranothing/trigger_sound"
#include "beast/replace_weapon_sprites"

const bool blAntiRushEnabled = false; // You can change this to have AntiRush mode enabled or disabled

void MapInit()
{
	// Enable SC PointCheckPoint Support
	RegisterPointCheckPointEntity();
	RegisterTriggerSuitcheckEntity();
	// Enable Anti-Rush
	ANTI_RUSH::RemoveEntities = "models/cubemath/*;percent_lock*;kill_antirush*";
	ANTI_RUSH::EntityRegister( blAntiRushEnabled );
	REPLACE_WEAPON_SPRITES::SetReplacements( "azuresheep", "640hudas1;640hudas3;640hudas4;640hudas6;640hudas7", "weapon_crowbar;weapon_m16;weapon_snark" );
	// Enable this fucking catastrophe
	RegisterTriggerSoundEntity();	
	// Register these bitches
	barnielCustom::Register();
	kateCustom::Register();
	// Global CVars: Uncomment the line below if you want to disable monsterinfo on all maps
	//g_EngineFuncs.CVarSetFloat( "mp_allowmonsterinfo", 0 );
	g_EngineFuncs.CVarSetFloat( "mp_modelselection", 0 );
}
