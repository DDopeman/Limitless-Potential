// Workaround for controllable func_tanklasers damaging players
const array<string> STR_TANKLASER_NAMES = {"laser1"};
bool blPlayerTakeDamageLaser = g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @TanklaserNoDamage );

HookReturnCode TanklaserNoDamage(DamageInfo@ pDamageInfo)
{
    if( pDamageInfo is null || pDamageInfo.pVictim is null || pDamageInfo.pAttacker is null || pDamageInfo.pInflictor is null )
        return HOOK_CONTINUE;

    if( !pDamageInfo.pVictim.IsPlayer() )
        return HOOK_CONTINUE;

    if( STR_TANKLASER_NAMES.find( pDamageInfo.pAttacker.GetTargetname() ) < 0 || STR_TANKLASER_NAMES.find( pDamageInfo.pInflictor.GetTargetname() ) < 0 )
        return HOOK_CONTINUE;
    // Set zero damage upon hit
    pDamageInfo.flDamage = 0.0f;

    return HOOK_CONTINUE;
}
