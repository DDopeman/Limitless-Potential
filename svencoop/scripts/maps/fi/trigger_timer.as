// Based on Half-Life Featureful code, ported to AngelScript

const int SF_TRIGGER_TIMER_START_ON = 1;
const int SF_TRIGGER_TIMER_NO_FIRST_DELAY = 32;

class trigger_timer : ScriptBaseEntity
{
	void Spawn()
	{
		m_triggerCounter = 0;
		m_active = false;
		SetThink(ThinkFunction(TimerThink));

		if ((pev.spawnflags & SF_TRIGGER_TIMER_START_ON) != 0) {
			SetActive(true);
			pev.nextthink += 0.1; // some little delay of spawn
		}
	}
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "min_delay" ) {
			m_minDelay = atof( szValue );
			if (m_minDelay < 0) {
				m_minDelay = 0;
			}
			return true;
		} else if ( szKey == "max_delay" ) {
			m_maxDelay = atof( szValue );
			if (m_maxDelay < 0) {
				m_maxDelay = 0;
			}
			return true;
		} else if ( szKey == "trigger_number" ) {
			m_triggerNumberLimit = atoi( szValue );
			if (m_triggerNumberLimit < 0) {
				m_triggerNumberLimit = 0;
			}
			return true;
		} else if ( szKey == "trigger_on_limit" ) {
			m_triggerOnLimit = szValue;
			return true;
		} else {
			return BaseClass.KeyValue(szKey, szValue);
		}
	}
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		switch (useType) {
		case USE_OFF:
			SetActive(false);
			break;
		case USE_ON:
			SetActive(true);
			break;
		default:
			SetActive(!m_active);
			break;
		}
	}
	void TimerThink()
	{
		if (m_active) {
			if (pev.target != "") {
				g_EntityFuncs.FireTargets(pev.target, self, self, USE_TOGGLE);
			}

			if (m_triggerNumberLimit > 0) {
				m_triggerCounter++;
				if (m_triggerCounter >= m_triggerNumberLimit) {
					SetActive(false);
					if (m_triggerOnLimit != "")
						g_EntityFuncs.FireTargets(m_triggerOnLimit, self, self, USE_TOGGLE);
					return;
				}
			}

			pev.nextthink = g_Engine.time + GetRandomDelay();
		}
	}

	float GetRandomDelay()
	{
		const float minDelay = m_minDelay;
		const float maxDelay = Math.max(m_maxDelay, m_minDelay);
		return Math.RandomFloat(minDelay, maxDelay);
	}
	void SetActive(bool active)
	{
		if (m_active == active)
			return;
		m_active = active;
		if (m_active)
		{
			if ((pev.spawnflags & SF_TRIGGER_TIMER_NO_FIRST_DELAY) != 0)
				pev.nextthink = g_Engine.time;
			else
				pev.nextthink = g_Engine.time + GetRandomDelay();
		}
		else
		{
			m_triggerCounter = 0;
		}
	}

	int m_triggerNumberLimit;
	int m_triggerCounter;
	float m_minDelay;
	float m_maxDelay;
	bool m_active;
	string m_triggerOnLimit;
};
