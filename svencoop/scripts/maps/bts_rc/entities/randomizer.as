namespace randomizer
{
#if DEVELOP
    CLogger@ m_Logger = CLogger( "Randomizer" );
#endif

    // Swap a specific squad to a random location.
    void randomize_squad( CBaseMonster@ squad, CBaseEntity@ entity )
    {
        if( squad !is null && g_EntityFuncs.IsValidEntity( squad.pev.owner ) )
        {
            CBaseEntity@ owner_spot = g_EntityFuncs.Instance( squad.pev.owner );

            if( owner_spot !is null )
            {
                owner_spot.Use( null, null, USE_TOGGLE ); // Do not change USE_TYPE input.
            }
#if DEVELOP
            else
            {
                randomizer::m_Logger.warn( "Failed to swap a squad. null owner for squad" );
            }
#endif
        }
#if DEVELOP
        else
        {
            randomizer::m_Logger.warn( "Failed to swap a squad: {}", { ( squad is null ? "null squad" : "null owner for squad" ) } );
        }
#endif
    }

    // Swap all squads to a random and unique location.
    void randomize( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        g_RandomizerHeadcrab.init();
        g_RandomizerNpc.init();
        g_RandomizerBoss.init();
        g_RandomizerHull.init();
        g_RandomizerWave.init();
        g_RandomizerItem.init();
        g_RandomizerHullWave.init();

        // Free the entity slot.
        if( pActivator !is null )
            pActivator.pev.flags |= FL_KILLME;
    }

    class CRandomizerEntity : ScriptBaseEntity
    {
        int type() { return 0; }

        // Get a entity index from the proper randomizer.
        int GetRandomizerIndex()
        {
            switch( this.type() )
            {
                case 1:
                    return g_RandomizerNpc.indexes[ Math.RandomLong( 0, g_RandomizerNpc.indexes.length() -1 ) ];
                case 2:
                    return g_RandomizerItem.indexes[ Math.RandomLong( 0, g_RandomizerItem.indexes.length() -1 ) ];
                case 3:
                    return g_RandomizerHull.indexes[ Math.RandomLong( 0, g_RandomizerHull.indexes.length() -1 ) ];
                case 4:
                    return g_RandomizerBoss.indexes[ Math.RandomLong( 0, g_RandomizerBoss.indexes.length() -1 ) ];
                case 5:
                    return g_RandomizerWave.indexes[ Math.RandomLong( 0, g_RandomizerWave.indexes.length() -1 ) ];
                case 6:
                    return g_RandomizerHeadcrab.indexes[ Math.RandomLong( 0, g_RandomizerHeadcrab.indexes.length() -1 ) ];
                case 7:
                    return g_RandomizerHullWave.indexes[ Math.RandomLong( 0, g_RandomizerHullWave.indexes.length() -1 ) ];
            }

            return self.entindex();
        }

        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.effects |= EF_NODRAW;
            self.pev.movetype = MOVETYPE_NONE;
#if TEST
            m_Logger.debug( "Random origin for \"{}\" at \"{}\"", { self.GetClassname(), self.GetOrigin().ToString() } );
#endif
        }

        // Swap the given squadmaker with the given randomizer position.
        void Use( CBaseEntity@ squad, CBaseEntity@ randomizer, USE_TYPE use, float value )
        {
            switch( use )
            {
                case USE_TOGGLE:
                {
                    // Repeat in case we matched this same entity
                    for( int i = 0; i < 5; i++ )
                    {
                        // Pick a random randomizer from the list of indexes.
                        @randomizer = g_EntityFuncs.Instance( this.GetRandomizerIndex() );

                        if( randomizer !is null && randomizer !is self )
                        {
                            // Swap owners
                            self.Use( g_EntityFuncs.Instance( self.pev.owner ), self, USE_SET );
                            self.Use( ( randomizer !is null ? g_EntityFuncs.Instance( randomizer.pev.owner ) : null ), randomizer, USE_SET );
#if DEVELOP
                            m_Logger.debug( "{}: \"{}\" <-> \"{}\"", { self.pev.classname, self.entindex(), randomizer.entindex() } );
#endif
                            break;
                        }
                    }
                    break;
                }

                case USE_SET:
                {
                    if( squad !is null && randomizer !is null )
                    {
                        @randomizer.pev.owner = @squad.edict();
                        @squad.pev.owner = @randomizer.edict();
                        g_EntityFuncs.SetOrigin( squad, randomizer.GetOrigin() );
                    }
                    break;
                }
            }
        }
    }

    class randomizer_npc : CRandomizerEntity
    {
        int type() { return 1; }
    }

    class randomizer_item : CRandomizerEntity
    {
        int type() { return 2; }
    }

    class randomizer_hull : CRandomizerEntity
    {
        int type() { return 3; }
    }

    class randomizer_boss : CRandomizerEntity
    {
        int type() { return 4; }
    }

    class randomizer_wave : CRandomizerEntity
    {
        int type() { return 5; }
    }

    class randomizer_headcrab : CRandomizerEntity
    {
        int type() { return 6; }
    }
    
    class randomizer_hullwave : CRandomizerEntity
    {
        int type() { return 7; }
    }

    //============================================================================
    // End of map-entities
    //============================================================================

    //============================================================================
    // Start of swap logic
    //============================================================================

    class CRandomizer
    {
        // Identifier name for this class
        string name() { return String::EMPTY_STRING; }

        // List of entities names for this class
        array<string>@ entities() { return {}; }

        // Indexes of randomizer entities
        array<int> indexes;

        void init()
        {
            const string name = this.name();
            string target;
            snprintf( target, "randomizer_%1", name );
#if DEVELOP
            m_Logger.info( "Initializing swappers \"{}\"", { target } );
#endif
            // Find all randomizers and store them in indexes
            CBaseEntity@ pRandomizer = null;
            while( ( @pRandomizer = g_EntityFuncs.FindEntityByClassname( pRandomizer, target ) ) !is null )
            {
#if TEST
                m_Logger.info( "Got entity {} at \"{}\"", { pRandomizer.entindex(), pRandomizer.GetOrigin().ToString() } );
#endif

                this.indexes.insertLast( pRandomizer.entindex() );
            }

            // Swaps a list for initial result of Vectors.
            array<int> swaps = this.indexes;
            for( int i = swaps.length() - 1; i > 0; i-- )
            {
                int j = Math.RandomLong( 0, i );
                int temp = swaps[i];
                swaps[i] = swaps[j];
                swaps[j] = temp;
            }
            this.indexes = swaps;
#if TEST
            m_Logger.info( "Swapped list {} indexes", { this.name() } );
#endif

            array<string> entities_names = this.entities();

            int index = this.indexes.length();

            for( uint ui = 0; ui < entities_names.length(); ui++, index-- )
            {
                if( ( @pRandomizer = g_EntityFuncs.Instance( this.indexes[ index - 1 ] ) ) !is null )
                {
#if TEST
                    m_Logger.debug( "{}: \"{}\" Swap position to {}", { name, entities_names[ui], pRandomizer.GetOrigin().ToString() } );
#endif
                    pRandomizer.Use( g_EntityFuncs.FindEntityByTargetname( null, entities_names[ui] ), pRandomizer, USE_SET );
                }
            }
        }
    }

    final class CRanomizerHeadcrabs : CRandomizer
    {
        string name() { return "headcrab"; }

        array<string>@ entities()
        {
            return
            {
                "GM_HEAD_S1",
                "GM_HEAD_S2",
                "GM_HEAD_S3",
                "GM_HEAD_S4",
                "GM_HEAD_S5",
                "GM_HEAD_S6",
                "GM_HEAD_S7",
                "GM_HEAD_S8",
                "GM_HEADZOEA_S1",
                "GM_HEADZOEA_S2",
                "GM_HEADZOEA_S3",
                "GM_HEADZOEA_S4"
            };
        }
    }
    CRanomizerHeadcrabs g_RandomizerHeadcrab;

    final class CRanomizerItems : CRandomizer
    {
        string name() { return "item"; }

        array<string>@ entities()
        {
            return
            {
                // WEAPONS
                "GM_SG_1",
                "GM_SG_2",
                "GM_SG_3",
                "GM_SG_4",
                "GM_CB_1",
                "GM_CB_2",
                "GM_CB_3",
                "GM_CB_4",
                "GM_KN_1",
                "GM_PIPE_1",
                "GM_PIPE_2",
                "GM_PS_1",
                "GM_SD_1",
                "GM_AXE_1",
                "GM_MAG_1",
                "GM_MAG_2",
                "GM_DE_1",
                "GM_DE_2",
                "GM_HG_1",
                "GM_HG_2",
                "GM_HG_3",
                "GM_HG_4",
                "GM_HG_5",
                "GM_HG_6",
                "GM_HG_7",
                "GM_HG_8",
                "GM_FGUN_1",
                "GM_G18_1",
                "GM_PHK_1",
                "GM_PHK_2",
                "GM_UZI_1",
                "GM_MP5_1",
                "GM_MP5_2",
                "GM_M4_1",
                "GM_M16_1",
                "GM_SAW_1",
                // ITEMS
                "GM_HK_1",
                "GM_HK_2",
                "GM_HK_3",
                // AMMO
                "GM_AMMO_1",
                "GM_AMMO_2",
                "GM_AMMO_3",
                "GM_AMMO_4",
                "GM_AMMO_5",
                "GM_AMMO_6",
                "GM_AMMO_7",
                "GM_AMMO_8",
                "GM_AMMO_9",
                "GM_AMMO_10",
                "GM_AMMO_11",
                "GM_AMMO_12",
                "GM_AMMO_13",
                "GM_AMMO_14",
                "GM_AMMO_15",
                "GM_AMMO_16",
                "GM_AMMO_17",
                "GM_AMMO_18",
                "GM_AMMO_19",
                "GM_AMMO_20",
                "GM_AMMO_21",
                "GM_AMMO_22",
                "GM_AMMO_23",
                "GM_AMMO_24",
                "GM_AMMO_25",
                "GM_AMMO_26",
                "GM_AMMO_27",
                "GM_AMMO_28",
                "GM_AMMO_29",
                "GM_AMMO_30",
                "AU_AMMO_1",
                "AU_AMMO_2",
                "AU_AMMO_3",
                "AU_AMMO_4",
                "AU_AMMO_5",
                "AU_AMMO_6",
                "AU_AMMO_7",
                "AU_AMMO_8",
                "AU_AMMO_9",
                "AU_AMMO_10",
                "AU_AMMO_11",
                "AU_AMMO_12",
                // PLAYER COUNT AMMO
                "GM_AMMO_PC1",
                "GM_AMMO_PC2",
                "GM_AMMO_PC3",
                "GM_AMMO_PC4",
                "GM_AMMO_PC5",
                "GM_AMMO_PC6",
                "GM_AMMO_PC7",
                // BATTERIES
                "GM_BA_1",
                "GM_BA_2",
                "GM_BA_3",
                "GM_BA_4",
                "GM_BA_5",
                // ITEMS
                "objective_dorms_key3",
                "objective_dorms_key4",
                "GM_ANTIDOTE_1",
                "GM_ANTIDOTE_2",
                "GM_ANTIDOTE_3",
                "GM_ANTIDOTE_4",
                "GM_FLR_1",
                "GM_FLR_2",
                "GM_FLR_3",
                "GM_FLR_4",
                "GM_FLR_5",
                "GM_FLR_6",
                "GM_FLASH_1",
                "GM_FLASH_2",
                "GM_FLASH_3",
                "GM_FLASH_4",
                "GM_TOOLBOX_1",
                "GM_TOOLBOX_2"
            };
        }
    }
    CRanomizerItems g_RandomizerItem;

    final class CRanomizerHulls : CRandomizer
    {
        string name() { return "hull"; }

        array<string>@ entities()
        {
            return
            {
                "GM_AGRUNT_S1",
                "GM_VOLT_S1",
                "GM_BULL_S1",
                "GM_BULL_S2",
                "GM_BULL_S3"
            };
        }
    }
    CRanomizerHulls g_RandomizerHull;

    final class CRanomizerBosss : CRandomizer
    {
        string name() { return "boss"; }

        array<string>@ entities()
        {
            return
            {
                "GM_KPIN_S1",
                "GM_TOR_S1",
                "GM_VOLT_S2",
                "GM_BGARG_S1"
            };
        }
    }
    CRanomizerBosss g_RandomizerBoss;

    final class CRanomizerNpcs : CRandomizer
    {
        string name() { return "npc"; }

        array<string>@ entities()
        {
            return
            {
                "GM_STUK_S1",
                "GM_STUK_S2",
                "GM_SLAVE_S1",
                "GM_SLAVE_S2",
                "GM_SLAVE_S3",
                "GM_SLAVE_S4",
                "GM_SLAVE_S5",
                "GM_SLAVE_S6",
                "GM_SLAVE_S7",
                "GM_SLAVE_S8",
                "GM_PITDRONE_S1",
                "GM_PITDRONE_S2",
                "GM_PITDRONE_S3",
                "GM_PITDRONE_S4",
                "GM_SNARK_S1",
                "GM_SNARK_S2",
                "GM_SNARK_S3",
                "GM_HOUND_S1",
                "GM_HOUND_S2",
                "GM_HOUND_S3",
                "GM_HOUND_S4",
                "GM_HOUND_S5",
                "GM_HOUND_S6",
                "GM_GONOME_S1",
                "GM_GONOME_S2",
                "GM_GONOME_S3",
                "GM_GONOME_S4",
                "GM_GONOME_S5",
                "GM_GONOME_S6",
                "GM_ZM_S1",
                "GM_ZM_S2",
                "GM_ZM_S3",
                "GM_ZM_S4",
                "GM_ZM_S5",
                "GM_ZM_S6",
                "GM_ZM_S7",
                "GM_ZM_S8",
                "GM_ZM_S9",
                "GM_ZM_S10",
                "GM_ZM_S11",
                "GM_ZM_S12",
                "GM_ZM_S13",
                "GM_ZM_S14",
                "GM_ZM_S15",
                "GM_ZM_S16",
                "GM_ZM_S17",
                "GM_ZM_S18",
                "GM_ZM_S19",
                "GM_ZM_S20",
                "GM_ZM_S21",
                "GM_ZM_S22",
                "GM_ZM_S23",
                "GM_ZM_S24",
                "GM_ZM_S25",
                "GM_ZM_S26",
                "GM_ZM_S27",
                "GM_ZM_S28",
                "GM_ZM_S29",
                "GM_ZM_S30",
                "GM_ZM_CS_1",
                "GM_ZM_CS_2",
                "GM_ZM_CS_3",
                "GM_ZM_CS_4"
            };
        }
    }
    CRanomizerNpcs g_RandomizerNpc;

    final class CRanomizerWaves : CRandomizer
    {
        string name() { return "wave"; }

        array<string>@ entities()
        {
            return
            {
                "GM_R_SLAVE_S1",
                "GM_R_SLAVE_S2",
                "GM_R_SLAVE_S3",
                "GM_R_SLAVE_S4",
                "GM_R_SLAVE_S5",
                "GM_R_SLAVE_S6",
                "GM_R_SLAVE_S7",
                "GM_R_SLAVE_S8",
                "GM_R_HOUND_S1",
                "GM_R_HOUND_S2",
                "GM_R_HOUND_S3",
                "GM_R_HOUND_S4",
                "GM_R_HOUND_S5",
                "GM_R_HOUND_S6",
                "GM_R_SNARK_S1",
                "GM_R_SNARK_S2",
                "GM_R_PITDRONE_S1",
                "GM_R_PITDRONE_S2",
                "GM_R_PITDRONE_S3",
                "GM_R_CRAB_S1",
                "GM_R_CRAB_S2",
                "GM_R_CRAB_S3",
                "GM_R_CRAB_S4",
                "GM_R_CRAB_S5",
                "GM_CHUM_S1",
                "GM_BABYVOLT_S1",
                "GM_BABYVOLT_S2"
            };
        }
    }
    CRanomizerWaves g_RandomizerWave;
    
    final class CRanomizerHullWaves : CRandomizer
    {
        string name() { return "hullwave"; }

        array<string>@ entities()
        {
            return
            {
                "GM_R_VOLT_S1",
                "GM_R_AGRUNT_S1",
                "GM_R_AGRUNT_S2",
                "GM_AGRUNT_TORTURED1",
                "GM_AGRUNT_TORTURED2",
                "GM_AGRUNT_TORTURED_A51",
                "GM_AGRUNT_TORTURED_A52",
                "GM_R_BULL_S1"
            };
        }
    }
    CRanomizerHullWaves g_RandomizerHullWave;
}
