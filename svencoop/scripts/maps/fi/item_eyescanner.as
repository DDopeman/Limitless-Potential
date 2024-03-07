// Based on Half-Life Featureful code, ported to AngelScript

const string ScannerModel = "models/fi/EYE_SCANNER.mdl";

const string GrantedSound = "buttons/blip2.wav";
const string DeniedSound = "buttons/button11.wav";
const string BeepSound = "buttons/blip1.wav";

const float M_PI_F = 3.1415926535;

const float EYESCANNER_BASE_FIRE_DELAY = 3.0;

class item_eyescanner : ScriptBaseAnimating
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "unlocked_target")
		{
			m_unlockedTarget = szValue;
			return true;
		}
		else if (szKey == "locked_target")
		{
			m_lockedTarget = szValue;
			return true;
		}
		else if (szKey == "unlockersname")
		{
			m_unlockerName = szValue;
			return true;
		}
		else
			return BaseClass.KeyValue( szKey,szValue );
	}
	void Spawn()
	{
		Precache();
		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.takedamage = DAMAGE_NO;
		pev.health = 1;
		pev.weapons = 0;
		m_willUnlock = false;

		g_EntityFuncs.SetModel(self, ScannerModel);
		const float yCos = abs(cos(pev.angles.y * M_PI_F / 180.0));
		const float ySin = abs(sin(pev.angles.y * M_PI_F / 180.0));
		g_EntityFuncs.SetSize(pev, Vector(-10-ySin*6, -10-yCos*6, 32), Vector(10+ySin*6, 10+yCos*6, 72));
		self.SetOrigin(pev.origin);
		SetActivity(ACT_CROUCHIDLE);
		self.ResetSequenceInfo();
	}
	void Precache()
	{
		g_Game.PrecacheModel(ScannerModel);
		g_SoundSystem.PrecacheSound(GrantedSound);
		g_SoundSystem.PrecacheSound(DeniedSound);
		g_SoundSystem.PrecacheSound(BeepSound);

		SetActivity( m_Activity );
	}
	void PlayBeep()
	{
		pev.skin = pev.weapons % 3 + 1;
		pev.weapons++;
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, BeepSound, 1, ATTN_NORM );
	}
	void WaitForSequenceEnd()
	{
		if (self.m_fSequenceFinished) {
			if (m_Activity == ACT_STAND) {
				SetActivity(ACT_IDLE);
			} else if (m_Activity == ACT_CROUCH) {
				SetActivity(ACT_CROUCHIDLE);
			}
		} else if (m_Activity != ACT_IDLE && m_Activity != ACT_CROUCHIDLE) {
			self.StudioFrameAdvance();
		}
	}
	void Think()
	{
		WaitForSequenceEnd();
		if (m_Activity == ACT_IDLE)
		{
			PlayBeep();
		}
		if (m_fireTime != 0 && m_fireTime <= g_Engine.time)
		{
			m_wasUnlocked = m_willUnlock;
			if (m_willUnlock) {
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, GrantedSound, 1.0, ATTN_NORM );
				g_EntityFuncs.FireTargets( m_unlockedTarget, self, self, USE_TOGGLE, 0.0, self.m_flDelay );
			} else {
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, DeniedSound, 1.0, ATTN_NORM );
				g_EntityFuncs.FireTargets( m_lockedTarget, self, self, USE_TOGGLE, 0.0, self.m_flDelay );
			}
			m_willUnlock = false;
			m_fireTime = 0;
			pev.skin = 0;
			pev.weapons = 0;
			if (m_Activity == ACT_IDLE)
				SetActivity(ACT_CROUCH);
		}
		pev.nextthink = g_Engine.time + 0.11;
	}
	int ObjectCaps() { return BaseClass.ObjectCaps() | FCAP_IMPULSE_USE; }
	void Use( CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float value )
	{
		if (pCaller.IsPlayer() && m_Activity != ACT_CROUCHIDLE)
			return;

		@pActivator = pActivator !is null ? pActivator : pCaller;

		if (!m_willUnlock)
		{
			if (m_unlockerName == '')
			{
				if (!pActivator.IsPlayer())
				{
					m_willUnlock = true;
					m_fireTime = g_Engine.time + EYESCANNER_BASE_FIRE_DELAY;
				}
			}
			else if (m_unlockerName == pActivator.GetTargetname() || pActivator.GetClassname() == m_unlockerName)
			{
				m_willUnlock = true;
				m_fireTime = g_Engine.time + EYESCANNER_BASE_FIRE_DELAY;
			}
		}

		if (m_Activity == ACT_CROUCHIDLE || m_Activity == ACT_CROUCH) {
			m_fireTime = g_Engine.time + EYESCANNER_BASE_FIRE_DELAY;
			SetActivity( ACT_STAND );
			pev.nextthink = g_Engine.time + 0.1;
		}
	}
	int TakeDamage(entvars_t @pevInflictor, entvars_t @pevAttacker, float flDamage, int bitsDamageType)
	{
		return 0;
	}
	void SetActivity(Activity NewActivity)
	{
		int iSequence;

		iSequence = self.LookupActivity( NewActivity );

		if( iSequence > -1 )
		{
			if( pev.sequence != iSequence || !self.m_fSequenceLoops )
			{
				if( !( m_Activity == ACT_WALK || m_Activity == ACT_RUN ) || !( NewActivity == ACT_WALK || NewActivity == ACT_RUN ) )
					pev.frame = 0;
			}

			pev.sequence = iSequence;
			self.ResetSequenceInfo();
		}
		else
		{
			pev.sequence = 0;
		}

		m_Activity = NewActivity;
	}

	string m_unlockedTarget;
	string m_lockedTarget;
	string m_unlockerName;
	Activity m_Activity;
	float m_fireTime;
	float m_playSentenceTime;
	bool m_willUnlock;
	bool m_wasUnlocked;
};
