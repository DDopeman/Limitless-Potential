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

        void AddItems( CBasePlayer@ player, dictionary@ kvObj )
        {
            array<string> keys = kvObj.getKeys();

            for( uint ui = 0; ui < keys.length(); ui++ )
                for( int i = 0; i < int(kvObj[keys[ui]]); i++ )
                    player.GiveNamedItem( keys[ui], SF_GIVENITEM ); // Somehow the third argument is not working so we iterate
        }

        void AddItemInventory( CBasePlayer@ player, dictionary@ kvObj )
        {
            if( player !is null )
            {
                auto entity = g_EntityFuncs.CreateEntity( "item_inventory", kvObj );

                if( entity !is null )
                {
                    entity.Touch( player );
                }
            }
        }

        void AddKeyCard( CBasePlayer@ player, dictionary@ kvObj )
        {
            if( player !is null )
            {
                if( !kvObj.exists( "model" ) )
                    kvObj[ "model" ] = "models/w_security.mdl";
                if( !kvObj.exists( "delay" ) )
                    kvObj[ "delay" ] = "0";
                if( !kvObj.exists( "holder_timelimit_wait_until_activated" ) )
                    kvObj[ "holder_timelimit_wait_until_activated" ] = "0";
                if( !kvObj.exists( "m_flCustomRespawnTime" ) )
                    kvObj[ "m_flCustomRespawnTime" ] = "0";
                if( !kvObj.exists( "holder_keep_on_death" ) )
                    kvObj[ "holder_keep_on_death" ] = "0";
                if( !kvObj.exists( "holder_keep_on_respawn" ) )
                    kvObj[ "holder_keep_on_respawn" ] = "0";
                if( !kvObj.exists( "holder_can_drop" ) )
                    kvObj[ "holder_can_drop" ] = "1";
                if( !kvObj.exists( "carried_hidden" ) )
                    kvObj[ "carried_hidden" ] = "1";
                if( !kvObj.exists( "return_timelimit" ) )
                    kvObj[ "return_timelimit" ] = "-1";

                AddItemInventory( player, kvObj );
            }
        }

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
            if( pActivator is null ) {
                #if DEVELOP
                g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got no !activator!", { self.GetTargetname(), self.GetOrigin().ToString() } );
                #endif
                return;
            }

            CBasePlayer@ player = null;

            if( !pActivator.IsPlayer() ) {
                #if DEVELOP
                g_PlayerClass.m_Logger.error( "Entity \"{}\" origin {} got an !activator that is not a player!", { self.GetTargetname(), self.GetOrigin().ToString() } );
                #endif
                return;
            }

            @player = cast<CBasePlayer@>( pActivator );

            if( player is null ) {
                return;
            }
			

            g_PlayerClass.set_class( player, m_class );

            Vector fadeColor;

            switch( m_loadout )
            {
                case LoadOut::Nothing:
                {
                    return; // Exit.
                }
                case LoadOut::Solo:
                {
                    fadeColor = Vector(255, 0, 0);

                    switch( Math.RandomLong( 1, 30 ) )
                    {
                        case 1:
                        {
                            AddItems( player, {
                                { "weapon_bts_glock", 3 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_armorvest", 2 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BLUE-SHIFT" );
							g_PlayerFuncs.SayText(player, "You have: Random: BLUE-SHIFT.\n");
                            break;
                        }
                        case 2:
                        {
                            AddItems( player, {
                                { "weapon_bts_flaregun", 1 }
                            } );
                            player.GiveNamedItem( "weapon_bts_flaregun", SF_GIVENITEM );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SIGNAL" );
							g_PlayerFuncs.SayText(player, "You have: Random: SIGNAL.\n");
                            break;
                        }
                        case 3:
                        {
                            AddItems( player, {
                                { "weapon_bts_sbshotgun", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 1 },
                                { "item_bts_armorvest", 1 },
                                { "ammo_buckshot", 1 },
                                { "ammo_bts_eagle", 1 },
                                { "ammo_mp5clip", 1 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "2" },
                                { "description", "Blackmesa Research Clearance level 1" },
                                { "display_name", "Research Keycard lvl 1" },
                                { "item_name", "Blackmesa_Research_Clearance_1" },
                                { "item_icon", "bts_rc/inv_card_research.spr" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: 99 PERCENT GAMBLERS QUIT" );
							g_PlayerFuncs.SayText(player, "You have: Random: 99 PERCENT GAMBLERS QUIT.\n");
                            break;
                        }
                        case 4:
                        {
                            AddItems( player, {
                                { "weapon_bts_glock17f", 2 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "3" },
                                { "description", "Blackmesa Security Clearance level 1" },
                                { "display_name", "Security Keycard lvl 1" },
                                { "item_name", "Blackmesa_Security_Clearance_1" },
                                { "item_icon", "bts_rc/inv_card_security.spr" },
                                { "item_group", "security" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: LEVEL 1 SECURITY" );
							g_PlayerFuncs.SayText(player, "You have: Random: LEVEL 1 SECURITY.\n");
                            break;
                        }
                        case 5:
                        {
                            AddItems( player, {
                                { "weapon_bts_handgrenade", 1 },
                                { "weapon_bts_screwdriver", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: FINAL SOLUTION" );
							g_PlayerFuncs.SayText(player, "You have: Random: FINAL SOLUTION.\n");
                            break;
                        }
                        case 6:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: OLD TIMES" );
							g_PlayerFuncs.SayText(player, "You have: Random: OLD TIMES.\n");
                            break;
                        }
                        case 7:
                        {
                            AddItems( player, {
                                { "weapon_bts_knife", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: THE BRITISH" );
							g_PlayerFuncs.SayText(player, "You have: Random: THE BRITISH.\n");
                            break;
                        }
                        case 8:
                        {
                            AddItems( player, {
                                { "weapon_bts_flare", 3 },
                                { "weapon_bts_flaregun", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "ammo_bts_flarebox", 3 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: PYROMANIAC" );
							g_PlayerFuncs.SayText(player, "You have: Random: PYROMANIAC.\n");
                            break;
                        }
                        case 9:
                        {
                            AddItems( player, {
                                { "weapon_bts_python", 1 },
                                { "ammo_bts_eagle", 2 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "2" },
                                { "description", "Blackmesa Maintenance Clearance" },
                                { "display_name", "Maintenance Keycard" },
                                { "item_name", "Blackmesa_Maintenance_Clearance" },
                                { "item_icon", "bts_rc/inv_card_maint.spr" },
                                { "item_group", "repair" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SIX PACK" );
							g_PlayerFuncs.SayText(player, "You have: Random: SIX PACK.\n");
                            break;
                        }
                        case 10:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_armorvest", 1 },
                                { "weapon_bts_crowbar", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: FREE MAN" );
							g_PlayerFuncs.SayText(player, "You have: Random: FREE MAN.\n");
                            break;
                        }
                        case 11:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 1 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BETTER LUCK NEXT TIME BUCKAROO" );
							g_PlayerFuncs.SayText(player, "You have: Random: BETTER LUCK NEXT TIME BUCKAROO.\n");
                            break;
                        }
                        case 12:
                        {
                            AddItems( player, {
                                { "weapon_bts_medkit", 1 },
                                { "weapon_bts_eagle", 1 },
                                { "item_bts_helmet", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: POOR MAN'S MEDIC" );
							g_PlayerFuncs.SayText(player, "You have: Random: POOR MAN'S MEDIC.\n");
                            break;
                        }
                        case 13:
                        {
                            AddItems( player, {
                                { "weapon_bts_screwdriver", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 1 },
                                { "ammo_mp5clip", 1 },
                                { "ammo_bts_battery", 1 },
                                { "ammo_buckshot", 1 },
                                { "ammo_bts_python", 2 },
                                { "weapon_bts_flare", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: HOARDER" );
							g_PlayerFuncs.SayText(player, "You have: Random: HOARDER.\n");
                            break;
                        }
                        case 14:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 },
                                { "ammo_bts_m16_grenade", 1 },
                                { "weapon_bts_flare", 1 },
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_handgrenade", 4 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: DEMOLITION MAN" );
							g_PlayerFuncs.SayText(player, "You have: Random: DEMOLITION MAN.\n");
                            break;
                        }
                        case 15:
                        {
                            AddItems( player, {
                                { "weapon_bts_poolstick", 1 },
                                { "weapon_bts_crowbar", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "weapon_bts_knife", 1 },
                                { "weapon_bts_screwdriver", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: BLACKMESA REDEMPTION" );
							g_PlayerFuncs.SayText(player, "You have: Random: BLACKMESA REDEMPTION.\n");
                            break;
                        }
                        case 16:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 1 },
                                { "weapon_bts_glock17f", 1 },
                                { "weapon_bts_flashlight", 1 },
                                { "weapon_bts_beretta", 1 },
                                { "ammo_9mmclip", 3 },
                                { "weapon_bts_glock", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: WEAPON COLLECTOR" );
							g_PlayerFuncs.SayText(player, "You have: Random: WEAPON COLLECTOR.\n");
                            break;
                        }
                        case 17:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 2 },
                                { "weapon_bts_beretta", 1 },
                                { "ammo_9mmclip", 3 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            AddKeyCard( player, {
                                { "skin", "3" },
                                { "description", "Blackmesa Security Clearance level 1" },
                                { "display_name", "Security Keycard lvl 1" },
                                { "item_name", "Blackmesa_Security_Clearance_1" },
                                { "item_icon", "bts_rc/inv_card_security.spr" },
                                { "item_group", "security" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TAX EVASION" );
							g_PlayerFuncs.SayText(player, "You have: Random: TAX EVASION.\n");
                            break;
                        }
                        case 18:
                        {
                            AddItems( player, {
                                { "weapon_bts_poolstick", 1 },
                                { "item_bts_helmet", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SNOOKERED" );
							g_PlayerFuncs.SayText(player, "You have: Random: SNOOKERED.\n");
                            break;
                        }
                        case 19:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 1 },
                                { "weapon_bts_beretta", 1 },
                                { "ammo_9mmclip", 2 },
                                { "weapon_bts_knife", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: LUCKY DAY" );
							g_PlayerFuncs.SayText(player, "You have: Random: LUCKY DAY.\n");
                            break;
                        }
                        case 20:
                        {
                            AddItems( player, {
                                { "item_bts_armorvest", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            AddItemInventory( player, {
                                { "model", "models/w_antidote.mdl" },
                                { "delay", "0" },
                                { "holder_timelimit_wait_until_activated", "0" },
                                { "m_flCustomRespawnTime", "0" },
                                { "holder_keep_on_death", "0" },
                                { "holder_keep_on_respawn", "0" },
                                { "weight", "25" },
                                { "carried_hidden", "1" },
                                { "holder_can_drop", "1" },
                                { "return_timelimit", "-1" },
                                { "scale", "1.3" },
                                { "item_name", "pickup" },
                                { "item_group", "Items" },
                                { "description", "Increased damage... at a cost. (25 SLOTS)" },
                                { "display_name", "Adrenaline" },
                                { "effect_damage", "112" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SPEED RUNNER" );
							g_PlayerFuncs.SayText(player, "You have: Random: SPEED RUNNER.\n");
                            break;
                        }  
                        case 21:
                        {
                            AddItems( player, {
                                { "weapon_bts_screwdriver", 1 },
                                { "hornet", 2 }
                            } );
                            AddItemInventory( player, {
                                { "model", "models/w_antidote.mdl" },
                                { "delay", "0" },
                                { "holder_timelimit_wait_until_activated", "0" },
                                { "m_flCustomRespawnTime", "0" },
                                { "holder_keep_on_death", "0" },
                                { "holder_keep_on_respawn", "0" },
                                { "weight", "10" },
                                { "carried_hidden", "1" },
                                { "holder_can_drop", "1" },
                                { "return_timelimit", "-1" },
                                { "scale", "1.3" },
                                { "item_name", "pickup" },
                                { "item_group", "Items" },
                                { "description", "Increased movement speed (10 SLOTS)" },
                                { "display_name", "Morphine Can" },
                                { "effect_speed", "108" }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: JUNKY" );
							g_PlayerFuncs.SayText(player, "You have: Random: JUNKY.\n");
                            break;
                        }
                        case 22:
                        {
                            AddItems( player, {
                                { "weapon_bts_screwdriver", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: SCREWED" );
							g_PlayerFuncs.SayText(player, "You have: Random: SCREWED.\n");
                            break;
                        }
                        case 23:
                        {
                            AddItems( player, {
                                { "weapon_bts_flashlight", 1 },
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_eagle", 1 },
                                { "weapon_bts_python", 1 },
                                { "ammo_bts_python", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TOUGH CHOICE" );
							g_PlayerFuncs.SayText(player, "You have: Random: TOUGH CHOICE.\n");
                            break;
                        }
                        case 24:
                        {
                            AddItems( player, {
                                { "weapon_bts_python", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: ROULETTE" );
							g_PlayerFuncs.SayText(player, "You have: Random: ROULETTE.\n");
                            break;
                        }
                        case 25:
                        {
                            AddItems( player, {
                                { "weapon_bts_medkit", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: MEDIC" );
							g_PlayerFuncs.SayText(player, "You have: Random: MEDIC.\n");
                            break;
                        }
                        case 26:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_glock17f", 1 },
                                { "ammo_9mmclip", 1 },
                                { "weapon_bts_screwdriver", 1 },
                                { "ammo_bts_python", 1 },
                                { "ammo_bts_shotshell", 2 },
                                { "weapon_bts_flare", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: ALL ROUNDER" );
							g_PlayerFuncs.SayText(player, "You have: Random: ALL ROUNDER.\n");
                            break;
                        }
                        case 27:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 1 },
                                { "ammo_9mmclip", 1 },
                                { "ammo_bts_m16", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: AND YET NO GUN" );
							g_PlayerFuncs.SayText(player, "You have: Random: AND YET NO GUN.\n");
                            break;
                        }
                        case 28:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 1 },
                                { "ammo_bts_shotshell", 2 },
                                { "ammo_bts_python", 3 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: AND YET NO DAMN GUN" );
							g_PlayerFuncs.SayText(player, "You have: Random: AND YET NO DAMN GUN.\n");
                            break;
                        }
                        case 29:
                        {
                            AddItems( player, {
                                { "item_bts_helmet", 2 },
                                { "weapon_bts_glock17f", 1 },
                                { "weapon_bts_eagle", 1 },
                                { "ammo_bts_python", 1 },
                                { "ammo_9mmclip", 1 },
                                { "weapon_bts_flashlight", 1 }
                            } );
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: DUAL WIELD" );
							g_PlayerFuncs.SayText(player, "You have: Random: DUAL WIELD.\n");
                            break;
                        }
                        case 30:
                        {
                            g_PlayerFuncs.HudMessage( player, msgParams, "RANDOM USER MODE SELECTED\nGEAR NAME: TORTURED PLUS" );
							g_PlayerFuncs.SayText(player, "You have: Random: TORTURED PLUS.\n");
                            break;
                        }
                    } 
                    break;
                }
                case LoadOut::Security:
                {
                    fadeColor = Vector(0, 170, 255);

                    string barney_ammo_type = "ammo_9mmclip";
                    string barney_wpn_type = "weapon_bts_glock17f";

                    switch( Math.RandomLong( 1, 3 ) )
                    {
                        case 1:
                            barney_ammo_type = "ammo_bts_eagle";
                            barney_wpn_type = "weapon_bts_eagle";
							g_PlayerFuncs.SayText(player, "Security: Desert Eagle.\n");
                        break;
                        case 2:
                            barney_wpn_type = "weapon_bts_beretta";
							g_PlayerFuncs.SayText(player, "Security: M9 Beretta.\n");
                        break;
                        case 3:
                            barney_wpn_type = "weapon_bts_glock";
							g_PlayerFuncs.SayText(player, "Security: Glock17.\n");
                        break;
                    }

                    AddItems( player, {
                        { "item_bts_helmet", 1 },
                        { barney_wpn_type, 1 },
                        { barney_ammo_type, 2 },
                        { "weapon_bts_flashlight", 1 },
                        { "item_bts_armorvest", 1 }
                    } );
                    AddKeyCard( player, {
                        { "skin", "3" },
                        { "description", "Blackmesa Security Clearance level 1" },
                        { "display_name", "Security Keycard lvl 1" },
                        { "item_name", "Blackmesa_Security_Clearance_1" },
                        { "item_icon", "bts_rc/inv_card_security.spr" },
                        { "item_group", "security" }
                    } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Security Force" );
                    break;
                }
                case LoadOut::Scientist:
                {
                    fadeColor = Vector(0, 255, 93);

                    AddItems( player, {
                        { "weapon_bts_screwdriver", 1 },
                        { "weapon_bts_flashlight", 1 },
                        { "weapon_medkit", 1 }
                    } );
                    AddKeyCard( player, {
                        { "skin", "2" },
                        { "description", "Blackmesa Research Clearance level 1" },
                        { "display_name", "Research Keycard lvl 1" },
                        { "item_name", "Blackmesa_Research_Clearance_1" },
                        { "item_icon", "bts_rc/inv_card_research.spr" }
                    } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Science Team" );
					g_PlayerFuncs.SayText(player, "Scientist.\n");
                    break;
                }
                case LoadOut::Constructor:
                {
                    fadeColor = Vector(255, 255, 127);
					
					switch( Math.RandomLong( 1, 2 ) ) // sorry
                    {
                        case 1:
						AddItems( player, {
							{ "weapon_bts_pipewrench", 1 },
							{ "item_bts_helmet", 3 },
							{ "weapon_bts_flashlight", 1 }
						} );
						g_PlayerFuncs.SayText(player, "Maintenance: Pipewrench.\n");
                        break;
                        case 2:
						AddItems( player, {
							{ "weapon_bts_crowbar", 1 },
							{ "item_bts_helmet", 3 },
							{ "weapon_bts_flashlight", 1 }
						} );
						g_PlayerFuncs.SayText(player, "Maintenance: Crowbar.\n");
						break;
                    }
                    AddKeyCard( player, {
                        { "skin", "2" },
                        { "description", "Blackmesa Maintenance Clearance" },
                        { "display_name", "Maintenance Keycard" },
                        { "item_name", "Blackmesa_Maintenance_Clearance" },
                        { "item_icon", "bts_rc/inv_card_maint.spr" },
                        { "item_group", "repair" }
                    } );
                    AddItemInventory( player, {
                        { "model", "models/bts_rc/items/tool_box.mdl" },
						{ "skin", "1" },
                        { "delay", "0" },
                        { "holder_timelimit_wait_until_activated", "0" },
                        { "m_flCustomRespawnTime", "0" },
                        { "holder_keep_on_death", "0" },
                        { "holder_keep_on_respawn", "0" },
                        { "weight", "10" },
                        { "carried_hidden", "1" },
                        { "holder_can_drop", "1" },
                        { "return_timelimit", "-1" },
                        { "scale", "0.8" },
                        { "item_icon", "bts_rc/inv_card_maint.spr" },
                        { "item_name", "GM_TOOLBOX_SPECIAL" },
                        { "item_group", "TOOLBOX" },
                        { "description", "This Toolbox can be used for yellow and orange repair markers,(10 SLOTS)" },
                        { "display_name", "Engineers Toolbox" }
                    } );
                    g_PlayerFuncs.HudMessage( player, msgParams, "Blackmesa Maintenance" );
                    break;
                }
            }
            g_PlayerFuncs.ScreenFade( player, fadeColor, 0.25f, 1.0f, 255.0f, FFADE_OUT );
            g_Scheduler.SetTimeout( this, "PlayerFade", 1.0f, @player, fadeColor);
        }

        protected void PlayerFade(CBasePlayer@ player, Vector color)
        {
            if( player !is null )
            {
                g_PlayerFuncs.ScreenFade(player, color, 1.0f, 0.0f, 255.0f, FFADE_IN );
				g_PlayerFuncs.SayText(player, "The game is about to start.\n");
            }
        }
    }
}
