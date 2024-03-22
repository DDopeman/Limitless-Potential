#include "hl_weapons/weapons"
#include "hl_weapons/mappings"

#include "mikk/entities/utils"

#include "mikk/multi_language"
#include "mikk/entities/game_text_custom"

#include "gaftherman/misc/ammo_individual"

#include "mikk/entities/item_airbubble"
#include "mikk/entities/tram_ride_train"

#include "point_checkpoint"
#include "residualpoint/trigger_once_mp"
#include "residualpoint/weapon_teleporter"
#include "residualpoint/monster_zombie_hev"

// Modify code bellow for Server operator's choices. -Mikk
bool blSpawnNpcRequired = false;
/*
	true	=	Npc's for-progress-required will respawn when die.
	false	=	Npc's for-progress-required will restart the map when die.
*/

bool blIsAntiRushEnable = true;
/*
	true	=	Anti-Rush is disabled.
	false	=	Anti-Rush is enabled.
*/

bool blClassicModeChoos = true;
/*
	true	=	Enables classic mode vote button at lobby.
	false	=	Disable classic mode vote button at lobby.
*/

bool blWeWantSurvival = true;
/*
	true	=	Enables Survival-Mode.
	false	=	Disable Survival-Mode.
*/

bool blDifficultyChoose = true;
/*
	true	=	Enables Difficulty vote button at lobby.
	false	=	Disable Difficulty vote button at lobby.
*/

const string str_DiffIs = "easy";
/*
	easy		=	Easy difficulty (most normal by its server)
	medium		=	Medium difficulty (some cvars update) Health/suit max 80
	hard		=	Hard difficulty (some cvars update) Health/suit max 50
	hardcore	=	Hardcore difficulty (some cvars update) Health/suit max 1
	anything	=	same as easy. use this if using DynamicDifficulty things locked at a certain diff.
	
	if you're using DinamicDifficulty plugins monster_alien_tor will be kinda strong there.
	custom keyvalue for skippin npcs Health Updates is "$i_dyndiff_skip" -Mikk
*/

int DiffMode = 0; //Default DO NOT CHANGE HERE. this will be updated via mapping trigger_save/load. see bool blDifficultyChoose and string str_DiffIs -Mikk

bool ShouldRestartResidualPoint(const string& in szMapName){return szMapName != "rp_c00_lobby";}

void MapInit()
{
	RegisterCustomTextGame();
	MultiLanguageInit();
	RegisterHLMP5(); 
	RegisterAmmoIndividual();
	MonsterZombieHev::Register();
	RegisterSolidityZone();
	
	// For classic mode support
	g_ClassicMode.EnableMapSupport();
	RegisterClassicWeapons();
	g_ClassicMode.SetItemMappings( @g_ClassicWeapons );
	if( !ShouldRestartResidualPoint( g_Engine.mapname ) ) { g_ClassicMode.SetShouldRestartOnChange( false ); }
	if( g_ClassicMode.IsEnabled() ) { Precacheclassic(); g_Scheduler.SetInterval( "ReloadModelsClassicMode", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES ); }	// Cuz squadmakers x[
	
	// Item airbubble tank for oxygen.
	if(string(g_Engine.mapname) == "rp_c08_m3" or string(g_Engine.mapname) == "rps_sewer" ){RegisterAirbubbleCustomEntity();}
	
	// We want to check if the map supports survival before registering game_save.
	const bool IsSurvivalEnabled = g_EngineFuncs.CVarGetFloat("mp_survival_supported") == 1;
	if( IsSurvivalEnabled and blWeWantSurvival )
	{
		g_EngineFuncs.CVarSetFloat( "mp_survival_starton", 1 );
		RegisterPointCheckPointEntity();
	}
	
	// Just in case...
	g_EngineFuncs.CVarSetFloat( "mp_npckill", 2 );

	// Register antirush entity.
	if( blIsAntiRushEnable )
	{
		RegisterAntiRushEntity();
	
		g_Game.PrecacheModel( "models/cubemath/skull.mdl" );
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );
		g_Game.PrecacheGeneric( "sprites/laserbeam.spr" );
	}
}

void MapStart()
{
	if( !blIsAntiRushEnable )
		return;

	LoadFileFromAntiRush();
}

void MapActivate()
{
	// We want to customize votes by bools choices.
	if( string(g_Engine.mapname) == "rp_c00_lobby" )
	{
		CBaseEntity@ pVotes = null;
		if( !blClassicModeChoos ){
			while((@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "classic_mode_button")) !is null)
			{
				edict_t@ pEdict = pVotes.edict();
				g_EntityFuncs.DispatchKeyValue( pEdict, "target", "vote_disabled_msg" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "Please.Dont." );
			}
		}

		if( !blDifficultyChoose ){
			while((@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_button")) !is null
			or(@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_button_med")) !is null
			or(@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_button_har")) !is null
			or(@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "difficulty_buttonhardcore")) !is null){
				edict_t@ pEdict = pVotes.edict();
				
				g_EntityFuncs.DispatchKeyValue( pEdict, "target", "vote_disabled_msg" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "Please.Dont." );
			}

			while((@pVotes = g_EntityFuncs.FindEntityByTargetname(pVotes, "store_difficulty")) !is null){
				edict_t@ pEdict = pVotes.edict();
				g_EntityFuncs.DispatchKeyValue( pEdict, "$s_difficulty", "" + str_DiffIs );
			}
		}
		g_EngineFuncs.CVarSetFloat( "mp_allowmonsterinfo", 1 );
	}
	
	// We want to Respawn Required-for-progress npcs if they die instead of restart the map.
	if( blSpawnNpcRequired ){
		if(string(g_Engine.mapname) == "rp_c08_m1sewer"		)	{ KillThisNpc( "z3f_sci_03"			);										}
		if(string(g_Engine.mapname) == "rp_c08_m2surface"	)	{ KillThisNpc( "p03_scientist_b"	); KillThisNpc( "p03_scientist_a"	);	}
		if(string(g_Engine.mapname) == "rp_c08_m3surface"	)	{ KillThisNpc( "p03_scientist_a"	); KillThisNpc( "spawnsuittted1"	);	}
		if(string(g_Engine.mapname) == "rp_c11"				)	{ KillThisNpc( "suvi_barney"		);										}
		if(string(g_Engine.mapname) == "rp_c12_m1"			)	{ KillThisNpc( "o3n_kelly"			);										}
		if(string(g_Engine.mapname) == "rps_surface"		)	{ KillThisNpc( "bar01_friend"		);										}
	}
}

void KillThisNpc(const string TN){
	CBaseEntity@ pEntity = null;
	g_EntityFuncs.FireTargets( "spawn_npc_required", null, null, USE_TOGGLE );
	while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, TN )) !is null )
		g_EntityFuncs.Remove(pEntity);
}

void ReloadModelsClassicMode(){
	// For classic model SetUp models.
	// i know this method is kinda of "Why you do this?"
	// but as long as it works i won't be reworkin the system for 46 maps. -Mikk
	CBaseEntity@ pCM = null;
	while((@pCM = g_EntityFuncs.FindEntityByClassname(pCM, "*")) !is null)
	{
		if( pCM.pev.model == "models/mikk/residualpoint/w_bloodly_shotgun.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_w_bloodly_shotgun", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.model == "models/mikk/residualpoint/w_bloodly_9mmar.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_w_bloodly_9mmar", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.model == "models/mikk/residualpoint/zgrunt.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_zgrunt", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.model == "models/mikk/residualpoint/xenocrab.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_xenocrab", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.classname == "monster_male_assassin" and pCM.pev.model == "models/mikk/residualpoint/ngrunt.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_ngrunt", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.model == "models/mikk/residualpoint/hgrunt_opfor.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_hgrunt_opfor", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.model == "models/mikk/residualpoint/aworker.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_aworker", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.classname == "monster_male_assassin" and pCM.pev.model == "models/massn.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_massn", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.classname == "monster_otis" and pCM.pev.model != "models/cm_v3/otis.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_otis", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.classname == "monster_zombie_soldier" and pCM.pev.model != "models/cm_v3/zombie_soldier.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_zombie_soldier", pCM, pCM, USE_TOGGLE );
		if( pCM.pev.classname == "monster_zombie_barney" and pCM.pev.model != "models/cm_v3/zombie_barney.mdl" )
			g_EntityFuncs.FireTargets( "ClassicMode_zombie_barney", pCM, pCM, USE_TOGGLE );
	}
}

// CallBack for rp_c00_lobby
void ButtonsTargets( CBaseEntity@ pTriggerScript )
{
	CBaseEntity@ pButtons = null;
	while((@pButtons = g_EntityFuncs.FindEntityByClassname(pButtons, "func_button")) !is null){
		if( g_Utility.VoteActive() ){
			if( pButtons.GetCustomKeyvalues().HasKeyvalue( "$i_ignore_item" ) or pButtons.pev.target == "vote_disabled_msg")
				continue;

			edict_t@ pEdict = pButtons.edict();
			g_EntityFuncs.DispatchKeyValue( pEdict, "target", "vote_progress_msg" );
		}
		// Now that i think on this i could have use a dictionary instead of changevalues in a raw
		if( pButtons.pev.target == "vote_progress_msg" and !g_Utility.VoteActive() ){
			g_EntityFuncs.FireTargets( "ReturnTargets", null, null, USE_TOGGLE );
		}
	}
}

// CallBack for rp_c00_lobby
void StartClassicModeVote( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
	StartClassicModeVote( false );
}

void StartClassicModeVote( const bool bForce ){
	if( !bForce && g_ClassicMode.IsStateDefined() ){return;}
	float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
	if( flVoteTime <= 0 ){flVoteTime = 16;}
	float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
	if( flPercentage <= 0 ){flPercentage = 51;}
	Vote vote( "HLSP Classic Mode vote", ( g_ClassicMode.IsEnabled() ? "Disable" : "Enable" ) + " Classic Mode?", flVoteTime, flPercentage );
	vote.SetVoteBlockedCallback( @ClassicModeVoteBlocked );
	vote.SetVoteEndCallback( @ClassicModeVoteEnd );
	vote.Start();
}

void ClassicModeVoteBlocked( Vote@ pVote, float flTime ){
	g_Scheduler.SetTimeout( "StartClassicModeVote", flTime, false );
}

void ClassicModeVoteEnd( Vote@ pVote, bool bResult, int iVoters ){
	if( !bResult ){
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Classic Mode failed" );
		return;
	}
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !g_ClassicMode.IsEnabled() ? "Enable" : "Disable" ) + " Classic mode passed\n" );
	g_ClassicMode.Toggle();
}

// CallBack for rp_c13_m3a
void togglesurvival( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
	g_SurvivalMode.Disable();
}

// CallBack for rp_c13_m3a
void makezerodamage( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
	g_EngineFuncs.CVarSetFloat( "sk_kingpin_lightning", 0 );
	g_EngineFuncs.CVarSetFloat( "sk_tor_energybeam", 0 );
}

// CallBack for rp_c14
void SetOriginPlease( CBaseEntity@ pTriggerScript ){
    CBaseEntity@ pTrain = null;
    while( ( @pTrain = g_EntityFuncs.FindEntityByTargetname( pTrain, "kk01_truck_body" )) !is null ){
        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
        
            if( pPlayer is null or !pPlayer.IsConnected() )
                continue;

            pPlayer.SetOrigin( pTrain.Center() + Vector( 0, -24, 6 ) );
            pPlayer.pev.solid = SOLID_NOT;
            pPlayer.pev.flags |= FL_DUCKING | FL_NOTARGET;
			pPlayer.pev.flDuckTime = 26;
            pPlayer.BlockWeapons( pTrain );
        }
    }
}

void medium( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
    DiffMode = 1;
	Register();
}

void hard( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
    DiffMode = 2;
	Register();
}

void hardcore( CBaseEntity@ pActivator,CBaseEntity@ pCaller, USE_TYPE useType, float flValue ){
    DiffMode = 3;
	Register();

	CBaseEntity@ pRepl = null;
	while((@pRepl = g_EntityFuncs.FindEntityByClassname(pRepl, "point_checkpoint")) !is null)
		g_EntityFuncs.FireTargets( "limitless_potential", pRepl, pRepl, USE_TOGGLE );
}

void Register(){
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
}

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer){
    if( pPlayer is null or DiffMode == 0)
        return HOOK_CONTINUE;
    
	if(DiffMode == 1 )
    {
        pPlayer.pev.health = 80;
        pPlayer.pev.max_health = 80;
        pPlayer.pev.armortype = 80;
    }
    else if(DiffMode == 2 )
    {
        pPlayer.pev.health = 50;
        pPlayer.pev.max_health = 50;
        pPlayer.pev.armortype = 50;
    }
    else if(DiffMode == 3 )
    {
        pPlayer.pev.health = 1;
        pPlayer.pev.max_health = 1;
        pPlayer.pev.armortype = 1;
    }
    
    return HOOK_CONTINUE;
}

void Precacheclassic(){
	g_Game.PrecacheModel( "models/mikk/misc/limitless_potential.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/w_bloodly_9mmar.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/w_bloodly_shotgun.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/zgrunt.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/xenocrab.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/ngrunt.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/aworker.mdl" );
	g_Game.PrecacheModel( "models/mikk/residualpoint/hlclassic/hgrunt_opfor.mdl" );
	g_Game.PrecacheModel( "models/mikk/hlclassic/massn.mdl" );
	g_Game.PrecacheModel( "models/cm_v3/zombie_soldier.mdl" );
	g_Game.PrecacheModel( "models/cm_v3/zombie_barney.mdl" );
	g_Game.PrecacheModel( "models/cm_v3/otis.mdl" );
}