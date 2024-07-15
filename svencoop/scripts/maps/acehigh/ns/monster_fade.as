/* Natural Selection Fade NPC Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://github.com/ValveSoftware/halflife Half-Life SDK - by Valve
https://twhl.info/wiki/page/Tutorial%3A_Coding_NPCs_in_GoldSrc - by dexter
Natural Selection Source Code - by Unknown Worlds
*/
namespace NS_FADE
{
//Vars
const int TASKSTATUS_RUNNING = 1;
const bool blPredictiveLeap = false;
//Models
const string MODEL = "models/ns/monsters/fade_test_b.mdl";

//Sounds
const string FADE_SOUND_LEAP = "ns/monsters/fade/blinksuccess.wav";
const string FADE_SOUND_LEAP_HIT = "ns/monsters/skulk/leaphit1.wav";
const string FADE_SOUND_ATTACK1 = "ns/monsters/fade/claws1.wav";
const string FADE_SOUND_ATTACK2 = "ns/monsters/fade/claws2.wav";
const string FADE_SOUND_ATTACK3 = "ns/monsters/fade/claws3.wav";
const string FADE_SOUND_DEATH1 = "ns/monsters/fade/role6_die1.wav";
const string FADE_SOUND_DEATH2 = "ns/monsters/fade/role6_pain1.wav";

const string FADE_SOUND_WOUND1 = "ns/monsters/fade/role6_wound1.wav";

const string FADE_SOUND_IDLE = "ns/monsters/fade/role6_idle1.wav";
const string FADE_SOUND_ALERT = "ns/monsters/fade/role6_move1.wav";
const string FADE_SOUND_TAUNT1 = "ns/monsters/asay31.wav";

array<string> SOUNDS = {
	FADE_SOUND_LEAP,
	FADE_SOUND_LEAP_HIT,
	FADE_SOUND_ATTACK1,
	FADE_SOUND_ATTACK2,
	FADE_SOUND_ATTACK3,
	FADE_SOUND_DEATH1,
	FADE_SOUND_DEATH2,
	FADE_SOUND_WOUND1,
	FADE_SOUND_IDLE,
	FADE_SOUND_ALERT,
	FADE_SOUND_TAUNT1
};

//Stats
const float BITE_DMG = 25;
const float LEAP_DMG = 25;
const float MAX_HEALTH = 500;
const float CLOAK_AMT = 100; //Strength of cloak, lower = more invis

//enum FADE_EVENTS 
//{
//  FADE_IDLE_SOUND = 1,
//  FADE_ATTACK,
//  FADE_LEAP
//}

enum FADE_EVENTS 
{
  FADE_ATTACK = 2,
  FADE_LEAP
}

array<ScriptSchedule@>@ custom_fade_schedules;

ScriptSchedule slFadeLeap
(
	bits_COND_ENEMY_OCCLUDED |
	bits_COND_NO_AMMO_LOADED,
	0,
	"FadeLeap"
);

ScriptSchedule slFadeAttack
(
	bits_COND_NEW_ENEMY			|
	bits_COND_ENEMY_DEAD		|
	bits_COND_LIGHT_DAMAGE		|
	bits_COND_HEAVY_DAMAGE		|
	bits_COND_ENEMY_OCCLUDED,
	0,
	"FadeAttack"
);

ScriptSchedule slFadeChase
(
	bits_COND_NEW_ENEMY			|
	bits_COND_CAN_RANGE_ATTACK1	|
	bits_COND_CAN_MELEE_ATTACK1	|
	bits_COND_CAN_RANGE_ATTACK2	|
	bits_COND_CAN_MELEE_ATTACK2	|
	bits_COND_TASK_FAILED		|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER,
	"FadeChase"
);

void InitSchedules()
{
	slFadeLeap.AddTask( ScriptTask(TASK_STOP_MOVING, 0) );
	slFadeLeap.AddTask( ScriptTask(TASK_FACE_IDEAL, 0) );
	slFadeLeap.AddTask( ScriptTask(TASK_RANGE_ATTACK1, 0) );
	slFadeLeap.AddTask( ScriptTask(TASK_SET_ACTIVITY, ACT_IDLE) );
	slFadeLeap.AddTask( ScriptTask(TASK_FACE_IDEAL, 0) );
	
	slFadeAttack.AddTask( ScriptTask(TASK_STOP_MOVING, 0) );
	slFadeAttack.AddTask( ScriptTask(TASK_FACE_ENEMY, 0) );
	slFadeAttack.AddTask( ScriptTask(TASK_MELEE_ATTACK1, 0) );
	
	slFadeChase.AddTask( ScriptTask(TASK_SET_FAIL_SCHEDULE, SCHED_CHASE_ENEMY_FAILED ) );
	slFadeChase.AddTask( ScriptTask(TASK_GET_PATH_TO_ENEMY, 0 ) );
	slFadeChase.AddTask( ScriptTask(TASK_RUN_PATH, 0 ) );
	slFadeChase.AddTask( ScriptTask(TASK_WAIT_FOR_MOVEMENT, 0 ) );

	array<ScriptSchedule@> scheds = { slFadeLeap, slFadeAttack };
	
	@custom_fade_schedules = @scheds;
}

class monster_fade : ScriptBaseMonsterEntity
{
	private float m_flNextLeapAttack;
	private float m_flNextTauntTime;
	private bool m_blCanCamo = true;
	private bool m_blCamo = false;
	private float m_flNextCamoTime;
	
	void Spawn()
	{
		Precache();
		
		g_EntityFuncs.SetModel( self, MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, 0 ), Vector( 16, 16, 80 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_YELLOW;
		if( self.pev.health == 0 )
			self.pev.health = MAX_HEALTH;
		self.pev.max_health = self.pev.health;	
		self.m_MonsterState = MONSTERSTATE_NONE;
		
		//Start camouflaged (if enabled)
		if( m_blCanCamo )
		{
			m_blCamo = true;
			self.pev.rendermode = kRenderTransAdd;
			self.pev.renderfx = kRenderFxPulseSlowWide;
			self.pev.renderamt = CLOAK_AMT;
		}
		self.m_FormattedName = "Fade";
		self.MonsterInit();

		//If the model lacks an eye position, view_ofs should be defined after MonsterInit
		self.pev.view_ofs = Vector( 0, 0, 40 );
		self.m_flFieldOfView = 0.2;

		SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
		
		//allow it to open doors :)
		self.m_afCapability |= bits_CAP_DOORS_GROUP | bits_CAP_HEAR;
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_blCanCamo" )
		{
			m_blCanCamo = atobool( szValue );
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
		
		return true;
	}
	
	void Precache()
	{
		//precache shit here
		g_Game.PrecacheModel( MODEL );
		
		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}		
	}
	
	int Classify()
	{
		// player ally override
		if( self.IsPlayerAlly() )
			return CLASS_PLAYER_ALLY;
		
		// allow custom monster classifications
		if( self.m_fOverrideClass )
			return self.m_iClassSelection;

		//default			
		return CLASS_ALIEN_MILITARY;
	}  	
	
	void SetYawSpeed()
	{
		self.pev.yaw_speed = 150;
	}
	
	void DisableCamo()
	{
		self.pev.renderamt = 0;
		self.pev.renderfx = 0;
		self.pev.rendermode = 0;
		m_blCamo = false;
	}
	
	void EnableCamo()
	{
		self.pev.rendermode = kRenderTransAdd;
		self.pev.renderfx = kRenderFxPulseSlowWide;
		self.pev.renderamt = CLOAK_AMT;
		m_blCamo = true;
	}
	
	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case FADE_ATTACK:
			{
				if( m_blCamo )
				{
					DisableCamo();
				}
				CBaseEntity@ pHurt = CheckTraceHullAttack( self, 100, BITE_DMG, DMG_SLASH );
				if( pHurt !is null )
				{
					pHurt.pev.punchangle.z = -18;
					pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_forward * 40;					
				}
				//Let the Fade laugh at the poor sod it just killed
				if( pHurt !is null && !pHurt.IsAlive() && pHurt.IsPlayer() && m_flNextTauntTime < g_Engine.time )
				{
					if( Math.RandomLong( 0, 2 ) == 0 && self.IsAlive() )
					{
						g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, FADE_SOUND_TAUNT1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
						m_flNextTauntTime = g_Engine.time + 10;
					}
				}
				self.m_flNextAttack = g_Engine.time + 0.2;
				
				string szAttackSound;
				switch( Math.RandomLong( 0, 2 ) )
				{
					case 0:
						szAttackSound = FADE_SOUND_ATTACK1;
						break;
					case 1:
						szAttackSound = FADE_SOUND_ATTACK2;
						break;
					case 2:
						szAttackSound = FADE_SOUND_ATTACK3;
						break;					
				}
				
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, szAttackSound, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin,  600, 0.3, self );
				break;
			}
			case FADE_LEAP:
			{
				if( m_blCamo )
				{
					DisableCamo();
				}
				self.pev.flags &= ~FL_ONGROUND;

				g_EntityFuncs.SetOrigin( self, self.pev.origin + Vector( 0, 0, 1 ) );// take him off ground so engine doesn't instantly reset onground 
				Math.MakeVectors( self.pev.angles );

				Vector vecJumpDir;
				if( self.m_hEnemy.GetEntity() !is null )
				{
					CBaseEntity@ pEnemy = cast<CBaseEntity@>( self.m_hEnemy.GetEntity() );
					float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
					if( gravity <= 1 )
						gravity = 1;

					// How fast does the fade need to travel to reach that height given gravity?
					float height = ( pEnemy.pev.origin.z + pEnemy.pev.view_ofs.z - self.pev.origin.z );// - 20;
					//Avoid NaNs
					if( height <= 0 )
						height = 1;
					float speed = sqrt( 2 * gravity * height );
					float time = speed / gravity;
					
					Vector vecTarget = pEnemy.pev.origin + pEnemy.pev.view_ofs; 
					
					if( blPredictiveLeap )
					{
						//Fade tries to predict your movement
						Vector vecTargetOffset = pEnemy.pev.velocity.Normalize()*( Math.max( pEnemy.pev.velocity.Length2D(), 400 ) );
						vecTargetOffset.z = 0;
						vecJumpDir = ( ( vecTarget + vecTargetOffset ) - self.pev.origin );					
					}
					else
						vecJumpDir = ( vecTarget - self.pev.origin );
					
					
					vecJumpDir = vecJumpDir * ( 1.0 / time );
					// Speed to offset gravity at the desired height
					vecJumpDir.z = speed;

					// Don't jump too far/fast
					float distance = vecJumpDir.Length();
					
					if( distance > 650 )
						vecJumpDir = vecJumpDir * ( 650.0/distance );
				}
				else
				{
					// jump hop, don't care where
					vecJumpDir = Vector( g_Engine.v_forward.x, g_Engine.v_forward.y, g_Engine.v_up.z ) * 350;
				}
				
				self.pev.velocity = vecJumpDir;
				m_flNextLeapAttack = g_Engine.time + 4;
				break;
			}
			default:
				BaseClass.HandleAnimEvent( pEvent );	
				break;
		}
	}
	
	Schedule@ GetSchedule()
	{
		switch( self.m_MonsterState )
		{		
			case MONSTERSTATE_COMBAT:
			{	
				if( self.HasConditions( bits_COND_ENEMY_DEAD ) )
				{
					return BaseClass.GetSchedule();	
				}
				if( self.HasConditions( bits_COND_HEAVY_DAMAGE ) )
				{
					return BaseClass.GetScheduleOfType( SCHED_TAKE_COVER_FROM_ENEMY );
				}

				self.pev.movetype = MOVETYPE_STEP;
				CBaseEntity@ pTarget = self.m_hEnemy.GetEntity();
				
				if( pTarget !is null )
				{
					float distToEnemy = ( self.pev.origin - pTarget.pev.origin).Length();
					if( distToEnemy < 64 && self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) && pTarget.pev.velocity == Vector( 0, 0, 0 ) )
					{
						return GetScheduleOfType( SCHED_MELEE_ATTACK1 );
					}
					if( distToEnemy >= 180 && distToEnemy <= 360 && m_flNextLeapAttack < g_Engine.time )
					{
						return GetScheduleOfType( SCHED_RANGE_ATTACK1 );
					}
				}
				if( !self.HasConditions( bits_COND_CAN_RANGE_ATTACK1 ) )
				{
					return GetScheduleOfType( SCHED_CHASE_ENEMY );
				}				
				else
					return BaseClass.GetSchedule();
			}
			default:
			{
				if( !m_blCamo )
				{
					m_flNextCamoTime = g_Engine.time + 5;
				}
			}
			break;
		}
		return BaseClass.GetSchedule();
	}
	
	Schedule@ GetScheduleOfType( int Type )
	{
		switch( Type )
		{
			case SCHED_RANGE_ATTACK1: 
			{	
				return slFadeLeap;
			}
			case SCHED_MELEE_ATTACK1: 
			{
				return slFadeAttack;
			}
			case SCHED_CHASE_ENEMY:
			{
				return slFadeChase;
			}
			
		}
		return BaseClass.GetScheduleOfType( Type );
	}

	void StartTask ( Task@ pTask )
	{
		self.m_iTaskStatus = TASKSTATUS_RUNNING;

		switch ( pTask.iTask )
		{
			case TASK_RANGE_ATTACK1:
			{
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, FADE_SOUND_LEAP, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin,  400, 0.3, self );
				self.m_IdealActivity = ACT_RANGE_ATTACK1;
				SetTouch( TouchFunction( LeapTouch ) );
				break;
			}
			case TASK_MELEE_ATTACK1:
			{			
				self.m_IdealActivity = ACT_MELEE_ATTACK1;
				break;
			}
			default:
				BaseClass.StartTask( pTask );
		}
	}
	
	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		if( flDist <= 80 && flDot >= 0.7 && self.m_hEnemy.GetEntity() !is null && self.pev.FlagBitSet( FL_ONGROUND ) && self.m_flNextAttack < g_Engine.time )
		{
			return true;
		}
		return false;
	}	
	
	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( m_flNextLeapAttack > g_Engine.time )
		{
			return false;
		}

		if( self.m_hEnemy.GetEntity() !is null && self.m_hEnemy.GetEntity().pev.velocity != g_vecZero 
			&& self.pev.FlagBitSet( FL_ONGROUND ) && flDist > 180 && flDist <= 360 && flDot >= 0.65 )
		{
			return true;
		}

		return false;
	}
	
	void MonsterThink()
	{
		BaseClass.Think();
		if( @self.m_pSchedule is GetScheduleOfType( SCHED_CHASE_ENEMY ) && m_flNextLeapAttack < g_Engine.time )
		{
			CBaseEntity@ pTarget = self.m_hEnemy.GetEntity();
			if( pTarget !is null )
			{
				float distToEnemy = ( self.pev.origin - pTarget.pev.origin ).Length();
				
				//if( distToEnemy >= 160 && distToEnemy <= 224 )
				if( distToEnemy >= 180 && distToEnemy <= 360 )
				{
					self.ChangeSchedule( GetScheduleOfType( SCHED_RANGE_ATTACK1 ) );
					m_flNextLeapAttack = g_Engine.time + 4;
				}
			}
		}
		
		//This if block handles the attack whilst moving functionality by forcing gaitsequences
		if( @self.m_pSchedule is GetScheduleOfType( SCHED_CHASE_ENEMY ) )
		{
			CBaseEntity@ pEnemy = cast<CBaseEntity@>( self.m_hEnemy.GetEntity() );

			if( pEnemy !is null )
			{
				float distToEnemy = ( self.pev.origin - pEnemy.pev.origin).Length();
				
				if( self.pev.gaitsequence != 3 )
					self.pev.gaitsequence = 3;
				if( distToEnemy <= 80 && self.FInViewCone( pEnemy ) && self.pev.FlagBitSet( FL_ONGROUND ) && self.m_flNextAttack < g_Engine.time )
				{
					if( self.pev.sequence != 8 )
					{
						self.pev.sequence = 8;
						self.pev.gaitsequence = 3;
					}
				}
			}
		}
		
		//Seems to remain in combat if the player stays within their body
		if( m_blCanCamo && self.m_MonsterState != MONSTERSTATE_COMBAT && self.m_MonsterState != MONSTERSTATE_DEAD && !m_blCamo && m_flNextCamoTime < g_Engine.time )
			EnableCamo();
	}
	
	void LeapTouch( CBaseEntity@ pOther )
	{
		if ( pOther.pev.takedamage == DAMAGE_NO )
			return;

		if ( pOther.Classify() == self.Classify() )
			return;

		// Don't hit if back on ground
		if ( !self.pev.FlagBitSet( FL_ONGROUND ) )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, FADE_SOUND_LEAP_HIT, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			pOther.TakeDamage( self.pev, self.pev, LEAP_DMG, DMG_SLASH );
			
			pOther.pev.punchangle.z = -18;
			//TODO: Briefly slow down player
		}

		SetTouch( null );
	}
	
	CBaseEntity@ CheckTraceHullAttack( CBaseMonster@ pThis, float flDist, int iDamage, int iDmgType )
	{
		TraceResult tr;

		if( pThis.IsPlayer() )
			Math.MakeVectors( pThis.pev.angles );
		else
			Math.MakeAimVectors( pThis.pev.angles );

		Vector vecStart = self.pev.origin;

		vecStart.z += 64.0f;
		Vector vecEnd = vecStart + ( g_Engine.v_forward * flDist ) - ( g_Engine.v_up * flDist * 0.3 );

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );

		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
		if( pEntity !is null )
		{
			if( iDamage > 0 )
			{
				pEntity.TakeDamage( pThis.pev, pThis.pev, iDamage, iDmgType );
			}

			return pEntity;
		}

		return null;
	}

	void DeathSound()
	{
		switch ( Math.RandomLong( 0, 1 ) )
		{
		case 0:	
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, FADE_SOUND_DEATH1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, FADE_SOUND_DEATH2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			break;
		}
	}
	
	void PainSound()
	{
		if( Math.RandomLong( 0, 5 ) < 2 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, FADE_SOUND_WOUND1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		}
	}

	void RunAI( void )
	{
		if(( self.m_MonsterState == MONSTERSTATE_IDLE || self.m_MonsterState == MONSTERSTATE_ALERT ) && Math.RandomLong( 0, 99 ) == 0 )
			IdleSound();

		BaseClass.RunAI();
	}		
	
	void IdleSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, FADE_SOUND_IDLE, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, FADE_SOUND_ALERT, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}	
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if ( bitsDamageType & DMG_BULLET > 0 )
		{
			Vector vecDir = self.pev.origin - ( pevInflictor.absmin + pevInflictor.absmax ) * 0.5;
			vecDir = vecDir.Normalize();
			float flForce = self.DamageForce( flDamage );
			self.pev.velocity = self.pev.velocity + vecDir * flForce;
			flDamage *= 0.7;
		}	
		
		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	float GetPointsForDamage( float flDamage )
	{
		//return ( flDamage/self.pev.max_health ) * ( 3 * ( self.pev.max_health/sk_fade_health.value ) );
		return ( flDamage/self.pev.max_health ) * ( 10 );
	}	

}

void Register()
{
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_FADE::monster_fade", "monster_fade" );
}
}