#include '../mikk/as_utils'

// Maximun number of sounds precached per map
const int max_precache = 10;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Mikk" );
    g_Module.ScriptInfo.SetContactInfo( mk.GetDiscord() );

    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
    g_Hooks.RegisterHook( Hooks::Weapon::WeaponPrimaryAttack, @WeaponPrimaryAttack );
    g_Hooks.RegisterHook( Hooks::ASLP::Player::PlayerPostRevive, @PlayerPostRevive );
}

void MapInit()
{
    LoadListOfPrecaches();
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
    if( pPlayer is null )
        return HOOK_CONTINUE;

	pPlayer.pev.health = 1;
	pPlayer.pev.max_health = 1;

    return HOOK_CONTINUE;
}



HookReturnCode WeaponPrimaryAttack( CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon )
{
    if( pPlayer is null || pWeapon is null || pWeapon.GetClassname() != "weapon_medkit" )
        return HOOK_CONTINUE;

    return RegenerateMedkit( pPlayer );
}

HookReturnCode PlayerPostRevive( CBasePlayer@ pPlayer )
{
    if( pPlayer is null )
        return HOOK_CONTINUE;

	pPlayer.pev.health = 1;
	pPlayer.pev.max_health = 1;

    CBaseEntity@ pEntity = null;

    while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pPlayer, pPlayer.pev.origin, 512, "player", "classname" ) ) !is null )
    {
        CBasePlayer@ pRevividorxd = cast<CBasePlayer@>( pEntity );

        if( pRevividorxd !is null )
            return RegenerateMedkit( pRevividorxd );
    }
    return HOOK_CONTINUE;
}

HookReturnCode RegenerateMedkit( CBasePlayer@ pPlayer )
{
    if( pPlayer is null )
        return HOOK_CONTINUE;

    CBasePlayerItem@ pMedkit = pPlayer.HasNamedPlayerItem( "weapon_medkit" );

    if( pMedkit !is null )
        pPlayer.m_rgAmmo( pMedkit.PrimaryAmmoIndex(), pMedkit.iMaxAmmo1() );

    return HOOK_CONTINUE;
}

void LoadListOfPrecaches()
{
    File@ pFile = g_FileSystem.OpenFile( 'scripts/plugins/store/ChatSounds.ini', OpenFile::READ );

    if( pFile !is null && pFile.IsOpen() )
    {
        string m_iszLine;

        bool chatsounds = false;

        while( !pFile.EOFReached() )
        {
            pFile.ReadLine( m_iszLine );

            if( m_iszLine.Length() < 1 )
                continue;

            array<string> Sound = m_iszLine.Split( " " );

            if( Sound.length() > 1 )
            {
                g_Precaches.insertLast( Sound[1] );
            }
        }
        pFile.Close();
    }
    GetNextPrecache();
}

array<string> g_Precaches;

string latestmap;

void GetNextPrecache()
{
    if( latestmap != string( g_Engine.mapname ) )
    {
        ChangePrecaches();
        latestmap = string( g_Engine.mapname );
    }

    if( g_PrecacheNow.length() >= 1 )
    {
        for( uint i = 0; i < g_PrecacheNow.length(); i++ )
        {
            g_Game.PrecacheGeneric( g_PrecacheNow[i] );
            g_Game.AlertMessage( at_console, "precached " + g_PrecacheNow[i] + "\n" );
        }
    }
}

int iStartIndex;

array<string> g_PrecacheNow;

void ChangePrecaches()
{
    if( iStartIndex >= int( g_Precaches.length() ) )
        iStartIndex = 0;

    g_PrecacheNow.resize(0);

    if( g_Precaches.length() < 1 )
        return;

    int iOldStartIndex = iStartIndex;

    while( iStartIndex < ( iOldStartIndex + max_precache ) && iStartIndex < int( g_Precaches.length() ) )
    {
        g_PrecacheNow.insertLast( g_Precaches[ iStartIndex ] );
        iStartIndex++;
    }
}