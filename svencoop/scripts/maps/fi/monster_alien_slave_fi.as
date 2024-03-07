namespace FIVortigaunt
{

const int bits_MEMORY_ISLAVE_PROVOKED = bits_MEMORY_CUSTOM1;
const int bits_MEMORY_ISLAVE_REVIVED = bits_MEMORY_CUSTOM2;
const int bits_MEMORY_ISLAVE_LAST_ATTACK_WAS_COIL = bits_MEMORY_CUSTOM3;
const int bits_MEMORY_ISLAVE_FAMILIAR_IS_ALIVE = bits_MEMORY_CUSTOM4;

const int SF_SQUADMONSTER_LEADER = 32;
const int SF_MONSTER_FALL_TO_GROUND = int(0x80000000);

//=========================================================
// monster-specific schedule types
//=========================================================
enum SCHED_ISLAVE
{
	SCHED_ISLAVE_COVER_AND_SUMMON_FAMILIAR = LAST_COMMON_SCHEDULE + 1,
	SCHED_ISLAVE_SUMMON_FAMILIAR,
	SCHED_ISLAVE_HEAL_OR_REVIVE,
	SCHED_RETREAT_FROM_ENEMY,
	SCHED_RETREAT_FROM_ENEMY_FAILED
};

//=========================================================
// monster-specific tasks
//=========================================================
enum TASK_ISLAVE
{
	TASK_ISLAVE_SUMMON_FAMILIAR = LAST_COMMON_TASK + 1,
	TASK_ISLAVE_HEAL_OR_REVIVE_ATTACK,
};

//=========================================================
// Monster's Anim Events Go Here
//=========================================================
const int ISLAVE_AE_CLAW = ( 1 );
const int ISLAVE_AE_CLAWRAKE = ( 2 );
const int ISLAVE_AE_ZAP_POWERUP = ( 3 );
const int ISLAVE_AE_ZAP_SHOOT = ( 4 );
const int ISLAVE_AE_ZAP_DONE = ( 5 );

const int ISLAVE_MAX_BEAMS = 8;

const string ISLAVE_HAND_SPRITE_NAME = "sprites/glow02.spr";

const int ISLAVE_ZAP_RED = 180;
const int ISLAVE_ZAP_GREEN = 255;
const int ISLAVE_ZAP_BLUE = 96;

const int ISLAVE_LEADER_ZAP_RED = 150;
const int ISLAVE_LEADER_ZAP_GREEN = 255;
const int ISLAVE_LEADER_ZAP_BLUE = 120;

const int ISLAVE_ARMBEAM_RED = 96;
const int ISLAVE_ARMBEAM_GREEN = 128;
const int ISLAVE_ARMBEAM_BLUE = 16;

const int ISLAVE_LEADER_ARMBEAM_RED = 72;
const int ISLAVE_LEADER_ARMBEAM_GREEN = 180;
const int ISLAVE_LEADER_ARMBEAM_BLUE = 72;

const int ISLAVE_LIGHT_RED = 255;
const int ISLAVE_LIGHT_GREEN = 180;
const int ISLAVE_LIGHT_BLUE = 96;

const int ISLAVE_ELECTROONLY = (1 << 0);
const int ISLAVE_SNARKS = (1 << 1);
const int ISLAVE_HEADCRABS = (1 << 2);

const int ISLAVE_COIL_ATTACK_RADIUS = 196;

const string ISLAVE_SPAWNFAMILIAR_SPRITE = "sprites/bexplo.spr";
const int ISLAVE_SPAWNFAMILIAR_DELAY = 6;

enum ISLAVE_ARM
{
	ISLAVE_LEFT_ARM = -1,
	ISLAVE_RIGHT_ARM = 1
};

bool IsVortWounded(CBaseEntity@ pEntity)
{
	return pEntity.pev.health <= Math.min(pEntity.pev.max_health / 2, 20);
}

bool CanBeRevived(CBaseEntity@ pEntity)
{
	if ( pEntity !is null && pEntity.pev.deadflag == DEAD_DEAD && (pEntity.pev.flags & FL_KILLME) == 0 ) {
		CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
		if (pMonster is null || pMonster.HasMemory(bits_MEMORY_ISLAVE_REVIVED))
		{
			// Wrong target or was already revived once
			return false;
		}

		const Vector vecDest = pEntity.pev.origin + Vector( 0, 0, 38 );
		TraceResult tr;
		g_Utility.TraceHull( vecDest, vecDest - Vector(0,0,2), dont_ignore_monsters, human_hull, pEntity.edict(), tr );
	
		return tr.fAllSolid == 0 && tr.fStartSolid == 0;
	}
	return false;
}

bool CanSpawnAtPosition(const Vector position, HULL_NUMBER hullType, edict_t@ pentIgnore)
{
	TraceResult tr;
	g_Utility.TraceHull( position, position - Vector(0,0,1), dont_ignore_monsters, hullType, pentIgnore, tr );
	return tr.fStartSolid == 0 && tr.fAllSolid == 0;
}

void PrecacheSoundArray(const array<string>& in arr)
{
	for( uint i = 0; i < arr.length(); i++ )
		g_SoundSystem.PrecacheSound(arr[i]);
}

string RandomSoundFromArray(const array<string>& in arr)
{
	return arr[Math.RandomLong(0, arr.length() - 1)];
}

const array<string> pAttackHitSounds =
{
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav"
};

const array<string> pAttackMissSounds =
{
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav"
};

const array<string> pPainSounds =
{
	"aslave/slv_pain1.wav",
	"aslave/slv_pain2.wav"
};

const array<string> pDeathSounds =
{
	"aslave/slv_die1.wav",
	"aslave/slv_die2.wav"
};

const array<string> pGlowArmSounds =
{
	"debris/zap3.wav",
	"debris/zap8.wav"
};

float GetVortCvarValue(const string cvarName, float defaultValue)
{
	float value = g_EngineFuncs.CVarGetFloat(cvarName);
	if (value <= 0)
		value = defaultValue;
	return value;
}

float GetVortHealth()
{
	return GetVortCvarValue("sk_islave_health", 80);
}

float GetVortClawDmg()
{
	return GetVortCvarValue("sk_islave_dmg_claw", 8);
}

float GetVortClawRakeDmg()
{
	return GetVortCvarValue("sk_islave_dmg_clawrake", 24);
}

float GetVortZapDmg()
{
	return GetVortCvarValue("sk_islave_dmg_zap", 11);
}

float GetVortZapSpeed()
{
	float zapSpeed = GetVortCvarValue("sk_islave_speed_zap", 1);
	zapSpeed *= 1.25;
	zapSpeed = Math.min(1.5, zapSpeed);
	return zapSpeed;
}

//=========================================================
// AI Schedules Specific to this monster
//=========================================================

array<ScriptSchedule@>@ monster_alien_slave_schedules;

ScriptSchedule slSlaveAttack1(
		bits_COND_HEAR_SOUND |
		bits_COND_HEAVY_DAMAGE, 
		bits_SOUND_DANGER,
		"Slave Range Attack1"
);

ScriptSchedule slSlaveHealOrReviveAttack(
		bits_COND_CAN_MELEE_ATTACK1 |
		bits_COND_HEAR_SOUND |
		bits_COND_NEW_ENEMY |
		bits_COND_HEAVY_DAMAGE, 

		bits_SOUND_DANGER,
		"Slave Heal or Revive Range Attack"
);

ScriptSchedule slSlaveCoverAndSummon(
		bits_COND_NEW_ENEMY,
		0,
		"Slave Run Away and Summon"
);

ScriptSchedule slSlaveSummon(
		bits_COND_NEW_ENEMY,
		0,
		"Slave Summon"
);

ScriptSchedule slRetreatFromEnemy(
		bits_COND_NEW_ENEMY,
		0,
		"Retreat From Enemy"
);

void InitSchedules()
{
	slSlaveAttack1.AddTask(ScriptTask(TASK_STOP_MOVING, 0));
	slSlaveAttack1.AddTask(ScriptTask(TASK_FACE_IDEAL, 0));
	slSlaveAttack1.AddTask(ScriptTask(TASK_RANGE_ATTACK1, 0));

	slSlaveHealOrReviveAttack.AddTask(ScriptTask(TASK_STOP_MOVING, 0));
	slSlaveHealOrReviveAttack.AddTask(ScriptTask(TASK_MOVE_TO_TARGET_RANGE, 128));
	slSlaveHealOrReviveAttack.AddTask(ScriptTask(TASK_FACE_TARGET, 0));
	slSlaveHealOrReviveAttack.AddTask(ScriptTask(TASK_ISLAVE_HEAL_OR_REVIVE_ATTACK, 0));

	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_STOP_MOVING, 0));
	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_WAIT, 0.1));
	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_FIND_COVER_FROM_ENEMY, 0));
	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_RUN_PATH, 0));
	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_WAIT_FOR_MOVEMENT, 0));
	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_REMEMBER, bits_MEMORY_INCOVER));
	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_FACE_ENEMY, 0));
	slSlaveCoverAndSummon.AddTask(ScriptTask(TASK_ISLAVE_SUMMON_FAMILIAR, 0));

	slSlaveSummon.AddTask(ScriptTask(TASK_STOP_MOVING, 0));
	slSlaveSummon.AddTask(ScriptTask(TASK_FACE_ENEMY, 0));
	slSlaveSummon.AddTask(ScriptTask(TASK_ISLAVE_SUMMON_FAMILIAR, 0));

	slRetreatFromEnemy.AddTask(ScriptTask(TASK_SET_FAIL_SCHEDULE, SCHED_RETREAT_FROM_ENEMY_FAILED));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_STOP_MOVING, 0));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_WAIT, 0.1));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_FIND_COVER_FROM_ENEMY, 0));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_RUN_PATH, 0));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_WAIT_FOR_MOVEMENT, 0));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_REMEMBER, bits_MEMORY_INCOVER));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_FACE_ENEMY, 0));
	slRetreatFromEnemy.AddTask(ScriptTask(TASK_WAIT, 0.5));

	array<ScriptSchedule@> scheds = {slSlaveAttack1, slSlaveHealOrReviveAttack, slSlaveCoverAndSummon, slSlaveSummon};
	@monster_alien_slave_schedules = @scheds;
}

class CISlave : ScriptBaseMonsterEntity
{
	CISlave()
	{
		@this.m_Schedules = @monster_alien_slave_schedules;
		for( int i = 0; i < ISLAVE_MAX_BEAMS; i++ )
		{
			@m_pBeam[i] = null;
		}
	}
	void Spawn()
	{
		Precache();

		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/islave.mdl" );
		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_STEP;
		if (self.m_bloodColor == 0)
			self.m_bloodColor = BLOOD_COLOR_GREEN;
		pev.effects = 0;
		if ( self.pev.health == 0.0f )
			self.pev.health = GetVortHealth();
		pev.view_ofs = Vector( 0, 0, 64 );// position of the eyes relative to monster's origin.
		self.m_flFieldOfView = VIEW_FIELD_WIDE; // NOTE: we need a wide field of view so npc will notice player and say hello
		self.m_MonsterState = MONSTERSTATE_NONE;
		self.m_afCapability = bits_CAP_HEAR | bits_CAP_TURN_HEAD | bits_CAP_RANGE_ATTACK2 | bits_CAP_DOORS_GROUP | bits_CAP_SQUAD;

		m_voicePitch = Math.RandomLong( 85, 110 );

		@m_handGlow1 = CreateHandGlow(1);
		@m_handGlow2 = CreateHandGlow(2);
		HandsGlowOff();

		self.MonsterInit();

		m_originalMaxHealth = pev.max_health;
		self.m_flDistTooFar = Math.max(m_attackDistance, self.m_flDistTooFar);

		// leader starts with some energy pool
		if (m_freeEnergy <= 0 && (pev.spawnflags & SF_SQUADMONSTER_LEADER) != 0)
			m_freeEnergy = pev.max_health;
		else
			m_freeEnergy = pev.max_health / 2;

		if( string( self.m_FormattedName ).IsEmpty() )
		{
			self.m_FormattedName = "Vortigaunt";
		}
	}
	void Precache()
	{
		BaseClass.Precache();
		m_iLightningTexture = g_Game.PrecacheModel( "sprites/lgtning.spr" );
		m_iTrailTexture = g_Game.PrecacheModel( "sprites/plasma.spr" );

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( "models/islave.mdl" );
		g_SoundSystem.PrecacheSound( "debris/zap1.wav" );
		g_SoundSystem.PrecacheSound( "debris/zap4.wav" );
		g_SoundSystem.PrecacheSound( "debris/beamstart1.wav" );
		g_SoundSystem.PrecacheSound( "debris/beamstart7.wav" );
		g_SoundSystem.PrecacheSound( "weapons/electro4.wav" );
		g_SoundSystem.PrecacheSound( "hassault/hw_shoot1.wav" );
		g_SoundSystem.PrecacheSound( "zombie/zo_pain2.wav" );
		g_SoundSystem.PrecacheSound( "headcrab/hc_headbite.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cbar_miss1.wav" );
		g_SoundSystem.PrecacheSound( "aslave/slv_word5.wav" );
		g_SoundSystem.PrecacheSound( "aslave/slv_word7.wav" );

		PrecacheSoundArray( pAttackHitSounds );
		PrecacheSoundArray( pAttackMissSounds );
		PrecacheSoundArray( pPainSounds );
		PrecacheSoundArray( pDeathSounds );

		g_Game.PrecacheModel( ISLAVE_HAND_SPRITE_NAME );
		PrecacheSoundArray(pGlowArmSounds);
		g_Game.PrecacheModel( ISLAVE_SPAWNFAMILIAR_SPRITE );
		g_Game.PrecacheOther( "monster_snark" );
		g_Game.PrecacheOther( "monster_headcrab" );
	}
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if (szKey == "energy")
		{
			m_freeEnergy = atof(szValue);
			return true;
		}
		else if (szKey == "attack_distance")
		{
			//g_Game.AlertMessage(at_console, "Setting attack distance to %1\n", szValue);
			m_attackDistance = atof(szValue);
			return true;
		}
		else
			return BaseClass.KeyValue(szKey, szValue);
	}
	void UpdateOnRemove()
	{
		ClearBeams();
		RemoveHandGlows();

		BaseClass.UpdateOnRemove();
	}
	void SetYawSpeed( void )
	{
		int ys;
		switch( self.m_Activity )
		{
		case ACT_WALK:		
			ys = 50;	
			break;
		case ACT_RUN:		
			ys = 70;
			break;
		case ACT_IDLE:		
			ys = 50;
			break;
		default:
			ys = 90;
			break;
		}
		pev.yaw_speed = ys * 2.5; // multiply as monsters in SC tend to have higher yaw speeds than in HL
	}
	int ISoundMask()
	{
		return bits_SOUND_WORLD |
			bits_SOUND_COMBAT |
			bits_SOUND_DANGER |
			bits_SOUND_PLAYER;
	}
	int Classify()
	{
		if (self.m_fOverrideClass)
			return self.m_iClassSelection;
		return CLASS_ALIEN_MILITARY;
	}
	CBaseEntity@ VortCheckTraceHullAttack( float flDist, float iDamage, int iDmgType )
	{
		TraceResult tr;
		Math.MakeAimVectors( pev.angles );

		Vector vecStart = pev.origin;
		vecStart.z += pev.size.z * 0.5;
		Vector vecEnd = vecStart + ( g_Engine.v_forward * flDist );

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( iDamage > 0 )
			{
				pEntity.TakeDamage( pev, pev, iDamage, iDmgType );
			}
			return pEntity;
		}

		return null;
	}
	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case ISLAVE_AE_CLAW:
			{
				m_clawStrikeNum++;
				int damageType = DMG_SLASH;
				float damage = GetVortClawDmg();
				if (CanUseGlowArms()) {
					if ( m_clawStrikeNum == 1 ) {
						HandGlowOff(m_handGlow1);
						StartMeleeAttackGlow(ISLAVE_LEFT_ARM);
					}
					if ( m_clawStrikeNum == 2 ) {
						HandGlowOff(m_handGlow2);
						StartMeleeAttackGlow(ISLAVE_RIGHT_ARM);
					}
					if ( m_clawStrikeNum == 3 ) {
						HandGlowOff(m_handGlow1);
					}
					damageType |= DMG_SHOCK;
					damage *= 1.5;
				}
				CBaseEntity@ pHurt = VortCheckTraceHullAttack( 70.0, damage, damageType );
				if( pHurt !is null )
				{
					if( (pHurt.pev.flags & ( FL_MONSTER | FL_CLIENT )) != 0 )
					{
						pHurt.pev.punchangle.z = 18;
						pHurt.pev.punchangle.x = 5;
					}
					// Play a random attack hit sound
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, RandomSoundFromArray( pAttackHitSounds ), 1.0, ATTN_NORM, 0, m_voicePitch );
				}
				else
				{
					// Play a random attack miss sound
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, RandomSoundFromArray( pAttackMissSounds ), 1.0, ATTN_NORM, 0, m_voicePitch );
				}
			}
				break;
			case ISLAVE_AE_CLAWRAKE:
			{
				CBaseEntity@ pHurt = VortCheckTraceHullAttack( 70.0, GetVortClawRakeDmg(), DMG_SLASH );
				if( pHurt !is null )
				{
					if( (pHurt.pev.flags & ( FL_MONSTER | FL_CLIENT )) != 0 )
					{
						pHurt.pev.punchangle.z = -18;
						pHurt.pev.punchangle.x = 5;
					}
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, RandomSoundFromArray( pAttackHitSounds ), 1.0, ATTN_NORM, 0, m_voicePitch );
				}
				else
				{
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, RandomSoundFromArray( pAttackMissSounds ), 1.0, ATTN_NORM, 0, m_voicePitch );
				}
			}
				break;
			case ISLAVE_AE_ZAP_POWERUP:
			{
				// speed up attack depending on difficulty level
				pev.framerate = GetVortZapSpeed();

				Math.MakeAimVectors( pev.angles );

				if( m_iBeams == 0 )
				{
					Vector vecSrc = pev.origin + g_Engine.v_forward * 2;
					MakeDynamicLight(vecSrc, 12, int(20/pev.framerate));
				}
				if( CanRevive() )
				{
					WackBeam( ISLAVE_LEFT_ARM, m_hDead );
					WackBeam( ISLAVE_RIGHT_ARM, m_hDead );
				}
				else
				{
					ArmBeam( ISLAVE_LEFT_ARM );
					ArmBeam( ISLAVE_RIGHT_ARM );
					BeamGlow();
				}
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "debris/zap4.wav", 1, ATTN_NORM, 0, 100 + m_iBeams * 10 );
			}
				break;
			case ISLAVE_AE_ZAP_SHOOT:
			{
				ClearBeams();

				if( CanRevive() )
				{
					if( CanBeRevived(m_hDead) )
					{
						self.Forget(bits_MEMORY_ISLAVE_LAST_ATTACK_WAS_COIL);

						CBaseEntity@ revived = m_hDead.GetEntity();
						if (revived !is null) {
							CBaseMonster@ monster = revived.MyMonsterPointer();
							if (monster !is null)
							{
								ScriptBaseMonsterEntity@ scriptedMonster = cast<ScriptBaseMonsterEntity@>( CastToScriptClass( monster ) );
								CISlave@ revivedVort = cast<CISlave>(scriptedMonster);
								if (revivedVort !is null)
								{
									monster.pev.health = revivedVort.m_originalMaxHealth;
									// TODO: should restore the actual values that the vort had before he died
									monster.pev.rendermode = kRenderNormal;
									monster.pev.renderamt = 255;
									@monster.pev.owner = null; // nullify owner to avoid additional DeathNotice calls
									monster.Revive();
									monster.pev.health = monster.pev.max_health;
									monster.Remember(bits_MEMORY_ISLAVE_REVIVED);

									if (self.m_hEnemy.IsValid())
									{
										monster.PushEnemy(self.m_hEnemy, self.m_vecEnemyLKP);
									}

									// revived vort starts with zero energy
									revivedVort.m_freeEnergy = 0;
								}
							}

							WackBeam( ISLAVE_LEFT_ARM, revived );
							WackBeam( ISLAVE_RIGHT_ARM, revived );
							m_hDead = null;
							g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "hassault/hw_shoot1.wav", 1, ATTN_NORM, 0, Math.RandomLong( 130, 160 ) );

							SpendEnergy(pev.max_health);
						}
						break;
					}
					else {
						//ALERT(at_aiconsole, "Trace failed on revive\n");
					}
				}
				g_WeaponFuncs.ClearMultiDamage();

				bool coilAttack = false;
				// make coil attack on purpose to heal only if two wounded friends around
				if ( HasFreeEnergy() && IsValidHealTarget(m_hWounded) && IsValidHealTarget(m_hWounded2) &&
						(pev.origin - m_hWounded.GetEntity().pev.origin).Length() <= ISLAVE_COIL_ATTACK_RADIUS &&
						(pev.origin - m_hWounded2.GetEntity().pev.origin).Length() <= ISLAVE_COIL_ATTACK_RADIUS) {
					if (m_hWounded.GetEntity() == m_hWounded2.GetEntity()) {
						g_Game.AlertMessage(at_aiconsole, "m_hWounded && m_hWounded2 are the same!\n");
					}
					coilAttack = true;
					g_Game.AlertMessage(at_aiconsole, "Vort makes coil attack to heal friends\n");
				} else if ( self.m_hEnemy.GetEntity() !is null && (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length() <= ISLAVE_COIL_ATTACK_RADIUS && !self.HasMemory(bits_MEMORY_ISLAVE_LAST_ATTACK_WAS_COIL) ) {
					coilAttack = true;
				}

				if (coilAttack) {
					CoilBeam();
					self.Remember(bits_MEMORY_ISLAVE_LAST_ATTACK_WAS_COIL);

					g_PlayerFuncs.ScreenShake( pev.origin, 3.0, 40.0, 1.0, ISLAVE_COIL_ATTACK_RADIUS );

					CBaseEntity@ pEntity = null;
					while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pev.origin, ISLAVE_COIL_ATTACK_RADIUS, "*", "classname" ) ) !is null )
					{
						float flAdjustedDamage = GetVortZapDmg()*2.5;
						if( pEntity != self && pEntity.pev.takedamage != DAMAGE_NO ) {
							const int rel = self.IRelationship(pEntity);
							if (rel == R_AL)
							{
								if (pEntity.GetClassname() == self.GetClassname()) {
									if (AbleToHeal() && HealOther(pEntity)) {
										g_Game.AlertMessage(at_aiconsole, "Vort healed friend with coil attack\n");
									}
								}
							}
							else
							{
								if ( !self.FVisible( pEntity, true ) )
								{
									if (pEntity.IsPlayer())
									{
										// Restrict it to clients so that monsters in other parts of the level don't take the damage and get pissed.
										flAdjustedDamage *= 0.5f;
									}
									else
									{
										flAdjustedDamage = 0;
									}
								}

								if( flAdjustedDamage > 0 ) {
									pEntity.TakeDamage( pev, pev, flAdjustedDamage, DMG_SHOCK );
								}
							}
						}
					}
					g_SoundSystem.EmitAmbientSound( self.edict(), pev.origin, "weapons/electro4.wav", 0.5, ATTN_NORM, 0, Math.RandomLong( 140, 160 ) );

					m_flNextAttack = g_Engine.time + Math.RandomFloat( 1.0, 4.0 );
				} else {
					self.Forget(bits_MEMORY_ISLAVE_LAST_ATTACK_WAS_COIL);
					Math.MakeAimVectors( pev.angles );

					ZapBeam( ISLAVE_LEFT_ARM );
					ZapBeam( ISLAVE_RIGHT_ARM );
					
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "hassault/hw_shoot1.wav", 1, ATTN_NORM, 0, Math.RandomLong( 130, 160 ) );
					// STOP_SOUND( ENT( pev ), CHAN_WEAPON, "debris/zap4.wav" );
					g_WeaponFuncs.ApplyMultiDamage( pev, pev );

					m_flNextAttack = g_Engine.time + Math.RandomFloat( 0.5, 4.0 );
				}
			}
				break;
			case ISLAVE_AE_ZAP_DONE:
			{
				ClearBeams();
			}
				break;
			default:
				BaseClass.HandleAnimEvent( pEvent );
				break;
		}
	}
	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( m_flNextAttack > g_Engine.time )
		{
			return false;
		}
		if( flDist > 64 && flDist <= ISLAVE_COIL_ATTACK_RADIUS )
		{
			return true;
		}
		if (flDist > 64 && flDist <= Math.max(m_attackDistance, 784) && flDot >= 0.5)
		{
			return true;
		}
		return false;
	}
	bool CheckRangeAttack2( float flDot, float flDist )
	{
		if( m_flNextAttack > g_Engine.time )
		{
			return false;
		}
		return HasFreeEnergy() && CheckHealOrReviveTargets(flDist, true);
	}
	bool CheckHealOrReviveTargets( float flDist = 784, bool mustSee = true )
	{
		if (m_nextHealTargetCheck >= g_Engine.time)
		{
			return m_hDead.GetEntity() !is null || m_hWounded.GetEntity() !is null;
		}

		m_nextHealTargetCheck = g_Engine.time + 1;
		m_hDead = null;
		m_hWounded = null;
		m_hWounded2 = null;

		CBaseEntity@ pEntity = null;
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, self.GetClassname() ) ) != null )
		{
			if (self.IRelationship(pEntity) >= R_DL)
				continue;
			TraceResult tr;

			g_Utility.TraceLine( self.EyePosition(), pEntity.EyePosition(), ignore_monsters, dont_ignore_glass, self.edict(), tr );
			if( (mustSee && (tr.flFraction == 1.0f || tr.pHit is pEntity.edict())) || (!mustSee && (pEntity.pev.origin - pev.origin).Length() < flDist ) )
			{
				if( AbleToRevive() && CanBeRevived(pEntity) )
				{
					float d = ( pev.origin - pEntity.pev.origin ).Length();
					if( d < flDist )
					{
						m_hDead = pEntity;
						flDist = d;
					}
				}
				if ( AbleToHeal() && IsValidHealTarget(pEntity) )
				{
					float d = ( pev.origin - pEntity.pev.origin ).Length();
					if( d < flDist )
					{
						m_hWounded2 = m_hWounded;
						m_hWounded = pEntity;
						flDist = d;
					}
				}
			}
		}
		return m_hDead.GetEntity() !is null || m_hWounded.GetEntity() !is null;
	}
	bool IsValidHealTarget( CBaseEntity@ pEntity )
	{
		return pEntity !is null && pEntity != self && pEntity.IsAlive() && pEntity.pev.health > 0 && IsVortWounded(pEntity);
	}
	void CallForHelp( float flDist, EHandle hEnemy, const Vector& in vecLocation )
	{
		if( pev.netname == "" )
			return;

		CBaseEntity@ pEntity = null;

		while( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "netname", pev.netname ) ) != null)
		{
			float d = ( pev.origin - pEntity.pev.origin ).Length();
			if( d < flDist )
			{
				if (pEntity.GetClassname() != self.GetClassname())
					continue;
				CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
				if( pMonster !is null )
				{
					pMonster.m_afMemory |= bits_MEMORY_ISLAVE_PROVOKED;
					pMonster.PushEnemy( hEnemy, vecLocation );
				}
			}
		}
	}
	void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType )
	{
		if( (bitsDamageType & DMG_SHOCK) != 0) {
			if (pevAttacker is null)
				return;
			CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
			if (pAttacker !is null && self.IRelationship( pAttacker ) == R_AL)
				return;
		}

		BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
	}
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		// don't slash one of your own
		if( ( bitsDamageType & DMG_SLASH ) != 0 && pevAttacker !is null ) {
			CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
			if (pAttacker !is null && self.IRelationship( pAttacker ) == R_AL)
				return 0;
		}

		self.Remember( bits_MEMORY_ISLAVE_PROVOKED );
		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void DeathSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, RandomSoundFromArray( pDeathSounds ), 1.0, ATTN_NORM, 0, m_voicePitch );
	}
	void PainSound()
	{
		if( Math.RandomLong( 0, 2 ) == 0 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, RandomSoundFromArray( pPainSounds ), 1.0, ATTN_NORM, 0, m_voicePitch );
		}
	}
	void AlertSound()
	{
		if( self.m_hEnemy.GetEntity() !is null )
		{
			g_SoundSystem.PlaySentenceGroup( self.edict(), "SLV_ALERT", 0.85, ATTN_NORM, 0, m_voicePitch );
			CallForHelp( 512, self.m_hEnemy, self.m_vecEnemyLKP );
		}
	}
	void IdleSound()
	{
		if( Math.RandomLong( 0, 2 ) == 0 )
		{
			g_SoundSystem.PlaySentenceGroup( self.edict(), "SLV_IDLE", 0.85, ATTN_NORM, 0, m_voicePitch );
		}

		int side = Math.RandomLong( 0, 1 ) * 2 - 1;

		ArmBeamMessage( side );

		Math.MakeAimVectors( pev.angles );
		Vector vecSrc = pev.origin + g_Engine.v_right * 2 * side;
		MakeDynamicLight(vecSrc, 8, 10);

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "debris/zap1.wav", 1, ATTN_NORM, 0, 100 );
	}

	void Killed(entvars_t@ pevAttacker, int iGib)
	{
		ClearBeams();
		RemoveHandGlows();
		BaseClass.Killed(pevAttacker, iGib);
	}
	void DeathNotice( entvars_t@ pevChild )
	{
		self.Forget(bits_MEMORY_ISLAVE_FAMILIAR_IS_ALIVE);
	}

	void StartTask( Task@ pTask )
	{
		ClearBeams();
		switch(pTask.iTask)
		{
		case TASK_ISLAVE_SUMMON_FAMILIAR:
		{
			if (CanSpawnAtPosition(GetFamiliarSpawnPosition(), FamiliarHull(), self.edict()))
			{
				self.m_IdealActivity = ACT_CROUCH;
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "debris/beamstart1.wav", 1, ATTN_NORM );
				Math.MakeAimVectors( pev.angles );
				Vector vecSrc = pev.origin + g_Engine.v_forward * 8;
				MakeDynamicLight(vecSrc, 10, 15);
				HandsGlowOn();
				CreateSummonBeams();
			}
			else
			{
				m_flSpawnFamiliarTime = g_Engine.time + ISLAVE_SPAWNFAMILIAR_DELAY; // still set delay to avoid constant trying
				self.TaskFail();
			}
			break;
		}
			
		case TASK_ISLAVE_HEAL_OR_REVIVE_ATTACK:
		{
			g_Game.AlertMessage(at_aiconsole, "start TASK_ISLAVE_HEAL_OR_REVIVE_ATTACK\n");
			self.m_IdealActivity = ACT_RANGE_ATTACK1;
			break;
		}
		case TASK_WAIT_FOR_MOVEMENT:
			// a hack to prevent vortigaunts running with beams caused by dangling events from the attack animation
			self.m_IdealActivity = ACT_IDLE;
			BaseClass.StartTask( pTask );
		case TASK_MELEE_ATTACK1:
			m_clawStrikeNum = 0;
			BaseClass.StartTask( pTask );
		default:
			BaseClass.StartTask( pTask );
			break;
		}
	}
	void RunTask( Task@ pTask )
	{
		switch(pTask.iTask)
		{
		case TASK_ISLAVE_SUMMON_FAMILIAR:
			if( self.m_fSequenceFinished )
			{
				SpawnFamiliar(FamiliarName(), GetFamiliarSpawnPosition(), FamiliarHull());
				HandsGlowOff();
				self.TaskComplete();
				RemoveSummonBeams();
			}
			break;
		case TASK_ISLAVE_HEAL_OR_REVIVE_ATTACK:
			if( self.m_fSequenceFinished )
			{
				self.m_Activity = ACT_RESET;
				self.TaskComplete();
			}
			break;
		default:
			BaseClass.RunTask( pTask );
			break;
		}
	}
	void RunAI()
	{
		if (self.m_Activity == ACT_MELEE_ATTACK1 && m_clawStrikeNum == 0) {
			if ( m_handGlow1 !is null && (m_handGlow1.pev.effects & EF_NODRAW) != 0 && CanUseGlowArms() ) {
				StartMeleeAttackGlow(ISLAVE_RIGHT_ARM);
				g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_BODY, RandomSoundFromArray(pGlowArmSounds), Math.RandomFloat(0.6, 0.8), ATTN_NORM, 0, Math.RandomLong(70,90));
			}
		}
		BaseClass.RunAI();
	}

	void SpawnFamiliar(string entityName, const Vector& in origin, HULL_NUMBER hullType)
	{
		if (entityName.IsEmpty()) {
			g_Game.AlertMessage(at_console, "Null familiar name in SpawnFamiliar!\n");
			return;
		}
		if (CanSpawnAtPosition(origin, hullType, self.edict())) {
			CBaseEntity@ pNew = g_EntityFuncs.Create( entityName, origin, pev.angles, false, self.edict() );

			if(pNew !is null) {
				CBaseMonster@ pNewMonster = pNew.MyMonsterPointer( );

				self.Remember(bits_MEMORY_ISLAVE_FAMILIAR_IS_ALIVE);
				CSprite@ pSpr = g_EntityFuncs.CreateSprite( ISLAVE_SPAWNFAMILIAR_SPRITE, origin, true );
				if (pSpr !is null)
				{
					pSpr.pev.spawnflags |= 4;
					pSpr.pev.framerate = 20.0f;
					pSpr.SetTransparency( kRenderTransAdd, ISLAVE_ARMBEAM_RED, ISLAVE_ARMBEAM_GREEN, ISLAVE_ARMBEAM_BLUE, 255, kRenderFxNoDissipation );
				}
				g_SoundSystem.EmitSound( pNew.edict(), CHAN_BODY, "debris/beamstart7.wav", 0.9, ATTN_NORM );

				pNew.pev.spawnflags |= SF_MONSTER_FALL_TO_GROUND;
				if (pNewMonster !is null) {
					if (self.m_fOverrideClass)
						pNewMonster.m_iClassSelection = self.m_iClassSelection;
					if (self.m_hEnemy) {
						pNewMonster.PushEnemy(self.m_hEnemy, self.m_vecEnemyLKP);
					}
				}
			}
		} else {
			g_Game.AlertMessage(at_aiconsole, "Not enough room to create %1\n", entityName);
		}
		m_flSpawnFamiliarTime = g_Engine.time + ISLAVE_SPAWNFAMILIAR_DELAY;
	}
	Schedule@ GetSchedule()
	{
		if( self.HasConditions( bits_COND_HEAR_SOUND ) )
		{
			CSound@ pSound = self.PBestSound();
			if( pSound !is null )
			{
				if( (pSound.m_iType & bits_SOUND_DANGER) != 0 )
					return GetScheduleOfType( SCHED_TAKE_COVER_FROM_BEST_SOUND );
				if( (pSound.m_iType & bits_SOUND_COMBAT) != 0 )
					self.Remember(bits_MEMORY_ISLAVE_PROVOKED);
			}
		}

		switch( self.m_MonsterState )
		{
		case MONSTERSTATE_COMBAT:
			// dead enemy
			if( self.HasConditions( bits_COND_ENEMY_DEAD ) )
			{
				// call base class, all code to handle dead enemies is centralized there.
				return BaseClass.GetSchedule();
			}

			if( IsVortWounded(self) )
			{
				if( !self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) )
				{
					const int sched = CanSpawnFamiliar() ? int(SCHED_ISLAVE_COVER_AND_SUMMON_FAMILIAR) : int(SCHED_RETREAT_FROM_ENEMY);

					if( self.HasConditions( bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE ) )
					{
						return GetScheduleOfType( sched );
					}
					if( self.HasConditions( bits_COND_SEE_ENEMY ) && self.HasConditions( bits_COND_ENEMY_FACING_ME ) )
					{
						return GetScheduleOfType( sched );
					}
				}
			}
			break;
		case MONSTERSTATE_ALERT:
		case MONSTERSTATE_IDLE:
		case MONSTERSTATE_HUNT:
		{
			if( !self.HasConditions( bits_COND_NEW_ENEMY | bits_COND_SEE_ENEMY ) ) // ensure there's no enemy
			{
				if ( HasFreeEnergy() && CheckHealOrReviveTargets()) {
					SetHealTargetAsTargetEnt();
					if (CanGoToTargetEnt()) {
						g_Game.AlertMessage(at_aiconsole, "Vort gonna heal or revive friend when idle. State is %1\n", self.m_MonsterState == MONSTERSTATE_ALERT ? "alert" : "idle");
						return GetScheduleOfType( SCHED_ISLAVE_HEAL_OR_REVIVE );
					}
				}
			}
			break;
		}
		default:
			break;
		}
		return BaseClass.GetSchedule();
	}
	Schedule@ GetScheduleOfType( int Type )
	{
		switch( Type )
		{
		case SCHED_FAIL:
			if( self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) )
			{
				return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 );
			}
		case SCHED_CHASE_ENEMY_FAILED:
			if ( HasFreeEnergy() && CheckHealOrReviveTargets() )
			{
				SetHealTargetAsTargetEnt();
				if (CanGoToTargetEnt())
				{
					g_Game.AlertMessage(at_aiconsole, "Vort gonna heal or revive friends after chase enemy sched fail\n");
					return GetScheduleOfType( SCHED_ISLAVE_HEAL_OR_REVIVE );
				}
			}
			else if ( self.m_MonsterState == MONSTERSTATE_COMBAT && !self.HasConditions(bits_COND_ENEMY_TOOFAR) && CanSpawnFamiliar() )
			{
				return GetScheduleOfType( SCHED_ISLAVE_SUMMON_FAMILIAR );
			}
			break;
		case SCHED_RANGE_ATTACK1:
			return slSlaveAttack1;
		case SCHED_RANGE_ATTACK2:
			return slSlaveAttack1;
		case SCHED_ISLAVE_COVER_AND_SUMMON_FAMILIAR:
			return slSlaveCoverAndSummon;
		case SCHED_ISLAVE_SUMMON_FAMILIAR:
			return slSlaveSummon;
		case SCHED_ISLAVE_HEAL_OR_REVIVE:
			return slSlaveHealOrReviveAttack;
		case SCHED_RETREAT_FROM_ENEMY:
			return slRetreatFromEnemy;
		case SCHED_RETREAT_FROM_ENEMY_FAILED:
			{
				if ( self.HasConditions( bits_COND_CAN_RANGE_ATTACK1 ) && self.HasConditions( bits_COND_SEE_ENEMY ) )
				{
					return GetScheduleOfType(SCHED_RANGE_ATTACK1);
				}
			}
			return BaseClass.GetScheduleOfType(SCHED_FAIL);
		}
		
		return BaseClass.GetScheduleOfType( Type );
	}

	void ClearBeams()
	{
		for( int i = 0; i < ISLAVE_MAX_BEAMS; i++ )
		{
			if( m_pBeam[i] !is null )
			{
				m_pBeam[i].SUB_Remove();
				@m_pBeam[i] = null;
			}
		}
		m_iBeams = 0;

		HandsGlowOff();
		RemoveSummonBeams();

		g_SoundSystem.StopSound( self.edict(), CHAN_WEAPON, "debris/zap4.wav" );
	}
	void ArmBeam(int side)
	{
		TraceResult tr;
		float flDist = 1.0;

		if( m_iBeams >= ISLAVE_MAX_BEAMS )
			return;

		Math.MakeAimVectors( pev.angles );
		Vector vecSrc = HandPosition(side);

		for( int i = 0; i < 3; i++ )
		{
			Vector vecAim = g_Engine.v_right * side * Math.RandomFloat( 0, 1 ) + g_Engine.v_up * Math.RandomFloat( -1, 1 );
			TraceResult tr1;
			g_Utility.TraceLine( vecSrc, vecSrc + vecAim * 512, dont_ignore_monsters, self.edict(), tr1 );
			if( flDist > tr1.flFraction )
			{
				tr = tr1;
				flDist = tr.flFraction;
			}
		}

		// Couldn't find anything close enough
		if( flDist == 1.0f )
			return;

		g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CROWBAR );

		@m_pBeam[m_iBeams] = g_EntityFuncs.CreateBeam( "sprites/lgtning.spr", 30 );
		if( m_pBeam[m_iBeams] is null )
			return;

		int brightness;
		const Vector armBeamColor = GetArmBeamColor(brightness);
		m_pBeam[m_iBeams].PointEntInit( tr.vecEndPos, self.entindex() );
		m_pBeam[m_iBeams].SetEndAttachment( AttachmentFromSide(side) );
		m_pBeam[m_iBeams].SetColor( int(armBeamColor.x), int(armBeamColor.y), int(armBeamColor.z) );
		m_pBeam[m_iBeams].SetBrightness( brightness );
		m_pBeam[m_iBeams].SetNoise( 80 );
		m_iBeams++;
	}
	void ArmBeamMessage(int side)
	{
		TraceResult tr;
		float flDist = 1.0;

		Math.MakeAimVectors( pev.angles );
		Vector vecSrc = HandPosition(side);

		for( int i = 0; i < 3; i++ )
		{
			Vector vecAim = g_Engine.v_right * side * Math.RandomFloat( 0, 1 ) + g_Engine.v_up * Math.RandomFloat( -1, 1 );
			TraceResult tr1;
			g_Utility.TraceLine( vecSrc, vecSrc + vecAim * 512, dont_ignore_monsters, self.edict(), tr1 );
			if( flDist > tr1.flFraction )
			{
				tr = tr1;
				flDist = tr.flFraction;
			}
		}

		// Couldn't find anything close enough
		if( flDist == 1.0 )
			return;

		int brightness;
		const Vector armBeamColor = GetArmBeamColor(brightness);

		NetworkMessage m(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc);
		m.WriteByte( TE_BEAMENTPOINT );
		m.WriteShort( self.entindex() + 0x1000 * (AttachmentFromSide(side)) );
		m.WriteCoord( tr.vecEndPos.x );
		m.WriteCoord( tr.vecEndPos.y );
		m.WriteCoord( tr.vecEndPos.z );
		m.WriteShort( m_iLightningTexture );
		m.WriteByte( 0 ); // framestart
		m.WriteByte( 10 ); // framerate
		m.WriteByte( int(10*Math.RandomFloat( 0.8, 1.5 )) ); // life
		m.WriteByte( 30 );  // width
		m.WriteByte( 80 );   // noise
		m.WriteByte( int(armBeamColor.x) );   // r, g, b
		m.WriteByte( int(armBeamColor.y) );   // r, g, b
		m.WriteByte( int(armBeamColor.z) );   // r, g, b
		m.WriteByte( brightness );	// brightness
		m.WriteByte( 10 );		// speed
		m.End();
	}
	void WackBeam( int side, CBaseEntity@ pEntity )
	{
		if( m_iBeams >= ISLAVE_MAX_BEAMS )
			return;

		if( pEntity is null )
			return;

		@m_pBeam[m_iBeams] = g_EntityFuncs.CreateBeam( "sprites/lgtning.spr", 30 );
		if( m_pBeam[m_iBeams] is null )
			return;

		Vector zapColor = GetZapColor();
		m_pBeam[m_iBeams].PointEntInit( pEntity.pev.origin, self.entindex() );
		m_pBeam[m_iBeams].SetEndAttachment( AttachmentFromSide(side) );
		m_pBeam[m_iBeams].SetColor( int(zapColor.x), int(zapColor.y), int(zapColor.z) );
		m_pBeam[m_iBeams].SetBrightness( 255 );
		m_pBeam[m_iBeams].SetNoise( 80 );
		m_iBeams++;
	}
	CBaseEntity@ ZapBeam( int side )
	{
		Vector vecSrc, vecAim;
		TraceResult tr;

		if( m_iBeams >= ISLAVE_MAX_BEAMS )
		{
			g_Game.AlertMessage(at_warning, "Vort didn't zap because too many beams!\n");
			return null;
		}

		vecSrc = pev.origin + g_Engine.v_up * 36;
		if (IsValidHealTarget(m_hWounded)) {
			vecAim = ( ( m_hWounded.GetEntity().BodyTarget( vecSrc ) ) - vecSrc ).Normalize();
			g_Game.AlertMessage(at_aiconsole, "Vort shoot friend on purpose to heal\n");
		} else {
			vecAim = self.ShootAtEnemy( vecSrc );
		}

		float deflection = 0.01;
		vecAim = vecAim + side * g_Engine.v_right * Math.RandomFloat( 0, deflection ) + g_Engine.v_up * Math.RandomFloat( -deflection, deflection );

		const float beamDistance = Math.max(1024.0, m_attackDistance);
		g_Utility.TraceLine( vecSrc, vecSrc + vecAim * beamDistance, dont_ignore_monsters, self.edict(), tr );

		@m_pBeam[m_iBeams] = g_EntityFuncs.CreateBeam( "sprites/lgtning.spr", 50 );
		if( m_pBeam[m_iBeams] is null )
			return null;

		const Vector zapColor = GetZapColor();
		m_pBeam[m_iBeams].PointEntInit( tr.vecEndPos, self.entindex() );
		m_pBeam[m_iBeams].SetEndAttachment( AttachmentFromSide(side) );
		m_pBeam[m_iBeams].SetColor( int(zapColor.x), int(zapColor.y), int(zapColor.z) );
		m_pBeam[m_iBeams].SetBrightness( 255 );
		m_pBeam[m_iBeams].SetNoise( 20 );
		m_iBeams++;

		CBaseEntity@ pResult = null;
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
		if( pEntity !is null && pEntity.pev.takedamage != 0 )
		{
			if (self.IRelationship(pEntity) < R_DL && pEntity.GetClassname() == self.GetClassname()) {
				if (AbleToHeal() && HealOther(pEntity)) {
					g_Game.AlertMessage(at_aiconsole, "Vortigaunt healed friend with zap attack\n");
				}
			} else {
				const float zapDmg = GetVortZapDmg();
				pEntity.TraceAttack( pev, zapDmg, vecAim, tr, DMG_SHOCK );
				if ((pEntity.pev.flags & (FL_CLIENT | FL_MONSTER)) != 0) {
					//TODO: check that target is actually a living creature, not machine
					const float toHeal = zapDmg;
					bool healed = self.TakeHealth(toHeal, DMG_GENERIC);
					if (healed)
					{
						g_Game.AlertMessage(at_aiconsole, "Vortigaunt gets health from enemy\n");
					}
					m_freeEnergy += toHeal/2;
					g_Game.AlertMessage(at_aiconsole, "Vortigaunt gets energy from enemy. Energy level: %1\n", int(m_freeEnergy));
				}
			}
			@pResult = pEntity;
		}
		g_SoundSystem.EmitAmbientSound( self.edict(), tr.vecEndPos, "weapons/electro4.wav", 0.5, ATTN_NORM, 0, Math.RandomLong( 140, 160 ) );
		return pResult;
	}
	void BeamGlow()
	{
		int b = m_iBeams * 32;
		if( b > 255 )
			b = 255;
		
		HandsGlowOn(b);

		for( int i = 0; i < m_iBeams; i++ )
		{
			if( m_pBeam[i].GetBrightness() != 255 )
			{
				m_pBeam[i].SetBrightness( b );
			}
		}
	}
	void HandsGlowOn(int brightness = 224)
	{
		HandGlowOn(m_handGlow1, brightness);
		HandGlowOn(m_handGlow2, brightness);
	}
	void HandGlowOn(CSprite@ handGlow, int brightness = 224)
	{
		if (handGlow !is null) {
			Vector zapColor = GetZapColor();
			handGlow.SetTransparency( kRenderTransAdd, int(zapColor.x), int(zapColor.y), int(zapColor.z), brightness, kRenderFxNoDissipation );
			handGlow.SetOrigin(pev.origin);
			handGlow.SetScale(brightness / 255.0 * 0.3);
			handGlow.pev.effects &= ~EF_NODRAW;
		}
	}
	void StartMeleeAttackGlow(int side)
	{
		CSprite@ handGlow = side == ISLAVE_LEFT_ARM ? m_handGlow2 : m_handGlow1;
		HandGlowOn(handGlow);
		int brightness;
		const Vector armBeamColor = GetArmBeamColor(brightness);
		NetworkMessage m(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin);
		m.WriteByte( TE_BEAMFOLLOW );
		m.WriteShort( self.entindex() + 0x1000 * (AttachmentFromSide(side)) );
		m.WriteShort( m_iTrailTexture );
		m.WriteByte( 5 ); // life
		m.WriteByte( 3 );  // width
		m.WriteByte( int(armBeamColor.x) );   // r, g, b
		m.WriteByte( int(armBeamColor.y) );   // r, g, b
		m.WriteByte( int(armBeamColor.z) );   // r, g, b
		m.WriteByte( 128 );	// brightness
		m.End();
	}
	bool CanUseGlowArms()
	{
		return (pev.spawnflags & SF_SQUADMONSTER_LEADER) != 0 || HasFreeEnergy();
	}
	void HandGlowOff(CSprite@ handGlow)
	{
		if (handGlow !is null) {
			handGlow.pev.effects |= EF_NODRAW;
		}
	}
	void HandsGlowOff()
	{
		HandGlowOff(m_handGlow1);
		HandGlowOff(m_handGlow2);
	}
	void CreateSummonBeams()
	{
		g_EngineFuncs.MakeVectors(pev.angles);
		Vector vecEnd = pev.origin + g_Engine.v_forward * 36;
		if (m_handGlow1 !is null) {
			@m_handsBeam1 = CreateSummonBeam(vecEnd, 1);
		}
		if (m_handGlow2 !is null) {
			@m_handsBeam2 = CreateSummonBeam(vecEnd, 2);
		}
	}
	void RemoveSummonBeams()
	{
		if (m_handsBeam1 !is null)
			m_handsBeam1.SUB_Remove();
		@m_handsBeam1 = null;
		if (m_handsBeam2 !is null)
			m_handsBeam2.SUB_Remove();
		@m_handsBeam2 = null;
	}
	void RemoveHandGlows()
	{
		if (m_handGlow1 !is null)
			m_handGlow1.SUB_Remove();
		@m_handGlow1 = null;
		if (m_handGlow2 !is null)
			m_handGlow2.SUB_Remove();
		@m_handGlow2 = null;
	}
	void CoilBeam()
	{
		Vector zapColor = GetZapColor();

		NetworkMessage m(MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pev.origin);
		m.WriteByte( TE_BEAMCYLINDER );
		m.WriteCoord( pev.origin.x );
		m.WriteCoord( pev.origin.y );
		m.WriteCoord( pev.origin.z + 16 );
		m.WriteCoord( pev.origin.x );
		m.WriteCoord( pev.origin.y );
		m.WriteCoord( pev.origin.z + 16 + ISLAVE_COIL_ATTACK_RADIUS*5 ); 
		m.WriteShort( m_iLightningTexture );
		m.WriteByte( 0 ); // startframe
		m.WriteByte( 10 ); // framerate
		m.WriteByte( 2 ); // life
		m.WriteByte( 128 );  // width
		m.WriteByte( 20 );   // noise

		m.WriteByte( int(zapColor.x) );
		m.WriteByte( int(zapColor.y) );
		m.WriteByte( int(zapColor.z) );

		m.WriteByte( 255 ); //brightness
		m.WriteByte( 0 );		// speed
		m.End();

		NetworkMessage m2(MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pev.origin);
		m2.WriteByte( TE_BEAMCYLINDER );
		m2.WriteCoord( pev.origin.x );
		m2.WriteCoord( pev.origin.y );
		m2.WriteCoord( pev.origin.z + 48 );
		m2.WriteCoord( pev.origin.x );
		m2.WriteCoord( pev.origin.y );
		m2.WriteCoord( pev.origin.z + 48 + ISLAVE_COIL_ATTACK_RADIUS*2 ); 
		m2.WriteShort( m_iLightningTexture );
		m2.WriteByte( 0 ); // startframe
		m2.WriteByte( 10 ); // framerate
		m2.WriteByte( 2 ); // life
		m2.WriteByte( 128 );  // width
		m2.WriteByte( 25 );   // noise

		m2.WriteByte( int(zapColor.x) );
		m2.WriteByte( int(zapColor.y) );
		m2.WriteByte( int(zapColor.z) );

		m2.WriteByte( 255 ); //brightness
		m2.WriteByte( 0 );		// speed
		m2.End();
	}
	void MakeDynamicLight(const Vector& in vecSrc, int radius, int t)
	{
		NetworkMessage m(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc);
		m.WriteByte( TE_DLIGHT );
		m.WriteCoord( vecSrc.x );	// X
		m.WriteCoord( vecSrc.y );	// Y
		m.WriteCoord( vecSrc.z );	// Z
		m.WriteByte( radius );		// radius * 0.1
		m.WriteByte( ISLAVE_LIGHT_RED );		// r
		m.WriteByte( ISLAVE_LIGHT_GREEN);		// g
		m.WriteByte( ISLAVE_LIGHT_BLUE );		// b
		m.WriteByte( t );		// time * 10
		m.WriteByte( 0 );		// decay * 0.1
		m.End();
	}

	Vector HandPosition(int side)
	{
		Math.MakeAimVectors( pev.angles );
		return pev.origin + g_Engine.v_up * 36 + g_Engine.v_right * side * 16 + g_Engine.v_forward * 32;
	}

	CSprite@ CreateHandGlow(int attachment)
	{
		CSprite@ handSprite = g_EntityFuncs.CreateSprite( ISLAVE_HAND_SPRITE_NAME, pev.origin, false );
		handSprite.SetAttachment( self.edict(), attachment );
		handSprite.SetScale(0.25);
		return handSprite;
	}
	CBeam@ CreateSummonBeam(const Vector& in vecEnd, int attachment)
	{
		CBeam@ beam = g_EntityFuncs.CreateBeam( "sprites/lgtning.spr", 30 );
		if( beam is null )
			return beam;

		Vector zapColor = GetZapColor();
		beam.PointEntInit(vecEnd, self.entindex());
		beam.SetEndAttachment(attachment);
		beam.SetColor( int(zapColor.x), int(zapColor.y), int(zapColor.z) );
		beam.SetBrightness( 192 );
		beam.SetNoise( 80 );
		return beam;
	}

	float HealPower()
	{
		return Math.min(GetVortZapDmg(), m_freeEnergy);
	}
	void SpendEnergy(float energy)
	{
		// It's ok to be negative. Vort must restore power to positive values to proceed with healing or reviving.
		if ((pev.spawnflags & SF_SQUADMONSTER_LEADER) != 0) // leader spends less energy
			m_freeEnergy -= energy/2;
		else
			m_freeEnergy -= energy;
	}
	bool HasFreeEnergy() {
		return m_freeEnergy > 0;
	}
	bool AbleToHeal() {
		return true;
	}
	bool AbleToRevive() {
		return true;
	}
	bool CanRevive()
	{
		return AbleToRevive() && m_hDead.GetEntity() !is null && HasFreeEnergy();
	}
	bool HealOther(CBaseEntity@ pEntity)
	{
		if (pEntity.IsAlive() && pEntity.pev.health > 0) {
			const float healthBeforeHealed = pEntity.pev.health;
			if (pEntity.TakeHealth(HealPower(), 0))
			{
				float amount = pEntity.pev.health - healthBeforeHealed;
				if (amount > 0)
				{
					SpendEnergy(amount);
					return true;
				}
			}
		}
		return false;
	}
	bool CanSpawnFamiliar()
	{
		if ((pev.weapons & (ISLAVE_SNARKS | ISLAVE_HEADCRABS)) != 0) {
			if (!self.HasMemory(bits_MEMORY_ISLAVE_FAMILIAR_IS_ALIVE) && m_flSpawnFamiliarTime < g_Engine.time) {
				return true;
			}
		}
		return false;
	}

	Vector GetZapColor()
	{
		if ((pev.spawnflags & SF_SQUADMONSTER_LEADER) != 0) {
			return Vector(ISLAVE_LEADER_ZAP_RED, ISLAVE_LEADER_ZAP_GREEN, ISLAVE_LEADER_ZAP_BLUE);
		}
		return Vector(ISLAVE_ZAP_RED, ISLAVE_ZAP_GREEN, ISLAVE_ZAP_BLUE);
	}
	Vector GetArmBeamColor(int& out brightness)
	{
		if ((pev.spawnflags & SF_SQUADMONSTER_LEADER) != 0) {
			brightness = 128;
			return Vector(ISLAVE_LEADER_ARMBEAM_RED, ISLAVE_LEADER_ARMBEAM_GREEN, ISLAVE_LEADER_ARMBEAM_BLUE);
		}
		brightness = 64;
		return Vector(ISLAVE_ARMBEAM_RED, ISLAVE_ARMBEAM_GREEN, ISLAVE_ARMBEAM_BLUE);
	}

	int AttachmentFromSide(int side) {
		return side < 0 ? 2 : 1;
	}

	void SetHealTargetAsTargetEnt()
	{
		if (m_hDead) {
			self.m_hTargetEnt = m_hDead;
		} else if (m_hWounded) {
			self.m_hTargetEnt = m_hWounded;
		}
	}

	bool CanGoToTargetEnt()
	{
		if (self.m_hTargetEnt.GetEntity() !is null)
			return self.FGetNodeRoute(self.m_hTargetEnt.GetEntity().pev.origin);
		return false;
	}

	string FamiliarName()
	{
		if ((pev.weapons & ISLAVE_SNARKS) != 0) {
			return "monster_snark";
		} else if ((pev.weapons & ISLAVE_HEADCRABS) != 0) {
			return "monster_headcrab";
		}
		return string();
	}

	HULL_NUMBER FamiliarHull()
	{
		return head_hull;
	}

	Vector GetFamiliarSpawnPosition()
	{
		g_EngineFuncs.MakeVectors( pev.angles );
		if ((pev.weapons & ISLAVE_SNARKS) != 0) {
			return pev.origin + g_Engine.v_forward * 36 + Vector(0,0,20);
		} else if ((pev.weapons & ISLAVE_HEADCRABS) != 0) {
			return pev.origin + g_Engine.v_forward * 48 + Vector(0,0,20);
		}
		return pev.origin + g_Engine.v_forward * 36 + Vector(0,0,20);
	}

	array<CBeam@> m_pBeam(ISLAVE_MAX_BEAMS);

	int m_iBeams;
	float m_flNextAttack;

	int m_voicePitch;

	float m_freeEnergy;

	EHandle m_hDead;
	EHandle m_hWounded;
	EHandle m_hWounded2;
	float m_nextHealTargetCheck;
	float m_originalMaxHealth;

	int m_clawStrikeNum;

	float m_flSpawnFamiliarTime;

	CSprite@ m_handGlow1;
	CSprite@ m_handGlow2;
	CBeam@ m_handsBeam1;
	CBeam@ m_handsBeam2;

	int m_iLightningTexture;
	int m_iTrailTexture;
	
	float m_attackDistance;
};

//=========================================================

bool blEntityCreatedHookRegister = false;

dictionary@ DictFromMonster(CBaseMonster@ pMonster)
{
	dictionary dictMonster =
	{
		{ "displayname",        "" + pMonster.m_FormattedName },
		{ "health",             "" + pMonster.pev.health },
		{ "max_health",         "" + pMonster.pev.max_health },
		{ "body",               "" + pMonster.pev.body },
		{ "skin",               "" + pMonster.pev.skin },
		{ "weapons",            "" + pMonster.pev.weapons },
		{ "bloodcolor",         "" + pMonster.m_bloodColor },
		{ "TriggerCondition",   "" + pMonster.m_iTriggerCondition },
		{ "rendermode",         "" + pMonster.pev.rendermode },
		{ "renderamt",          "" + pMonster.pev.renderamt },
		{ "renderfx",           "" + pMonster.pev.renderfx },
		{ "rendercolor",        pMonster.pev.rendercolor.ToString().Replace( ",", "" ) }
	};

	if( pMonster.GetTargetname() != "" )
		dictMonster["targetname"] = pMonster.GetTargetname();

	if( pMonster.pev.target != "" )
		dictMonster["target"] = "" + pMonster.pev.target;

	if( pMonster.pev.netname != "" )
		dictMonster["netname"] = "" + pMonster.pev.netname;

	if( pMonster.m_fCustomModel )
		dictMonster["model"] = "" + pMonster.pev.model;

	if( pMonster.m_iszTriggerTarget != "" )
		dictMonster["TriggerTarget"] = "" + pMonster.m_iszTriggerTarget;

	if( pMonster.m_iszGuardEntName != "" )
		dictMonster["guard_ent"] = "" + pMonster.m_iszGuardEntName;

	if( pMonster.m_fOverrideClass )
	{
		if (pMonster.m_iClassSelection <= 0)
			dictMonster["classify"] = "-1";
		else
			dictMonster["classify"] = "" + pMonster.m_iClassSelection;
	}

	if( pMonster.pev.spawnflags > 0 )
		dictMonster["spawnflags"] = "" + ( pMonster.pev.spawnflags & ~( 16 | 64 | 128 | 256 ) );

	CustomKeyvalues@ customKeyValues = pMonster.GetCustomKeyvalues();
	if (customKeyValues !is null)
	{
		float customAttackDistance = customKeyValues.GetKeyvalue("$f_attack_distance").GetFloat();
		if (customAttackDistance != 0)
		{
			//g_Game.AlertMessage(at_console, "Got custom attack distance: %1\n", customAttackDistance);
			dictMonster["attack_distance"] = "" + customAttackDistance;
		}
	}

	return @dictMonster;
}

void VortSpawned(EHandle hEntity)
{
	CBaseEntity@ pEntity = hEntity.GetEntity();
	if (pEntity !is null)
	{
		CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
		if (pMonster !is null)
		{
			dictionary@ dictMonster = DictFromMonster(pMonster);
			dictMonster["origin"] = pEntity.GetOrigin().ToString().Replace( ",", "" );
			dictMonster["angles"] = pEntity.pev.angles.ToString().Replace( ",", "" );
			g_EntityFuncs.Remove(pEntity);
			g_EntityFuncs.CreateEntity( "monster_alien_slave_fi", dictMonster );
		}
	}
}

HookReturnCode EntityCreated(CBaseEntity@ pEntity)
{
	if( pEntity !is null && pEntity.pev.classname == "monster_alien_slave" )
	{
		CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
		if (pMonster !is null)
		{
			g_Scheduler.SetTimeout( "VortSpawned", 0.0f, EHandle(pEntity) );
// 			if (pEntity.pev.owner is null)
// 			{
// 				g_Scheduler.SetTimeout( "VortSpawned", 0.0f, DictFromMonster(pMonster), EHandle(pEntity) );
// 			}
// 			else
// 			{
// 				VortSpawned(DictFromMonster(pMonster), EHandle(pEntity));
// 			}
			return HOOK_HANDLED;
		}
	}
	return HOOK_CONTINUE;
}

void Register(bool replaceOrigVorts = true)
{
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "FIVortigaunt::CISlave", "monster_alien_slave_fi" );
	if (replaceOrigVorts)
	{
		g_Game.PrecacheOther("monster_alien_slave_fi");
		if (!blEntityCreatedHookRegister)
			blEntityCreatedHookRegister = g_Hooks.RegisterHook( Hooks::Game::EntityCreated, @EntityCreated );
	}
}

void MapActivate()
{
	if (!blEntityCreatedHookRegister)
		return;
	CBaseEntity@ pVort = null;
	while( ( @pVort = g_EntityFuncs.FindEntityByClassname( pVort, "monster_alien_slave" ) ) !is null )
	{
		CBaseMonster@ pMonster = pVort.MyMonsterPointer();
		if (pMonster !is null)
			VortSpawned(EHandle(pVort));
	}
}

}
