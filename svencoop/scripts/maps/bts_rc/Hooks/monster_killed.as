#if DEVELOP
    namespace monster_killed
    {
        CLogger@ m_Logger = CLogger( "MonsterKilledHook" );
    }
#endif

HookReturnCode monster_killed( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
{
    if( monster !is null )
    {
        dictionary@ user_data = monster.GetUserData();

        if( freeedicts( 1 ) )
        {
            bool is_zombie = false;

            string drop_item = String::EMPTY_STRING;

            if( "monster_zombie" == monster.pev.classname )
            {
                is_zombie = true;

                switch( Math.RandomLong( 1, 7 ) )
                {
                    case 1:
                        drop_item = "ammo_bts_battery";
                    break;
                    case 2:
                        drop_item = "weapon_bts_flare";
                    break;
                    case 3:
                        drop_item = "ammo_bts_dglocksd";
                    break;
                    case 4:
                        drop_item = "item_bts_sprayaid";
                    break;
                }
            }
            else if( monster.pev.classname == "monster_zombie_barney" )
            {
                is_zombie = true;

                switch( Math.RandomLong( 1, 7 ) )
                {
                    case 1:
                        drop_item = "ammo_bts_dglocksd";
                    break;
                    case 2:
                        drop_item = "ammo_bts_dreagle";
                    break;
                    case 3:
                        drop_item = "ammo_bts_shotshell";
                    break;
                    case 4:
                        drop_item = "ammo_bts_beretta";
                    break;
                }
            }
            else if( monster.pev.classname == "monster_zombie_soldier" || monster.pev.classname == "monster_gonome" )
            {
                is_zombie = true;

                switch( Math.RandomLong( 1, 15 ) )
                {
                    case 1:
                    case 2:
                        drop_item = "ammo_bts_shotshell";
                    break;
                    case 3:
                        drop_item = "ammo_bts_9mmbox";
                    break;
                    case 4:
                        drop_item = "ammo_bts_556round";
                    break;
                    case 5:
                        drop_item = "ammo_bts_357cyl";
                    break;
                    case 6:
                        drop_item = "ammo_bts_dreagle";
                    break;
                    case 7:
                        drop_item = "ammo_bts_dglocksd";
                    break;
                    case 8:
                        drop_item = "ammo_bts_556mag";
                    break;
                    case 9:
                        drop_item = "item_bts_hevbattery";
                    break;
                    default:
                        g_EntityFuncs.ShootTimed( monster.pev, monster.Center(), Vector( 0, 0, -90 ), Math.RandomFloat( 1.5, 5.5 ) );
                    break;
                }
            }
            else if( monster.pev.classname == "monster_sentry" )
            {
                if( Math.RandomLong( 1, 2 ) == 1 )
                {
                    drop_item = "ammo_bts_9mmbox";
                }
            }

            if( is_zombie )
            {
                const float headcrab_health = g_EngineFuncs.CVarGetFloat( "sk_headcrab_health" );
                const float headcrab_damage = int(user_data[ "headcrab_damage" ]);

                // Check if the stored received damage is less than a headcrab's HP
                if( headcrab_damage < headcrab_health )
                {
                    monster.SetBodygroup( 1, 1 );

                    // This model does have an extra bodygroup for the headcrab or was gibbed
                    if( monster.GetBodygroup( 1 ) == 1 || gib == GIB_ALWAYS )
                    {
                        // -TODO Should models have an attachment instead of +72 offset?
                        CBaseEntity@ headcrab = g_EntityFuncs.Create( "monster_headcrab", monster.pev.origin + Vector( 0, 0, 72 ), monster.pev.angles, false, monster.edict() );

                        if( headcrab !is null )
                        {
                            headcrab.pev.health = headcrab_health - headcrab_damage;

#if DEVELOP
                            monster_killed::m_Logger.info( "Created Headcrab for \"{}\" at \"{}\" with \"{}\" HP", { monster.pev.classname, headcrab.pev.origin.ToString(), headcrab.pev.health } );
#endif
                        }
                    }
#if DEVELOP
                    else
                    {
                        monster_killed::m_Logger.info( "Monster \"{}\" doesn't have a headcrab hitgroup for model \"{}\"", { monster.pev.classname, monster.pev.model } );
                    }
#endif
                }
            }

            if( drop_item != String::EMPTY_STRING )
            {
                CBaseEntity@ item = g_EntityFuncs.Create( drop_item, monster.Center(), g_vecZero, false, monster.edict() );

                if( item !is null )
                {
#if DEVELOP
                    monster_killed::m_Logger.info( "Created item \"{}\" for monster \"{}\" at \"{}\"", { drop_item, monster.pev.classname, monster.Center().ToString() } );
#endif
                    item.pev.spawnflags |= 1024; // no more respawn
                }
            }

            if( cvar_bloodpuddles.GetInt() == 0
            and freeedicts( 30 )
            /* Do not create for non-bleedable npcs */
            and monster.m_bloodColor != DONT_BLEED
            /* I'm sure Kern fixed this but just in case of a future update, we wouldn't want a bunch of puddles overflow x[ */
            and !user_data.exists( "bloodpuddle" ) )
            {
                CBaseEntity@ entity = g_EntityFuncs.Create( "env_bloodpuddle", monster.pev.origin, g_vecZero, true, monster.edict() );

                if( entity !is null )
                {
                    env_bloodpuddle::env_bloodpuddle@ bloodpuddle = cast<env_bloodpuddle::env_bloodpuddle@>( CastToScriptClass( entity ) );

                    if( bloodpuddle !is null )
                    {
                        if( monster.m_bloodColor == ( BLOOD_COLOR_GREEN | BLOOD_COLOR_YELLOW ) )
                        {
                            bloodpuddle.pev.skin = 1;
                        }

                        if( monster.pev.classname == "monster_headcrab" || monster.pev.classname == "monster_houndeye" || monster.pev.classname == "monster_babycrab" )
                        {
                            bloodpuddle.pev.scale = Math.RandomFloat( 0.5, 1.5 );
                        }
                        else
                        {
                            bloodpuddle.pev.scale = Math.RandomFloat( 1.5, 2.5 );
                        }

                        /* Monster gibed? Set it to full gib */
                        if( monster.ShouldGibMonster( gib ) )
                        {
                            bloodpuddle.state = env_bloodpuddle::BLOOD_STATE::EXPANDED;
                            // Think right away
                            bloodpuddle.pev.nextthink = g_Engine.time + 0.1f;
                        }
                        else
                        {
                            bloodpuddle.pev.nextthink = g_Engine.time + 0.8f;
                        }

                        bloodpuddle.Spawn();
                    }
                    else
                    {
#if DEVELOP
                        env_bloodpuddle::m_Logger.error( "Failed to cast to class, Liberating edict." );
#endif
                        entity.pev.flags |= FL_KILLME;
                    }
                }
                else
                {
#if DEVELOP
                    env_bloodpuddle::m_Logger.error( "Failed to create for monster \"{}\" at \"{}\"", { monster.pev.classname, monster.pev.origin.ToString() } );
#endif
                }

                user_data[ "bloodpuddle" ] = true;
            }
        }
    }

    return HOOK_CONTINUE;
}
