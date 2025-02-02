/*
    Author: Mikk
    Original Code: Gaftherman
    Original Idea: EdgarBarney (Trinity Rendering)
*/

namespace env_bloodpuddle
{
#if DEVELOP
    CLogger@ m_Logger = CLogger( "Blood Puddle" );
#endif

    enum BLOOD_STATE
    {
        IDLE = 0,
        EXPANDING,
        EXPANDED
    };

    class env_bloodpuddle : ScriptBaseAnimating
    {
        BLOOD_STATE state = BLOOD_STATE::IDLE;
        private float last_time = 0;
        private uint uisize = 0;

        void Spawn()
        {
            self.pev.movetype = MOVETYPE_TOSS;
            self.pev.solid = SOLID_NOT;
            g_EntityFuncs.SetSize( self.pev, Vector( -12, -12, -1 ), Vector( 12, 12, 1 ) );

#if DISCARDED
            uisize = CONST_BLOODPUDDLE_SND.length();

            if( uisize > 0 )
            {
                self.pev.solid = SOLID_BBOX;
                SetTouch( TouchFunction( this.touch ) );
            }
#endif
            SetThink( ThinkFunction( this.think ) );

            g_EntityFuncs.SetModel( self, "models/mikk/misc/bloodpuddle.mdl" );

            switch( state )
            {
                case BLOOD_STATE::EXPANDED:
                {
                    self.pev.renderamt = 255;
                    self.pev.rendermode = kRenderTransTexture;
                    self.pev.sequence = 0;
#if DEVELOP
                    m_Logger.info( "Created for \"{}\" at \"{}\" with scale of \"{}\"", { self.pev.owner.vars.classname, self.pev.origin.ToString(), self.pev.scale } );
#endif
                    break;
                }

                case BLOOD_STATE::IDLE:
                default:
                {
                    self.pev.sequence = 1;
                    self.pev.framerate = Math.RandomFloat( 0.3, 0.6 );  
                    self.pev.frame = 0;
#if DEVELOP
                    m_Logger.info( "Created for \"{}\" at \"{}\" with scale of \"{}\" at framerate of \"{}\"", { self.pev.owner.vars.classname, self.pev.origin.ToString(), self.pev.scale, self.pev.framerate } );
#endif
                    break;
                }
            }

            self.ResetSequenceInfo();
        }

        void think()
        {
            switch( state )
            {
                case BLOOD_STATE::EXPANDED:
                {
                    if( self.pev.renderamt <= 1 )
                    {
                        self.pev.flags |= FL_KILLME;
                        return;
                    }

                    self.pev.renderamt -= 1;
                    self.pev.nextthink = g_Engine.time + 0.1;
                    break;
                }

                case BLOOD_STATE::IDLE:
                case BLOOD_STATE::EXPANDING:
                default:
                {
                    if( g_EntityFuncs.IsValidEntity( self.pev.owner ) )
                    {
                        self.StudioFrameAdvance();
                    }
                    else
                    {
                        self.pev.renderamt = 255;
                        self.pev.rendermode = kRenderTransTexture;
                        state = BLOOD_STATE::EXPANDED;
                    }
                    self.pev.nextthink = g_Engine.time + 0.1;
                    break;
                }
            }
        }

#if DISCARDED
        void touch( CBaseEntity@ other )
        {
            if( g_Engine.time > last_time && other !is null && other.IsPlayer() )
            {
                g_SoundSystem.PlaySound( self.edict(), CHAN_BODY, CONST_BLOODPUDDLE_SND[ Math.RandomLong( 0, uisize - 1 ) ], 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, self.GetOrigin() );

                last_time = g_Engine.time + 0.3f;
            }
        }
#endif
    }
}
