#include 'as_register'

namespace info_player_deathmatch_state
{
    void MapInit()
    {
        m_EntityFuncs.CustomEntity( 'info_player_deathmatch_state' );
    }

    void MapStart()
    {
        CBaseEntity@ pSpawns = null;

        while( ( @pSpawns = g_EntityFuncs.FindEntityByClassname( pSpawns, 'info_player_deathmatch' ) ) !is null )
        {
            CBaseEntity@ pState = g_EntityFuncs.CreateEntity
            (
                'info_player_deathmatch_state',
                {
                    { 'angles', pSpawns.pev.angles.ToString() },
                    /* Someday?
                    { 'master', string( pSpawns.m_sMaster ) },
                    */
                    { 'targetname', string( pSpawns.pev.targetname ) },
                    { 'spawnflags', string( pSpawns.pev.spawnflags ) }
                },
                true
            );

            if( pState !is null )
            {
                @pState.pev.owner = pSpawns.edict();
                g_EntityFuncs.SetOrigin( pState, pSpawns.pev.origin );
            }
        }
    }

    enum INFO_PLAYER_DEATHMATCH_STATE
    {
        IPDS_START_OFF = 2,
        IPDS_IS_NOT_ACTIVE = 0,
        IPDS_IS_ACTIVE = 1
    }

    class info_player_deathmatch_state : ScriptBaseEntity
    {
        private int m_iSpawnPointState = 1;

        private CBaseEntity@ pOwner
        {
            get const { return g_EntityFuncs.Instance( self.pev.owner ); }
        }

        void Spawn()
        {
		    self.pev.movetype = MOVETYPE_NONE;
		    self.pev.solid = SOLID_NOT;

            if( self.pev.SpawnFlagBitSet( IPDS_START_OFF ) )
            {
                m_iSpawnPointState = IPDS_IS_NOT_ACTIVE;
            }

		    SetThink( ThinkFunction( this.Think ) );
		    self.pev.nextthink = g_Engine.time + 0.5f;

            BaseClass.Spawn();
        }

        void Think()
        {
            if( pOwner is null )
            {
                g_EntityFuncs.Remove( self );
                return;
            }

            if( pOwner.pev.origin != self.pev.origin )
            {
                g_EntityFuncs.SetOrigin( self, pOwner.pev.origin );
            }

            if( pOwner.pev.angles != self.pev.angles )
            {
                self.pev.angles = pOwner.pev.angles;
            }

            m_CustomKeyValue.SetValue( pOwner, '$i_state', m_iSpawnPointState );

		    self.pev.nextthink = g_Engine.time + 0.1f;
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE UseType, float fdelay )
        {
            if( UseType == USE_ON )
            {
                m_iSpawnPointState = IPDS_IS_ACTIVE;
            }
            else if( UseType == USE_OFF )
            {
                m_iSpawnPointState = IPDS_IS_NOT_ACTIVE;
            }
            else if( m_iSpawnPointState == IPDS_IS_NOT_ACTIVE )
            {
                m_iSpawnPointState == IPDS_IS_ACTIVE;
            }
            else
            {
                m_iSpawnPointState == IPDS_IS_NOT_ACTIVE;
            }
        }
    }
}