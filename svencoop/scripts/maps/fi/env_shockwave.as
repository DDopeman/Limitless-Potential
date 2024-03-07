// Based on env_shockwave from Spirit of Half-Life, ported to AngelScript by FreeSlave

const int SF_SHOCKWAVE_CENTERED = 1;
const int SF_SHOCKWAVE_REPEATABLE = 2;

class env_shockwave : ScriptBaseEntity
{
	int m_iTime;
	int m_iRadius;
	int	m_iHeight;
	int m_iScrollRate;
	int m_iNoise;
	int m_iFrameRate;
	int m_iStartFrame;
	int m_iSpriteTexture;
	int m_cType = TE_BEAMCYLINDER;
	string m_iszPosition = "";

	void Precache()
	{
		m_iSpriteTexture = g_Game.PrecacheModel( string(pev.netname) );
	}
	void Spawn() { Precache(); }
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value = 0.0f )
	{
		Vector vecPos;
		if (m_iszPosition != '')
		{
			CBaseEntity@ ent = null;
			if (m_iszPosition == '!activator' || m_iszPosition == '*locus')
			{
				@ent = pActivator;
			}
			else if (m_iszPosition == '!caller')
			{
				@ent = pCaller;
			}
			else
			{
				@ent = g_EntityFuncs.FindEntityByTargetname( null, m_iszPosition );
			}
			if (ent !is null)
				vecPos = ent.pev.origin;
			else
				return;
		}
		else
			vecPos = pev.origin;
		if ((pev.spawnflags & SF_SHOCKWAVE_CENTERED) == 0)
			vecPos.z += m_iHeight;

		int type = m_cType;
		switch (type) {
		case TE_BEAMTORUS:
		case TE_BEAMDISK:
		case TE_BEAMCYLINDER:
			break;
		default:
			type = TE_BEAMCYLINDER;
			break;
		}

		NetworkMessage m(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecPos);
		m.WriteByte(type);
		m.WriteCoord(vecPos.x);
		m.WriteCoord(vecPos.y);
		m.WriteCoord(vecPos.z);
		m.WriteCoord(vecPos.x);
		m.WriteCoord(vecPos.y);
		m.WriteCoord(vecPos.z + m_iRadius);
		m.WriteShort(m_iSpriteTexture);
		m.WriteByte(m_iStartFrame);
		m.WriteByte(m_iFrameRate);
		m.WriteByte(m_iTime);
		m.WriteByte(m_iHeight);
		m.WriteByte(m_iNoise);
		m.WriteByte(int(pev.rendercolor.x));
		m.WriteByte(int(pev.rendercolor.y));
		m.WriteByte(int(pev.rendercolor.z));
		m.WriteByte(int(pev.renderamt));
		m.WriteByte(m_iScrollRate);
		m.End();
		
		if ((pev.spawnflags & SF_SHOCKWAVE_REPEATABLE) == 0)
		{
			self.SUB_Remove();
		}
	}
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "m_iTime")
		{
			m_iTime = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iRadius")
		{
			m_iRadius = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iHeight")
		{
			m_iHeight = atoi(szValue)/2;
			return true;
		}
		else if (szKey == "m_iScrollRate")
		{
			m_iScrollRate = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iNoise")
		{
			m_iNoise = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iFrameRate")
		{
			m_iFrameRate = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iStartFrame")
		{
			m_iStartFrame = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iszPosition")
		{
			m_iszPosition = szValue;
			return true;
		}
		else if (szKey == "m_cType")
		{
			m_cType = atoi(szValue);
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
};


