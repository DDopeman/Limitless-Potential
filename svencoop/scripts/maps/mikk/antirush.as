#include 'as_register'

namespace antirush
{
    void MapInit()
    {
        m_EntityFuncs.CustomEntity( 'antirush' );

        g_Hooks.RegisterHook( Hooks::Player::ClientSay, @antirush::ClientSay );

        string m_szPath = 'scripts/maps/mikk/MSG/antirush/';

        m_FileSystem.GetKeyAndValue( m_szPath + 'msg_skull.txt', msg_skull, true );
        m_FileSystem.GetKeyAndValue( m_szPath + 'msg_percent.txt', msg_percent, true );
        m_FileSystem.GetKeyAndValue( m_szPath + 'msg_countdown.txt', msg_countdown, true );
    }

    dictionary lang, msg_skull, msg_percent, msg_countdown;

    HookReturnCode ClientSay( SayParameters@ pParams )
    {
        const CCommand@ args = pParams.GetArguments();
        CBasePlayer@ pPlayer = pParams.GetPlayer();

        if( args[0] == "/antirush" && pPlayer !is null )
        {
            if( pPlayer !is null && pPlayer.IsConnected() )
            {
                if( args[1] == 'on' || args[1] == 'off' )
                {
                    g_VoteAR.StartVote( pPlayer, args[1] );
                }
                else
                {
                    lang['english'] = '[Anti-Rush] This map doesn\'t supports anti-rush..';
                    lang['spanish'] = '[Anti-Rush] Este mapa no soporta anti-rush.';
                    lang['portuguese'] = '[Anti-Rush] Este mapa no soporta anti-rush.';
                    m_Language.PrintMessage( pPlayer, lang, ML_CHAT );
                }
            }
        }
        return HOOK_CONTINUE;
    }

    bool IsDisabledByVote = false;

    CVoteMenu g_VoteAR;

    final class CVoteMenu 
    {
        private int ivoteEnable = 0;
        private int ivoteDisable = 0;
        
        array<CTextMenu@> g_VoteMenu = 
        {
            null, null, null, null, null, null, null, null,
            null, null, null, null, null, null, null, null,
            null, null, null, null, null, null, null, null,
            null, null, null, null, null, null, null, null,
            null
        };

        void StartVote(CBasePlayer@ pCaller, string state )
        {
            if( pCaller !is null )
            {
                lang['english'] = '[Anti-Rush] Vote for toggle antirush started by ' + string( pCaller.pev.netname );
                lang['spanish'] = '[Anti-Rush] Vote for toggle antirush started by ' + string( pCaller.pev.netname );
                m_Language.PrintMessage( pCaller, lang, ML_CHAT, true );
            }

            for( int i = 1; i <= g_Engine.maxClients; i++ ) 
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                int eidx = pPlayer.entindex();

                if( g_VoteMenu[eidx] is null )
                {
                    @g_VoteMenu[eidx] = CTextMenu( TextMenuPlayerSlotCallback( this.MainCallback ) );

                    if( state == 'on' )
                    lang['english'] = '[Anti-Rush] Anti-Rush vote ';
                    lang['spanish'] = '[Anti-Rush] Anti-Rush vote ';
                    g_VoteMenu[eidx].SetTitle( m_Language.GetLanguage( pPlayer, lang ) );

                    g_VoteMenu[eidx].AddItem( 'Yes' );
                    g_VoteMenu[eidx].AddItem( 'No' );

                    g_VoteMenu[eidx].Register();
                    g_VoteMenu[eidx].Open( 10, 0, pPlayer );
                }
            }

            g_Scheduler.SetTimeout( @this, "Results", 10 + 3.0f );
        }

        void MainCallback( CTextMenu@ CMenu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
        {
            if( pItem !is null )
            {
                if( pItem.m_szName == "Yes" )
                {
                    ivoteEnable++;
                }
                else if( pItem.m_szName == "No" )
                {
                    ivoteDisable--;
                }
            }
        }

        void Results()
        {
            bool VoteIsNull = (ivoteEnable == 0 && ivoteDisable == 0);
            bool VoteIsTie = (ivoteEnable == ivoteDisable);
            bool VoteIsEnable = (ivoteEnable > ivoteDisable);
            bool VoteIsDisable = (ivoteDisable > ivoteEnable);

            if( VoteIsNull || VoteIsTie )
            {
                return;
            }

            //IsDisabledByVote = 1 * VoteIsEnable + 1 * VoteIsDisable;
        }
    }

    enum ANTIRUSH
    {
        AR_DISABLED = 1,
        AR_HIDE_MESSAGE = 2
    }

    class antirush : ScriptBaseEntity, ScriptBaseCustomEntity, LANGUAGE::ScriptBaseLanguages
    {
        private float m_fCurrentPercent;
        private float CurrentPercentage;
        private string m_iszCustomSound;
        private int milisecs;
        private int m_fCountdown;
        private int m_iNeedPercent = 66;
        private int iAlivePlayers;

        private const int m_iCounter()
        {
            return int( self.pev.health ) - int( self.pev.frags );
        }

        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            ExtraKeyValues( szKey, szValue );
            LangKeyValues( szKey, szValue );

            if( szKey == "percent" )
            {
                m_iNeedPercent = atoi( szValue );
            }
            else if( szKey == "delay_countdown" )
            {
                m_fCountdown = atoi( szValue );
            }
            else if( szKey == "sound" )
            {
                m_iszCustomSound = szValue;
            }
            else
            {
                return BaseClass.KeyValue( szKey, szValue );
            }
            return true;
        }

        void Precache()
        {
            if( !m_iszCustomSound.IsEmpty() )
            {
                g_SoundSystem.PrecacheSound( m_iszCustomSound );
                g_Game.PrecacheGeneric( "sound/" + m_iszCustomSound );
            }
            BaseClass.Precache();
        }

        void Spawn()
        {
            Precache();

            self.pev.movetype = MOVETYPE_NONE;
            self.pev.solid = SOLID_NOT;
            self.pev.effects |= EF_NODRAW;

            SetBBOX();

            SetThink( ThinkFunction( this.InternalThink ) );
            self.pev.nextthink = g_Engine.time + 0.1f;

            BaseClass.Spawn();
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE UseType, float delay )
        {
            self.pev.frags++;

            if( self.pev.frags >= self.pev.health )
            {
                self.pev.frags = 0;
                return;
            }

        }

        void InternalThink()
        {
            if( IsLockedByMaster() )
            {
                self.pev.nextthink = g_Engine.time + 0.1f;
                return;
            }

            CurrentPercentage = float( double( m_fCurrentPercent / ( iAlivePlayers == 0 ? 2 : iAlivePlayers ) * 100 ) );

            if( CurrentPercentage < m_iNeedPercent )
            {
                m_fCurrentPercent = 0;
                iAlivePlayers = 0;

                for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
                {
                    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                    if( pPlayer !is null )
                    {
                        int iAFKTime; m_CustomKeyValue.GetValue( pPlayer, '$i_afkmanager', iAFKTime );

                        if( pPlayer.IsAlive() && pPlayer.IsConnected() && iAFKTime < 120 )
                        {
                            ++iAlivePlayers;
                        }

                        if( pPlayer.Intersects( self ) )
                        {
                            if( spawnflag( AR_DISABLED ) )
                            {
                                ConditionsMet( true );
                                return;
                            }

                            if( m_iCounter() > 0 )
                            {
                                if( !spawnflag( AR_HIDE_MESSAGE ) )
                                {
                                    m_Language.PrintMessage( pPlayer, msg_skull, ML_HUD, false, { { '$count$', string( m_iCounter() ) } } );
                                }
                            }
                            else
                            {
                                if( pPlayer.IsAlive() && pPlayer.pev.flags & FL_NOTARGET == 0 )
                                {
                                    m_fCurrentPercent++;
                                }

                                if( !spawnflag( AR_HIDE_MESSAGE ) )
                                {
                                    m_Language.PrintMessage( pPlayer, msg_percent, ML_HUD, false, { { '$got$', string( int( CurrentPercentage ) ) }, { '$needed$', string( m_iNeedPercent ) } } );
                                }
                            }
                        }
                    }
                }
            }

            if( iAlivePlayers > 0 && CurrentPercentage >= m_iNeedPercent )
            {
                if( m_fCountdown > 0 || milisecs > 0 )
                {
                    if( !spawnflag( AR_HIDE_MESSAGE ) )
                    {
                        string iszTime = ( m_fCountdown < 10 ? '0' : '' ) + string( m_fCountdown ) + '.' + ( milisecs < 10 ? '0' : '' ) + string( milisecs );
                        m_Language.PrintMessage( null, msg_countdown, ML_HUD, true, { { '$count$', string( iszTime ) } } );
                    }

                    --milisecs;

                    if( milisecs <= 0 && m_fCountdown > 0 )
                    {
                        milisecs = 99;
                        --m_fCountdown;
                    }
                    self.pev.nextthink = 0.1f;
                    return;
                }

                ConditionsMet();
                return;
            }
            self.pev.nextthink = g_Engine.time + 0.1f;
        }

        void ConditionsMet( const bool &in bDisabled = false )
        {
            m_EntityFuncs.Trigger( string( self.pev.target ), self, self, USE_TOGGLE, ( bDisabled ? 0.0f : m_fDelay ) );

            if( !m_iszCustomSound.IsEmpty() && !bDisabled )
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, m_iszCustomSound, 1.0f, ATTN_NORM );

            g_EntityFuncs.Remove( self );
        }
    }
}