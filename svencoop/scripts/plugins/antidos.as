// How many times he can **Attempt** to join the server
int max_ping = 5;

// Reason of disconnecting
const string reason = "Reason for disconnecting";

// Time for decreasing pings, i.e each second decrease max_ping in 1 per user
float runcheck_time = 10.0f;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "idk" );
    g_Module.ScriptInfo.SetContactInfo( "idk" );

    g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );

    if( pThink !is null )
    {
        g_Scheduler.RemoveTimer( pThink );
    }

    @pThink = g_Scheduler.SetInterval( "CheckRuns", runcheck_time, g_Scheduler.REPEAT_INFINITE_TIMES );
}

void CheckRuns()
{
    const array<string> s_Data = g_Data.getKeys();

    for( uint ui = 0; ui < s_Data.length(); ui++ )
    {
        int times = int( g_Data[ s_Data[ ui ] ] );

        if( times > 0 )
        {
            times--;
        }

        g_Data[ s_Data[ ui ] ] = times;

        if( times == 0 )
        {
            g_Data.delete( s_Data[ ui ] );
        }
    }
}

CScheduledFunction@ pThink = null;

dictionary g_Data;

HookReturnCode ClientConnected( edict_t@ pEntity, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
    if( !szIPAddress.IsEmpty() && pThink !is null )
    {
        if( g_Data.exists( szIPAddress ) )
        {
            int times = int( g_Data[ szIPAddress ] );

            if( times >= max_ping )
            {
                szRejectReason = reason;
                bDisallowJoin = true;
                g_Game.AlertMessage( at_logged, "Rejected connectiong from " + szIPAddress + " " + ( szPlayerName.IsEmpty() ? "" : szPlayerName + " " ) + "\n" );
                return HOOK_HANDLED; // Idk if calling other hooks actually resets the bool, happened to my custom hooks, HOOK_HANDLED for this then
            }
            else
            {
                times++;
                g_Data[ szIPAddress ] = times;
            }
        }
        else
        {
            g_Data[ szIPAddress ] = 1;
        }
    }

    return HOOK_CONTINUE;
}