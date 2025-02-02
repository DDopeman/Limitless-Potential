/*
    Author: Mikk
    Help Support: SoloKiller
    Idea: AraseFiq
*/

class CVoice
{
    private string __owner__;
    private string __type__;

    private array<string> voices;

    float cooldown = 0.0f;

    void push_back( const string& in sound )
    {
        g_SoundSystem.PrecacheSound( sound );

        this.voices.insertLast( sound );

#if DEVELOP
        g_VoiceResponse.m_Logger.info( "Push sound \"{}\" for \"{}\" as \"{}\"", { sound, this.__owner__, this.__type__ } );
#endif
    }

    CVoice( const string owner, const string type )
    {
        this.__type__ = type;
        this.__owner__ = owner;
    }

    bool PlaySound( CBaseEntity@ target, const float volume = 1.0, const int pitch = PITCH_NORM, const int flags = 0 )
    {
        if( target is null )
            return false;

        dictionary@ data = target.GetUserData();

        if( g_Engine.time < float( data[ this.__type__ ] ) )
            return false;

        if( this.voices.length() <= 0 )
        {
#if DEVELOP
            g_VoiceResponse.m_Logger.warn( "Tried to PlaySound on a empty CVoice list for \"{}\" at \"{}\"", { this.__type__, this.__owner__ } );
#endif

            return false;
        }

        const string sound = this.voices[ Math.RandomLong( 0, this.voices.length() - 1 ) ];

#if DEVELOP
        g_VoiceResponse.m_Logger.info( "PlaySound \"{}\" for {} as \"{}\" from \"{}\"", { sound, target.pev.netname, this.__type__, this.__owner__ } );
#endif

        g_SoundSystem.PlaySound( target.edict(), CHAN_VOICE, sound, volume, ATTN_NORM, flags, pitch, 0, true, target.GetOrigin() );

        data[ this.__type__] = g_Engine.time + this.cooldown;

        return true;
    }
}

class CVoices
{
    private string __name__;

    const string& name() const
    {
        return this.__name__;
    }

    CVoice@ takedamage;
    CVoice@ killed;

    CVoices( const string&in name )
    {
        __name__ = name;
        @takedamage = CVoice(this.__name__, "takedamage" );
        @killed = CVoice(this.__name__, "killed" );
    }
}

class CVoiceResponse
{
#if DEVELOP
    CLogger@ m_Logger = CLogger( "Voice Responses" );
#endif

    dictionary@ voices = {
        { "barney", null },
        { "scientist", null },
        { "construction", null },
        { "helmet", null }
    };

    CVoices@ opIndex( CBasePlayer@ player ) const
    {
        if( player is null )
            return null;

        const PM player_class = g_PlayerClass[ player, true ];

        switch( player_class )
        {
            case PM::BARNEY:
                return cast<CVoices@>( this.voices[ "barney" ] );

            case PM::CONSTRUCTION:
                return cast<CVoices@>( this.voices[ "construction" ] );

            case PM::HELMET:
                return cast<CVoices@>( this.voices[ "helmet" ] );

            case PM::CLSUIT:
                return cast<CVoices@>( this.voices[ "cleansuit" ] );

            case PM::SCIENTIST:
            case PM::BSCIENTIST:
            default:
                return cast<CVoices@>( this.voices[ "scientist" ] );
        }
    }
}

CVoiceResponse g_VoiceResponse;
