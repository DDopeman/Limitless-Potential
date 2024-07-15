
/* Natural Selection Skulk NPC Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://github.com/ValveSoftware/halflife Half-Life SDK - by Valve
https://twhl.info/wiki/page/Tutorial%3A_Coding_NPCs_in_GoldSrc - by dexter
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_SKULK
{
//Vars
const int TASKSTATUS_RUNNING = 1;
//Models
const string MODEL = "models/ns/monsters/skulk_test_b.mdl";

//Sounds
const string SKULK_SOUND_LEAP = "ns/monsters/skulk/leap1.wav";
const string SKULK_SOUND_LEAP_HIT = "ns/monsters/skulk/leaphit1.wav";
const string SKULK_SOUND_BITE1 = "ns/monsters/skulk/bite.wav";
const string SKULK_SOUND_BITE2 = "ns/monsters/skulk/bite2.wav";
const string SKULK_SOUND_DEATH1 = "ns/monsters/skulk/role4_die1.wav";
const string SKULK_SOUND_DEATH2 = "ns/monsters/skulk/role4_pain1.wav";
const string SKULK_SOUND_WOUND1 = "ns/monsters/skulk/role4_wound1.wav";
const string SKULK_SOUND_WOUND2 = "ns/monsters/skulk/role4_wound2.wav";
const string SKULK_SOUND_IDLE = "ns/monsters/skulk/role4_idle1.wav";
const string SKULK_SOUND_ALERT = "ns/monsters/skulk/role5_move1.wav";

array<string> SOUNDS = {
	SKULK_SOUND_LEAP,
	SKULK_SOUND_LEAP_HIT,
	SKULK_SOUND_BITE1,
	SKULK_SOUND_BITE2,
	SKULK_SOUND_DEATH1,
	SKULK_SOUND_DEATH2,
	SKULK_SOUND_WOUND1,
	SKULK_SOUND_WOUND2,
	SKULK_SOUND_IDLE,
	SKULK_SOUND_ALERT 
};

//Stats
const float BITE_DMG = 25;
const float LEAP_DMG = 25;
const float MAX_HEALTH = 100;

enum SKULK_EVENTS 
{
  SKULK_ATTACK = 2,
  SKULK_LEAP
}

array<ScriptSchedule@>@ custom_skulk_schedules;

ScriptSchedule slSkulkLeap
(
	bits_COND_ENEMY_OCCLUDED |
	bits_COND_NO_AMMO_LOADED,
	0,
	"SkulkLeap"
);

void InitSchedules()
{
	slSkulkLeap.AddTask( ScriptTask(TASK_STOP_MOVING, 0) );
	slSkulkLeap.AddTask( ScriptTask(TASK_FACE_IDEAL, 0) );
	slSkulkLeap.AddTask( ScriptTask(TASK_RANGE_ATTACK1, 0) );
	slSkulkLeap.AddTask( ScriptTask(TASK_SET_ACTIVITY, ACT_IDLE) );
	slSkulkLeap.AddTask( ScriptTask(TASK_FACE_IDEAL, 0) );
	//slSkulkLeap.AddTask( ScriptTask(TASK_WAIT_RANDOM, 0.5f) );

	array<ScriptSchedule@> scheds = { slSkulkLeap };
	
	@custom_skulk_schedules = @scheds;
}

class monster_skulk : ScriptBaseMonsterEntity
{
	private float m_flNextLeapAttack;
	
	void Spawn()
	{
		Precache();
		
		g_EntityFuncs.SetModel( self, MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, 0 ), Vector( 16, 16, 32 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_YELLOW;
		if( self.pev.health == 0 )
			self.pev.health = MAX_HEALTH;
		self.pev.max_health = self.pev.health;
		self.m_MonsterState = MONSTERSTATE_NONE;
		
		self.m_FormattedName = "Skulk";
		self.MonsterInit();

		//If the model lacks an eye position, view_ofs should be defined after MonsterInit
		self.pev.view_ofs = Vector( 0, 0, 10 );
		self.m_flFieldOfView = 0.2;
		self.m_afCapability |= bits_CAP_HEAR;

		SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
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
	
	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case SKULK_ATTACK:
			{
				CBaseEntity@ pHurt = CheckTraceHullAttack( self, 80, BITE_DMG, DMG_SLASH );
				if( pHurt !is null )
				{
					pHurt.pev.punchangle.z = -18;
					pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_forward * 40;					
				}
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Math.RandomLong( 0, 1 ) == 0 ? SKULK_SOUND_BITE1: SKULK_SOUND_BITE2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin,  600, 0.3, self );
			}
			//Do not break here, this is a cheap hack which will force the skulk to leap whilst melee attacking, giving the impression it is trying to dodge the player
			//break;
			case SKULK_LEAP:
			{	
				self.pev.flags &= ~FL_ONGROUND;

				g_EntityFuncs.SetOrigin( self, self.pev.origin + Vector( 0, 0, 1 ) );// take him off ground so engine doesn't instantly reset onground 
				Math.MakeVectors( self.pev.angles );

				Vector vecJumpDir;
				if( self.m_hEnemy.GetEntity() !is null )
				{
					float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
					if( gravity <= 1 )
						gravity = 1;

					// How fast does the skulk need to travel to reach that height given gravity?
					float height = ( self.m_hEnemy.GetEntity().pev.origin.z + self.m_hEnemy.GetEntity().pev.view_ofs.z - self.pev.origin.z ) - 20;
					if( height < 16 )
						height = 16;
					float speed = sqrt( 2 * gravity * height );
					float time = speed / gravity;

					// Scale the sideways velocity to get there at the right time
					vecJumpDir = ( self.m_hEnemy.GetEntity().pev.origin + self.m_hEnemy.GetEntity().pev.view_ofs - self.pev.origin );
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
			}
			break;
			
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

					if( distToEnemy < 96 && self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) )
					{
						return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 );
					}
					else if( distToEnemy >= 160 && distToEnemy <= 224 )
					{
						return GetScheduleOfType( SCHED_RANGE_ATTACK1 );
					}
				}
				else
					return BaseClass.GetSchedule();
			}			
		}
		return BaseClass.GetSchedule();
	}
	
	Schedule@ GetScheduleOfType( int Type )
	{
		switch( Type )
		{
			case SCHED_RANGE_ATTACK1: return slSkulkLeap;
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
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, SKULK_SOUND_LEAP, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin,  700, 0.3, self );
				self.m_IdealActivity = ACT_RANGE_ATTACK1;
				SetTouch( TouchFunction( LeapTouch ) );
				break;
			}
			default:
				BaseClass.StartTask( pTask );
		}
	}
	
	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		if( flDist <= 80 && flDot >= 0.7 && self.m_hEnemy.GetEntity() !is null && self.pev.FlagBitSet( FL_ONGROUND ) )
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

		if( self.m_hEnemy.GetEntity() !is null && self.m_hEnemy.GetEntity().pev.velocity != g_vecZero && self.pev.FlagBitSet( FL_ONGROUND ) && flDist > 160 && flDist <= 224 && flDot >= 0.65 )
		{
			return true;
		}

		return false;
	}	
	
	void MonsterThink()
	{
		BaseClass.Think();
		if( @self.m_pSchedule is BaseClass.GetScheduleOfType( SCHED_CHASE_ENEMY ) && m_flNextLeapAttack < g_Engine.time )
		{
			CBaseEntity@ pTarget = self.m_hEnemy.GetEntity();
			
			if( pTarget !is null )
			{
				float distToEnemy = ( self.pev.origin - pTarget.pev.origin ).Length();
				
				if( distToEnemy >= 160 && distToEnemy <= 224 )
				{
					self.ChangeSchedule( BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ) );
					m_flNextLeapAttack = g_Engine.time + 4;
				}
			}
		}
	}
	
	void LeapTouch( CBaseEntity@ pOther )
	{
		if ( !self.IsAlive() )
			return;
			
		if ( pOther.pev.takedamage == DAMAGE_NO )
			return;

		if ( pOther.Classify() == self.Classify() )
			return;

		// Don't hit if back on ground
		if ( !self.pev.FlagBitSet( FL_ONGROUND ) )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, SKULK_SOUND_LEAP_HIT, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			pOther.TakeDamage( self.pev, self.pev, LEAP_DMG, DMG_SLASH );
			
			pOther.pev.punchangle.z = -18;
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
		//vecStart.z += self.pev.size.z * 0.5;
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
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, SKULK_SOUND_DEATH1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, SKULK_SOUND_DEATH2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			break;
		}
	}
	
	void PainSound()
	{
		if( Math.RandomLong( 0, 5 ) < 2 )
		{
			switch ( Math.RandomLong( 0, 1 ) )
			{
			case 0:	
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, SKULK_SOUND_WOUND1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, SKULK_SOUND_WOUND2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				break;
			}
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, SKULK_SOUND_IDLE, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, SKULK_SOUND_ALERT, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}
	
	float GetPointsForDamage( float flDamage )
	{
		//return ( flDamage/self.pev.max_health ) * ( 3 * ( self.pev.max_health/sk_skulk_health.value ) );
		return ( flDamage/self.pev.max_health ) * ( 3 );
	}

}

void Register()
{
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_SKULK::monster_skulk", "monster_skulk" );
}
}