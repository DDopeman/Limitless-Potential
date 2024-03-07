const string ZAPBALLTRAP_DETECT_SOUND = "ambience/alien_frantic.wav";
const string ZAPBALLTRAP_LAUNCH_SOUND = "debris/beamstart4.wav";

const int ZAPTRAP_SENSE_RADIUS = 244;
const int ZAPTRAP_RESPAWN_TIME = 18;

class env_energy_ball_trap : ScriptBaseEntity
{
	private float m_respawnTime;
	private float m_radius;
	private int m_awareness;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "wait")
		{
			m_respawnTime = atof(szValue);
			return true;
		}
		else if (szKey == "radius")
		{
			m_radius = atof(szValue);
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	void Spawn()
	{
		Precache();

		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		g_EntityFuncs.SetModel(self, "sprites/xspark4.spr" );
		pev.rendermode = kRenderTransAdd;
		pev.rendercolor.x = 255;
		pev.rendercolor.y = 255;
		pev.rendercolor.z = 255;

		g_EntityFuncs.SetSize(pev, Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );
		self.SetOrigin(pev.origin);

		if (pev.targetname == "")
		{
			Materialize();
		}
		else
		{
			pev.effects |= EF_NODRAW;
			SetUse(UseFunction(this.EnableUse));
		}
	}
	void Precache()
	{
		g_Game.PrecacheOther("controller_head_ball");
		g_Game.PrecacheModel("sprites/xspark4.spr");
		g_SoundSystem.PrecacheSound(ZAPBALLTRAP_DETECT_SOUND);
		g_SoundSystem.PrecacheSound(ZAPBALLTRAP_LAUNCH_SOUND);
	}
	void Animate()
	{
		pev.frame = ( int(pev.frame) + 1 ) % 11;
	}
	void DetectThink()
	{
		Animate();
		CBaseEntity@ pFoundTarget = null;
		for( int i = 1; i <= g_Engine.maxClients; i++ )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
			if (pPlayer !is null && pPlayer.IsPlayer() && pPlayer.IsConnected() && pPlayer.IsAlive())
			{
				const float distance = (pPlayer.pev.origin - pev.origin).Length();
				if (distance <= SenseRadius())
				{
					TraceResult tr;
					g_Utility.TraceLine(pev.origin, pPlayer.Center(), dont_ignore_monsters, self.edict(), tr);
					CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
					if (pEntity is pPlayer)
					{
						@pFoundTarget = pPlayer;
						bool ballLaunched = IncreaseAwareness(pPlayer, distance <= FastSenseRadius() ? 4 : 2);
						if (ballLaunched)
							return;
					}
				}
			}
		}
		if (pFoundTarget is null)
		{
			DecreaseAwareness();
		}
		pev.nextthink = g_Engine.time + ThinkPeriod();
	}
	void Materialize()
	{
		pev.renderamt = BaseBrigthness();
		pev.scale = BaseScale();
		m_awareness = 0;
		SetThinkPeriod(IdleThinkPeriod());
		pev.effects &= ~EF_NODRAW;
		pev.frame = 0;
		SetThink( ThinkFunction(this.DetectThink) );
		pev.nextthink = g_Engine.time + 0.1f;
	}
	void LaunchBall(CBaseEntity@ pTarget)
	{
		pev.effects |= EF_NODRAW;
		SetThink(ThinkFunction(this.Materialize));
		pev.nextthink = g_Engine.time + RespawnTime();

		g_SoundSystem.EmitSound(self.edict(), CHAN_WEAPON, ZAPBALLTRAP_LAUNCH_SOUND, 1.0, ATTN_STATIC);

		CBaseEntity@ pBallEnt = g_EntityFuncs.Create( "controller_head_ball", pev.origin, pev.angles, false, self.edict() );
		if (pBallEnt is null)
			return;
		CBaseMonster@ pBall = pBallEnt.MyMonsterPointer();
		if (pBall !is null)
		{
			pBall.pev.velocity = Vector( 0.0f, 0.0f, 32.0f );
			pBall.m_hEnemy = pTarget;
		}
	}
	void EnableUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		if (useType != USE_OFF)
		{
			Materialize();
			SetUse(null);
		}
	}

	float IdleThinkPeriod() {
		return 0.2;
	}
	float AlertThinkPeriod() {
		return 0.1;
	}
	float ThinkPeriod() const {
		return pev.frags;
	}
	void SetThinkPeriod(float value) const {
		pev.frags = value;
	}

	float SenseRadius() const {
		return m_radius > 0.0 ? m_radius : ZAPTRAP_SENSE_RADIUS;
	}
	float FastSenseRadius() const {
		return SenseRadius() / 3;
	}

	bool IncreaseAwareness(CBaseEntity@ pTarget, int value)
	{
		const int prevAwareness = CurrentAwareness();
		m_awareness += value;
		const int newAwareness = m_awareness;

		if (newAwareness >= MaxAwareness())
		{
			g_SoundSystem.StopSound(self.edict(), CHAN_ITEM, ZAPBALLTRAP_DETECT_SOUND);
			LaunchBall(pTarget);
			return true;
		}
		if (prevAwareness == 0)
		{
			SetThinkPeriod(AlertThinkPeriod());
			g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_ITEM, ZAPBALLTRAP_DETECT_SOUND, 0.8, ATTN_STATIC, 0, 110);
		}

		AwareEffect();

		return false;
	}
	void DecreaseAwareness()
	{
		if (m_awareness > 0)
		{
			m_awareness--;
			AwareEffect();
			if (m_awareness == 0)
			{
				g_SoundSystem.StopSound(self.edict(), CHAN_ITEM, ZAPBALLTRAP_DETECT_SOUND);
				SetThinkPeriod(IdleThinkPeriod());
			}
		}
	}
	void AwareEffect()
	{
		const float factor = float(CurrentAwareness()) / float(MaxAwareness());
		pev.scale = BaseScale() + (MaxScale() - BaseScale()) * factor;
		pev.renderamt = BaseBrigthness() + (MaxBrightness() - BaseBrigthness()) * factor;
	}
	int CurrentAwareness() const {
		return m_awareness;
	}
	int MaxAwareness() const {
		return 20;
	}

	int BaseBrigthness() const {
		return 80;
	}
	int MaxBrightness() const {
		return 255;
	}

	float BaseScale() const {
		return 1.0f;
	}
	float MaxScale() const {
		return BaseScale() * 2;
	}

	float RespawnTime() const {
		return m_respawnTime > 0 ? m_respawnTime : ZAPTRAP_RESPAWN_TIME;
	}
};
