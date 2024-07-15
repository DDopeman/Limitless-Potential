#include "base_turret"

/* Natural Selection Alien Turret Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://github.com/ValveSoftware/halflife Half-Life SDK - by Valve
https://twhl.info/wiki/page/Tutorial%3A_Coding_NPCs_in_GoldSrc - by dexter
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_OFF_CHAMBER
{
//Vars
//Models
const string MODEL = "models/ns/monsters/ba_offense_test_a.mdl";
const string MODEL_SPIKE = "models/ns/spike.mdl";
const string MODEL_SPRITE = "sprites/ns/bigspit.spr";

//Sounds
const string SOUND_FIRE = "ns/monsters/ba_offense/aturret-1.wav";
const string SOUND_DEPLOY = "ns/monsters/ba_offense/alien_chamber_deploy.wav";
const string SOUND_DEATH = "ns/monsters/ba_offense/alien_chamber_die.wav";

array<string> SOUNDS = {
	SOUND_FIRE,
	SOUND_DEPLOY,
	SOUND_DEATH 
};
//Stats
const float TURRET_HEALTH = 150;
const float SPIKE_LIFETIME = 10;
const float SPIKE_DMG = 20;
const float SPIKE_SPEED = 1500;

enum e_chamber_anims
{
	SPAWN = 0,
	DEPLOY,
	IDLE1,
	IDLE2,
	RESEARCHING,
	DUMMY_ACTIVE,
	FIRE,
	TAKE_DAMAGE,
	DIE_FORWARD,
	DIE_LEFT,
	DIE_BACKWARD,
	DIE_RIGHT,
	DUMMY_SPECIAL
}

class CAlienTurret : ScriptBaseMonsterEntity, NS_BASE_TURRET::TurretBase
{
	private float m_flBuildEndTime;
	private bool m_blIsBuilt = false;
	private bool m_blPersistent = false;
	private float m_flEnergy;

	private int m_iModelIndex;
	void Precache()
	{
		m_iModelIndex = g_Game.PrecacheModel( MODEL );
		g_Game.PrecacheModel( MODEL_SPIKE );
		g_Game.PrecacheModel( MODEL_SPRITE );

		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}

		CommonPrecache();
	}

	void Spawn()
	{
		Precache();
		m_flEnergy = 0.0f;
		g_EntityFuncs.SetModel( self, MODEL );

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_SLIDEBOX;   
		self.m_bloodColor = BLOOD_COLOR_YELLOW;

		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, 0 ), Vector( 16.0, 16.0, 44.0 ) );

		//TODO Health from keyvalue or cvar?
		if( self.pev.health == 0 )
			self.pev.health = TURRET_HEALTH;
		self.pev.max_health = self.pev.health;

		PlayAnimationAtIndex( DEPLOY, true, 0.2f ); 
				
		m_flBuildEndTime = g_Engine.time + ( GetTimeForAnimation( self.pev.sequence ) / self.pev.framerate );
		//SetTouch( TouchFunction( BuildableTouch ) );
		Setup();
		
		SetThink( ThinkFunction( PreBuiltThink ) );
		self.pev.nextthink = g_Engine.time + 0.5f;
		g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, SOUND_DEPLOY, 1.0, ATTN_IDLE );    
	}

	int Classify()
	{
		return CLASS_ALIEN_MILITARY;
	}

	void PreBuiltThink()
	{
		//if( !GetIsBuilt() )
		//    UpdateAutoBuild( 0.5 );
		//else
		//    SetHasBeenBuilt();
		if( m_flBuildEndTime < g_Engine.time )
		{
			m_blIsBuilt = true;
			SetEnabledState();
		}
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		TurretKilled( pevAttacker, iGib );
	}

	void Shoot( const Vector& in vecOrigin, const Vector& in vecToEnemy, const Vector& in vecEnemyVelocity)
	{
		// Spawn spike
		CBaseEntity@ pEntitySpike = g_EntityFuncs.CreateEntity( "proj_turret_spike" );
		CSpike@ pSpike = cast<CSpike@>( CastToScriptClass( pEntitySpike ) );

		pSpike.pev.effects = 0;
		pSpike.pev.frame = 0;
		pSpike.pev.scale = 0.5;
		pSpike.pev.rendermode = kRenderTransAlpha;
		pSpike.pev.renderamt = 255;

		// Predict where enemy will be when the spike hits and shoot that way
		float flTimeToReachEnemy = vecToEnemy.Length2D()/SPIKE_SPEED;
		Vector vecEnemyPosition;
		VectorAdd( self.pev.origin, vecToEnemy, vecEnemyPosition );

		float flVelocityLength = vecEnemyVelocity.Length();
		Vector flEnemyNormVelocity = vecEnemyVelocity.Normalize();

		// Don't always hit very fast moving targets (jetpackers)
		const float kVelocityFactor = .7f;

		Vector vecPredictedPosition;
		VectorMA( vecEnemyPosition, flVelocityLength*kVelocityFactor*flTimeToReachEnemy, flEnemyNormVelocity, vecPredictedPosition );

		Vector theOrigin = vecOrigin;
		
		//Vector vecDirToEnemy = inDirToEnemy.Normalize();

		Vector vecDirToPredictedEnemy;
		VectorSubtract( vecPredictedPosition, self.pev.origin, vecDirToPredictedEnemy );
		Vector vecDirToEnemy = vecDirToPredictedEnemy.Normalize();

		VectorCopy( vecOrigin, pSpike.pev.origin) ;

		// Pass this velocity to event
		int iVelocityScalar = SPIKE_SPEED;

		Vector vecInitialVelocity;
		VectorScale( vecDirToEnemy, iVelocityScalar, vecInitialVelocity );
		
		// Set spike owner to OC so it doesn't collide with it
		@pSpike.pev.owner = self.edict();

		// Set Spike's team :)
		pSpike.pev.team = self.pev.team;

		VectorCopy( vecInitialVelocity, pSpike.pev.velocity );

		// Set amount of damage it will do
		//pSpike.SetDamage(BALANCE_VAR(kOffenseChamberDamage));

		// Take into account network precision
		Vector vecNetworkDirToEnemy;
		VectorScale( vecDirToEnemy, 100.0f, vecNetworkDirToEnemy );

		//PLAYBACK_EVENT_FULL(0, 0, this->mEvent, 0, theOrigin, vecNetworkDirToEnemy, 1.0f, 0.0, /*theWeaponIndex*/ this->entindex(), 0, 0, 0 );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, SOUND_FIRE, 1.0f, ATTN_NORM, 0, 100 + ( Math.RandomLong(0, 30) - 30/2 ) );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin,  600, 0.5, self );
		pSpike.pev.angles = Math.VecToAngles( vecDirToEnemy );

		// Play attack anim
		PlayAnimationAtIndex( 6, true );

		//Uncloak();
	}

	int MoveTurret()
	{
		// Set animation, without overriding
		int iAnim = GetIdle1Animation();
		if( Math.RandomLong( 0, 1 ) == 0 )
		{
			iAnim = GetIdle2Animation();
		}
		PlayAnimationAtIndex( iAnim, false );
		
		return BaseMoveTurret();
	}
	float GetPointsForDamage( float flDamage )
	{
		//return ( flDamage/self.pev.max_health ) * ( 3 * ( self.pev.max_health/sk_offensechamber_health.value ) );
		return ( flDamage/self.pev.max_health ) * ( 4 );
	}

	int GetSetEnabledAnimation()
	{
		return -1;
	}

	bool GetRequiresLOS()
	{
		return true;
	}

	bool GetIsOrganic()
	{
		return true;
	}

	float GetRateOfFire() const
	{
		return .5f + Math.RandomFloat( 0.0f, ( 1.0f - m_flEnergy ) );
	}

	//AAAAAAAAAAAAAAAAAAAAAAAAAAA THIS IS SO DUMB WHY DOESN'T AS EXPOSE STUDIO MODEL FUNCS AHHHHHHHHHHHHHHHHHHHHH
	float GetTimeForAnimation( int iIndex ) 
	{
		switch( iIndex )
		{
			case 0:
				return (2.0f/12.0f);
			case 1:
				return (17.0f/6.0f);
			case 2:
				return (35.0f/5.0f);
			case 3:
				return (35.0f/2.0f);
			case 4:
				return (35.0f/15.0f);
			case 5:
				return (2.0f/8.0f);
			case 6:
				return (9.0f/24.0f);
			case 7:
				return (13.0f/30.0f);
			case 8:
				return (2.0f/17.0f);
			case 9:
				return (2.0f/17.0f);
			case 10:
				return (2.0f/17.0f);
			case 11:
				return (2.0f/17.0f);
			case 12:
				return (2.0f/1.0f);
		}
		return 0.0f;
	} 

	int	GetXYRange()
	{
		return 1000;
	}

	string GetKilledSound()
	{
		return SOUND_DEATH;
	}

	string GetPingSound()
	{
		return "";
	}

	int	GetIdle1Animation() const
	{
		int iAnim = -1;
		
		if( m_blIsBuilt )
		{
			if( Math.RandomLong( 0, 5 ) == 0)
			{
				iAnim = 4;
			}
			else
			{
				iAnim = 2;
			}
		}
		
		return iAnim;
	}

	int	GetIdle2Animation() const
	{
		int iAnim = -1;
		
		if( m_blIsBuilt )
		{
			iAnim = 3;
		}
		
		return iAnim;
	}
}

class CSpike : ScriptBaseEntity
{
	EHandle m_hOwner;

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_SPIKE );
	}

	void Spawn()
	{
		Precache();

		self.pev.movetype = MOVETYPE_FLY;
		g_EntityFuncs.SetModel( self, MODEL_SPIKE );
		self.pev.solid = SOLID_BBOX;
		
		self.pev.frame = 0;
		self.pev.scale = 0.5;
		self.pev.rendermode = kRenderTransAlpha;
		self.pev.renderamt = 255;
		
		SetTouch( TouchFunction( SpikeTouch ) );
		
		// Enforce short range
		SetThink( ThinkFunction( SpikeDeath ) );
		self.pev.nextthink = g_Engine.time + SPIKE_LIFETIME;
	}

	void SpikeDeath()
	{
		g_EntityFuncs.Remove( self );
	}

	void SpikeTouch( CBaseEntity@ pOther )
	{
		if( !m_hOwner )
		{
			if( self.pev.owner !is null )
				m_hOwner = EHandle( g_EntityFuncs.Instance( self.pev.owner ) );
		}
		CBaseEntity@ pSpikeOwner = cast<CBaseEntity@>( m_hOwner.GetEntity() );
		if( pSpikeOwner !is null && pOther !is pSpikeOwner )
		{
			if( self.IRelationship( pOther ) != -2 )
			{
				if( pSpikeOwner.IsAlive() )
					pOther.TakeDamage( self.pev, pSpikeOwner.pev, SPIKE_DMG, DMG_SLASH );
				else
					pOther.TakeDamage( self.pev, self.pev, SPIKE_DMG, DMG_SLASH );
			}
			// Kill it off
			SpikeDeath();
		}
	}
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_OFF_CHAMBER::CAlienTurret", "monster_offensechamber" );
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_OFF_CHAMBER::CSpike", "proj_turret_spike" );
}
}