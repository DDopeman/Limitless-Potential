#include '../mikk/as_register'

namespace entities_state
{
    void increase_state( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE UseType, float delay )
    {
        m_iCurrentState++;
        StateWritte( m_iCurrentState );
    }

    void MapInit()
    {
        StateRead();

        g_Hooks.RegisterHook( Hooks::Entity::KeyValue, @KeyValue );

        m_ScriptInfo.SetScriptInfo
        (
            {
                { "script", "entities_state" },
                { "description", "Allow to configurate entitie\'s state based on a saved state" }
            }
        );
    }

    HookReturnCode KeyValue( CBaseEntity@ pEntity, const string& in pszKey, const string& in pszValue, const string& in szClassName, META_RES& out meta_result )
    {
        if( pszKey == '$i_entity_state' && atoi( pszValue ) > 0  )
        {
            eidx.insertLast( pEntity.entindex() );
        }
        return HOOK_CONTINUE;
    }

    array<int> eidx;

    void MapStart()
    {
        MatchEntities();
    }

    void MatchEntities()
    {
        if( eidx.length() > 0 )
        {
            CBaseEntity@ pEntity = null;

            for( uint i = 0; i < eidx.length(); i++ )
            {
                if( ( @pEntity = g_EntityFuncs.Instance( eidx[i] ) ) !is null )
                {
                    int iState;
                    m_CustomKeyValue.GetValue( pEntity, '$i_entity_state', iState );

                    if( iState > 0 && iState == m_iCurrentState )
                    {
                        int iStateAction;
                        m_CustomKeyValue.GetValue( pEntity, '$i_entity_state_action', iStateAction );

                        if( iStateAction == ES_USE_ON )
                        {
                            pEntity.Use( null, null, USE_ON, 0.0f );
                        }
                        else if( iStateAction == ES_USE_OFF )
                        {
                            pEntity.Use( null, null, USE_OFF, 0.0f );
                        }
                        else if( iStateAction == ES_USE_KILL )
                        {
                            g_EntityFuncs.Remove( pEntity );
                        }
                        else if( iStateAction == ES_KILLED )
                        {
                            pEntity.Killed( null, GIB_ALWAYS );
                        }
                    }
                }
            }
        }
    }

    enum ENTITIES_STATE
    {
        ES_NONE = 0,
        ES_USE_ON = 1,
        ES_USE_OFF = 2,
        ES_USE_KILL = 3,
        ES_KILLED = 4
    }

    int m_iCurrentState = ES_NONE;

    void StateRead()
    {
        File@ pFile = g_FileSystem.OpenFile( 'scripts/maps/store/entities_state.txt', OpenFile::READ );

        if( pFile !is null && pFile.IsOpen() )
        {
            string line;
            while( !pFile.EOFReached() )
            {
                pFile.ReadLine( line );

                if( line.Length() > 0 )
                {
                    m_Debug.Server( 'line ' + string( line ) );
                    array<string> pArguments = line.Split( ',' );

                    m_Debug.Server( 'pArguments.length() ' + string( pArguments.length() ) );
                    if( pArguments.length() == 2 )
                    {
                        m_Debug.Server( 'pArguments[1] ' + string( pArguments[0] ) );
                        m_Debug.Server( 'pArguments[2] ' + string( pArguments[1] ) );
                        m_iCurrentState = atoi( pArguments[1] );

                        if( pArguments[0] != string( g_Engine.mapname ) )
                        {
                            StateWritte( 0 );
                        }
                    }
                }
            }
            pFile.Close();
        }
    }

    void StateWritte( const int NewState )
    {
        File@ pFile = g_FileSystem.OpenFile( 'scripts/maps/store/entities_state.txt', OpenFile::WRITE );

        if( pFile !is null && pFile.IsOpen() )
        {
            string line = string( g_Engine.mapname ) + ',' + string( NewState );
            pFile.Write( line );
            pFile.Close();
        }
    }
}