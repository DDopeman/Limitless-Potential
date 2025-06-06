//==========================================================================================================================================\\
//                                                                                                                                          \\
//                              Creative Commons Attribution-NonCommercial 4.0 International                                                \\
//                              https://creativecommons.org/licenses/by-nc/4.0/                                                             \\
//                                                                                                                                          \\
//   * You are free to:                                                                                                                     \\
//      * Copy and redistribute the material in any medium or format.                                                                       \\
//      * Remix, transform, and build upon the material.                                                                                    \\
//                                                                                                                                          \\
//   * Under the following terms:                                                                                                           \\
//      * You must give appropriate credit, provide a link to the license, and indicate if changes were made.                               \\
//      * You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.                   \\
//      * You may not use the material for commercial purposes.                                                                             \\
//      * You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.     \\
//                                                                                                                                          \\
//==========================================================================================================================================\\

namespace datashared
{
    CSharedDataPlugins@ GetDataClass()
    {
        if( !g_CustomEntityFuncs.IsCustomEntity( 'data_shared' ) )
        {
            g_CustomEntityFuncs.RegisterCustomEntity( 'datashared::CSharedDataPlugins', 'data_shared' );
        }

        CBaseEntity@ pDataEnt = g_EntityFuncs.FindEntityByClassname( null, 'data_shared' );

        if( pDataEnt is null )
        {
            @pDataEnt = g_EntityFuncs.Create( 'data_shared', g_vecZero, g_vecZero, false );
        }

        if( pDataEnt is null )
        {
            return null;
        }

        CSharedDataPlugins@ pDataClass = cast<CSharedDataPlugins@>( CastToScriptClass( pDataEnt ) );

        if( pDataClass is null )
        {
            return null;
        }

        return @pDataClass;
    }

    dictionary GetData( const string szPlugin = String::EMPTY_STRING )
    {
        string szLabel = ( szPlugin == String::EMPTY_STRING ? g_Module.GetModuleName() : szPlugin );

        CSharedDataPlugins@ pData = GetDataClass();

        if( pData !is null )
        {
            return dictionary( pData.PublicData[ szLabel ] );
        }

        return {};
    }

    dictionary SetData( dictionary pNewData, const string szPlugin = String::EMPTY_STRING )
    {
        string szLabel = ( szPlugin == String::EMPTY_STRING ? g_Module.GetModuleName() : szPlugin );

        CSharedDataPlugins@ pData = GetDataClass();
        dictionary gOldData = {};

        if( pData !is null )
        {
            gOldData = dictionary( pData.PublicData[ szLabel ] );
            pData.PublicData[ szLabel ] = pNewData;
        }

        return gOldData;
    }

    class CSharedDataPlugins : ScriptBaseEntity
    {
        dictionary PublicData;
        bool KeyValue( const string& in szKey, const string& in szValue ) { PublicData[ szKey ] = szValue; return true; }
    }
}
