MCustomKeyValues m_CustomKeyValue;

final class MCustomKeyValues
{
    bool HasKey( CBaseEntity@ pTarget, const string m_iszKey )
    {
        return ( pTarget !is null && pTarget.GetCustomKeyvalues().HasKeyvalue( m_iszKey ) );
    }

    void SetValue( CBaseEntity@ pTarget, const string m_iszKey, string m_iszValue )
    {
        if( pTarget is null or m_iszValue.IsEmpty() )
        {
            return;
        }

        g_EntityFuncs.DispatchKeyValue( pTarget.edict(), m_iszKey, m_iszValue );
    }

    string GetValue( CBaseEntity@ pTarget, const string m_iszKey )
    {
        string m_iszValue = pTarget.GetCustomKeyvalues().GetKeyvalue( m_iszKey ).GetString();

        if( pTarget is null or m_iszValue.IsEmpty() )
        {
            return '';
        }
        return m_iszValue;
    }

    void GetValue( CBaseEntity@ pTarget, const string m_iszKey, Vector &out m_VecValue )
    {
        m_VecValue = atov( GetValue( pTarget, m_iszKey ) );
    }

    void GetValue( CBaseEntity@ pTarget, const string m_iszKey, int &out m_iValue )
    {
        m_iValue = atoi( GetValue( pTarget, m_iszKey ) );
    }

    void GetValue( CBaseEntity@ pTarget, const string m_iszKey, string &out m_iszValue )
    {
        m_iszValue = GetValue( pTarget, m_iszKey );
    }

    void GetValue( CBaseEntity@ pTarget, const string m_iszKey, float &out m_fValue )
    {
        m_fValue = atof( GetValue( pTarget, m_iszKey ) );
    }
}