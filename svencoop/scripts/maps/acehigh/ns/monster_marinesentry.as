#include "base_turret"

/* Natural Selection Marine Sentry Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://github.com/ValveSoftware/halflife Half-Life SDK - by Valve
https://twhl.info/wiki/page/Tutorial%3A_Coding_NPCs_in_GoldSrc - by dexter
Natural Selection Source Code - by Unknown Worlds
*/

namespace NS_MARINE_SENTRY
{
//Vars
//Models
const string MODEL = "models/ns/monsters/b_sentry_test_a.mdl";
//Sounds
const string SOUND_FIRE1 = "ns/monsters/b_sentry/turret-1.wav";
const string SOUND_FIRE2 = "ns/monsters/b_sentry/turret-2.wav";
const string SOUND_FIRE3 = "ns/monsters/b_sentry/turret-3.wav";
const string SOUND_FIRE4 = "ns/monsters/b_sentry/turret-4.wav";
const string SOUND_DEPLOY = "ns/monsters/b_sentry/turret_deploy.wav";
const string SOUND_PING = "ns/monsters/b_sentry/turret_ping.wav";
const string SOUND_DEATH1 = "turret/tu_die.wav";
const string SOUND_DEATH2 = "turret/tu_die2.wav";
const string SOUND_DEATH3 = "turret/tu_die3.wav";

array<string> SOUNDS = {
	SOUND_FIRE1,
	SOUND_FIRE2,
	SOUND_FIRE3,
	SOUND_FIRE4,
	SOUND_DEPLOY,
	SOUND_PING,
	SOUND_DEATH1,
	SOUND_DEATH2,
	SOUND_DEATH3,
};

//Stats
const float SENTRY_HEALTH = 150;
//const float SENTRY_DMG = 10;
const float SENTRY_DMG = 6;

enum e_sentry_anims
{
	IDLE_OFF = 0,
	FIRE,
	SPIN,
	DEPLOY,
	RETIRE,
	DIE
}

class CMarineSentry : ScriptBaseMonsterEntity, NS_BASE_TURRET::TurretBase
{
	private float m_flBuildEndTime;
	private bool m_blIsBuilt = false;
	private bool m_blPersistent = false;

	private int m_iModelIndex;
	
	void Precache()
	{
		m_iModelIndex = g_Game.PrecacheModel( MODEL );
		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL );

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_SLIDEBOX;   
		self.m_bloodColor = DONT_BLEED;

		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, 0 ), Vector( 16.0, 16.0, 42.0 ) );

		//TODO Health from keyvalue or cvar?
		if( self.pev.health == 0 )
			self.pev.health = SENTRY_HEALTH;
		self.pev.max_health = self.pev.health;      

		PlayAnimationAtIndex( DEPLOY, true, 0.2f ); 
				
		m_flBuildEndTime = g_Engine.time + ( GetTimeForAnimation( self.pev.sequence ) / self.pev.framerate );
		Setup();

		SetThink( ThinkFunction( PreBuiltThink ) );
		self.pev.nextthink = g_Engine.time + 0.5f;
		
		g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, SOUND_DEPLOY, 1.0, ATTN_IDLE );

		//hardcoding whether entities are healable or not by classname is dumb af
		g_EntityFuncs.DispatchKeyValue( self.edict(), "classname", "monster_sentry" );
	}

	int Classify()
	{
		// player ally override
		if( self.IsPlayerAlly() )
			return CLASS_PLAYER_ALLY;
		
		// allow custom monster classifications
		if( self.m_fOverrideClass )
			return self.m_iClassSelection;
		
		// default
		return CLASS_MACHINE;
	}

	void PreBuiltThink()
	{
		if( m_flBuildEndTime < g_Engine.time )
		{
			m_blIsBuilt = true;
			SetEnabledState();
		}
		
		self.pev.nextthink = g_Engine.time + 0.1f;
	}       

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		PlayAnimationAtIndex( DIE, true, 1.0f );
		TurretKilled( pevAttacker, iGib );
	}

	void Shoot( Vector& in vecOrigin, Vector& in vecToEnemy, Vector& in vecEnemyVelocity )
	{
		Vector vecDirToEnemy = vecToEnemy.Normalize();
		//Use BULLET_PLAYER_CUSTOMDAMAGE because other bullet types have DMG_ALWAYSGIB for some reason
		self.FireBullets( 1, vecOrigin, vecDirToEnemy, VECTOR_CONE_3DEGREES, GetXYRange(), BULLET_PLAYER_CUSTOMDAMAGE, 1, SENTRY_DMG, self.pev );
		
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, SOUND_FIRE4, VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );
		
		self.pev.effects |= EF_MUZZLEFLASH;

		//TODO: Smoke/sprites
		//int theRandomSmoke = RANDOM_LONG(0, 3);
		//if(theRandomSmoke == 0)
		//{
		//    AvHSUPlayParticleEvent(kpsSmokePuffs, this->edict(), vecOrigin);
		//}

		//GetGameRules()->TriggerAlert((AvHTeamNumber)this->pev->team, ALERT_SENTRY_FIRING, this->entindex());
	}

	int MoveTurret()
	{
		return BaseMoveTurret();
	}        

	float GetPointsForDamage( float flDamage )
	{
		//return ( flDamage/self.pev.max_health ) * ( 3 * ( self.pev.max_health/sk_marinesentry_health.value ) );
		return ( flDamage/self.pev.max_health ) * ( 4 );
	}    

	bool GetIsOrganic()
	{
		return false;
	}

	bool IsMachine()
	{
		return true;
	}

	float GetRateOfFire()
	{
		float flVariance = Math.RandomFloat( 0, 0.2 );
		//float flBaseROF = 0.7f;
		float flBaseROF = 0.1f;
		return flBaseROF + flVariance;
	}     

	int	GetXYRange()
	{
		return 1200;
	}

	string GetKilledSound()
	{
		switch( Math.RandomLong( 0, 2 ) )
		{
			case 0:
				return SOUND_DEATH1;
			case 1:
				return SOUND_DEATH2;
			case 2:
				return SOUND_DEATH3;
		}
		return SOUND_DEATH1;
	}

	string GetPingSound()
	{
		return SOUND_PING;
	}        

	int GetSetEnabledAnimation()
	{
		return 3;
	}     

	bool GetRequiresLOS()
	{
		return true;
	}    

	//AAAAAAAAAAAAAAAAAAAAAAAAAAA THIS IS SO DUMB WHY DOESN'T AS EXPOSE STUDIO MODEL FUNCS AHHHHHHHHHHHHHHHHHHHHH
	float GetTimeForAnimation( int iIndex ) 
	{
		switch( iIndex )
		{
			case 0:
				return (2.0f);
			case 1:
				return (17.0f/20.0f);
			case 2:
				return (17.0f/10.0f);
			case 3:
				return (9.0f/20.0f);
			case 4:
				return (9.0f/10.0f);
			case 5:
				return (7.0f/5.0f);
		}
		return 0.0f;
	}               
}
void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "NS_MARINE_SENTRY::CMarineSentry", "monster_marinesentry" );
}    
}