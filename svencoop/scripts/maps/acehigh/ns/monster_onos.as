
/* Natural Selection Onos NPC Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://github.com/ValveSoftware/halflife Half-Life SDK - by Valve
https://twhl.info/wiki/page/Tutorial%3A_Coding_NPCs_in_GoldSrc - by dexter
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_ONOS
{
//Vars
const int TASKSTATUS_RUNNING = 1;
//Models
const string MODEL = "models/ns/monsters/onos_test_a.mdl";
const string MODEL_STOMP = "models/ns/monsters/stomp_test_a.mdl";
const string SPRITE_STOMP = "sprites/ns/stomp.spr";

//Sounds
const string ONOS_SOUND_ATTACK1 = "ns/monsters/onos/swipe1.wav";
const string ONOS_SOUND_ATTACK2 = "ns/monsters/onos/swipe2.wav";
const string ONOS_SOUND_ATTACK3 = "ns/monsters/onos/swipe3.wav";
const string ONOS_SOUND_ATTACK4 = "ns/monsters/onos/swipe4.wav";
const string ONOS_SOUND_STOMP = "ns/monsters/onos/stomp.wav";
const string ONOS_SOUND_DEATH1 = "ns/monsters/onos/role7_die1.wav";
const string ONOS_SOUND_DEATH2 = "ns/monsters/onos/role7_die2.wav";

const string ONOS_SOUND_WOUND1 = "ns/monsters/onos/role7_wound1.wav";
const string ONOS_SOUND_WOUND2 = "ns/monsters/onos/role7_pain1.wav";

const string ONOS_SOUND_IDLE = "ns/monsters/onos/role7_idle1.wav";
const string ONOS_SOUND_ALERT = "ns/monsters/onos/role7_spawn1.wav";

array<string> SOUNDS = {
	ONOS_SOUND_ATTACK1,
	ONOS_SOUND_ATTACK2,
	ONOS_SOUND_ATTACK3,
	ONOS_SOUND_ATTACK4,
	ONOS_SOUND_STOMP,
	ONOS_SOUND_DEATH1,
	ONOS_SOUND_DEATH2,
	ONOS_SOUND_WOUND1,
	ONOS_SOUND_WOUND2,
	ONOS_SOUND_IDLE,
	ONOS_SOUND_ALERT
};

//Stats
const float BITE_DMG = 25;
const float MAX_HEALTH = 800;

const float STOMP_SPEED = 600;
const float STOMP_STUN_DURATION = 3.0f;

enum ONOS_EVENTS 
{
  ONOS_ATTACK = 2,
}

array<ScriptSchedule@>@ custom_onos_schedules;

void InitSchedules()
{

}

//Remove stomp's stun from players after a short duration
HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;
		
	CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();
	int iStunned = kvPlayer.GetKeyvalue( "$i_ns_stunned" ).GetInteger();
	float flStunTime = kvPlayer.GetKeyvalue( "$f_ns_stun_time" ).GetFloat();

	if( iStunned == 1 && flStunTime < g_Engine.time )
	{
		g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_ns_stunned", "0" );	
		pPlayer.SetMaxSpeed( int( g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) ) );		
	}
	
	return HOOK_CONTINUE;
}

class monster_onos : ScriptBaseMonsterEntity
{
	private float m_flNextStompAttack;
	
	void Spawn()
	{
		Precache();
		
		g_EntityFuncs.SetModel( self, MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -48, -48, 0 ), Vector( 48, 48, 80 ) );
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_YELLOW;
		if( self.pev.health == 0 )
			self.pev.health = MAX_HEALTH;
		self.pev.max_health = self.pev.health;
		self.m_MonsterState = MONSTERSTATE_NONE;
		
		self.m_FormattedName = "Onos";
		self.MonsterInit();

		self.m_afCapability |= bits_CAP_HEAR;

		//If the model lacks an eye position, view_ofs should be defined after MonsterInit
		self.pev.view_ofs = Vector( 0, 0, 60 );
		self.m_flFieldOfView = 0.2;

		SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}
	
	void Precache()
	{
		//precache shit here
		g_Game.PrecacheModel( MODEL );
		g_Game.PrecacheModel( MODEL_STOMP );
		g_Game.PrecacheModel( SPRITE_STOMP );
		
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
		self.pev.yaw_speed = 120;
	}
	
	void Stomp()
	{
		CBaseEntity@ pEntityStomp = g_EntityFuncs.CreateEntity( "onos_stomp" );
		CStomp@ pStomp = cast<CStomp@>( CastToScriptClass( pEntityStomp ) );	
		CBaseEntity@ pTarget = self.m_hEnemy.GetEntity();

		if( pTarget !is null )
		{
			@pStomp.pev.owner = self.edict();

			pStomp.pev.origin = self.pev.origin;

			// Save starting point
			pStomp.m_vecSpawn = self.pev.origin;
			
			Vector vecDir, vecAngles, vecTarget;
			vecTarget = pTarget.pev.origin + ( ( pTarget.pev.velocity.Normalize() )*100 );
			vecDir = vecTarget - self.pev.origin;
			
			g_EngineFuncs.VecToAngles( vecDir, vecAngles );

			Math.MakeVectors( vecAngles );
			
			//Math.MakeVectors( self.pev.angles );
			
			// Zero out z velocity so it stays on the ground
			Vector vecAim, vecNorm;
			vecAim = g_Engine.v_forward;
			vecAim.z = 0;
			vecNorm = vecAim.Normalize();

			//VectorScale( vecNorm, STOMP_SPEED, pStomp.pev.velocity );
			pStomp.pev.velocity.x = vecNorm.x * STOMP_SPEED;
			pStomp.pev.velocity.y = vecNorm.y * STOMP_SPEED;
			//pStomp.pev.velocity.z = vecNorm.z * STOMP_SPEED;
			//pStomp.pev.velocity.z = 0;
			
			//pStomp.pev.angles = self.pev.angles;
			//vecAngles.z = 0;
			pStomp.pev.angles = vecAngles;

			// Play view shake here
			float theShakeAmplitude = 100;
			float theShakeFrequency = 100;
			float theShakeDuration = 1.0f;
			float theShakeRadius = 700;
			g_PlayerFuncs.ScreenShake( self.pev.origin, theShakeAmplitude, theShakeFrequency, theShakeDuration, theShakeRadius );
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, ONOS_SOUND_STOMP, 1.0, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong( -10,10 ) );
			GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin,  900, 0.5, self );
		}
		m_flNextStompAttack = g_Engine.time + 5.0f;
	}
	
	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case ONOS_ATTACK:
			{
				CBaseEntity@ pHurt = CheckTraceHullAttack( self, 150, BITE_DMG, DMG_SLASH );
				if( pHurt !is null )
				{
					pHurt.pev.punchangle.z = -20;
					pHurt.pev.punchangle.x = 20;
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 200;		
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_up * 100;						
				}
				
				self.m_flNextAttack = g_Engine.time + 0.2;
				
				string szAttackSound;
				switch( Math.RandomLong( 0, 2 ) )
				{
					case 0:
						szAttackSound = ONOS_SOUND_ATTACK1;
						break;
					case 1:
						szAttackSound = ONOS_SOUND_ATTACK2;
						break;
					case 2:
						szAttackSound = ONOS_SOUND_ATTACK3;
						break;
					case 3:
						szAttackSound = ONOS_SOUND_ATTACK4;
						break;
				}
				
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, szAttackSound, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
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
				if( self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) )
				{
					return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 );
				}
				if( self.HasConditions( bits_COND_CAN_RANGE_ATTACK1 ) )
				{
					return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 );
				}				
				else
					return BaseClass.GetSchedule();
			}
		}
		return BaseClass.GetSchedule();
	}
	
	//Schedule@ GetScheduleOfType( int Type )
	//{
	//	switch( Type )
	//	{
	//		case SCHED_RANGE_ATTACK1: 
	//		{
	//			return slonosAttack;
	//		}
	//	}
	//	return BaseClass.GetScheduleOfType( Type );
	//}

	void StartTask ( Task@ pTask )
	{
		self.m_iTaskStatus = TASKSTATUS_RUNNING;

		switch ( pTask.iTask )
		{
			case TASK_MELEE_ATTACK1:
			{			
				self.m_IdealActivity = ACT_MELEE_ATTACK1;
				break;
			}
			case TASK_RANGE_ATTACK1:
			{
				self.m_IdealActivity = ACT_RANGE_ATTACK1;
				Stomp();
				break;
			}			
			default:
				BaseClass.StartTask( pTask );
		}
	}
	
	bool CheckMeleeAttack1( float flDot, float flDist )
	{	
		if( flDist <= 120 && flDot >= 0.7 && self.m_hEnemy.GetEntity() !is null && self.pev.FlagBitSet( FL_ONGROUND ) && self.m_flNextAttack < g_Engine.time )
		{
			return true;
		}
		return false;
	}	
	
	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( m_flNextStompAttack > g_Engine.time )
		{
			return false;
		}

		CBaseEntity@ pEntity = self.m_hEnemy.GetEntity();
	
		if( pEntity !is null && pEntity.pev.velocity != g_vecZero && self.FVisible( pEntity, false ) 
			&& self.pev.FlagBitSet( FL_ONGROUND ) && flDist >= 200 && flDist <= 600 && flDot >= 0.65 )
		{
			return true;
		}
	
		return false;
	}	
	
	void MonsterThink()
	{
		BaseClass.Think();
		
		if( @self.m_pSchedule is BaseClass.GetScheduleOfType( SCHED_CHASE_ENEMY ) && m_flNextStompAttack < g_Engine.time )
		{
			CBaseEntity@ pEnemy = cast<CBaseEntity@>( self.m_hEnemy.GetEntity() );

			if( pEnemy !is null )
			{
				float distToEnemy = ( self.pev.origin - pEnemy.pev.origin).Length();
				
				if( self.FVisible( pEnemy, false ) )
				{	
					if( distToEnemy >= 200 && distToEnemy <= 600 && self.pev.FlagBitSet( FL_ONGROUND ) )
					{
						self.ChangeSchedule( BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ) );
					}
				}
			}
		}
	}
	
	CBaseEntity@ CheckTraceHullAttack( CBaseMonster@ pThis, float flDist, int iDamage, int iDmgType )
	{
		TraceResult tr;

		if( pThis.IsPlayer() )
			Math.MakeVectors( pThis.pev.angles );
		else
			Math.MakeAimVectors( pThis.pev.angles );

		Vector vecStart = pThis.pev.origin;
		vecStart.z += pThis.pev.size.z * 0.5;
		Vector vecEnd = vecStart + ( g_Engine.v_forward * flDist );

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
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, ONOS_SOUND_DEATH1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, ONOS_SOUND_DEATH2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			break;
		}
	}
	
	void PainSound()
	{
		if( Math.RandomLong( 0, 5 ) < 2 )
		{
			switch( Math.RandomLong( 0, 1 ) )
			{
				case 0:
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, ONOS_SOUND_WOUND1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, ONOS_SOUND_WOUND2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, ONOS_SOUND_IDLE, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, ONOS_SOUND_ALERT, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if ( bitsDamageType & DMG_BULLET > 0 )
		{
			Vector vecDir = self.pev.origin - ( pevInflictor.absmin + pevInflictor.absmax ) * 0.5;
			vecDir = vecDir.Normalize();
			float flForce = self.DamageForce( flDamage );
			self.pev.velocity = self.pev.velocity + vecDir * flForce;
			flDamage *= 0.6;
		}	
		
		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}	

}

class CStomp : ScriptBaseEntity
{
	Vector m_vecSpawn;
	private float m_flStunTime = STOMP_STUN_DURATION;
	EHandle m_hOwner;
	
	void Spawn()
	{	
		Precache();
		
		self.pev.movetype = MOVETYPE_NOCLIP;
		
		g_EntityFuncs.SetModel( self, MODEL_STOMP );
		self.pev.solid = SOLID_TRIGGER;
		
		self.pev.frame = 0;
		self.pev.scale = 1.0;
		self.pev.rendermode = kRenderTransAdd;
		self.pev.renderamt = 180;
		self.pev.friction = 0;

		const int iBoxWidth = 100;
		g_EntityFuncs.SetSize( self.pev, Vector( -iBoxWidth, -iBoxWidth, -iBoxWidth ), Vector( iBoxWidth, iBoxWidth, iBoxWidth ) );

		SetTouch( TouchFunction( StompTouch ) );

		SetThink( ThinkFunction( KillYourself ) );
		self.pev.nextthink = g_Engine.time + 1.2;
	}
	
	void KillYourself()
	{
		g_EntityFuncs.Remove( self );
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( MODEL_STOMP );
	}
	
	void StompTouch( CBaseEntity@ pOther )
	{
		if( !m_hOwner )
		{
			if( self.pev.owner !is null )
			{
				m_hOwner = EHandle( g_EntityFuncs.Instance( self.pev.owner ) );
			}
			else
				return;
		}
		
		if( pOther is m_hOwner.GetEntity() )
		{
			return;
		}
		
		// Stop when it hits the world
		//TODO: Needs to affect enemy npcs as well
		if( pOther.IsPlayer() )
		{	
			// Stun them if they're not stunned already, to prevent perpetual stunning
			if( !GetStun( pOther ) )
			{
				// Do a traceline to make sure the world isn't blocking it
				TraceResult tr;
				g_Utility.TraceLine( m_vecSpawn, pOther.pev.origin, ignore_monsters, ignore_glass, null, tr );

				if( tr.flFraction == 1.0f )
				{
					if( SetStun( pOther, m_flStunTime ) )
					{
						// Play effect at player's feet
						//Vector theMinSize, theMaxSize;
						//pOther.GetSize( theMinSize, theMaxSize );
						//
						//vec3_t theOrigin = pOther.pev.origin;
						//theOrigin.z += theMinSize.z;
						//
						//AvHSUPlayParticleEvent( kpsStompEffect, pOther.edict(), theOrigin );
						CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );
						CBaseEntity@ pOnos = cast<CBaseEntity@>( m_hOwner.GetEntity() );
						pPlayer.TakeDamage( pOnos.pev, pOnos.pev, 25, DMG_SONIC );
						pPlayer.SetMaxSpeed( int( g_EngineFuncs.CVarGetFloat( "sv_maxspeed" )*0.5 ) );
					}
				}
				//else
				//{
				//	CBaseEntity* theEntityHit = CBaseEntity::Instance(ENT(theTraceResult.pHit));
				//}
			}
		}
	}

	bool SetStun( EHandle hEntity, float flStunTime )
	{
		if( !hEntity )
			return false;
		
		CBaseEntity@ pEntity = cast<CBaseEntity@>( hEntity.GetEntity() );
		
		if( pEntity.IsPlayer() )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_ns_stunned", 1 );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$f_ns_stun_time", g_Engine.time + flStunTime );
			return true;
		}
		
		return false;
	}
	
	bool GetStun( EHandle hEntity )
	{
		if( !hEntity )
			return false;
		
		CBaseEntity@ pEntity = cast<CBaseEntity@>( hEntity.GetEntity() );
		
		if( pEntity.IsPlayer() )
		{
			CustomKeyvalues@ kvPlayer = pEntity.GetCustomKeyvalues();
			
			if( kvPlayer.HasKeyvalue( "$i_ns_stunned" ) )
			{
				if( kvPlayer.GetKeyvalue( "$i_ns_stunned" ).GetInteger() == 1 )
					return true;
			}
		}
		
		return false;
	}

	float GetPointsForDamage( float flDamage )
	{
		//return ( flDamage/self.pev.max_health ) * ( 3 * ( self.pev.max_health/sk_onos_health.value ) );
		return ( flDamage/self.pev.max_health ) * ( 12 );
	}		
}

void Register()
{
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_ONOS::monster_onos", "monster_onos" );
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_ONOS::CStomp", "onos_stomp" );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, NS_ONOS::PlayerPreThink );
}
}