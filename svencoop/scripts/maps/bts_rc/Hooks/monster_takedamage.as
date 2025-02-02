/*
    Author: Mikk
*/

HookReturnCode monster_takedamage( DamageInfo@ pDamageInfo )
{
    if( pDamageInfo.flDamage <= 0 )
        return HOOK_CONTINUE;

    if( pDamageInfo.pVictim !is null )
    {
        CBaseMonster@ monster = cast<CBaseMonster@>( pDamageInfo.pVictim );

        if( monster !is null )
        {
            // Got hit on the headcrab. store damage
            if( monster.m_LastHitGroup == 1 && 
            (
                monster.pev.classname == "monster_zombie" ||
                monster.pev.classname == "monster_zombie_soldier" ||
                monster.pev.classname == "monster_zombie_barney" ||
                monster.pev.classname == "monster_gonome"
            ) )
            {
                dictionary@ user_data = monster.GetUserData();
                user_data[ "headcrab_damage" ] = int(user_data[ "headcrab_damage" ]) + pDamageInfo.flDamage;
            }
        }
    }

    return HOOK_CONTINUE;
}
