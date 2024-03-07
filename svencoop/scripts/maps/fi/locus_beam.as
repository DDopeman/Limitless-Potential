// Based on locus_beam from Spirit of Half-Life, ported to AngelScript by FreeSlave

const int SF_LBEAM_SHADEIN = 128;
const int SF_LBEAM_SHADEOUT = 256;
const int SF_LBEAM_SOLID = 512;
const int SF_LBEAM_SINE = 1024;

class calc_position : ScriptBaseEntity
{
	void Spawn()
	{
		g_Utility.StringToVector(pev.velocity, pev.message);
	}
}

bool CalcPosition(CBaseEntity @pActivator, CBaseEntity @pCaller, const string& in position, Vector &out outVec)
{
	CBaseEntity@ ent = null;
	if (position == '!activator' || position == '*locus')
	{
		@ent = pActivator;
	}
	else if (position == '!caller')
	{
		@ent = pCaller;
	}
	else
	{
		@ent = g_EntityFuncs.FindEntityByTargetname( null, position );
	}
	if (ent !is null)
	{
		if (ent.GetClassname() == "calc_position")
		{
			CBaseEntity@ subject = g_EntityFuncs.FindEntityByTargetname( null, ent.pev.netname );
			if (subject !is null)
			{
				Vector vecPosition;
				Vector vecOffest = ent.pev.velocity;
				switch(ent.pev.impulse)
				{
				case 1:
					vecPosition = subject.EyePosition();
					break;
				case 2:
					vecPosition = subject.pev.origin + Vector(
						(subject.pev.mins.x + subject.pev.maxs.x)/2,
						(subject.pev.mins.y + subject.pev.maxs.y)/2,
						subject.pev.maxs.z
					);
					break;
				case 3:
					vecPosition = subject.Center();
					break;
				default:
					vecPosition = subject.pev.origin;
					break;
				}
				outVec = vecPosition + vecOffest;
				return true;
			}
			return false;
		}
		else
			outVec = ent.pev.origin;
		return true;
	}
	else
		return false;
}

void RemoveEHandle(EHandle handle)
{
	CBaseEntity@ pEntity = handle.GetEntity();
	if (pEntity !is null)
	{
		pEntity.SUB_Remove();
	}
}

class locus_beam : ScriptBaseEntity
{
	string m_iszSprite;
	string m_iszTargetName;
	string m_iszStart;
	string m_iszEnd;
	int		m_iWidth;
	int		m_iDistortion;
	float	m_fFrame;
	int		m_iScrollRate;
	float	m_fDuration;
	float	m_fDamage;
	int		m_iDamageType;
	int		m_iFlags;
	int	m_iStartAttachment;
	int	m_iEndAttachment;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "m_iszSprite")
		{
			m_iszSprite = szValue;
			return true;
		}
		else if (szKey == "m_iszTargetName")
		{
			m_iszTargetName = szValue;
			return true;
		}
		else if (szKey == "m_iszStart")
		{
			m_iszStart = szValue;
			return true;
		}
		else if (szKey == "m_iszEnd")
		{
			m_iszEnd = szValue;
			return true;
		}
		else if (szKey == "m_iWidth")
		{
			m_iWidth = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iDistortion")
		{
			m_iDistortion = atoi(szValue);
			return true;
		}
		else if (szKey == "m_fFrame")
		{
			m_fFrame = atof(szValue);
			return true;
		}
		else if (szKey == "m_iScrollRate")
		{
			m_iScrollRate = atoi(szValue);
			return true;
		}
		else if (szKey == "m_fDuration")
		{
			m_fDuration = atof(szValue);
			return true;
		}
		else if (szKey == "m_fDamage")
		{
			m_fDamage = atof(szValue);
			return true;
		}
		else if (szKey == "m_iDamageType")
		{
			m_iDamageType = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iStartAttachment")
		{
			m_iStartAttachment = atoi(szValue);
			if (m_iStartAttachment > 4 || m_iStartAttachment < 0)
				m_iStartAttachment = 0;
			return true;
		}
		else if (szKey == "m_iEndAttachment")
		{
			m_iEndAttachment = atoi(szValue);
			if (m_iEndAttachment > 4 || m_iEndAttachment < 0)
				m_iEndAttachment = 0;
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	void Spawn()
	{
		Precache();
		m_iFlags = 0;
		if ((pev.spawnflags & SF_LBEAM_SHADEIN) != 0)
			m_iFlags |= BEAM_FSHADEIN;
		if ((pev.spawnflags & SF_LBEAM_SHADEOUT) != 0)
			m_iFlags |= BEAM_FSHADEOUT;
		if ((pev.spawnflags & SF_LBEAM_SINE) != 0)
			m_iFlags |= BEAM_FSINE;
		if ((pev.spawnflags & SF_LBEAM_SOLID) != 0)
			m_iFlags |= BEAM_FSOLID;
	}
	void Precache()
	{
		g_Game.PrecacheModel( m_iszSprite );
	}
	void Use(CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float value)
	{
		CBaseEntity @pStartEnt = null;
		CBaseEntity @pEndEnt = null;
		Vector vecStartPos;
		Vector vecEndPos;
		CBeam @pBeam = null;

		switch(pev.impulse)
		{
		case 0: // ents
			@pStartEnt = g_EntityFuncs.FindEntityByTargetname(null, m_iszStart);
			@pEndEnt = g_EntityFuncs.FindEntityByTargetname(null, m_iszEnd);

			if (@pStartEnt is null || pEndEnt is null)
				return;
			@pBeam = g_EntityFuncs.CreateBeam( m_iszSprite, m_iWidth );
			if (m_iStartAttachment > 0)
				pBeam.SetStartAttachment(m_iStartAttachment);
			if (m_iEndAttachment > 0)
				pBeam.SetEndAttachment(m_iEndAttachment);
			pBeam.EntsInit( pStartEnt, pEndEnt );
			break;

		case 1: // pointent
			if (!CalcPosition(pActivator, pCaller, m_iszStart, vecStartPos))
				return;

			@pEndEnt = g_EntityFuncs.FindEntityByTargetname(null, m_iszEnd);

			if (pEndEnt is null)
				return;
			@pBeam = g_EntityFuncs.CreateBeam( m_iszSprite, m_iWidth );
			pBeam.SetEndAttachment(m_iEndAttachment);
			pBeam.PointEntInit( vecStartPos, pEndEnt.entindex() );
			break;
		case 2: // points
			if (!CalcPosition( pActivator, pCaller, m_iszStart, vecStartPos ) || !CalcPosition( pActivator, pCaller, m_iszEnd, vecEndPos )) {
				return;
			}
			@pBeam = g_EntityFuncs.CreateBeam( m_iszSprite, m_iWidth );
			pBeam.PointsInit( vecStartPos, vecEndPos );
			break;
		}
		pBeam.SetColor( int(pev.rendercolor.x), int(pev.rendercolor.y), int(pev.rendercolor.z) );
		pBeam.SetBrightness( int(pev.renderamt) );
		pBeam.SetNoise( m_iDistortion );
		pBeam.SetFrame( m_fFrame );
		pBeam.SetScrollRate( m_iScrollRate );
		pBeam.SetFlags( m_iFlags );
		pBeam.pev.dmg = m_fDamage;
		pBeam.pev.frags = m_iDamageType;
		pBeam.pev.spawnflags |= pev.spawnflags & (SF_BEAM_RING |
				SF_BEAM_SPARKSTART | SF_BEAM_SPARKEND | SF_BEAM_DECALS);
		pBeam.pev.targetname = m_iszTargetName;
		if (m_fDuration > 0)
		{
			g_Scheduler.SetTimeout( "RemoveEHandle", m_fDuration, EHandle(pBeam) );
		}

		if (pev.target != '')
		{
			g_EntityFuncs.FireTargets( pev.target, pBeam, self, USE_TOGGLE );
		}
	}
};
