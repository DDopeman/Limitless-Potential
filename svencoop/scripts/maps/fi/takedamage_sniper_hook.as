bool blPlayerTakeDamageSniper = g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @TakeDamageNormalizeSniper );

HookReturnCode TakeDamageNormalizeSniper(DamageInfo@ pDamageInfo)
{
    if( pDamageInfo is null || pDamageInfo.pVictim is null || pDamageInfo.pAttacker is null || pDamageInfo.pInflictor is null )
        return HOOK_CONTINUE;

    if( pDamageInfo.pVictim.IsPlayer() )
        pDamageInfo.bitsDamageType &= ~DMG_SNIPER;

    return HOOK_CONTINUE;
}
