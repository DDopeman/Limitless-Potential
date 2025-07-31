/*
    Author: Giegue
    Modified by Mikk
*/

namespace func_bts_recharger
{
    enum sound_status
    {
        OFF = 0,
        ON = 1,
        LOOP = 2
    };

    class func_bts_recharger : ScriptBaseEntity
    {
        protected float m_recharge_time = -1;
        protected int m_customjuice = 30;
        protected float m_last_use;
        protected int m_juice = 30;
        protected int m_sound_status;
        protected float m_flSoundTime;
        protected string_t fire_on_empty;
        protected string_t fire_on_refilled;

        void Spawn()
        {
            self.pev.solid = SOLID_BSP;
            self.pev.movetype = MOVETYPE_PUSH;

            g_EntityFuncs.SetOrigin( self, self.pev.origin ); // set size and link into world
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
            g_EntityFuncs.SetModel( self, self.pev.model );

            m_juice = m_customjuice;
            self.pev.frame = 0; 
        }
        
        bool KeyValue( const string& in szKeyName, const string& in szValue )
        {
            if( "CustomJuice" == szKeyName )
            {
                m_customjuice = atoi( szValue );
            }
            else if( "CustomRechargeTime" == szKeyName )
            {
                m_recharge_time = atoi( szValue );
            }
            else if( "TriggerOnEmpty" == szKeyName )
            {
                fire_on_empty = string_t(szValue);
            }
            else if( "TriggerOnRecharged" == szKeyName )
            {
                fire_on_refilled = string_t(szValue);
            }
            else
            {
                return BaseClass.KeyValue( szKeyName, szValue );
            }
            return true;
        }

        int ObjectCaps()
        {
            return ( BaseClass.ObjectCaps() | FCAP_CONTINUOUS_USE ) & ~FCAP_ACROSS_TRANSITION;
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
        {
            if( activator is null || !activator.IsPlayer() || !activator.IsAlive() )
                return;

            CBasePlayer@ player = cast<CBasePlayer@>( activator );

            if( player is null )
                return;

            // if there is no juice left, turn it off
            if ( m_juice <= 0 )
            {
                self.pev.frame = 1;
                Off();
            }

            // if there is no juice left, make the deny noise
            if ( m_juice <= 0 || PM::HELMET != g_PlayerClass[ player, true ] )
            {
                if ( m_flSoundTime <= g_Engine.time )
                {
                    m_flSoundTime = g_Engine.time + 0.62;
                    g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/suitchargeno1.wav", 1.0, ATTN_NORM );
                }
                return;
            }

            self.pev.nextthink = g_Engine.time + 0.25;
            SetThink( ThinkFunction( Off ) );

            // Time to recharge yet?
            if ( m_last_use >= g_Engine.time )
                return;

            // Play the on sound or the looping charging sound
            if( m_sound_status == sound_status::OFF )
            {
                m_sound_status++;
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM );
                m_flSoundTime = 0.56 + g_Engine.time;
            }
            if ( m_sound_status == sound_status::ON && m_flSoundTime <= g_Engine.time )
            {
                m_sound_status++;
                g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "bts_rc/items/suitcharge1.wav", 1.0, ATTN_NORM );
            }

            // charge the player
            if ( activator.TakeArmor( 1, DMG_GENERIC ) )
            {
                m_juice--;

                if( m_juice <= 0 )
                {
                    g_EntityFuncs.FireTargets( fire_on_empty, activator, self, USE_TOGGLE );
                }
            }

            // govern the rate of charge
            m_last_use = g_Engine.time + 0.1;
        }

        void Recharge()
        {
            self.pev.frame = 0;
            m_juice = m_customjuice;
            g_EntityFuncs.FireTargets( fire_on_refilled, self, self, USE_TOGGLE );
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/suitchargeok1.wav", 1.0, ATTN_NORM );
            SetThink( null );
        }

        void Off()
        {
            if( m_juice <= 0 )
            {
                if( m_recharge_time > -1 )
                {
                    SetThink( ThinkFunction( Recharge ) );
                    self.pev.nextthink = g_Engine.time + m_recharge_time;
                }
                else
                {
                    SetThink( null );
                }
            }

            // Stop looping sound.
            if ( m_sound_status >= sound_status::LOOP )
            {
                g_SoundSystem.StopSound( self.edict(), CHAN_STATIC, "bts_rc/items/suitcharge1.wav" );
            }
            m_sound_status = sound_status::OFF;
        }
    }
}

#if DISCARDED
// Stupid shit idk why it doesn't move the charger owner entity to the location, it is not null.
namespace func_bts_recharger
{
    int register = LINK_ENTITY_TO_CLASS( "func_bts_recharger", "func_bts_recharger" );

    class func_bts_recharger : ScriptBaseEntity
    {
        private float m_lastuse;

        private dictionary @map_values = {};

        private CBaseEntity@ m_recharger
        {
            get const {
                return ( g_EntityFuncs.IsValidEntity( self.pev.owner ) ? g_EntityFuncs.Instance( self.pev.owner ) : null );
            }
            set {
                @self.pev.owner = ( value !is null ? value.edict() : null );
            }
        }

        void Spawn()
        {
            self.pev.solid = SOLID_BSP;
            self.pev.movetype = MOVETYPE_PUSH;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
            g_EntityFuncs.SetModel( self, self.pev.model );
            self.pev.frame = 0;

            @m_recharger = g_EntityFuncs.CreateEntity( "func_recharge", map_values, true );

            if( m_recharger !is null )
            {
                m_recharger.pev.solid = SOLID_NOT;
                m_recharger.pev.effects |= ( EF_NODRAW | EF_NODECALS );
                g_EntityFuncs.SetOrigin( m_recharger, self.pev.origin );
            }

            @map_values = null;

            SetThink( ThinkFunction( this.Think ) );
            self.pev.nextthink = g_Engine.time + 0.1;
        }

        bool KeyValue( const string& in szKeyName, const string& in szValue )
        {
            map_values[ szKeyName ] = szValue;
            return true;
        }

        int ObjectCaps()
        {
            return ( BaseClass.ObjectCaps() | FCAP_CONTINUOUS_USE ) & ~FCAP_ACROSS_TRANSITION;
        }

        void Think()
        {
            if( m_recharger is null )
            {
                self.pev.flags |= FL_KILLME;
                SetThink( null );
                return;
            }

            self.pev.frame = m_recharger.pev.frame;
            self.pev.nextthink = g_Engine.time + 0.1;
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE usetype, float value )
        {
            if( m_recharger is null || m_lastuse < g_Engine.time || activator is null || !activator.IsPlayer() || !activator.IsAlive() )
                return;

            CBasePlayer@ player = cast<CBasePlayer@>( activator );

            if( player is null )
                return;

            if( PM::HELMET == g_PlayerClass[ player, true ] )
                return;

            m_recharger.Use( activator, activator, USE_SET, 1 );
            self.pev.frame = m_recharger.pev.frame;
            m_lastuse = g_Engine.time + 0.3f;
        }
    }
}
#endif
