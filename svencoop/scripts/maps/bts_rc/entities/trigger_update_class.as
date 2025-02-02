/*
    Author: Mikk
*/

namespace trigger_update_class
{
    HUDTextParams msgParams;

    enum LoadOut
    {
        Nothing = -1,
        Security = 0,
        Scientist = 1,
        Constructor = 2,
        Solo = 3
    };

    class trigger_update_class : ScriptBaseEntity
    {
        private PM m_class = PM::SCIENTIST;
        private LoadOut m_loadout = LoadOut::Nothing;

        void Spawn()
        {
            msgParams.x = 0;
            msgParams.y = 0;
            msgParams.effect = 2;
            msgParams.r1 = 255;
            msgParams.g1 = 255;
            msgParams.b1 = 255;
            msgParams.a1 = 0;
            msgParams.r2 = 240;
            msgParams.g2 = 110;
            msgParams.b2 = 0;
            msgParams.a2 = 0;
            msgParams.fadeinTime = 0.05f;
            msgParams.fadeoutTime = 0.5f;
            msgParams.holdTime = 1.2f;
            msgParams.fxTime = 0.025f;
            msgParams.channel = 5;

            self.pev.movetype = MOVETYPE_NONE;
            self.pev.effects |= EF_NODRAW;
            self.pev.solid = SOLID_NOT;
        }

        bool KeyValue( const string& in szKeyName, const string& in szValue )
        {
            if( szKeyName == 'm_class' )
            {
                int value = atoi( szValue );

                switch( value )
                {
                    case 6: // Solo
                    {
                        m_loadout = LoadOut::Solo;
                        m_class = PM::BARNEY;
                        break;
                    }
                    case PM::BARNEY:
                    {
                        m_loadout = LoadOut::Security;
                        m_class = PM::BARNEY;
                        break;
                    }
                    case PM::SCIENTIST:
                    {
                        m_loadout = LoadOut::Scientist;
                        m_class = PM::SCIENTIST;
                        break;
                    }
                    case PM::CONSTRUCTION:
                    {
                        m_loadout = LoadOut::Constructor;
                        m_class = PM::CONSTRUCTION;
                        break;
                    }
                    default:
                    {
                        m_class = PM( value );
                        break;
                    }
                }
                return true;
            }
            return BaseClass.KeyValue( szKeyName, szValue );
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( pActivator !is null )
            {
                CBasePlayer@ player = null;

                if( pActivator.IsPlayer() && ( @player = cast<CBasePlayer@>( pActivator ) ) !is null )
                {
                    g_PlayerClass.set_class( player, m_class );

                    string sound;
                    string message = "";
                    Vector fadeColor;

                    dictionary keycard;
                    CBaseEntity@ invkeycard = null;
                    keycard[ "model" ] = "models/w_security.mdl";
                    keycard[ "delay" ] = "0";
                    keycard[ "holder_timelimit_wait_until_activated" ] = "0";
                    keycard[ "m_flCustomRespawnTime" ] = "0";
                    keycard[ "holder_keep_on_death" ] = "0";
                    keycard[ "holder_keep_on_respawn" ] = "0";
                    keycard[ "holder_can_drop" ] = "1";
                    keycard[ "carried_hidden" ] = "1";
                    keycard[ "return_timelimit" ] = "-1";

                    switch( m_loadout )
                    {
                        case LoadOut::Nothing:
                        {
                            return; // Exit.
                        }
                        case LoadOut::Solo:
                        {
                            snprintf( sound, "vox/user.wav" );
                            snprintf( message, "USER MODE SELECTED\nSECURITY CLEARANCE LEVEL 5\nADMINISTRATOR OBSERVING\nTECHNICIAN OBSERVING\nTROUBLE SHOOTING ENABLED\nGENERATING USER SCENARIOS\n10%.. 20%.. 30%.. 40%.. 50%.. 60%..\n70%.. 80%.. 90%.. 100%.. COMPLETE\nSIMUL" );
                            fadeColor = Vector(255, 0, 0);

                            player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );
#if DEVELOP
                            g_PlayerClass.m_Logger.error( "Set loadout \"Solo\" for player {}", { player.pev.netname } );
#endif
                            break;
                        }
                        case LoadOut::Security:
                        {
                            fadeColor = Vector(0, 170, 255);
                            snprintf( sound, "vox/security.wav" );
                            snprintf( message, "%1%2", message, "Blackmesa Security Force" );

                            switch( Math.RandomLong( 1, 4 ) )
                            {
                                case 1:
                                {
                                    player.GiveNamedItem( "weapon_bts_eagle", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_bts_eagle", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_bts_eagle", SF_GIVENITEM );
									player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_armorvest", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                                    break;
                                }
                                case 2:
                                {
                                    player.GiveNamedItem( "weapon_bts_beretta", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_9mmclip", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_9mmclip", SF_GIVENITEM );
									player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_armorvest", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                                    break;
                                }
                                case 3:
                                {
                                    player.GiveNamedItem( "weapon_bts_glock", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_9mmclip", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_9mmclip", SF_GIVENITEM );
									player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_armorvest", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                                    break;
                                }
                                case 4:
                                {
                                    player.GiveNamedItem( "weapon_bts_glock17f", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_9mmclip", SF_GIVENITEM );
                                    player.GiveNamedItem( "ammo_9mmclip", SF_GIVENITEM );
									player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_armorvest", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                                    break;
                                }
                            }
                            player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                            player.GiveNamedItem( "item_bts_armorvest", SF_GIVENITEM );
                            player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );

                            keycard[ "skin" ] = "3";
                            keycard[ "description" ] = "Blackmesa Security Clearance level 1";
                            keycard[ "display_name" ] = "Security Keycard lvl 1";
                            keycard[ "item_name" ] = "Blackmesa_Security_Clearance_1";
                            keycard[ "item_icon" ] = "bts_rc/inv_card_security.spr";
                            keycard[ "item_group" ] = "security";
                            @invkeycard = g_EntityFuncs.CreateEntity( "item_inventory", keycard );
#if DEVELOP
                            g_PlayerClass.m_Logger.error( "Set loadout \"Security\" for player {}", { player.pev.netname } );
#endif
                            break;
                        }
                        case LoadOut::Scientist:
                        {
                            fadeColor = Vector(0, 255, 93);
                            snprintf( sound, "vox/research.wav" );
                            snprintf( message, "%1%2", message, "Blackmesa Science Team" );

                            player.GiveNamedItem( "weapon_bts_screwdriver", SF_GIVENITEM );
                            player.GiveNamedItem( "weapon_medkit", SF_GIVENITEM );
                            player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );

                            keycard[ "skin" ] = "2";
                            keycard[ "description" ] = "Blackmesa Research Clearance level 1";
                            keycard[ "display_name" ] = "Research Keycard lvl 1";
                            keycard[ "item_name" ] = "Blackmesa_Research_Clearance_1";
                            keycard[ "item_icon" ] = "bts_rc/inv_card_research.spr";
                            @invkeycard = g_EntityFuncs.CreateEntity( "item_inventory", keycard );
#if DEVELOP
                            g_PlayerClass.m_Logger.error( "Set loadout \"Scientist\" for player {}", { player.pev.netname } );
#endif
                            break;
                        }
                        case LoadOut::Constructor:
                        {
                            fadeColor = Vector(255, 255, 127);
                            snprintf( sound, "vox/maintenance.wav" );
                            snprintf( message, "%1%2", message, "Blackmesa Maintenance" );

                            switch( Math.RandomLong( 1, 2 ) )
                            {
                                case 1:
                                {
                                    player.GiveNamedItem( "weapon_bts_screwdriver", SF_GIVENITEM );
									player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                                    break;
                                }
                                case 2:
                                {
                                    player.GiveNamedItem( "weapon_bts_crowbar", SF_GIVENITEM );
									player.GiveNamedItem( "weapon_bts_flashlight", SF_GIVENITEM );
									player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                                    break;
                                }
                            }
                            player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );
                            player.GiveNamedItem( "item_bts_helmet", SF_GIVENITEM );

                            keycard[ "skin" ] = "2";
                            keycard[ "description" ] = "Blackmesa Maintenance Clearance";
                            keycard[ "display_name" ] = "Maintenance Keycard";
                            keycard[ "item_name" ] = "Blackmesa_Maintenance_Clearance";
                            keycard[ "item_icon" ] = "bts_rc/inv_card_maint.spr";
							keycard[ "item_group" ] = "repair";
                            @invkeycard = g_EntityFuncs.CreateEntity( "item_inventory", keycard );

                            dictionary kv;
                            kv[ "model" ] = "models/tool_box.mdl";
                            kv[ "delay" ] = "0";
                            kv[ "holder_timelimit_wait_until_activated" ] = "0";
                            kv[ "m_flCustomRespawnTime" ] = "0";
                            kv[ "holder_keep_on_death" ] = "0";
                            kv[ "holder_keep_on_respawn" ] = "0";
                            kv[ "weight" ] = "10";
                            kv[ "carried_hidden" ] = "1";
                            kv[ "holder_can_drop" ] = "1";
                            kv[ "return_timelimit" ] = "-1";
                            kv[ "scale" ] = "0.8";
                            kv[ "item_icon" ] = "bts_rc/inv_card_maint.spr";
                            kv[ "item_name" ] = "GM_TOOLBOX";
                            kv[ "description" ] = "Blackmesa Maintenance Toolcase";
                            kv[ "display_name" ] = "Maintenance Toolbox (10 SLOTS)";

                            CBaseEntity@ toolbox = g_EntityFuncs.CreateEntity( "item_inventory", kv );

                            if( toolbox !is null )
                            {
                                toolbox.Touch( player );
                            }
#if DEVELOP
                            g_PlayerClass.m_Logger.error( "Set loadout \"Constructor\" for player {}", { player.pev.netname } );
#endif
                            break;
                        }
                    }

                    if( invkeycard !is null )
                    {
                        invkeycard.Touch( player );
                    }

                    g_PlayerFuncs.ScreenFade( player, fadeColor, 0.25f, 1.0f, 255.0f, FFADE_OUT );
                    g_Scheduler.SetTimeout( this, "PlayerFade", 1.0f, @player, fadeColor);
					g_PlayerFuncs.HudMessage( player, msgParams, message );
                }
#if DEVELOP
                else
                {
                    g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got an !activator that is not a player!", { self.GetTargetname(), self.GetOrigin().ToString() } );
                }
                #endif
            }
#if DEVELOP
            else
            {
                g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got no !activator!", { self.GetTargetname(), self.GetOrigin().ToString() } );
            }
#endif
        }

        protected void PlayerFade(CBasePlayer@ player, Vector& in color)
        {
            if( player !is null )
            {
                g_PlayerFuncs.ScreenFade(player, color, 1.0f, 0.0f, 255.0f, FFADE_IN );
            }
        }
    }
}
