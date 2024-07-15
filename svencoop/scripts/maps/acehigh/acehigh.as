#include "ns/weapon_ns_shotgun"
#include "ns/weapon_ns_pistol"
#include "ns/monster_skulk"
#include "ns/weapon_ns_knife"
#include "ns/weapon_ns_machinegun"
#include "ns/weapon_ns_heavymachinegun"
#include "ns/weapon_ns_grenade"
#include "ns/weapon_ns_grenadegun"
#include "ns/weapon_ns_mine"
#include "ns/monster_fade"
#include "ns/monster_onos"
#include "ns/monster_gorge"
#include "ns/monster_marinesentry"
#include "lootbox"
#include "CustomHUD"
#include "player_sentry"

enum GAMESTATE
{
	GAMESTATE_NEW = 0,
	GAMESTATE_RUNNING,
	GAMESTATE_FINISHED,
	GAMESTATE_FAILED
};

GAMESTATE g_gamestate = GAMESTATE_NEW;

enum DIFFICULTY
{
	DIFFICULTY_ROOK = 0,
	DIFFICULTY_VET,
	DIFFICULTY_LEG
};

DIFFICULTY g_difficulty = DIFFICULTY_VET;
int g_iTimer = 900;

const string SPRITE_HUD_BATT = "chan_space/items/batv2.spr";
const string SPRITE_HUD_KEY = "chan_space/items/k1.spr";
const string SPRITE_HUD_TOOL = "chan_space/items/tool.spr";
const string SPRITE_HUD_SUIT = "chan_space/items/heavy.spr";

array<string> SPRITE_ITEMS = {
	"chan_space/items/b1.spr",
	"chan_space/items/b8.spr",
	"chan_space/items/b2.spr",
	"chan_space/items/b4.spr",
	"chan_space/items/b3.spr",
	"chan_space/items/b6.spr",
	"chan_space/items/b7.spr",
	"chan_space/items/b5.spr"
};

void MapInit()
{
	NS_SHOTGUN::Register();
	NS_PISTOL::Register();
	NS_KNIFE::Register();
	NS_MACHINEGUN::Register();
	NS_HEAVYMACHINEGUN::Register();
	NS_GRENADE::Register();
	NS_GRENADEGUN::Register();
	NS_MINE::Register();
	NS_SKULK::Register();
	NS_FADE::Register();
	NS_ONOS::Register();
	NS_GORGE::Register();
	NS_MARINE_SENTRY::Register();
	PLAYER_SENTRY::WeaponRegister();
	
	LOOTBOX::Precache();
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
	
	CustomHUD::Init();

	g_Game.PrecacheModel( "sprites/" + SPRITE_HUD_BATT );
	g_Game.PrecacheModel( "sprites/" + SPRITE_HUD_KEY );
	g_Game.PrecacheModel( "sprites/" + SPRITE_HUD_TOOL );
	g_Game.PrecacheModel( "sprites/" + SPRITE_HUD_SUIT );

	for( uint i = 0; i < SPRITE_ITEMS.length(); i++ )
	{
		g_Game.PrecacheModel( "sprites/" + SPRITE_ITEMS[i] );
	}	
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if( g_gamestate == GAMESTATE_RUNNING )
	{
		int iPlayerCount = 0;	
		for( int i = 1; i <= g_Engine.maxClients; i++ )
		{
			CBasePlayer@ pPlayerSearch = g_PlayerFuncs.FindPlayerByIndex( i );
			
			if( pPlayerSearch !is null && pPlayerSearch.IsAlive() )
				iPlayerCount++;
		}
		if( iPlayerCount == 0 )
		{
			g_gamestate = GAMESTATE_FAILED;
			g_EntityFuncs.FireTargets( "ship_ending_mm_fail", null, null, USE_TOGGLE, 0.0f, 0.0f );
		}
	}
	return HOOK_CONTINUE;
}

void StartTimer1( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	g_gamestate = GAMESTATE_RUNNING;
	CustomHUD::SetTarget( g_iTimer, "game_time_ranout" );
	CustomHUD::SetWarningTarget( 60, "" );

	CustomHUD::ToggleTimeDisplay( true );
}

void StartTimer2( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	CustomHUD::SetTarget( 60, "" );
	CustomHUD::SetWarningTarget( 10, "" );

	CustomHUD::ToggleTimeDisplay( true );
}

void CancelTimer( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CustomHUD::ToggleTimeDisplay( false );
}

void FailedGame( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	if( g_gamestate != GAMESTATE_RUNNING )
		return;	
		
	g_gamestate = GAMESTATE_FAILED;
}

void EndGame( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	if( g_gamestate != GAMESTATE_RUNNING )
		return;
		
	g_gamestate = GAMESTATE_FINISHED;
}

void VoteStart( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	CustomHUD::ToggleTimeDisplay( false );
	CustomHUD::SetTarget( 10, "vote_end" );
	CustomHUD::SetWarningTarget( 5, "" );
	CustomHUD::ToggleTimeDisplay( true );
}

void VoteResults( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	array<string> voteZones;
	array<string> voteCounters;
	array<string> entsToTrigger;
	CBaseEntity@ pZone, pCounter, pWinningCounter;
	
	while( ( @pZone = g_EntityFuncs.FindEntityByTargetname( pZone, "vote_zone_*" ) ) !is null )
	{
		voteZones.insertLast( pZone.pev.targetname );
	}
	while( ( @pCounter = g_EntityFuncs.FindEntityByTargetname( pCounter, "vote_count_*" ) ) !is null )
	{
		voteCounters.insertLast( pCounter.pev.targetname );
		pCounter.pev.frags = 0;
	}	
	for( uint i = 0; i < voteZones.length(); i++ )
	{
		g_EntityFuncs.FireTargets( voteZones[i], null, null, USE_ON );
	}
	
	float flScore = 0;
	string szWinningVote = "No result";
	string szDiffTgtNme;
	for( uint i = 0; i < voteCounters.length(); i++ )
	{
		@pCounter = g_EntityFuncs.FindEntityByTargetname( pCounter, voteCounters[i] );
		if( pCounter !is null )
		{
			if( pCounter.pev.frags > flScore )
			{
				flScore = pCounter.pev.frags;
				@pWinningCounter = @pCounter;
			}
			else
				continue;
		}
	} 
	if( pWinningCounter !is null )
	{
		CustomKeyvalues@ kvCounter = pWinningCounter.GetCustomKeyvalues();
		int iDiff = kvCounter.GetKeyvalue( "$i_diff" ).GetInteger();
		switch( iDiff )
		{
			case 0:
			{	
				szWinningVote = "Rookie Difficulty";
				szDiffTgtNme = "rook";				
				g_difficulty = DIFFICULTY_ROOK;
				g_iTimer = 1200;
				break;
			}
			case 1:
			{	
				szWinningVote = "Veteran Difficulty";
				szDiffTgtNme = "vet";
				g_difficulty = DIFFICULTY_VET;
				g_iTimer = 900;
				break;
			}
			case 2:
			{	
				szWinningVote = "Legendary Difficulty";
				szDiffTgtNme = "leg";
				g_difficulty = DIFFICULTY_LEG;
				g_iTimer = 600;
				break;
			}
			default:
			{	
				szWinningVote = "Med Difficulty";
				szDiffTgtNme = "vet";
				g_difficulty = DIFFICULTY_VET;
				g_iTimer = 900;
				break;
			}
		}
		
		entsToTrigger.insertLast( "game_mm_start_" + szDiffTgtNme );	
		int iPlayerCount = g_PlayerFuncs.GetNumPlayers();	
		
		if( iPlayerCount >= 15 )
			entsToTrigger.insertLast( "mm_" + szDiffTgtNme + "_20p_start" );
		else if( iPlayerCount >= 9 )
			entsToTrigger.insertLast( "mm_" + szDiffTgtNme + "_14p_start" );
		else if( iPlayerCount >= 5 )
			entsToTrigger.insertLast( "mm_" + szDiffTgtNme + "_8p_start" );
		else
			entsToTrigger.insertLast( "mm_" + szDiffTgtNme + "_4p_start" );
		
		for( uint i = 0; i < entsToTrigger.length(); i++ )
		{
			g_EntityFuncs.FireTargets( entsToTrigger[i], null, null, USE_TOGGLE, 0.0f, 0.0f );
		}
		
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[Vote] Winner: " + szWinningVote + "\n");
	}
	else
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[Vote] " + szWinningVote + "\n");
}

void ItemPickup( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	if( pActivator !is null && pCaller !is null )
	{
		ShowHUDTeamSprite( pActivator, pCaller, true );
	}
}

void ItemDrop( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE usetype, float fValue )
{
	if( pActivator !is null && pCaller !is null )
	{
		ShowHUDTeamSprite( pActivator, pCaller, false );
	}
}

enum ITEMS
{
	KEY = 0,
	SUIT,
	TOOL,
	ITEM
};

dictionary g_spriteDict = 
{
	{ "key_items", ITEM },
	{ "doorkeycards", KEY },
	{ "suit", SUIT },
	{ "tools", TOOL }
};

void ShowHUDTeamSprite( EHandle hPlayer, EHandle hItem, bool blActive )
{
	if( !hPlayer || !hItem )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
	CItemInventory@ pItem = cast<CItemInventory@>( hItem.GetEntity() );
	string szSprite;
	float y_axis;
	uint iChannel;

	switch( int(g_spriteDict[pItem.m_szItemGroup]) )
	{
		case ITEM:
		{
			if( string( pItem.m_szItemName ) == "battery" )
				szSprite = SPRITE_HUD_BATT;
			else
				szSprite = SPRITE_ITEMS[ atoi( string( pItem.pev.targetname ).Split( "_" )[1] ) - 1 ];
			
			y_axis = 0.30;
			iChannel = 1;
			break;
		}
		case KEY:
		{
			szSprite = "chan_space/items/"+pItem.pev.targetname+".spr";
			y_axis = 0.38;
			iChannel = 2;
			break;
		}
		case TOOL:
		{
			szSprite = SPRITE_HUD_TOOL;
			y_axis = 0.46;
			iChannel = 3;
			break;
		}
		case SUIT:
		{
			szSprite = SPRITE_HUD_SUIT;
			y_axis = 0.54;
			iChannel = 4;
			break;
		}
	}

	HUDSpriteParams SpriteDisplayParams;
	SpriteDisplayParams.channel = iChannel;
	SpriteDisplayParams.flags = HUD_ELEM_EFFECT_ONCE;
	SpriteDisplayParams.x = 0.01;
	SpriteDisplayParams.y = y_axis;
	SpriteDisplayParams.spritename = szSprite;
	SpriteDisplayParams.left = 0; 
	SpriteDisplayParams.top = 255; 
	SpriteDisplayParams.width = 0; 
	SpriteDisplayParams.height = 0;
	SpriteDisplayParams.color1 = RGBA( 255, 255, 255, 255 );
	SpriteDisplayParams.color2 = RGBA( 255, 255, 255, 255 );
	SpriteDisplayParams.fxTime = 0.5;
	SpriteDisplayParams.effect = HUD_EFFECT_RAMP_DOWN;
	SpriteDisplayParams.holdTime = blActive ? 9999999 : 0;
	
	g_PlayerFuncs.HudCustomSprite( pPlayer, SpriteDisplayParams );
}