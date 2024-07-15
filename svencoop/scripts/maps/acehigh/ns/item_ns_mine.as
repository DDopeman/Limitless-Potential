/* Natural Selection Deployed Mine Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://anggaranothing.gitlab.io/as/svencoop/# Angelscript for SC Docs
INS2 Weapon Scripts for SC - by Kerncore
Natural Selection Source Code - by Unknown Worlds
*/


namespace NS_DEPLOYED_MINE
{
//Models
const string MODEL_W = "models/ns/w_mine.mdl";

//Sounds
const string SND_DEPLOY = "ns/weapons/mine/mine_deploy.wav";
const string SND_CHARGE = "ns/weapons/mine/mine_charge.wav";
const string SND_ACTIVATE = "ns/weapons/mine/mine_activate.wav";
const string SND_STEP = "ns/weapons/mine/mine_step.wav";

array<string> SOUNDS = {
	SND_DEPLOY,
	SND_CHARGE,
	SND_ACTIVATE,
	SND_STEP,
};

array<string> MineExplodeSounds =
{
	"ns/weapons/explode3.wav",
	"ns/weapons/explode4.wav",
	"ns/weapons/explode5.wav"
};

//Stats
const float MINE_HEALTH = 20;
const float MINE_DMG = 125;

//Think times
const float POWERUP_THINK_TIME = 0.2f;
const float ACTIVE_THINK_TIME = .8f;
const float POWER_UP_TIME = 3.8f;
const float FAIL_TIME = 20.0f;

class CNSMine : ScriptBaseMonsterEntity
{
	private float m_flTimePlaced;
	private float m_flLastTimeTouched;
	private Vector m_vecDir;
	private Vector m_vecOwnerOrigin;
	private Vector m_vecOwnerAngles;
	private bool m_blDetonated = false;
	private bool m_blPoweredUp = false;
	private EHandle m_hOwner;
	private entvars_t@ m_pevPlacer;
	private int m_iSmokeSprite, m_iExplodeSprite, m_iWaterExSprite;

	void Spawn()
	{
		Precache();
		
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_NOT;
		self.pev.targetname = "foobar";
		
		g_EntityFuncs.SetModel( self, MODEL_W );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector( -8, -8, -8 ), Vector( 8, 8, 8 ) );
		

		// Can't emit beep until active
		m_flTimePlaced = g_Engine.time;
		m_flLastTimeTouched = m_flTimePlaced;
		
		SetThink( ThinkFunction( this.PowerupThink ) );
		self.pev.nextthink = g_Engine.time + POWERUP_THINK_TIME;

		// give them hit points
		self.pev.takedamage = DAMAGE_YES;
		self.pev.health = MINE_HEALTH;
		self.pev.dmg = MINE_DMG;
		
		// play deploy sound
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, SND_DEPLOY, .8f, ATTN_NORM );
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, SND_CHARGE, .5f, ATTN_NORM ); // chargeup	
	}
	
	void Precache()
	{
		//Models
		g_Game.PrecacheModel( MODEL_W );
		
		//Sounds
		for( uint i = 0; i < SOUNDS.length(); i++ )
		{
			g_SoundSystem.PrecacheSound( SOUNDS[i] );
			g_Game.PrecacheGeneric( "sound/" + SOUNDS[i] );
		}
		
		for( uint j = 0; j < MineExplodeSounds.length(); j++ )
		{
			g_SoundSystem.PrecacheSound( MineExplodeSounds[j] );
			g_Game.PrecacheGeneric( "sound/" + MineExplodeSounds[j] );
		}
		
		//Sprites
		m_iSmokeSprite = g_Game.PrecacheModel( "sprites/steam1.spr" );
		m_iExplodeSprite = g_Game.PrecacheModel( "sprites/zerogxplode.spr" );
		m_iWaterExSprite = g_Game.PrecacheModel( "sprites/WXplo1.spr" );
	}	
	
	void ActiveThink()
	{
		DetonateIfOwnerInvalid();
		self.pev.nextthink = g_Engine.time + ACTIVE_THINK_TIME;
	}
	
	void DetonateIfOwnerInvalid()
	{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( m_hOwner.GetEntity() );
		
		if( ( pPlayer is null ) )
			Detonate();
	}
	
	void PowerupThink()
	{
		// Find an owner
		if( !m_hOwner )
		{
			m_hOwner = EHandle( g_EntityFuncs.Instance( self.pev.euser1 ) );
		}
		else
		{
			DetonateIfOwnerInvalid();
		}

		if( !m_blPoweredUp )
		{
			if( g_Engine.time > ( m_flTimePlaced + POWER_UP_TIME ) )
			{
				// play enabled sound
				//self.pev.solid = SOLID_BBOX;
				self.pev.solid = SOLID_TRIGGER;
				
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, SND_ACTIVATE, 0.5, ATTN_NORM, 1.0, 75 );
				
				SetTouch( TouchFunction( this.ActiveTouch ) );
				
				SetThink( ThinkFunction( this.ActiveThink ) );
				self.pev.nextthink = g_Engine.time + ACTIVE_THINK_TIME;
					
				m_blPoweredUp = true;
			}
		}

		if( !m_blPoweredUp )
		{
			self.pev.nextthink = g_Engine.time + POWERUP_THINK_TIME;
		}
	}	
	
	void SetPlacer( entvars_t@ pevInPlacer )
	{
		@m_pevPlacer = pevInPlacer;
	}	
	
	void Detonate()
	{
		// Stop charging up
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "common/null.wav", 0.5, ATTN_NORM ); 

		if( !m_blDetonated && m_blPoweredUp )
		{
			TraceResult tr;
			g_Utility.TraceLine( self.pev.origin + m_vecDir * 8, self.pev.origin - m_vecDir * 64, dont_ignore_monsters, self.edict(), tr );
			
			Explode( tr, DMG_BLAST );

			m_blDetonated = true;
		}
	}
	
	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		Detonate();

		BaseClass.Killed( pevAttacker, iGib );
	}

	void Smoke()
	{
		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_WATER )
		{
			g_Utility.Bubbles( self.pev.origin - Vector( 64, 64, 64 ), self.pev.origin + Vector( 64, 64, 64 ), 100 );
		}
		else
		{	
			NetworkMessage smoke_msg( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, self.GetOrigin() );
				smoke_msg.WriteByte( TE_SMOKE );
				smoke_msg.WriteCoord( self.pev.origin.x );
				smoke_msg.WriteCoord( self.pev.origin.y );
				smoke_msg.WriteCoord( self.pev.origin.z );
				smoke_msg.WriteShort( m_iSmokeSprite );
				smoke_msg.WriteByte( uint( ( self.pev.dmg - 50 ) * 0.80 ) ); // scale * 10
				smoke_msg.WriteByte( 12  ); // framerate
			smoke_msg.End();
		}
		g_EntityFuncs.Remove( self );
	}	
	
	void Explode( TraceResult pTrace, int iBitsDamageType)
	{
		float flRndSound;// sound randomizer
		
		self.pev.model = string_t();//invisible
		self.pev.solid = SOLID_NOT;// intangible

		float flDamage = self.pev.dmg;

		self.pev.takedamage = DAMAGE_NO;

		// Pull out of the wall a bit
		if( pTrace.flFraction != 1.0 )
		{
			self.pev.origin = pTrace.vecEndPos + ( pTrace.vecPlaneNormal * ( flDamage - 24 ) * 0.6 );
		}

		int iContents = g_EngineFuncs.PointContents( self.GetOrigin() );
		
		NetworkMessage exp_msg( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, self.GetOrigin() );
			exp_msg.WriteByte( TE_EXPLOSION );		// self makes a dynamic light and the explosion sprites/sound
			exp_msg.WriteCoord( self.pev.origin.x );	// Send to PAS because of the sound
			exp_msg.WriteCoord( self.pev.origin.y );
			exp_msg.WriteCoord( self.pev.origin.z );
			if( iContents != CONTENTS_WATER )
			{
				exp_msg.WriteShort( m_iExplodeSprite );
			}
			else
			{
				exp_msg.WriteShort( m_iWaterExSprite );
			}
			exp_msg.WriteByte( uint( ( flDamage - 50 ) * .60 )  ); // scale * 10
			exp_msg.WriteByte( 15  ); // framerate
			exp_msg.WriteByte( TE_EXPLFLAG_NOSOUND );
		exp_msg.End();

		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, self.pev.origin, NORMAL_EXPLOSION_VOLUME, 3, self );
		
		g_WeaponFuncs.RadiusDamage( self.GetOrigin(), self.pev, m_pevPlacer, flDamage, flDamage * 2, CLASS_NONE, DMG_BLAST );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_AUTO, MineExplodeSounds[ Math.RandomLong( 0, MineExplodeSounds.length() - 1 )], VOL_NORM, 0.4, 0, PITCH_NORM );
		// Play view shake here
		float flShakeAmplitude = 80;
		float flShakeFrequency = 100;
		float flShakeDuration = 1.0f;
		float flShakeRadius = 700;
		g_PlayerFuncs.ScreenShake( self.pev.origin, flShakeAmplitude, flShakeFrequency, flShakeDuration, flShakeRadius );

		if ( Math.RandomFloat( 0 , 1 ) < 0.5 )
		{
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH1 );
		}
		else
		{
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH2 );
		}

		flRndSound = Math.RandomFloat( 0 , 1 );

		switch ( Math.RandomLong( 0, 2 ) )
		{
			case 0:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/debris1.wav", 0.55, ATTN_NORM );	break;
			case 1:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/debris2.wav", 0.55, ATTN_NORM );	break;
			case 2:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/debris3.wav", 0.55, ATTN_NORM );	break;
		}

		self.pev.effects |= EF_NODRAW;
		SetThink( ThinkFunction( this.Smoke ) );
		self.pev.velocity = g_vecZero;
		pev.nextthink = g_Engine.time + 0.3;

		if( iContents != CONTENTS_WATER )
		{
			int iSparkCount = Math.RandomLong( 0,3 );
			for ( int i = 0; i < iSparkCount; i++ )
				g_EntityFuncs.Create( "spark_shower", self.pev.origin, pTrace.vecPlaneNormal, false );
		}
	}

	void ActiveTouch( CBaseEntity@ pOther )
	{
		float flTimeBetweenBeeps = 3.0f;
		
		if( pOther.IsMonster() && ( self.pev.team != pOther.pev.team ) )
		{
			Detonate();
		}
		else
		{
			if( g_Engine.time > m_flLastTimeTouched + flTimeBetweenBeeps )
			{
				// Only players trigger this, not buildings or other mines
				if( pOther.IsPlayer() )
				{
					// Play warning proximity beep
					g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, SND_STEP, 0.5, ATTN_NORM ); // shut off chargeup
					m_flLastTimeTouched = g_Engine.time;
				}
			}
		}
	}
}

void Register()
{
	if( g_CustomEntityFuncs.IsCustomEntity( "monster_ns_mine" ) )
		return;

	g_CustomEntityFuncs.RegisterCustomEntity( "NS_DEPLOYED_MINE::CNSMine", "monster_ns_mine" );
}
}