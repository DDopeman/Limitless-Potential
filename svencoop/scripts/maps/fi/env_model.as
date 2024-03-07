// Based on env_model from Spirit of Half-Life, ported to AngelScript by FreeSlave
// Sven Co-op already has entity named env_model, so we have to rename it to env_model_spirit

const int SF_ENVMODEL_OFF = 1;
const int SF_ENVMODEL_DROPTOFLOOR = 2;
const int SF_ENVMODEL_SOLID = 4;

class env_model_spirit : ScriptBaseAnimating
{
	string m_iszSequence_On;
	string m_iszSequence_Off;
	int m_iAction_On;
	int m_iAction_Off;
	float m_flFramerate_On;
	float m_flFramerate_Off;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "m_iszSequence_On")
		{
			m_iszSequence_On = szValue;
			return true;
		}
		else if (szKey == "m_iszSequence_Off")
		{
			m_iszSequence_Off = szValue;
			return true;
		}
		else if (szKey == "m_iAction_On")
		{
			m_iAction_On = atoi(szValue);
			return true;
		}
		else if (szKey == "m_iAction_Off")
		{
			m_iAction_Off = atoi(szValue);
			return true;
		}
		else if (szKey == "m_flFramerate_On")
		{
			m_flFramerate_On = atof(szValue);
			return true;
		}
		else if (szKey == "m_flFramerate_Off")
		{
			m_flFramerate_Off = atof(szValue);
			return true;
		}
		else
		{
			return BaseClass.KeyValue( szKey, szValue );
		}
	}
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel(self, pev.model);
		self.SetOrigin(pev.origin);

		if ((pev.spawnflags & SF_ENVMODEL_SOLID) != 0)
		{
			pev.solid = SOLID_SLIDEBOX;
			g_EntityFuncs.SetSize(pev, Vector(-10, -10, -10), Vector(10, 10, 10));
		}

		if ((pev.spawnflags & SF_ENVMODEL_DROPTOFLOOR) != 0)
		{
			pev.origin.z += 1;
			g_EngineFuncs.DropToFloor( self.edict() );
		}

		self.SetBoneController( 0, 0 );
		self.SetBoneController( 1, 0 );

		const float startingFrame = pev.frame;
		SetSequence();
		if (startingFrame < 0)
			pev.frame = Math.RandomLong(0, 255);
		else
			pev.frame = startingFrame;

		pev.nextthink = g_Engine.time + 0.1;
	}
	void Precache()
	{
		g_Game.PrecacheModel(pev.model);
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if (self.ShouldToggle(useType, (pev.spawnflags & SF_ENVMODEL_OFF) == 0))
		{
			if ((pev.spawnflags & SF_ENVMODEL_OFF) != 0)
				pev.spawnflags &= ~SF_ENVMODEL_OFF;
			else
				pev.spawnflags |= SF_ENVMODEL_OFF;

			SetSequence();
			pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void Think()
	{
		bool hasNegativeFramerate = false;
		if ((pev.spawnflags & SF_ENVMODEL_OFF) != 0)
		{
			hasNegativeFramerate = m_flFramerate_Off < 0;
		}
		else
		{
			hasNegativeFramerate = m_flFramerate_On < 0;
		}

		if (hasNegativeFramerate)
		{
			pev.framerate = 0;
			return;
		}
		int iTemp;

		self.StudioFrameAdvance();

		if (self.m_fSequenceFinished && !self.m_fSequenceLoops)
		{
			if ((pev.spawnflags & SF_ENVMODEL_OFF) != 0)
				iTemp = m_iAction_Off;
			else
				iTemp = m_iAction_On;

			switch (iTemp)
			{
			case 2: // change state
				if ((pev.spawnflags & SF_ENVMODEL_OFF) != 0)
					pev.spawnflags &= ~SF_ENVMODEL_OFF;
				else
					pev.spawnflags |= SF_ENVMODEL_OFF;
				SetSequence();
				break;
			default: //remain frozen
				return;
			}
		}
		pev.nextthink = g_Engine.time + 0.1;
	}

	void SetSequence()
	{
		string iszSeq;

		if ((pev.spawnflags & SF_ENVMODEL_OFF) != 0)
			iszSeq = m_iszSequence_Off;
		else
			iszSeq = m_iszSequence_On;

		if (iszSeq == "")
			return;
		pev.sequence = self.LookupSequence( iszSeq );

		if (pev.sequence == -1)
		{
			g_Game.AlertMessage( at_error, "env_model_spirit %1: unknown sequence \"%2\"\n", pev.targetname, iszSeq );
			pev.sequence = 0;
		}

		pev.frame = 0;
		self.ResetSequenceInfo();

		if ((pev.spawnflags & SF_ENVMODEL_OFF) != 0 && m_flFramerate_Off > 0)
			pev.framerate = m_flFramerate_Off;
		else if (m_flFramerate_On > 0)
			pev.framerate = m_flFramerate_On;

		if ((pev.spawnflags & SF_ENVMODEL_OFF) != 0)
		{
			if (m_iAction_Off == 1)
				self.m_fSequenceLoops = true;
			else
				self.m_fSequenceLoops = false;
		}
		else
		{
			if (m_iAction_On == 1)
				self.m_fSequenceLoops = true;
			else
				self.m_fSequenceLoops = false;
		}
	}
}
