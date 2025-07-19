void PushEnemy( CBaseEntity@ self )
{
    if( g_PlayerFuncs.GetNumPlayers() == 0 )
        return;

    CBaseEntity@ pEntity = null;

    while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity , 'kz_npc_alerted' ) ) !is null )
    {
        // Puede que no sea certero pero mientras corras este script varias veces en algun punto se alertaran
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( Math.RandomLong( 1, g_PlayerFuncs.GetNumPlayers() ) );

        g_Game.AlertMessage( at_console, "Push Enemy " + ( pPlayer is null ? "Jugador Nulo" : !pPlayer.IsAlive() ? "Jugador Muerto" : !pEntity.IsMonster() ? "Entidad no es monster" : "Se alerto" ) + "\n" );

        if( !pEntity.IsMonster() || pPlayer is null || !pPlayer.IsAlive() )
            continue;

        CBaseMonster@ pMonster = cast<CBaseMonster@>( pEntity );

        if( pMonster.m_hEnemy.GetEntity() !is null )
            continue;

        pMonster.PushEnemy( pPlayer, pPlayer.pev.origin );
    }
}