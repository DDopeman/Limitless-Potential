/*
    Author: Mikk
*/

namespace notice_assets
{
    void delayed_notice( EHandle hplayer )
    {
        if( !hplayer.IsValid() )
            return;

        CBaseEntity@ entity = hplayer.GetEntity();

        if( entity is null )
            return;

        CBasePlayer@ player = cast<CBasePlayer@>(entity);

        if( player is null )
            return;

        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "NOTICE: If you have played older versions of this map previously\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tPlease consider updating manually to the latest version as many assets has been modified\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "\t\tAnd your gameplay most likely will be affected. Open the console to get the download link.\n" );
        g_PlayerFuncs.ClientPrint( player, HUD_PRINTCONSOLE, "http://scmapdb.wikidot.com/map:blackmesa-training-simulation:resonance-cascade\n" );
    }

    HookReturnCode player_connect( CBasePlayer@ player )
    {
        if( player !is null )
        {
            g_Scheduler.SetTimeout( "delayed_notice", 6.0f, EHandle(player) );
        }
        return HOOK_CONTINUE;
    }
}
