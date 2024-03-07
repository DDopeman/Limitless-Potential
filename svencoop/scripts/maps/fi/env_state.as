// Based on env_state from Spirit of Half-Life, ported to AngelScript by FreeSlave
// Note: for some reason this entity can't work as master

const int STATE_OFF = 0;
const int STATE_ON = 1;

const int SF_ENVSTATE_START_ON = 1;

class env_state : ScriptBaseEntity
{
	void Spawn()
	{
		if ((pev.spawnflags & SF_ENVSTATE_START_ON) != 0)
			m_iState = STATE_ON;
		else
			m_iState = STATE_OFF;
		m_fireWhenOn = pev.noise1;
		pev.noise1 = '';
		m_fireWhenOff = pev.noise2;
		pev.noise2 = '';
	}
	void Use( CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float value )
	{
		if (!self.ShouldToggle(useType, m_iState == STATE_ON))
			return;

		switch (m_iState)
		{
		case STATE_ON:
			{
				m_iState = STATE_OFF;
				g_EntityFuncs.FireTargets(pev.target, pActivator, self, USE_OFF);
				g_EntityFuncs.FireTargets(m_fireWhenOff, pActivator, self, USE_TOGGLE);
			}
			break;
		case STATE_OFF:
			{
				m_iState = STATE_ON;
				g_EntityFuncs.FireTargets(pev.target, pActivator, self, USE_ON);
				g_EntityFuncs.FireTargets(m_fireWhenOn, pActivator, self, USE_TOGGLE);
			}
			break;
		default:
			break;
		}
	}
	int ObjectCaps() { return BaseClass.ObjectCaps() | FCAP_MASTER; }
	bool IsTriggered(CBaseEntity@ pActivator) {
		g_Game.AlertMessage(at_console, "State is %1\n", m_iState);
		return m_iState == STATE_ON;
	}

	int m_iState;
	string m_fireWhenOn;
	string m_fireWhenOff;
};
