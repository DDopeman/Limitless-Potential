/* Uplinked Script by Outerbeast

Allows an optional transition from hl_c11_a5 to the start of this campaign via vote or directly
To skip the voting option and directly change to Uplinked, set this cvar in hl_c11_a5.cfg:

as_command uplinked_voteskip 0
*/
CCVar cvarVoteSkip( "uplinked_voteskip", 0, "Skip voting for Uplink (Direct Changelevel to Uplinked)", ConCommandFlag::AdminOnly );
CScheduledFunction@ fnInitUplinkedTransition = g_Scheduler.SetTimeout( "InitUplinkedTransition", 2.0f );
const string strUplinkedLevel = "hl_u12", strDefaultLevel = "hl_c12";

void InitUplinkedTransition()
{
    if( !g_EngineFuncs.IsMapValid( strUplinkedLevel ) )
        return;

    CBaseEntity@ pOldChangeLevel = g_EntityFuncs.FindEntityByClassname( pOldChangeLevel, "trigger_changelevel" );

    if( pOldChangeLevel is null )
        return;

    dictionary trgr =
    {
        { "model", "" + pOldChangeLevel.pev.model },
        { "origin", "0 16 0" }
    },
    vote =
    {
        { "targetname", "hl_u12_vote" },
        { "m_iszScriptFunctionName", "VoteUplinked" },
        { "m_iMode", "1" }
    },
    clip =
    {
        { "model", "" + pOldChangeLevel.pev.model },
        { "rendermode", "2" },
        { "renderamt", "0" }
    };

    if( cvarVoteSkip.GetInt() > 0 )
    {
        trgr["classname"] = "trigger_changelevel";
        trgr["map"] = "hl_u12";
    }
    else
    {
        trgr["classname"] = "trigger_once";
        trgr["target"] = "hl_u12_vote";
        g_EntityFuncs.CreateEntity( "trigger_script", vote );
    }

    g_EntityFuncs.CreateEntity( string( trgr["classname"] ), trgr );
    g_EntityFuncs.CreateEntity( "func_wall", clip );
    g_EntityFuncs.Remove( pOldChangeLevel );
}

void VoteUplinked(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    Vote voteUplinked( "Vote Uplinked", "Want to play extended chapter?", 20.0f, 51.0f );
    voteUplinked.SetYesText( "Yes, play Uplinked" );
    voteUplinked.SetNoText( "No, Lambda Bunker" );
    voteUplinked.SetVoteEndCallback( ChangeToUplinked );
    voteUplinked.Start();
}

void ChangeToUplinked(Vote@ pVote, bool fResult, int iVoters)
{
    g_EngineFuncs.ChangeLevel( fResult ? strUplinkedLevel : strDefaultLevel );
}
