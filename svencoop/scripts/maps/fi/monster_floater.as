namespace FIFlockingFloater
{

const string FLOATER_MODEL = "models/fi/floater.mdl";

const int FLOATER_HEALTH = 45;
const int FLOATER_EXPLO_DAMAGE = 70;

const Vector FLOATER_NORMAL_COLOR = Vector(127, 0, 255);
const Vector FLOATER_PREPROVOKED_COLOR = Vector(0, 255, 255);

const int SF_MONSTER_GAG = 2;
const int SF_FLOATER_WAIT_UNTIL_PROVOKED = 64;

const int bits_MEMORY_FLOATER_PROVOKED = bits_MEMORY_CUSTOM1;

const int bits_MF_NOT_TO_MASK = (bits_MF_IS_GOAL | bits_MF_DONT_SIMPLIFY);

const float BLOATING_TIME = 2.1;
const int BASE_FLOATER_SPEED = 120;
const string FLOATER_GLOW_SPRITE = "sprites/glow02.spr";
const float FLOATER_HOWL_ATTN = 0.7;

float g_howlTime = 0;

const int LOCALMOVE_INVALID = 0;
const int LOCALMOVE_INVALID_DONT_TRIANGULATE = 1;
const int LOCALMOVE_VALID = 2;

const int MOVEGOAL_NONE = 0;
const int MOVEGOAL_TARGETENT = (bits_MF_TO_TARGETENT);
const int MOVEGOAL_ENEMY = (bits_MF_TO_ENEMY);
const int MOVEGOAL_PATHCORNER = (bits_MF_TO_PATHCORNER);
const int MOVEGOAL_LOCATION = (bits_MF_TO_LOCATION);
const int MOVEGOAL_NODE = (bits_MF_TO_NODE);

const int TASK_WAIT_PATROL_TURNING = LAST_COMMON_TASK;

class WaypointValue
{
	WaypointValue()
	{
		flSavedMoveWait = 0;
		iType = 0;
	}

	Vector vecLocation;
	Vector vecJumpVelocity;
	Vector vecLadderVelocity;
	EHandle hDoor;
	float flSavedMoveWait;
	int iType;

	WaypointValue& opAssign(Waypoint& waypoint)
	{
		vecLocation = waypoint.vecLocation;
		vecJumpVelocity = waypoint.vecJumpVelocity;
		vecLadderVelocity = waypoint.vecLadderVelocity;
		hDoor = waypoint.hDoor;
		flSavedMoveWait = waypoint.flSavedMoveWait;
		return this;
	}
};

void WaypointAssign(Waypoint& dest, const WaypointValue& in src)
{
	dest.vecLocation = src.vecLocation;
	dest.vecJumpVelocity = src.vecJumpVelocity;
	dest.vecLadderVelocity = src.vecLadderVelocity;
	dest.hDoor = src.hDoor;
	dest.flSavedMoveWait = src.flSavedMoveWait;
}

void WaypointAssign(Waypoint& dest, Waypoint& src)
{
	dest.vecLocation = src.vecLocation;
	dest.vecJumpVelocity = src.vecJumpVelocity;
	dest.vecLadderVelocity = src.vecLadderVelocity;
	dest.hDoor = src.hDoor;
	dest.flSavedMoveWait = src.flSavedMoveWait;
}

float UTIL_Approach( float target, float value, float speed )
{
	float delta = target - value;

	if( delta > speed )
		value += speed;
	else if( delta < -speed )
		value -= speed;
	else
		value = target;

	return value;
}

class CFlockingFloater : ScriptBaseMonsterEntity
{
	private CSprite@ m_leftGlow;
	private CSprite@ m_rightGlow;

	private float m_nextPainTime;
	private float m_originalScale;
	private float m_targetScale;
	private float m_startBloatingTime;

	private Vector m_velocity;

	private int m_tinySpit;
	private int m_explode1;
	private int m_explode2;

	private float m_flLastYawTime;
	private float m_moveSpeed;
	
	private CBaseEntity@ m_goalEnt = null;
	private float m_nextPatrolPathCheck;

	CFlockingFloater()
	{
		@this.m_Schedules = @monster_floater_schedules;
	}

	int ISoundMask()
	{
		bool isProvoked = IsProvoked();
		// HACK: Don't hear anything at the start of the level
		if (!isProvoked && g_Engine.time < 5)
			return 0;
		int bits = bits_SOUND_WORLD | bits_SOUND_COMBAT | bits_SOUND_DANGER;
		if (isProvoked)
			bits |= bits_SOUND_PLAYER;
		return bits;
	}

	int Classify()
	{
		if (IsProvoked())
			return self.GetClassification(CLASS_ALIEN_MONSTER);
		else
			return self.GetClassification(CLASS_ALIEN_PASSIVE);
	}

	void SetYawSpeed( void )
	{
		pev.yaw_speed = 120;
		if (self.m_flGroundSpeed == 0)
			SetMoveSpeed(BASE_FLOATER_SPEED);
	}

	float ChangeYaw( int yawSpeed )
	{
		float ideal, current, move, speed;

		current = Math.AngleMod( pev.angles.y );
		ideal = pev.ideal_yaw;
		if( current != ideal )
		{
			float delta;

			delta = Math.min( g_Engine.time - m_flLastYawTime, 0.25 );

			speed = float(yawSpeed) * delta * 2;

			move = ideal - current;

			if( ideal > current )
			{
				if( move >= 180 )
					move = move - 360;
			}
			else
			{
				if( move <= -180 )
					move = move + 360;
			}

			if( move > 0 )
			{
				// turning to the monster's left
				if( move > speed )
					move = speed;
			}
			else
			{
				// turning to the monster's right
				if( move < -speed )
					move = -speed;
			}

			pev.angles.y = Math.AngleMod( current + move );
		}
		else
			move = 0;

		m_flLastYawTime = g_Engine.time;

		return move;
	}

	void Spawn()
	{
		Precache();

		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, FLOATER_MODEL );

		g_EntityFuncs.SetSize( self.pev, Vector( -16.0, -16.0, 0.0 ), Vector( 16.0, 16.0, 36.0 ) );

		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_FLY;
		pev.flags |= FL_FLY;
		self.m_bloodColor = BLOOD_COLOR_GREEN;
		if( self.pev.health == 0.0f )
		{
			self.pev.health = FLOATER_HEALTH;
		}
		pev.view_ofs = Vector( 0, 0, -2 );
		self.m_flFieldOfView = VIEW_FIELD_FULL;
		self.m_MonsterState = MONSTERSTATE_NONE;

		m_originalScale = pev.scale;

		SetTouch( TouchFunction( FloaterTouch ) );

		if( string( self.m_FormattedName ).IsEmpty() )
		{
			self.m_FormattedName = "Flocking Floater";
		}

		self.MonsterInit();
		pev.view_ofs = Vector( 0, 0, -2 );

		SetThink(ThinkFunction(MonsterInitThink));
		pev.nextthink = g_Engine.time + Math.RandomFloat(0.1, 0.2);
		SetUse( UseFunction( FloaterBloatUse ) );

		m_flLastYawTime = g_Engine.time;
		if (self.m_iTriggerCondition != 0)
			g_Game.AlertMessage(at_console, "Condition: %1. Target: %2\n", self.m_iTriggerCondition, self.m_iszTriggerTarget);
	}

	void Precache()
	{
		BaseClass.Precache();
		if( string( self.pev.model ).IsEmpty() )
		{
			g_Game.PrecacheModel(FLOATER_MODEL);
		}

		m_tinySpit = g_Game.PrecacheModel("sprites/tinyspit.spr");
		m_explode1 = g_Game.PrecacheModel ("sprites/spore_exp_01.spr");
		m_explode2 = g_Game.PrecacheModel ("sprites/spore_exp_c_01.spr");

		g_SoundSystem.PrecacheSound("weapons/splauncher_impact.wav");
		g_SoundSystem.PrecacheSound("fi/floater/floater_spinup.wav");
		g_SoundSystem.PrecacheSound("fi/floater/floater_howl.wav");
		g_SoundSystem.PrecacheSound("fi/floater/floater_pain1.wav");
		g_SoundSystem.PrecacheSound("fi/floater/floater_pain2.wav");
		g_SoundSystem.PrecacheSound("fi/floater/floater_pain3.wav");

		g_Game.PrecacheModel(FLOATER_GLOW_SPRITE);

		g_howlTime = 0;
	}

	void FloaterTouch(CBaseEntity@ pOther)
	{
		if (pOther !is null && pOther.IsPlayer() && self.IRelationship(pOther) != R_AL)
		{
			CBaseEntity@ groundEnt = g_EntityFuncs.Instance(pOther.pev.groundentity);
			if (groundEnt == self)
				self.TakeDamage(pev,pev,pev.health,DMG_GENERIC);
		}
	}

	void StartTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
		case TASK_GET_PATH_TO_ENEMY:
		{
			CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();

			if( pEnemy is null )
			{
				self.TaskFail();
				return;
			}

			if( BuildRoute( pEnemy.pev.origin, bits_MF_TO_ENEMY, pEnemy ) )
			{
				self.TaskComplete();
			}
			else
			{
				BaseClass.StartTask(pTask);
			}
		}
			break;
		case TASK_GET_PATH_TO_ENEMY_LKP:
			if( BuildRoute( self.m_vecEnemyLKP, bits_MF_TO_LOCATION, null ) )
			{
				self.TaskComplete();
			}
			else
			{
				BaseClass.StartTask(pTask);
			}
			break;
		case TASK_WAIT_PATROL_TURNING:
			self.m_flWaitFinished = m_nextPatrolPathCheck;
			break;
		default:
			BaseClass.StartTask(pTask);
			break;
		}
	}

	void RunTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
		case TASK_WAIT_FOR_MOVEMENT:
		{
			CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();
			if (pEnemy !is null)
			{
				self.MakeIdealYaw( self.m_vecEnemyLKP );
				ChangeYaw( int(pev.yaw_speed) );
				const float distance = (pEnemy.Center() - pev.origin).Length();
				if (distance < 128 && !Bloating())
				{
					StartBloating();
				}
			}
			BaseClass.RunTask( pTask );
			break;
		}
		case TASK_WAIT_PATROL_TURNING:
		{
			ChangeYaw( int(pev.yaw_speed) );
			if( g_Engine.time >= self.m_flWaitFinished )
			{
				self.TaskComplete();
			}
			break;
		}
		default:
 			BaseClass.RunTask( pTask );
			break;
		}
	}

	void RunAI()
	{
		if (m_leftGlow is null && m_rightGlow is null)
		{
			Vector glowColor(FLOATER_NORMAL_COLOR);
			if ((pev.spawnflags & SF_FLOATER_WAIT_UNTIL_PROVOKED) != 0)
				glowColor = FLOATER_PREPROVOKED_COLOR;
			@m_leftGlow = CreateGlow(glowColor,2);
			@m_rightGlow = CreateGlow(glowColor,1);
		}

		if (g_howlTime <= g_Engine.time && self.IsMoving() && Math.RandomLong(0,10) == 0)
		{
			if (g_Engine.time > m_nextPainTime && (pev.spawnflags & SF_MONSTER_GAG) == 0)
			{
				const int pitch = 95 + Math.RandomLong(0,10);

				g_howlTime = g_Engine.time + 5;
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "fi/floater/floater_howl.wav", 1.0, FLOATER_HOWL_ATTN, 0, pitch );
			}
		}
		GlowUpdate();
		if (Bloating())
		{
			float fraction = (g_Engine.time - m_startBloatingTime) / BLOATING_TIME;
			pev.scale = m_originalScale + (m_targetScale - m_originalScale) * fraction;
			if (g_Engine.time >= m_startBloatingTime + BLOATING_TIME)
			{
				self.TakeDamage(pev,pev,pev.health,DMG_GENERIC);
			}
			SetMoveSpeed(BASE_FLOATER_SPEED + 400 * fraction);
		}
		BaseClass.RunAI();
		//g_Game.AlertMessage( at_console, "Speed: %1. yaw_speed: %2\n", self.m_flGroundSpeed, pev.yaw_speed );
	}

	void MonsterInitThink()
	{
		if( pev.target != "" )
		{
			// Find the monster's initial target entity, stash it
			CBaseEntity@ path = g_EntityFuncs.FindEntityByTargetname(null, pev.target);

			Schedule@ patrolSchedule = StartPatrol(path);
			if (patrolSchedule !is null)
			{
				self.SetState( MONSTERSTATE_IDLE );
				self.ChangeSchedule( patrolSchedule );
			}
		}
		pev.nextthink = g_Engine.time + 0.1;
		SetThink(ThinkFunction(MonsterThink));
	}
	
	void MonsterThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		RunAI();

		float flInterval = self.StudioFrameAdvance();
		if( self.m_MonsterState != MONSTERSTATE_SCRIPT && self.m_MonsterState != MONSTERSTATE_DEAD && self.m_Activity == ACT_IDLE && self.m_fSequenceFinished )
		{
			int iSequence = LookupActivity( self.m_Activity );
			if( iSequence >= 0 )
			{
				pev.sequence = iSequence;
				self.ResetSequenceInfo();
				if (self.m_flGroundSpeed == 0)
					SetMoveSpeed(BASE_FLOATER_SPEED);
			}
		}

		self.DispatchAnimEvents( flInterval );

		if( !self.MovementIsComplete() )
		{
			Move( flInterval );
		}
	}

	Schedule@ GetSchedule()
	{
		if( self.HasConditions( bits_COND_HEAR_SOUND ) && !IsProvoked() )
		{
			CSound@ pSound = self.PBestSound();
			/*if (pSound !is null)
				g_Game.AlertMessage(at_console, "Floater alerted by combat sound at %1! Type: %2. Volume: %3. Time: %4\n", pSound.m_vecOrigin.ToString(), pSound.m_iType, pSound.m_iVolume, g_Engine.time);*/
			if( pSound !is null && ( pSound.m_iType & (bits_SOUND_DANGER | bits_SOUND_COMBAT) ) != 0 )
			{
				if ((pSound.m_vecOrigin - self.EarPosition()).Length() <= pSound.m_iVolume * 0.3)
				{
					MakeProvoked();
				}
			}
		}
		switch( self.m_MonsterState )
		{
		case MONSTERSTATE_COMBAT:
			if( self.HasConditions( bits_COND_ENEMY_DEAD ) )
			{
				return BaseClass.GetSchedule();
			}
			return self.GetScheduleOfType(SCHED_CHASE_ENEMY);
		case MONSTERSTATE_IDLE:
		case MONSTERSTATE_ALERT:
			{
				if( IsProvoked() && self.HasConditions( bits_COND_HEAR_SOUND ) )
				{
					return GetScheduleOfType( SCHED_ALERT_FACE );
				}
				else if( self.m_Route(self.m_iRouteIndex).iType == 0 || self.m_movementGoal == MOVEGOAL_NONE )
				{
					if (m_goalEnt !is null )
					{
						if (m_nextPatrolPathCheck <= g_Engine.time)
						{
							Schedule@ patrolSchedule = StartPatrol(m_goalEnt);
							if (patrolSchedule !is null)
								return patrolSchedule;
						}
						else
						{
							return slIdlePatrolTurning;
						}
					}
					return GetScheduleOfType( SCHED_IDLE_STAND );
				}
				else
				{
					return GetScheduleOfType( SCHED_IDLE_WALK );
				}
				//break;
			}
		default:
			break;
		}

		return BaseClass.GetSchedule();
	}

	Schedule@ GetScheduleOfType( int Type )
	{
		//g_Game.AlertMessage(at_console, "Requested schedule: %1\n", Type);
		switch( Type )
		{
		case SCHED_CHASE_ENEMY:
			return slFloaterChaseEnemy;
		case SCHED_TAKE_COVER_FROM_ENEMY:
			return slFloaterTakeCover;
		case SCHED_FAIL:
			return slFloaterFail;
		}

		return BaseClass.GetScheduleOfType( Type );
	}

	bool CheckRangeAttack1( float flDot, float flDist ) { return false; }
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }
	bool CheckMeleeAttack1( float flDot, float flDist ) { return false; }

	// TODO:
// 	void SetActivity( Activity NewActivity )
// 	{
// 		g_Game.AlertMessage( at_console, "Floater: SetActivity\n" );
// 		CBaseMonster@ pMonster = cast<CBaseMonster>(self);
// 		pMonster.SetActivity(NewActivity);
// 		if (self.m_flGroundSpeed == 0)
// 		{
// 			self.m_flGroundSpeed = BASE_FLOATER_SPEED;
// 		}
// 	}

	int LookupActivity(int activity)
	{
		return self.LookupSequence("idle1");
	}

	float GetMoveSpeed()
	{
		return Math.max(m_moveSpeed, self.m_flGroundSpeed);
	}

	void SetMoveSpeed(float speed)
	{
		m_moveSpeed = self.m_flGroundSpeed = speed;
	}

	void Move( float flInterval )
	{
		const int DIST_TO_CHECK = 200;
		float		flWaypointDist;
		float		flCheckDist;
		float		flDist;// how far the lookahead check got before hitting an object.
		float		flMoveDist;
		Vector		vecDir;
		Vector		vecApex;
		CBaseEntity@ pTargetEnt;

		// Don't move if no valid route
		if( self.m_Route(self.m_iRouteIndex).iType == 0 || self.m_movementGoal == 0 )
		{
			self.TaskFail();
			return;
		}

		if( self.m_flMoveWaitFinished > g_Engine.time )
			return;

		// if the monster is moving directly towards an entity (enemy for instance), we'll set this pointer
		// to that entity for the CheckLocalMove and Triangulate functions.
		@pTargetEnt = null;

		if( self.m_flGroundSpeed == 0 )
		{
			SetMoveSpeed(BASE_FLOATER_SPEED);
		}

		flMoveDist = GetMoveSpeed() * flInterval;

		do
		{
			// local move to waypoint.
			vecDir = ( self.m_Route(self.m_iRouteIndex).vecLocation - pev.origin ).Normalize();
			flWaypointDist = ( self.m_Route(self.m_iRouteIndex).vecLocation - pev.origin ).Length();

			self.MakeIdealYaw( self.m_Route(self.m_iRouteIndex).vecLocation );
			ChangeYaw( int(pev.yaw_speed) );
			//g_Game.AlertMessage(at_console, "Yaw: %1. Yaw Speed: %2. Ideal yaw: %3\n", pev.angles.y, pev.yaw_speed, pev.ideal_yaw);

			// if the waypoint is closer than CheckDist, CheckDist is the dist to waypoint
			if( flWaypointDist < DIST_TO_CHECK )
			{
				flCheckDist = flWaypointDist;
			}
			else
			{
				flCheckDist = DIST_TO_CHECK;
			}

			if( ( self.m_Route(self.m_iRouteIndex).iType & ( ~bits_MF_NOT_TO_MASK ) ) == bits_MF_TO_ENEMY )
			{
				// only on a PURE move to enemy ( i.e., ONLY MF_TO_ENEMY set, not MF_TO_ENEMY and DETOUR )
				@pTargetEnt = self.m_hEnemy.GetEntity();
			}
			else if( ( self.m_Route(self.m_iRouteIndex).iType & ~bits_MF_NOT_TO_MASK ) == bits_MF_TO_TARGETENT )
			{
				@pTargetEnt = self.m_hTargetEnt.GetEntity();
			}

			// !!!BUGBUG - CheckDist should be derived from ground speed.
			// If this fails, it should be because of some dynamic entity blocking this guy.
			// We've already checked this path, so we should wait and time out if the entity doesn't move
			flDist = 0;
			Vector vecEndPos;
			if( CheckLocalMove( pev.origin, pev.origin + vecDir * flCheckDist, pTargetEnt, flDist, vecEndPos ) != LOCALMOVE_VALID )
			{
				CBaseEntity@ pBlocker = null;

				// Can't move, stop
				self.Stop();
				// Blocking entity is in global trace_ent
				int globalTraceEntIndex = g_EngineFuncs.IndexOfEdict(g_Engine.trace_ent);
				if (globalTraceEntIndex > 0)
					@pBlocker = g_EntityFuncs.Instance( globalTraceEntIndex );
				//TODO:
// 				if( pBlocker !is null )
// 				{
// 					DispatchBlocked( edict(), pBlocker.edict() );
// 				}
				if( pBlocker !is null && self.m_moveWaitTime > 0 && pBlocker.IsMoving() && !pBlocker.IsPlayer() && (g_Engine.time -  self.m_flMoveWaitFinished) > 3.0 )
				{
					// Can we still move toward our target?
					if( flDist < GetMoveSpeed() )
					{
						// Wait for a second
						self.m_flMoveWaitFinished = g_Engine.time + self.m_moveWaitTime;
						return;
					}
				}
				else
				{
					// try to triangulate around whatever is in the way.
					if( FTriangulate( pev.origin, self.m_Route(self.m_iRouteIndex).vecLocation, flDist, pTargetEnt, vecApex ) )
					{
						InsertWaypoint( vecApex, bits_MF_TO_DETOUR );
						RouteSimplify( pTargetEnt );
					}
					else
					{
						self.Stop();
						if( self.m_moveWaitTime > 0 )
						{
							FRefreshRoute();
							self.m_flMoveWaitFinished = g_Engine.time + self.m_moveWaitTime * 0.5;
						}
						else
						{
							self.TaskFail();
						}
						return;
					}
				}
			}

			if( flCheckDist < flMoveDist )
			{
				MoveExecute( pTargetEnt, vecDir, flCheckDist / GetMoveSpeed() );

				AdvanceRoute( flWaypointDist );
				flMoveDist -= flCheckDist;
			}
			else
			{
				MoveExecute( pTargetEnt, vecDir, flMoveDist / GetMoveSpeed() );

				if( ShouldAdvanceRoute( flWaypointDist - flMoveDist ) )
				{
					AdvanceRoute( flWaypointDist );
				}
				flMoveDist = 0;
			}

			if( self.MovementIsComplete() )
			{
				self.Stop();
				RouteClear();
			}
		} while( flMoveDist > 0 && flCheckDist > 0 );
	}

	void RouteNew()
	{
		self.m_iRouteIndex = 0;
		
		for (size_t i=0; i<ROUTE_SIZE; ++i)
		{
			self.m_Route(i).iType = 0;
			self.m_Route(i).flSavedMoveWait = 0;
		}
	}

	void RouteClear()
	{
		RouteNew();

		self.m_movementGoal = MOVEGOAL_NONE;
		self.m_movementActivity = ACT_IDLE;
		self.Forget( bits_MEMORY_MOVE_FAILED );
	}

	void InsertWaypoint( const Vector& in vecLocation, int afMoveFlags )
	{
		int type = afMoveFlags | ( self.m_Route(self.m_iRouteIndex).iType & ~bits_MF_NOT_TO_MASK );

		for( int i = ROUTE_SIZE - 1; i > 0; i-- )
		{
			WaypointAssign(self.m_Route(i), self.m_Route(i - 1));
		}

		self.m_Route(self.m_iRouteIndex).vecLocation = vecLocation;
		self.m_Route(self.m_iRouteIndex).iType = type;
	}

	bool ShouldSimplify( int routeType )
	{
		routeType &= ~bits_MF_IS_GOAL;
		if( ( routeType == bits_MF_TO_PATHCORNER ) || ( routeType & bits_MF_DONT_SIMPLIFY ) != 0 )
			return false;
		return true;
	}

	void RouteSimplify( CBaseEntity@ pTargetEnt )
	{
		// BUGBUG: this doesn't work 100% yet
		int		i, count;
		Vector		vecStart;
		array<WaypointValue> outRoute(ROUTE_SIZE * 2);

		count = 0;

		const int routeSize = ROUTE_SIZE;
		for( i = self.m_iRouteIndex; i < routeSize; i++ )
		{
			if( self.m_Route(i).iType == 0 )
				break;
			else
				count++;
			if( (self.m_Route(i).iType & bits_MF_IS_GOAL) != 0 )
				break;
		}
		// Can't simplify a direct route!
		if( count < 2 )
		{
			return;
		}

		size_t outCount = 0;
		vecStart = pev.origin;

		float localMoveDist;
		Vector localMoveEndPos;

		for( i = 0; i < count - 1; i++ )
		{
			// Don't eliminate path_corners
			if( !ShouldSimplify( self.m_Route(self.m_iRouteIndex + i).iType ) )
			{
				outRoute[outCount] = self.m_Route(self.m_iRouteIndex + i);
				outCount++;
			}
			else if( CheckLocalMove( vecStart, self.m_Route(self.m_iRouteIndex+i + 1).vecLocation, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
			{
				// Skip vert
				continue;
			}
			else
			{
				Vector vecTest, vecSplit;

				// Halfway between this and next
				vecTest = ( self.m_Route(self.m_iRouteIndex + i + 1).vecLocation + self.m_Route(self.m_iRouteIndex + i).vecLocation ) * 0.5f;

				// Halfway between this and previous
				vecSplit = ( self.m_Route(self.m_iRouteIndex + i).vecLocation + vecStart ) * 0.5f;

				int iType = ( self.m_Route(self.m_iRouteIndex + i).iType | bits_MF_TO_DETOUR ) & ~bits_MF_NOT_TO_MASK;
				if( CheckLocalMove( vecStart, vecTest, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
				{
					outRoute[outCount].iType = iType;
					outRoute[outCount].vecLocation = vecTest;
				}
				else if( CheckLocalMove( vecSplit, vecTest, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
				{
					outRoute[outCount].iType = iType;
					outRoute[outCount].vecLocation = vecSplit;
					outRoute[outCount+1].iType = iType;
					outRoute[outCount+1].vecLocation = vecTest;
					outCount++; // Adding an extra point
				}
				else
				{
					outRoute[outCount] = self.m_Route(self.m_iRouteIndex + i);
				}
			}
			// Get last point
			vecStart = outRoute[outCount].vecLocation;
			outCount++;
		}
		//ASSERT( i < count );
		outRoute[outCount] = self.m_Route(self.m_iRouteIndex + i);
		outCount++;

		// Terminate
		outRoute[outCount].iType = 0;
		//ASSERT( outCount < ( ROUTE_SIZE * 2 ) );

		// Copy the simplified route, disable for testing
		self.m_iRouteIndex = 0;

		int outCounti = outCount;
		for( i = 0; i < routeSize && i < outCounti; i++ )
		{
			WaypointAssign(self.m_Route(i), outRoute[i]);
		}

		// Terminate route
		if( i < routeSize )
			self.m_Route(i).iType = 0;
	}

	bool FRefreshRoute()
	{
		bool returnCode = false;
		RouteNew();

		switch( self.m_movementGoal )
		{
			case MOVEGOAL_PATHCORNER:
			{
				// monster is on a path_corner loop
				CBaseEntity@ pPathCorner = m_goalEnt;
				if (pPathCorner !is null)
				{
					returnCode = BuildRoute( pPathCorner.pev.origin, bits_MF_TO_PATHCORNER, null );
				}
			}
			break;
			case MOVEGOAL_ENEMY:
				returnCode = BuildRoute( self.m_vecEnemyLKP, bits_MF_TO_ENEMY, self.m_hEnemy );
				break;
			case MOVEGOAL_LOCATION:
				returnCode = BuildRoute( self.m_vecMoveGoal, self.m_movementGoal, null );
				break;
			case MOVEGOAL_TARGETENT:
			{
				CBaseEntity@ pTarget = self.m_hTargetEnt.GetEntity();
				if( pTarget !is null )
				{
					returnCode = BuildRoute( pTarget.pev.origin, self.m_movementGoal, pTarget );
				}
			}
				break;
			case MOVEGOAL_NODE:
				returnCode = self.FGetNodeRoute( self.m_vecMoveGoal );
				break;
		}
		return returnCode;
	}

	bool BuildRoute(const Vector& in vecGoal, int iMoveFlag, CBaseEntity@ pTarget)
	{
		float flDist;
		Vector vecApex;
		int iLocalMove;

		RouteNew();
		self.m_movementGoal = self.RouteClassify( iMoveFlag );

		// so we don't end up with no moveflags
		self.m_Route(0).vecLocation = vecGoal;
		self.m_Route(0).iType = iMoveFlag | bits_MF_IS_GOAL;

		// check simple local move
		Vector vecEndPos;
		iLocalMove = CheckLocalMove( pev.origin, vecGoal, pTarget, flDist, vecEndPos );

		if( iLocalMove == LOCALMOVE_VALID )
		{
			// monster can walk straight there!
			return true;
		}
		//TODO: the floater gets jerking movement when this is enabled
		else if( iLocalMove != LOCALMOVE_INVALID_DONT_TRIANGULATE && FTriangulate( pev.origin, vecGoal, flDist, pTarget, vecApex ) )
		{
			self.m_Route(0).vecLocation = vecApex;
			self.m_Route(0).iType = (iMoveFlag | bits_MF_TO_DETOUR);
			self.m_Route(0).flSavedMoveWait = 0;
			self.m_Route(1).vecLocation = vecGoal;
			self.m_Route(1).iType = iMoveFlag | bits_MF_IS_GOAL;
			self.m_Route(1).flSavedMoveWait = 0;

			//RouteSimplify( pTarget );
			return true;
		}

		// last ditch, try nodes
		if( self.FGetNodeRoute( vecGoal ) )
		{
			self.m_vecMoveGoal = vecGoal;
			RouteSimplify( pTarget );
			return true;
		}

		return false;
	}

	bool FTriangulate( const Vector& in vecStart, const Vector& in vecEnd, float flDist, CBaseEntity@ pTargetEnt, Vector& out pApex )
	{
		Vector		vecDir;
		Vector		vecForward;
		Vector		vecLeft;// the spot we'll try to triangulate to on the left
		Vector		vecRight;// the spot we'll try to triangulate to on the right
		Vector		vecTop;// the spot we'll try to triangulate to on the top
		Vector		vecBottom;// the spot we'll try to triangulate to on the bottom
		Vector		vecFarSide;// the spot that we'll move to after hitting the triangulated point, before moving on to our normal goal.
		int			i;
		float		sizeX, sizeZ;

		// If the hull width is less than 24, use 24 because CheckLocalMove uses a min of
		// 24.
		sizeX = pev.size.x;
		if (sizeX < 24.0)
			sizeX = 24.0;
		else if (sizeX > 48.0)
			sizeX = 48.0;
		sizeZ = pev.size.z;
		//if (sizeZ < 24.0)
		//	sizeZ = 24.0;

		vecForward = ( vecEnd - vecStart ).Normalize();

		Vector vecDirUp(0,0,1);
		vecDir = CrossProduct ( vecForward, vecDirUp);

		// start checking right about where the object is, picking two equidistant starting points, one on
		// the left, one on the right. As we progress through the loop, we'll push these away from the obstacle,
		// hoping to find a way around on either side. pev->size.x is added to the ApexDist in order to help select
		// an apex point that insures that the monster is sufficiently past the obstacle before trying to turn back
		// onto its original course.

		vecLeft = pev.origin + ( vecForward * ( flDist + sizeX ) ) - vecDir * ( sizeX * 3 );
		vecRight = pev.origin + ( vecForward * ( flDist + sizeX ) ) + vecDir * ( sizeX * 3 );
		if (pev.movetype == MOVETYPE_FLY)
		{
			vecTop = pev.origin + (vecForward * flDist) + (vecDirUp * sizeZ * 3);
			vecBottom = pev.origin + (vecForward * flDist) - (vecDirUp *  sizeZ * 3);
		}

		vecFarSide = self.m_Route(self.m_iRouteIndex).vecLocation;

		vecDir = vecDir * sizeX * 2;
		if (pev.movetype == MOVETYPE_FLY)
			vecDirUp = vecDirUp * sizeZ * 2;

		Vector localMoveEndPos;
		float localMoveDist;
		for ( i = 0 ; i < 8; i++ )
		{
			if ( CheckLocalMove( pev.origin, vecRight, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
			{
				if ( CheckLocalMove ( vecRight, vecFarSide, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
				{
					pApex = vecRight;
					return true;
				}
			}
			if ( CheckLocalMove( pev.origin, vecLeft, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
			{
				if ( CheckLocalMove ( vecLeft, vecFarSide, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
				{
					pApex = vecLeft;
					return true;
				}
			}

			if (pev.movetype == MOVETYPE_FLY)
			{
				if ( CheckLocalMove( pev.origin, vecTop, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID)
				{
					if ( CheckLocalMove ( vecTop, vecFarSide, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
					{
						pApex = vecTop;
						return true;
					}
				}
				if ( CheckLocalMove( pev.origin, vecBottom, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
				{
					if ( CheckLocalMove ( vecBottom, vecFarSide, pTargetEnt, localMoveDist, localMoveEndPos ) == LOCALMOVE_VALID )
					{
						pApex = vecBottom;
						return true;
					}
				}
			}

			vecRight = vecRight + vecDir;
			vecLeft = vecLeft - vecDir;
			if (pev.movetype == MOVETYPE_FLY)
			{
				vecTop = vecTop + vecDirUp;
				vecBottom = vecBottom - vecDirUp;
			}
		}

		return false;
	}

	bool ShouldAdvanceRoute( float flWaypointDist )
	{
		return flWaypointDist <= 32;
	}

	void AdvanceRoute( float distance )
	{
		const int routeSize = ROUTE_SIZE;
		if( self.m_iRouteIndex == routeSize - 1 )
		{
 			FRefreshRoute();
		}
		else
		{
			if( ( self.m_Route(self.m_iRouteIndex).iType & bits_MF_IS_GOAL ) == 0 )
			{
				if( ( self.m_Route(self.m_iRouteIndex).iType & ~bits_MF_NOT_TO_MASK ) == bits_MF_TO_PATHCORNER )
					@m_goalEnt = m_goalEnt.GetNextTarget();
				self.m_iRouteIndex++;
			}
			else
			{
				if( distance < GetMoveSpeed() * 0.2 )
				{
					if (m_goalEnt !is null && (self.m_Route(self.m_iRouteIndex).iType & bits_MF_TO_PATHCORNER) != 0)
					{
						m_nextPatrolPathCheck = g_Engine.time + m_goalEnt.GetDelay();
						pev.ideal_yaw = m_goalEnt.pev.angles.y;
						@m_goalEnt = m_goalEnt.GetNextTarget();
					}
					self.MovementComplete();
				}
			}
		}
	}

	int CheckLocalMove( const Vector& in vecStart, const Vector& in vecEnd, CBaseEntity@ pTarget, float& out flDist, Vector& out vecEndPosition, bool fOriginalCheck = false )
	{
		TraceResult tr;

		g_Utility.TraceHull( vecStart + Vector( 0, 0, 18 ), vecEnd + Vector( 0, 0, 18 ), dont_ignore_monsters, head_hull, self.edict(), tr );

		flDist = ( ( tr.vecEndPos - Vector( 0, 0, 18 ) ) - vecStart ).Length();

		if( tr.fStartSolid != 0 || tr.flFraction < 1.0 )
		{
			vecEndPosition = tr.vecEndPos;
			if( pTarget !is null && pTarget.edict() is g_Engine.trace_ent )
				return LOCALMOVE_VALID;
			return LOCALMOVE_INVALID;
		}

		return LOCALMOVE_VALID;
	}
//
	void MoveExecute( CBaseEntity@ pTargetEnt, const Vector& in vecDir, float flInterval )
	{
		if( self.m_IdealActivity != self.m_movementActivity )
			self.m_IdealActivity = self.m_movementActivity;

		m_velocity = m_velocity * 0.8 + GetMoveSpeed() * vecDir * 0.2;

		g_EngineFuncs.MoveToOrigin( self.edict(), pev.origin + m_velocity, m_velocity.Length() * flInterval, MOVE_STRAFE );
	}

	void PainSound( void )
	{
		if( g_Engine.time > m_nextPainTime )
		{
			m_nextPainTime = g_Engine.time + 1.5;
			const int pitch = 95 + Math.RandomLong( 0, 10 );

			string painSound = "";
			switch (Math.RandomLong(0,2))
			{
			case 0:
				painSound = "fi/floater/floater_pain1.wav";
				break;
			case 1:
				painSound = "fi/floater/floater_pain2.wav";
				break;
			case 2:
				painSound = "fi/floater/floater_pain3.wav";
				break;
			}

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, painSound, 1.0, ATTN_NORM, 0, pitch );
		}
	}

	// TODO:
// 	float HearingSensitivity()
// 	{
// 		if (IsProvoked())
// 			return BaseClass.HearingSensitivity();
// 		else
// 			return 0.6f;
// 	}

	int TakeDamage(entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{
		MakeProvoked();
		return BaseClass.TakeDamage(pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}

	void Killed(entvars_t@ pevAttacker, int iGib)
	{
		BaseClass.Killed(pevAttacker, GIB_ALWAYS);
		g_howlTime = g_Engine.time;
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "fi/floater/floater_howl.wav", 1.0, FLOATER_HOWL_ATTN, SND_STOP, 100 );
		ExplodeEffect();
		GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, pev.origin, 300, 0.3, self );
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "common/bodysplat.wav", 1, ATTN_NORM );

		g_EntityFuncs.SpawnRandomGibs( pev, 4, 0 );

		SetThink( ThinkFunction( ThinkRemove ) );
		pev.nextthink = g_Engine.time;
	}

	void ThinkRemove( void )
	{
		self.SUB_Remove();
	}

	void UpdateOnRemove()
	{
		//g_Game.AlertMessage( at_console, "Floater: UpdateOnRemove\n" );
		g_EntityFuncs.Remove(m_leftGlow);
		@m_leftGlow = null;
		g_EntityFuncs.Remove(m_rightGlow);
		@m_rightGlow = null;
		BaseClass.UpdateOnRemove();
	}

	void GlowUpdate()
	{
		GlowUpdate(m_leftGlow);
		GlowUpdate(m_rightGlow);
	}

	void GlowUpdate(CSprite@ glow)
	{
		const float blueSpeed = 16;
		const float redSpeed = 6;
		if (glow !is null)
		{
			if (Bloating())
			{
				glow.pev.rendercolor.z = UTIL_Approach(0,glow.pev.rendercolor.z,blueSpeed);
				glow.pev.rendercolor.x = UTIL_Approach(255,glow.pev.rendercolor.x,redSpeed);
			}
			glow.SetOrigin( pev.origin );
		}
	}

	CSprite@ CreateGlow(const Vector& in glowColor, int attachment)
	{
		CSprite@ glow = g_EntityFuncs.CreateSprite(FLOATER_GLOW_SPRITE, pev.origin, false);
		if (glow !is null)
		{
			glow.SetTransparency(kRenderGlow, int(glowColor.x), int(glowColor.y), int(glowColor.z), 220, kRenderFxNoDissipation);
			glow.SetScale(0.2);
			glow.SetAttachment(self.edict(), attachment);
		}
		return glow;
	}

	void StartBloating()
	{
		g_SoundSystem.EmitSound(self.edict(), CHAN_WEAPON, "fi/floater/floater_spinup.wav", 1, ATTN_NORM);
		m_targetScale = m_originalScale * 1.5;
		m_startBloatingTime = g_Engine.time;
	}

	void ExplodeEffect()
	{
		Vector up(0,0,1);
		Vector exploOrigin = pev.origin;
		exploOrigin.z += 32.0;

		NetworkMessage mSpray(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, exploOrigin);
		mSpray.WriteByte(TE_SPRITE_SPRAY);
		mSpray.WriteCoord(exploOrigin.x);
		mSpray.WriteCoord(exploOrigin.y);
		mSpray.WriteCoord(exploOrigin.z);
		mSpray.WriteCoord(up.x);
		mSpray.WriteCoord(up.y);
		mSpray.WriteCoord(up.z);
		mSpray.WriteShort(m_tinySpit);
		mSpray.WriteByte(25);
		mSpray.WriteByte(15);
		mSpray.WriteByte(255);
		mSpray.End();

		NetworkMessage mSprite(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, exploOrigin);
		mSprite.WriteByte(TE_SPRITE);
		mSprite.WriteCoord(exploOrigin.x);
		mSprite.WriteCoord(exploOrigin.y);
		mSprite.WriteCoord(exploOrigin.z);
		mSprite.WriteShort(Math.RandomLong( 0, 1 ) == 1 ? m_explode1 : m_explode2);
		mSprite.WriteByte(20);
		mSprite.WriteByte(120);
		mSprite.End();

		NetworkMessage mLight(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, exploOrigin);
		mLight.WriteByte(TE_DLIGHT);
		mLight.WriteCoord(exploOrigin.x);
		mLight.WriteCoord(exploOrigin.y);
		mLight.WriteCoord(exploOrigin.z);
		mLight.WriteByte(12);
		mLight.WriteByte(60);
		mLight.WriteByte(180);
		mLight.WriteByte(0);
		mLight.WriteByte(20);
		mLight.WriteByte(20);
		mLight.End();

		g_SoundSystem.EmitSound(self.edict(), CHAN_BODY, "weapons/splauncher_impact.wav", 1, ATTN_NORM);

		g_WeaponFuncs.RadiusDamage(exploOrigin, pev, pev, FLOATER_EXPLO_DAMAGE, FLOATER_EXPLO_DAMAGE * 2.5, CLASS_ALIEN_MONSTER, DMG_BLAST|DMG_ACID);
	}

	void FloaterBloatUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		StartBloating();
		SetUse(null);
	}

	bool Bloating()
	{
		return m_startBloatingTime > 0;
	}
	bool IsProvoked()
	{
		return (pev.spawnflags & SF_FLOATER_WAIT_UNTIL_PROVOKED) == 0 || self.HasMemory(bits_MEMORY_FLOATER_PROVOKED);
	}

	void MakeProvoked(bool alertOthers = true)
	{
		if (!IsProvoked())
		{
			Vector glowColor = FLOATER_NORMAL_COLOR;
			if (m_leftGlow !is null)
				m_leftGlow.SetColor(int(glowColor.x), int(glowColor.y), int(glowColor.z));
			if (m_rightGlow !is null)
				m_rightGlow.SetColor(int(glowColor.x), int(glowColor.y), int(glowColor.z));
			self.Remember(bits_MEMORY_FLOATER_PROVOKED);
			if (alertOthers)
				AlertOthers();
			// TODO:
			/*if (self.m_pCine && self.m_pCine.CanInterrupt())
			{
				self.CineCleanup();
				self.ClearSchedule();
			}*/
		}
	}

	void AlertOthers()
	{
		if( pev.netname == "")
			return;

		CBaseEntity@ pEntity = null;

		while( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "netname", pev.netname ) ) !is null)
		{
			if ( pEntity == self )
				continue;
			if (pEntity.GetClassname() != pEntity.GetClassname())
				continue;
			CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
			if( pMonster !is null )
			{
				CFlockingFloater@ pFloater = cast<CFlockingFloater>(CastToScriptClass(pMonster));
				if (pFloater !is null)
					pFloater.MakeProvoked(false); // no recusrive alert
			}
		}
	}
	
	Schedule@ StartPatrol(CBaseEntity @path)
	{
		if (path !is null)
		{
			@m_goalEnt = path;

			// Monster will start turning towards his destination
			self.MakeIdealYaw( m_goalEnt.pev.origin );

			self.m_movementGoal = MOVEGOAL_PATHCORNER;

			if( pev.movetype == MOVETYPE_FLY )
				self.m_movementActivity = ACT_FLY;
			else if (m_goalEnt.pev.speed < 200)
				self.m_movementActivity = ACT_WALK;
			else
				self.m_movementActivity = ACT_RUN;

			if( FRefreshRoute() )
			{
				return GetScheduleOfType( SCHED_IDLE_WALK );
			}
			else
			{
				g_Game.AlertMessage( at_aiconsole, "%1: couldn't create route. Can't patrol\n", self.GetClassname() );
			}
		}
		return null;
	}
};

array<ScriptSchedule@>@ monster_floater_schedules;

ScriptSchedule slFloaterChaseEnemy(
		bits_COND_NEW_ENEMY |
		bits_COND_ENEMY_DEAD |
		bits_COND_TASK_FAILED,

		0,

		"FloaterChaseEnemy");

ScriptSchedule slFloaterTakeCover(
		bits_COND_NEW_ENEMY,
		0,
		"FloaterTakeCover");

ScriptSchedule slFloaterFail(
		0,
		0,
		"FloaterFail");

ScriptSchedule slIdlePatrolTurning(
		bits_COND_NEW_ENEMY |
		bits_COND_SEE_FEAR |
		bits_COND_LIGHT_DAMAGE |
		bits_COND_HEAVY_DAMAGE |
		bits_COND_HEAR_SOUND,

		bits_SOUND_COMBAT |
		bits_SOUND_WORLD |
		bits_SOUND_PLAYER |
		bits_SOUND_DANGER,
		"IdleTurning");

void InitSchedules()
{
	slFloaterChaseEnemy.AddTask(ScriptTask(TASK_GET_PATH_TO_ENEMY, 64));
	slFloaterChaseEnemy.AddTask(ScriptTask(TASK_WAIT_FOR_MOVEMENT, 0));

	slFloaterTakeCover.AddTask(ScriptTask(TASK_WAIT, 0.2));
	slFloaterTakeCover.AddTask(ScriptTask(TASK_FIND_COVER_FROM_ENEMY, 0));
	slFloaterTakeCover.AddTask(ScriptTask(TASK_WAIT_FOR_MOVEMENT, 0));
	slFloaterTakeCover.AddTask(ScriptTask(TASK_WAIT, 1));

	slFloaterFail.AddTask(ScriptTask(TASK_STOP_MOVING, 0));
	slFloaterFail.AddTask(ScriptTask(TASK_WAIT, 1));
	slFloaterFail.AddTask(ScriptTask(TASK_WAIT_PVS, 0));
	
	slIdlePatrolTurning.AddTask(ScriptTask(TASK_STOP_MOVING, 0));
	slIdlePatrolTurning.AddTask(ScriptTask(TASK_SET_ACTIVITY, ACT_IDLE));
	slIdlePatrolTurning.AddTask(ScriptTask(TASK_WAIT_PATROL_TURNING, 0));

	array<ScriptSchedule@> scheds = {slFloaterChaseEnemy, slFloaterTakeCover, slIdlePatrolTurning};

	@monster_floater_schedules = @scheds;
}

void Register()
{
	g_howlTime = 0;
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity( "FIFlockingFloater::CFlockingFloater", "monster_floater" );
}

}
