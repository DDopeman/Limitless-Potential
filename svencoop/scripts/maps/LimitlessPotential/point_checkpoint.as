#include "../mikk/as_register"
#include "../mikk/info_player_deathmatch_state"

namespace point_checkpoint
{
    dictionary activated, triggered, use;

    string m_szPath = 'scripts/maps/LimitlessPotential/MSG/point_checkpoint_';

    void MapInit()
    {
        m_FileSystem.GetKeyAndValue( m_szPath + 'use.txt', use, true );
        m_FileSystem.GetKeyAndValue( m_szPath + 'activated.txt', activated, true );
        m_FileSystem.GetKeyAndValue( m_szPath + 'triggered.txt', triggered, true );

        m_EntityFuncs.CustomEntity( 'point_checkpoint' );
        g_Game.PrecacheOther( 'point_checkpoint' );
    }

    enum POINT_CHECKPOINT
    {
        PC_ONLY_TRIGGER = 1,
        PC_MONSTERS_CAN = 2,
        PC_START_OFF = 4,
        PC_ONLY_IOS = 8,
        PC_NO_CLIENTS = 16,
        PC_NO_MESSAGE = 32,
        PC_SPAWN_SELF_ORIGIN = 64,
        PC_FORCE_ANGLES = 128,
        PC_SPAWN_PLAYER_ORIGIN = 256
    }

    class point_checkpoint : ScriptBaseAnimating, ScriptBaseCustomEntity
    {
        private string m_iszDefaultModel = 'models/limitlesspotential/mk_logo_purple.mdl';
        private string m_iszCustomMusic = '../media/valve.mp3';
        private string m_iszPlayersTarget;
        private string m_iszTriggerOnTouch;
        private string m_iszTriggerOnActivate;
        private string m_iszTriggerOnEnd;
        private string m_iszTriggerOnSpawn;

        private float m_fDelayBetweenPlayers = 0.5f;
        private float m_fDelayBeforeStart = 3.0f;

        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            ExtraKeyValues( szKey, szValue );

            if( szKey == "m_fDelayBetweenPlayers" )
            {
                m_fDelayBetweenPlayers = atof( szValue );
            }
            else if( szKey == "m_fDelayBeforeStart" )
            {
                m_fDelayBeforeStart = atof( szValue );
            }
            else if( szKey == "m_iszCustomMusic" )
            {
                m_iszCustomMusic = szValue;
            }
            else if( szKey == "m_iszPlayersTarget" )
            {
                m_iszPlayersTarget = szValue;
            }
            else if( szKey == "m_iszTriggerOnActivate" )
            {
                m_iszTriggerOnActivate = szValue;
            }
            else if( szKey == "m_iszTriggerOnTouch" )
            {
                m_iszTriggerOnTouch = szValue;
            }
            else if( szKey == "m_iszTriggerOnEnd" )
            {
                m_iszTriggerOnEnd = szValue;
            }
            else if( szKey == "m_iszTriggerOnSpawn" )
            {
                m_iszTriggerOnSpawn = szValue;
            }
            return BaseClass.KeyValue( szKey, szValue );
        }

        void Precache()
        {
            CustomModelPrecache( m_iszDefaultModel );
		    g_SoundSystem.PrecacheSound( m_iszCustomMusic );
            BaseClass.Precache();
        }

        void Spawn()
        {
            Precache();

		    self.pev.movetype = MOVETYPE_NONE;
		    self.pev.solid = SOLID_TRIGGER;

            if( SetBBOX() == SetBounds_NONE )
            {
                g_EntityFuncs.SetSize( self.pev, Vector( -32, -32, -32 ), Vector( 32, 32, 32 ) );
            }

            CustomModelSet( m_iszDefaultModel );

            self.pev.framerate = ( self.pev.framerate <= 0.0 ? 1.0f : self.pev.framerate );
            self.pev.sequence = 0;
            self.pev.frame = 0;
            self.ResetSequenceInfo();

		    SetThink( ThinkFunction( this.Think ) );
		    self.pev.nextthink = g_Engine.time + 0.1f;

            BaseClass.Spawn();
        }

        void Think()
        {
		    self.StudioFrameAdvance();
		    self.pev.nextthink = g_Engine.time + 0.1f;
        }

        void Touch( CBaseEntity@ pOther )
        {
            if( pOther is null )
                return;

            m_EntityFuncs.Trigger( m_iszTriggerOnTouch, pOther, self, itout( m_iUseType, m_UTLatest ), m_fDelay );

            if( IsLockedByMaster()
            or spawnflag( PC_START_OFF )
            or spawnflag( PC_ONLY_TRIGGER )
            or spawnflag( PC_NO_CLIENTS ) && pOther.IsPlayer()
            or spawnflag( PC_ONLY_IOS ) && !self.FVisibleFromPos( self.pev.origin, pOther.Center() )
            ){ return; }

            if( pOther.IsPlayer() )
            {
                m_Language.PrintMessage( cast<CBasePlayer@>( pOther ), use, ML_BIND, false, { { '$key$', '+use' } } );

                if( pOther.pev.button & IN_USE == 0 )
                    return;

                Activate( pOther, string( pOther.pev.netname ) );
            }
            else if( spawnflag( PC_MONSTERS_CAN ) && pOther.IsMonster() && pOther.Classify() == CLASS_PLAYER_ALLY )
            {
                Activate( pOther, string( cast<CBaseMonster@>( pOther ).m_FormattedName ) );
            }
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE UseType, float fdelay )
        {
            if( IsLockedByMaster() )
            {
                return;
            }

            m_UTLatest = UseType;

            if( spawnflag( PC_START_OFF ) )
            {
                self.pev.spawnflags &= ~PC_START_OFF;
                m_EntityFuncs.Trigger( m_iszTriggerOnSpawn, pActivator, self, itout( m_iUseType, m_UTLatest ), m_fDelay );
            }
            else
            {
                Activate( pActivator, '' );
            }
        }

        void Activate( CBaseEntity@ pActivator, string &in m_iszActivator )
        {
            self.pev.spawnflags |= PC_START_OFF;

		    SetThink( ThinkFunction( this.FadeThink ) );
		    self.pev.nextthink = g_Engine.time + 0.1f;

            if( !spawnflag( PC_NO_MESSAGE ) )
            {
                m_Language.PrintMessage( null, ( m_iszActivator != '' ?  activated : triggered ), ML_CHAT, true, { { '$name$', m_iszActivator } } );
            }

			g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, m_iszCustomMusic, 1.0f, ATTN_NONE );

            dictionary pPlayers;

            for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                if( pPlayer !is null && !pPlayer.IsAlive() )
                {
                    pPlayers[ int( pPlayer.entindex() )] = float( pPlayer.pev.frags );
                }
            }

            g_Scheduler.SetTimeout( @this, 'StartSpawning', m_fDelayBeforeStart, @pPlayers );

            m_EntityFuncs.Trigger( m_iszTriggerOnActivate, pActivator, self, itout( m_iUseType, m_UTLatest ), m_fDelay );
        }

        void FadeThink()
        {
            if( self.pev.rendermode == kRenderNormal )
            {
                self.pev.rendermode = kRenderTransAlpha;

                if( self.pev.renderamt == 0 )
                {
                    self.pev.renderamt = 255;
                }
            }

            if( self.pev.renderamt > 0 )
            {
                self.StudioFrameAdvance();

                self.pev.renderamt -= 30;

                if ( self.pev.renderamt < 0 )
                {
                    self.pev.renderamt = 0;
                }

                self.pev.nextthink = g_Engine.time + 0.1f;
            }
            else
            {
			    self.pev.effects |= EF_NODRAW;
            }
        }

        void StartSpawning( dictionary@ pPlayers )
        {
            if( pPlayers is null )
                return;

            float GreaterScore = -9999;
            int GreaterIndex;

            const array<string> eidx = pPlayers.getKeys();

            if( eidx.length() > 0 )
            {
                for( uint i = 0; i < eidx.length(); i++ )
                {
                    if( float( pPlayers[ atoi( eidx[i] ) ] ) > GreaterScore )
                    {
                        GreaterIndex = atoi( eidx[i] );
                        pPlayers.delete( atoi( eidx[i] ) );
                    }
                }
            }
            else
            {
                m_EntityFuncs.Trigger( m_iszTriggerOnEnd, self, self, itout( m_iUseType, m_UTLatest ), m_fDelay );
                g_EntityFuncs.Remove( self );
                return;
            }

            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( GreaterIndex );

            if( IsFilteredByName( pPlayer ) )
            {
                g_Scheduler.SetTimeout( @this, 'StartSpawning', 0.0f, @pPlayers );
            }
            else
            {
                if( spawnflag( PC_SPAWN_SELF_ORIGIN ) )
                {
                    Revive( pPlayer, self.pev.origin, self.pev.angles );
                }
                else
                {
                    dictionary ValidSpawnPoints;

                    CBaseEntity@ pSpawns = null;

                    while( ( @pSpawns = g_EntityFuncs.FindEntityByClassname( pSpawns, 'info_player_deathmatch' ) ) !is null )
                    {
                        int State;

                        m_CustomKeyValue.GetValue( pSpawns, '$i_state', State );

                        if( State == info_player_deathmatch_state::IPDS_IS_ACTIVE )
                        {
                            ValidSpawnPoints[ pSpawns.pev.origin.ToString() ] = pSpawns.pev.angles.ToString();
                        }
                    }

                    const array<string> ValidSpawnOrigin = ValidSpawnPoints.getKeys();

                    if( ValidSpawnOrigin.length() > 0 )
                    {
                        int GetRandom = Math.RandomLong( 0, ValidSpawnOrigin.length()-1 );

                        Vector VecPos = atov( string( ValidSpawnOrigin[ GetRandom ] ) );

                        if( VecPos != g_vecZero )
                        {
                            Revive( pPlayer, VecPos, atov( string( ValidSpawnPoints[ ValidSpawnOrigin[ GetRandom ] ] ) ) );
                        }
                        else
                        {
                            m_Debug.Server( '[point_checkpoint] Failed to instantiate a valid spawnpoint\'s vector.', DEBUG_LEVEL_IMPORTANT );
                            Revive( pPlayer, self.pev.origin, self.pev.angles );
                        }
                    }
                    else
                    {
                        m_Debug.Server( '[point_checkpoint] WARNING! No valid spawnpoints. using self->origin.', DEBUG_LEVEL_IMPORTANT );
                        Revive( pPlayer, self.pev.origin, self.pev.angles );
                    }
                }
                g_Scheduler.SetTimeout( @this, 'StartSpawning', ( m_fDelayBetweenPlayers > 0.1f ? m_fDelayBetweenPlayers : 0.5f ), @pPlayers );
            }
        }

        void Revive( CBasePlayer@ pPlayer, Vector VecPos, Vector VecAng )
        {
            if( !spawnflag( PC_SPAWN_PLAYER_ORIGIN ) && pPlayer.GetObserver().HasCorpse() )
            {
                pPlayer.GetObserver().RemoveDeadBody();
            }
            else
            {
                g_EntityFuncs.SetOrigin( pPlayer, VecPos );
            }

            if( spawnflag( PC_FORCE_ANGLES ) )
            {
                pPlayer.pev.angles = VecAng;
            }

            if( m_iszNewTargetName != '' )
            {
                pPlayer.pev.targetname = m_iszNewTargetName;
            }

            pPlayer.Revive();

            m_Effect.quake( pPlayer.pev.origin, 1 );

            m_EntityFuncs.Trigger( m_iszPlayersTarget, pPlayer, self, itout( m_iUseType, m_UTLatest ), m_fDelay );
        }
    }
}