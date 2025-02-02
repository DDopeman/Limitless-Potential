/*
    Logger. This is shit and should be removed on release though for now it's a bit useful
*/

CCVar@ g_LoggerSet = CCVar( "bts_rc_logger", "", "Toggle a logger level", ConCommandFlag::AdminOnly, @ToggleLogger );

enum LoggerLevels
{
    None = 0,
    Warning = ( 1 << 0 ),
    Debug = ( 1 << 1 ),
    Info = ( 1 << 2 ),
    Critical = ( 1 << 3 ),
    Error = ( 1 << 4 )
};

int LoggerLevel = LoggerLevels::None;

const string& LoggerType( int logger_level )
{
    switch( logger_level )
    {
        case LoggerLevels::Warning: return "WARNING";
        case LoggerLevels::Debug: return "DEBUG";
        case LoggerLevels::Info: return "INFO";
        case LoggerLevels::Critical: return "CRITICAL";
        case LoggerLevels::Error: return "ERROR";
        default: return "Unknown";
    }
}

void ToggleLogger( CCVar@ cvar, const string& in szOldValue, float flOldValue )
{
    const LoggerLevels value = LoggerLevels( g_LoggerSet.GetInt() );

    string snprintfm;

    const string mytype = LoggerType( value );

    if( mytype != "Unknown" )
    {
        if( ( LoggerLevel & value ) != 0 )
        {
            snprintf( snprintfm, "[CLogger] Disabled logger type \"%1\"\n", mytype );
            g_EngineFuncs.ServerPrint( snprintfm );
            LoggerLevel &= ~value;
        }
        else
        {
            snprintf( snprintfm, "[CLogger] Enabled logger type \"%1\"\n", mytype );
            g_EngineFuncs.ServerPrint( snprintfm );
            LoggerLevel |= value;
        }
    }
    else
    {
        snprintf( snprintfm, "[CLogger] Unknown Logger value \"%1\"\nUse one of:\n1 = Warning\n2 = Debug\n4 = Info\n8 = Critical\n16 = Error\n", g_LoggerSet.GetInt() );
        g_EngineFuncs.ServerPrint( snprintfm );
    }
    g_LoggerSet.SetInt( LoggerLevel );
}

class CLogger
{
    private string __member__;

    CLogger( const string &in member )
    {
        __member__ = member;
    }

    private void __printf__( int&in level, const string &in message, array<string>&in args )
    {
        if( ( LoggerLevel & level ) == 0 )
            return;

        string str;
        snprintf( str, "> [%1] [%2] %3\n", __member__, LoggerType( level ), message );

        for( uint ui = 0; ui < args.length(); ui++ )
        {
            uint index = str.Find( "{}", 0 );

            if( index != String::INVALID_INDEX ) {
                str = str.SubString( 0, index ) + args[ui] + str.SubString( index + 2 );
            }
        }

        g_EngineFuncs.ServerPrint( str );
    }

    void warn( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Warning, message, args );
    }

    void debug( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Debug, message, args );
    }

    void info( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Info, message, args );
    }

    void critical( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Critical, message, args );
    }

    void error( const string &in message, array<string>&in args = {} ) {
        this.__printf__( Error, message, args );
    }
}

CLogger@ g_Logger = CLogger( "Global" );
