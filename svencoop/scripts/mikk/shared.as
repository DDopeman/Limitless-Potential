#include "Json"
#include "Utility"
#include "Language"
#include "PlayerFuncs"

MKShared Mikk;

class MKShared
{
    // prefix: "GetDiscord", "Discord"
    // description: Get discord server invite
    // body: Mikk
    string GetDiscord()
    {
        return 'https://discord.gg/THDKrgBEny';
    }
    
    // prefix: "GetContactInfo", "Contact"
    // description: Get contact info
    // body: Mikk
    string GetContactInfo()
    {
        return "\nDiscord Server: " + GetDiscord() + "Github: https://github.com/Mikk155";
    }

    MKJson Json;
    MKUtility Utility;
    MKLanguage Language;
    MKPlayerFuncs PlayerFuncs;

    MKShared()
    {
        Json = MKJson();
        Utility = MKUtility();
        Language = MKLanguage();
        PlayerFuncs = MKPlayerFuncs();
    }
}


// prefix: "atorgba", "RGBA"
// description: Return the given string as a 4D RGBA
RGBA atorgba( const string m_iszFrom )
{
    array<string> aSplit = m_iszFrom.Split( " " );

    while( aSplit.length() < 4 )
        aSplit.insertLast( '0' );

    return RGBA( atoui( aSplit[0] ), atoui( aSplit[1] ), atoui( aSplit[2] ), atoui( aSplit[3] ) );
}

// prefix: "atov", "StringToVector"
// description: Return the given string_t as a 3D Vector
Vector atov( string_t m_iszFrom )
{
    return atov( string( m_iszFrom ) );
}

// prefix: "atov", "StringToVector"
// description: Return the given string as a 3D Vector
Vector atov( const string m_iszFrom )
{
    Vector m_vTo;
    g_Utility.StringToVector( m_vTo, m_iszFrom );
    return m_vTo;
}

// prefix: "CKV", "CustomKeyValue"
// description: Return the value of the given CustomKeyValue, if m_iszValue is given it will update the value
string CustomKeyValue( CBaseEntity@ pEntity, const string&in m_iszKey, const string&in m_iszValue = String::EMPTY_STRING )
{
    if( pEntity is null )
        return String::INVALID_INDEX;

    if( m_iszValue != String::EMPTY_STRING )
        g_EntityFuncs.DispatchKeyValue( pEntity.edict(), m_iszKey, m_iszValue );

    return pEntity.GetCustomKeyvalues().GetKeyvalue( m_iszKey ).GetString();
}