#include "monster_offensechamber"
/* Natural Selection Gorge NPC Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://github.com/ValveSoftware/halflife Half-Life SDK - by Valve
https://twhl.info/wiki/page/Tutorial%3A_Coding_NPCs_in_GoldSrc - by dexter
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_GORGE
{
//Vars
const int TASKSTATUS_RUNNING = 1;
//Models
const string MODEL = "models/ns/monsters/gorge_test_a.mdl";
const string SPRITE_SPIT = "sprites/tinyspit.spr";
const string SPRITE_SPIT_PROJ = "sprites/ns/bigspit.spr";
const string SPRITE_SPRAY = "sprites/ns/bacteria.spr";

//Sounds
const string GORGE_SOUND_SPIT1 = "ns/monsters/gorge/spit-1.wav";
const string GORGE_SOUND_SPIT2 = "ns/monsters/gorge/spit-2.wav";
const string GORGE_SOUND_DEATH1 = "ns/monsters/gorge/role3_die1.wav";
const string GORGE_SOUND_DEATH2 = "ns/monsters/gorge/role3_pain1.wav";
const string GORGE_SOUND_WOUND1 = "ns/monsters/gorge/role3_wound1.wav";
const string GORGE_SOUND_WOUND2 = "ns/monsters/gorge/role3_spawn2.wav";
const string GORGE_SOUND_IDLE = "ns/monsters/gorge/role3_idle1.wav";
const string GORGE_SOUND_ALERT = "ns/monsters/gorge/role3_spawn1.wav";
const string GORGE_SOUND_SPRAY = "ns/monsters/gorge/alien_spray.wav";

array<string> SOUNDS = {
	GORGE_SOUND_SPIT1,
	GORGE_SOUND_SPIT2,
	GORGE_SOUND_DEATH1,
	GORGE_SOUND_DEATH2,
	GORGE_SOUND_WOUND1,
	GORGE_SOUND_WOUND2,
	GORGE_SOUND_IDLE,
	GORGE_SOUND_ALERT,
	GORGE_SOUND_SPRAY
};

//Stats
const float SPIT_DMG = 15;
const float SPIT_LIFETIME = 2.0;
const float MAX_HEALTH = 150;
const float BUILD_COOLDOWN = 20.0;

enum GORGE_TASK
{
	TASK_HEAL = LAST_COMMON_TASK + 1,
	TASK_BUILD
}

enum GORGE_EVENTS 
{
  GORGE_SPIT = 2,
  GORGE_HEAL
}

array<ScriptSchedule@>@ custom_gorge_schedules;

ScriptSchedule slGorgeHeal
(
	0,
	0,
	"GorgeHeal"
);

ScriptSchedule slGorgeBuild
(
	0,
	0,
	"GorgeBuild"
);

array<string> healable_targets = {
	"monster_skulk",
	"monster_fade",
	"monster_onos",
	"monster_gorge"
};

void InitSchedules()
{
	slGorgeHeal.AddTask( ScriptTask(TASK_MOVE_TO_TARGET_RANGE, 50) );
	slGorgeHeal.AddTask( ScriptTask(TASK_SET_FAIL_SCHEDULE, SCHED_IDLE_STAND ) ); //TODO: Change fail switchever to target chase
	slGorgeHeal.AddTask( ScriptTask(TASK_FACE_IDEAL, 0) );
	slGorgeHeal.AddTask( ScriptTask(TASK_HEAL, 0) );
	slGorgeHeal.AddTask( ScriptTask(TASK_SET_ACTIVITY, ACT_IDLE) );
	//slGorgeHeal.AddTask( ScriptTask(TASK_WAIT_RANDOM, 0.5f) );
	
	slGorgeBuild.AddTask( ScriptTask(TASK_MOVE_TO_TARGET_RANGE, 50) );
	slGorgeBuild.AddTask( ScriptTask(TASK_SET_FAIL_SCHEDULE, SCHED_IDLE_STAND ) ); //TODO: Change fail switchever to target chase
	slGorgeBuild.AddTask( ScriptTask(TASK_FACE_IDEAL, 0) );
	slGorgeBuild.AddTask( ScriptTask(TASK_BUILD, 0) );
	slGorgeBuild.AddTask( ScriptTask(TASK_WAIT_RANDOM, 0.5f) );
	slGorgeBuild.AddTask( ScriptTask(TASK_SET_ACTIVITY, ACT_IDLE) );
	
	array<ScriptSchedule@> scheds = { slGorgeHeal, slGorgeBuild };
	
	@custom_gorge_schedules = @scheds;	
}

class monster_gorge : ScriptBaseMonsterEntity
{

	private float m_flNextSpitTime;
	private float m_flBuildTime = g_Engine.time + 15.0f;
	private float m_healTime;
	private int m_iSquidSpitSprite;

	private bool m_blIsBuilding = false;
	
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
		
		self.m_FormattedName = "Gorge";
		self.MonsterInit();

		//If the model lacks an eye position, view_ofs should be defined after MonsterInit
		self.pev.view_ofs = Vector( 0, 0, 10 );
		self.m_flFieldOfView = 0.2;

		//SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
		self.m_afCapability |= bits_CAP_HEAR;
	}
	
	void Precache()
	{
		//precache shit here
		g_Game.PrecacheModel( MODEL );
		
		m_iSquidSpitSprite = g_Game.PrecacheModel( SPRITE_SPIT );
		g_Game.PrecacheModel( SPRITE_SPIT_PROJ );
		g_Game.PrecacheModel( SPRITE_SPRAY );
		
		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}

		g_Game.PrecacheMonster( "monster_offensechamber", true );
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
			case GORGE_SPIT:
			{
				if( self.m_hEnemy )
				{
					Vector	vecSpitOffset;
					Vector	vecSpitDir, vecTarget, vecTargetOffset;

					Math.MakeVectors( self.pev.angles );
					CBaseEntity@ pEnemy = cast<CBaseEntity@>( self.m_hEnemy.GetEntity() );

					//!!!HACKHACK - the spot at which the spit originates (in front of the mouth) was measured in 3ds and hardcoded here.
					//we should be able to read the position of bones at runtime for this info
					vecSpitOffset = ( g_Engine.v_right * 8 + g_Engine.v_forward * 37 + g_Engine.v_up * 23 );		
					vecSpitOffset = ( self.pev.origin + vecSpitOffset );
					
					vecTarget = pEnemy.pev.origin + pEnemy.pev.view_ofs; 
					
					//Gorge tries to predict your movement
					float flPredictionModifier = ( ( self.pev.origin - pEnemy.pev.origin ).Length2D() ) * 0.0005;
					vecTargetOffset = pEnemy.pev.velocity.Normalize()*( Math.max( pEnemy.pev.velocity.Length2D(), 400 ) * flPredictionModifier );
					vecTargetOffset.z = 0;
					
					vecSpitDir = ( ( vecTarget + vecTargetOffset ) - vecSpitOffset ).Normalize();

					//Add a bit of randomness to the accuracy 
					vecSpitDir.x += Math.RandomFloat( -0.1, 0.1 );
					vecSpitDir.y += Math.RandomFloat( -0.1, 0.1 );
					vecSpitDir.z += Math.RandomFloat( -0.1, 0 );
					
					switch ( Math.RandomLong( 0, 1 ) )
					{
					case 0:	
						g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_SPIT1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
						break;
					case 1:
						g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_SPIT2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
						break;
					}

					GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin,  600, 0.3, self );		

					Spit( vecSpitOffset, vecSpitDir * 1500 );
				}
				break;
			}
			case GORGE_HEAL:
			{
				if( !m_blIsBuilding )
					Heal();
				else
					Build();
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
			case MONSTERSTATE_IDLE:
			{
				//Forcibly check for sounds now, before we look for build/heal targets
				if( self.HasConditions( bits_COND_HEAR_SOUND ) )
				{
					CSound@ pSound = self.PBestSound();
		
					if( pSound !is null && ( pSound.m_iType & ( BaseClass.ISoundMask() & ~bits_SOUND_COMBAT ) != 0 ) )
					{
						return BaseClass.GetScheduleOfType( SCHED_INVESTIGATE_SOUND );
					}
					
					if( pSound !is null && (pSound.m_iType & bits_SOUND_COMBAT) != 0 )
					{
						return BaseClass.GetScheduleOfType( SCHED_INVESTIGATE_COMBAT );
					}
				}
				if( !self.HasConditions( bits_COND_SEE_ENEMY ) )
				{
					self.m_hTargetEnt = FindHealingTarget();
					if( CanHeal() )
					{
						return slGorgeHeal;
					}
					self.m_hTargetEnt = FindValidBuildNode();
					if( CanBuild() )
					{
						return slGorgeBuild;
					}
				}
				else
					return BaseClass.GetSchedule();
			}
			case MONSTERSTATE_ALERT:
			{
				//Forcibly check for sounds now, before we look for build targets
				if( self.HasConditions( bits_COND_HEAR_SOUND ) )
				{
					CSound@ pSound = self.PBestSound();
		
					if( pSound !is null && ( pSound.m_iType & ( BaseClass.ISoundMask() & ~bits_SOUND_COMBAT ) != 0 ) )
					{
						return BaseClass.GetScheduleOfType( SCHED_INVESTIGATE_SOUND );
					}
					
					if( pSound !is null && (pSound.m_iType & bits_SOUND_COMBAT) != 0 )
					{
						return BaseClass.GetScheduleOfType( SCHED_INVESTIGATE_COMBAT );
					}
				}				
				self.m_hTargetEnt = FindValidBuildNode();
				if( CanBuild() )
				{
					return slGorgeBuild;
				}
				else
					return BaseClass.GetSchedule();
			}
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

				self.m_hTargetEnt = FindValidBuildNode();
				if( CanBuild() )
				{
					return slGorgeBuild;
				}				
			
				if( self.HasConditions( bits_COND_CAN_RANGE_ATTACK1 ) )
				{
					return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 );
				}

				self.m_hTargetEnt = FindHealingTarget();
				if( CanHeal() )
				{
					return slGorgeHeal;
				}								
				else
					return BaseClass.GetSchedule();
			}			
		}
		return BaseClass.GetSchedule();
	}
	
	void StartTask ( Task@ pTask )
	{
		self.m_iTaskStatus = TASKSTATUS_RUNNING;

		switch ( pTask.iTask )
		{
			case TASK_HEAL:
			{
				self.m_IdealActivity = ACT_MELEE_ATTACK1;
				break;
			}
			case TASK_BUILD:
			{
				m_blIsBuilding = true;
				self.m_IdealActivity = ACT_MELEE_ATTACK1;
			}
			default:
				BaseClass.StartTask( pTask );
		}
	}	
	
	void RunTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_HEAL:
			{
				if( self.m_fSequenceFinished )
				{
					self.TaskComplete();
				}
				else
				{
					if( TargetDistance() > 128 )
						self.TaskComplete();
					//pev->ideal_yaw = UTIL_VecToYaw( m_hTargetEnt->pev->origin - pev->origin );
					//ChangeYaw( self.pev.yaw_speed );
				}
				break;
			}
			case TASK_BUILD:
			{
				if( self.m_fSequenceFinished )
				{
					self.TaskComplete();
				}
				else
				{
					if( TargetDistance() > 128 )
						self.TaskComplete();
					//pev->ideal_yaw = UTIL_VecToYaw( m_hTargetEnt->pev->origin - pev->origin );
					//ChangeYaw( self.pev.yaw_speed );
				}
				break;
			}			
			default:
			{
				BaseClass.RunTask( pTask );
				break;	
			}
		}
	}
	
	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( self.IsMoving() && flDist >= 512 )
		{
			//gorge will fall too far behind if he stops running to spit at this distance from the enemy.
			return false;
		}

		if( flDist <= 784 && flDot >= 0.5 && g_Engine.time >= m_flNextSpitTime )
		{
			if( self.m_hEnemy.GetEntity() !is null )
			{
				if( abs( self.pev.origin.z - self.m_hEnemy.GetEntity().pev.origin.z ) > 256 )
				{
					//don't try to spit at someone up really high or down really low.
					return false;
				}
			}

			//if( self.IsMoving() )
			//{
			//	// don't spit again for a long time, resume chasing enemy.
			//	m_flNextSpitTime = g_Engine.time + 5;
			//}
			//else
			//{
			//	// not moving, so spit again pretty soon.
			//	m_flNextSpitTime = g_Engine.time + 0.5;
			//}
			m_flNextSpitTime = g_Engine.time + 0.5;
			return true;
		}

		return false;
	}

	void Spit( Vector vecStart, Vector vecVelocity )
	{
		//Spawn spit
		CBaseEntity@ pEntitySpit = g_EntityFuncs.CreateEntity( "proj_gorge_spit" );
		CGorgeSpit@ pSpit = cast<CGorgeSpit@>( CastToScriptClass( pEntitySpit ) );

		pSpit.pev.origin = vecStart;
		pSpit.pev.velocity = vecVelocity;

		//Set owner
		@pSpit.pev.owner = self.edict();

		//Set spit's team :)
		pSpit.pev.team = self.pev.team;
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
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_DEATH1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			break;
		case 1:
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_DEATH2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
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
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_WOUND1, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_WOUND2, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_IDLE, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, GORGE_SOUND_ALERT, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	}	
	
	float GetPointsForDamage( float flDamage )
	{
		//return ( flDamage/self.pev.max_health ) * ( 3 * ( self.pev.max_health/sk_gorge_health.value ) );
		return ( flDamage/self.pev.max_health ) * ( 3 );
	}
	
	bool CanHeal()
	{ 
		if( m_healTime > g_Engine.time )
		{
			return false;
		}
		if( !self.m_hTargetEnt )
		{
			return false;
		}
	
		//if( ( m_healTime > g_Engine.time ) || ( !self.m_hTargetEnt ) || ( self.m_hTargetEnt.GetEntity().pev.health >= self.m_hTargetEnt.GetEntity().pev.max_health ) )
		//	return false;

		return true;
	}	
	
	EHandle FindHealingTarget()
	{
		CBaseEntity@ pFriend, pNearest;
		array<CBaseEntity@> healTargets;

		for( uint i = 0; i < healable_targets.length(); i++ )
		{
			while( ( @pFriend = g_EntityFuncs.FindEntityByClassname( pFriend, healable_targets[i] ) ) !is null )
			{
				if( pFriend is null || pFriend is self )
					continue;

				if( !pFriend.IsAlive() )
					continue;
					
				if( !self.FVisible( pFriend, false ) )
					continue;

				if( self.IRelationship( pFriend ) != R_AL )
					continue;

				if( pFriend.pev.health >= pFriend.pev.max_health )
					continue;

				healTargets.insertLast( pFriend );
			}
		}
		
		if( healTargets.length() == 0 )
			return EHandle( pFriend );
		else if( healTargets.length() == 1 )
			return EHandle( healTargets[0] );
		else
		{
			@pNearest = healTargets[0];
			for( uint j = 1; j < healTargets.length(); j++ )
			{
				if( ( healTargets[j].pev.origin - self.pev.origin ).Length2D() < ( pNearest.pev.origin - self.pev.origin ).Length2D() )
					@pNearest = healTargets[j];
			}			
		}
		
		return EHandle( pNearest );
	}
	
	float TargetDistance()
	{
		//If we lose the target, or it dies, return a really large distance
		if( !self.m_hTargetEnt || !self.m_hTargetEnt.GetEntity().IsAlive() )
			return 1e6;

		return ( self.m_hTargetEnt.GetEntity().pev.origin - self.pev.origin ).Length2D();
	}

	void Heal()
	{
		if( !CanHeal() )
			return;

		Vector vecTarget = self.m_hTargetEnt.GetEntity().pev.origin - self.pev.origin;
		if ( vecTarget.Length2D() > 100 )
			return;

		self.m_hTargetEnt.GetEntity().TakeHealth( 25, DMG_GENERIC );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, GORGE_SOUND_SPRAY, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		Math.MakeVectors( self.pev.angles );
		
		Vector vecSrc = self.pev.origin + ( g_Engine.v_forward * 10 + g_Engine.v_up * 16 );
		
		Vector vecDir = self.m_hTargetEnt.GetEntity().pev.origin - self.pev.origin;
		te_spray( vecSrc, vecDir , SPRITE_SPRAY, 6, 5, 255, 5 );
		//Heal cooldown
		m_healTime = g_Engine.time + 0.33;
	}
	
	void te_spray(Vector pos, Vector dir, string sprite="sprites/ns/bacteria.spr", 
		uint8 count=8, uint8 speed=127, uint8 noise=255, uint8 rendermode=0,
		NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_SPRAY);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteCoord(dir.x);
		m.WriteCoord(dir.y);
		m.WriteCoord(dir.z);
		m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
		m.WriteByte(count);
		m.WriteByte(speed);
		m.WriteByte(noise);
		m.WriteByte(rendermode);
		m.End();
	}

	bool CanBuild()
	{ 
		if( m_flBuildTime > g_Engine.time )
			return false;

		if( !self.m_hTargetEnt )
			return false;

		if( self.m_hTargetEnt.GetEntity().pev.classname != "info_gorge_node" )
			return false;

		return true;
	}

EHandle FindValidBuildNode()
	{
		CBaseEntity@ pNode, pNearest;
		array<CBaseEntity@> buildNodes;
		
		while( ( @pNode = g_EntityFuncs.FindEntityByClassname( pNode, "info_gorge_node" ) ) !is null )
		{
			if( pNode is null )
				continue;
			
			CGorgeNode@ pNodeEntity = cast<CGorgeNode@>( g_EntityFuncs.CastToScriptClass( @pNode ) );
			if( pNodeEntity.GetBuilding() || pNodeEntity.GetInvalid() )
				continue;

			if( !self.FVisible( pNode, false ) )
				continue;
			
			buildNodes.insertLast( pNode );
		}
		
		if( buildNodes.length() == 0 )
			return EHandle( pNode );
		else if( buildNodes.length() == 1 )
			return EHandle( buildNodes[0] );
		else
		{
			@pNearest = buildNodes[0];
			for( uint j = 1; j < buildNodes.length(); j++ )
			{
				if( ( buildNodes[j].pev.origin - self.pev.origin ).Length2D() < ( pNearest.pev.origin - self.pev.origin ).Length2D() )
					@pNearest = buildNodes[j];
			}			
		}
		
		return EHandle( pNearest );
	}

	void Build()
	{
		if( !CanBuild() )
			return;

		if( !self.m_hTargetEnt )
			return;
		
		CBaseEntity@ pNode = cast<CBaseEntity@>( self.m_hTargetEnt.GetEntity() );
		Vector vecTarget = pNode.pev.origin - self.pev.origin;

		if ( vecTarget.Length2D() > 100 )
			return;

		TraceResult trTurret;
	
		Vector vecForward;
		g_EngineFuncs.AngleVectors( self.pev.angles, vecForward, void, void );
		Vector vecGorgeDeployPos = self.GetOrigin();
		Vector vecTurretDeployPos = pNode.pev.origin + ( vecForward * ( 34.0f ) );
		//Raise z axis by 32 units, as mins of human_hull is -32
		vecTurretDeployPos.z = vecTurretDeployPos.z + 32;

		g_Utility.TraceHull( vecTurretDeployPos, vecTurretDeployPos, dont_ignore_monsters, human_hull, self.edict(), trTurret );

		//If there isn't enough room, don't bother building here and don't include in future checks
		//TODO: Don't disable the node for the rest of the level, do some checks again after X time
		if ( trTurret.fAllSolid == 1 || trTurret.fStartSolid == 1 || trTurret.fInOpen == 0 )
		{
			m_flBuildTime = g_Engine.time + 60.0f;
			cast<CGorgeNode@>( g_EntityFuncs.CastToScriptClass( @pNode ) ).SetInvalid( true );
			return;
		}	

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, GORGE_SOUND_SPRAY, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		Math.MakeVectors( self.pev.angles );

		Vector vecSrc = self.pev.origin + ( g_Engine.v_forward * 10 + g_Engine.v_up * 16 );
		Vector vecDir = pNode.pev.origin - self.pev.origin;
		te_spray( vecSrc, vecDir , SPRITE_SPRAY, 6, 5, 255, 5 );

		CBaseEntity@ pTurret = g_EntityFuncs.CreateEntity( "monster_offensechamber", null, false );
		pTurret.SetClassification( self.Classify() );
		pTurret.pev.origin = pNode.pev.origin;
		pTurret.pev.angles = self.pev.angles;

		if( g_EntityFuncs.DispatchSpawn( pTurret.edict() ) == -1 )
			return;		

		cast<CGorgeNode@>( g_EntityFuncs.CastToScriptClass( @pNode ) ).SetBuilding( true );

		//Build cooldown
		m_flBuildTime = g_Engine.time + BUILD_COOLDOWN;
	}
}

class CGorgeSpit : ScriptBaseEntity
{
	EHandle m_hOwner;

	void Spawn()
	{
		Precache();
		
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		
		g_EntityFuncs.SetModel( self, SPRITE_SPIT_PROJ );
		
		self.pev.frame = 0;
		self.pev.scale = 1;
		self.pev.rendermode = kRenderTransAlpha;
		self.pev.renderamt = 255;
		
		g_EntityFuncs.SetSize( self.pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );
		
		SetTouch( TouchFunction( SpitTouch ) );
		SetThink( ThinkFunction( SpitDeath ) );
		self.pev.nextthink = g_Engine.time + SPIT_LIFETIME;
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( SPRITE_SPIT_PROJ );
	}
	
	void SpitDeath()
	{
		g_EntityFuncs.Remove( self );
	}
	
	void SpitTouch( CBaseEntity@ pOther )
	{
		if( pOther !is null )
		{
			if( !m_hOwner )
			{
				if( self.pev.owner !is null )
				{
					m_hOwner = EHandle( g_EntityFuncs.Instance( self.pev.owner ) );
				}
			}
			
			if( m_hOwner.GetEntity() !is null && pOther !is m_hOwner.GetEntity() )
			{
				if( self.IRelationship( pOther ) != -2 )
					pOther.TakeDamage( self.pev, m_hOwner.GetEntity().pev, SPIT_DMG, DMG_ACID );
					
				SpitDeath();
			}
		}
	}

}

class CGorgeNode : ScriptBaseEntity
{
	bool m_blHasBuilding = false;
	bool m_blInvalid = false;

	void Spawn()
	{
		self.pev.movetype   = MOVETYPE_NONE;
		self.pev.solid      = SOLID_NOT;
		self.pev.effects    |= EF_NODRAW;
		
		g_EntityFuncs.SetModel( self, self.pev.model );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		BaseClass.Spawn();

		self.pev.nextthink = g_Engine.time + 1.0f;
	}

	void Think()
	{
		if( m_blHasBuilding )
		{
			CBaseEntity@ pEntity;
			int iCount = 0;
			//TODO: Make this pick up more than just the alien turret
			while( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, self.pev.origin, 32, "monster_offensechamber", "classname" ) ) !is null )
			{
				if( pEntity is null )
					continue;

				if( pEntity.IsAlive() )
					iCount++;
			}
			if( iCount == 0 )
				m_blHasBuilding = false;
		}

		self.pev.nextthink = g_Engine.time + 1.0f;
	}

	bool GetBuilding()
	{
		return m_blHasBuilding;
	}

	void SetBuilding( bool blBuilding )
	{
		m_blHasBuilding = blBuilding;
	}

	bool GetInvalid()
	{
		return m_blInvalid;
	}

	void SetInvalid( bool blInvalid )
	{
		m_blInvalid = blInvalid;
	}
}

void Register()
{
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_GORGE::monster_gorge", "monster_gorge" );
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_GORGE::CGorgeSpit", "proj_gorge_spit" );
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_GORGE::CGorgeNode", "info_gorge_node" );
	NS_OFF_CHAMBER::Register();
}
}