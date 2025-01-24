/*
* This script implements HLSP specific Classic Mode features
*/

array<ItemMapping@> g_ItemMappings = { ItemMapping( "weapon_m16", "weapon_9mmAR" ) };

bool ShouldRestartIfClassicModeChangesOn( const string& in szMapName )
{
	return szMapName != "-sp_campaign_portal" && szMapName != "hl_c00";
}

void ClassicModeMapInit()
{
	g_ClassicMode.SetItemMappings( @g_ItemMappings );

	//We want classic mode voting to be enabled here
	g_ClassicMode.EnableMapSupport();
	
	if( !ShouldRestartIfClassicModeChangesOn( g_Engine.mapname ) )
		g_ClassicMode.SetShouldRestartOnChange( false );
}

/*
* This is the function to use with trigger_script: triggering it will start classic mode. If the map is not hl_c00, the map is restarted
*/
void StartClassicModeVote( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	//Don't force the vote; only start if needed
	StartClassicModeVote( false );
}

void StartClassicModeVote( const bool bForce )
{
	if( !bForce && g_ClassicMode.IsStateDefined() )
		return;
		
	float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
	
	if( flVoteTime <= 0 )
		flVoteTime = 16;
		
	float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
	
	if( flPercentage <= 0 )
		flPercentage = 51;
		
	Vote vote( "HLSP Classic Mode vote", ( g_ClassicMode.IsEnabled() ? "Disable" : "Enable" ) + " Classic Mode?", flVoteTime, flPercentage );
	
	vote.SetVoteBlockedCallback( @ClassicModeVoteBlocked );
	vote.SetVoteEndCallback( @ClassicModeVoteEnd );
	
	vote.Start();
}

void ClassicModeVoteBlocked( Vote@ pVote, float flTime )
{
	// Voting is blocked at the moment (another vote in progress...).
	// Try again later.
	
	// The 3rd argument will be passed to the scheduled function.
	g_Scheduler.SetTimeout( "StartClassicModeVote", flTime, false );
}

void ClassicModeVoteEnd( Vote@ pVote, bool bResult, int iVoters )
{
	if( !bResult )
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Classic Mode failed" );
		return;
	}
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !g_ClassicMode.IsEnabled() ? "Enable" : "Disable" ) + " Classic mode passed\n" );
	
	g_ClassicMode.Toggle();
}

//Leave this out of release builds!
CConCommand g_ClassicModeVote( "debug_classicmodevote", "Debug only: starts the Classic Mode vote", @ClassicModeVoteCallback );

void ClassicModeVoteCallback( const CCommand@ pArgs )
{
	StartClassicModeVote( false );
}
