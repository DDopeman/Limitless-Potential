/* 
* The original Half-Life version of the gloun gun
*/

const int EGON_PRIMARY_VOLUME = 450;

const string EGON_BEAM_SPRITE = "sprites/xbeam1.spr";
const string EGON_FLARE_SPRITE = "sprites/xspark1.spr";
const string EGON_SOUND_OFF = "weapons/egon_off1.wav";
const string EGON_SOUND_RUN = "weapons/egon_run3.wav";
const string EGON_SOUND_STARTUP = "weapons/egon_windup2.wav";

const float EGON_SWITCH_NARROW_TIME = 0.75; // Time it takes to switch fire modes
const float EGON_SWITCH_WIDE_TIME = 1.5;

const int EGON_DEFAULT_GIVE = 20;
const int EGON_MAX_CARRY = 100;
const int EGON_MAX_CLIP = WEAPON_NOCLIP;
const int EGON_WEIGHT = 20;

const float EGON_PULSE_INTERVAL = 0.1;
const float EGON_DISCHARGE_INTERVAL = 0.1;

enum egon_e
{
	EGON_IDLE1 = 0,
	EGON_FIDGET1,
	EGON_ALTFIREON,
	EGON_ALTFIRECYCLE,
	EGON_ALTFIREOFF,
	EGON_FIRE1,
	EGON_FIRE2,
	EGON_FIRE3,
	EGON_FIRE4,
	EGON_DRAW,
	EGON_HOLSTER
};

enum EGON_FIREMODE
{
	FIRE_NARROW = 0,
	FIRE_WIDE
};

enum EGON_FIRESTATE
{
	FIRE_OFF = 0,
	FIRE_CHARGE
};

class weapon_hlegon : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	float m_flAmmoUseTime; // since we use < 1 point of ammo per update, we subtract ammo on a timer.
	CBeam@ m_pBeam;
	CBeam@ m_pNoise;
	CSprite@ m_pSprite;
	
	float m_shootTime;
	EGON_FIREMODE m_fireMode;
	float m_shakeTime;
	bool m_deployed;
	
	int m_fireState;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_egon.mdl" );
		
		self.m_iDefaultAmmo = EGON_DEFAULT_GIVE;

		self.FallInit(); // get ready to fall down.
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( "models/hlclassic/w_egon.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/v_egon.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_egon.mdl" );
		
		g_SoundSystem.PrecacheSound( EGON_SOUND_OFF );
		g_SoundSystem.PrecacheSound( EGON_SOUND_RUN );
		g_SoundSystem.PrecacheSound( EGON_SOUND_STARTUP );
		
		g_Game.PrecacheModel( EGON_BEAM_SPRITE );
		g_Game.PrecacheModel( EGON_FLARE_SPRITE );
		
		g_SoundSystem.PrecacheSound( "weapons/hlclassic/357_cock1.wav" );
		
		g_Game.PrecacheGeneric( "sprites/hl_weapons/weapon_hlegon.txt" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				message.WriteLong( self.m_iId );
			message.End();
			
			@m_pPlayer = pPlayer;
			
			return true;
		}
		
		return false;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/hlclassic/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= EGON_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= EGON_MAX_CLIP;
		info.iSlot 		= 3;
		info.iPosition 	= 7;
		info.iFlags 	= 0;
		info.iWeight 	= EGON_WEIGHT;
		
		return true;
	}
	
	bool Deploy()
	{
		m_deployed = false;
		m_fireState = FIRE_OFF;
		return self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_egon.mdl" ), self.GetP_Model( "models/hlclassic/p_egon.mdl" ), EGON_DRAW, "egon" );
	}
	
	void Holster( int skiplocal /* = 0 */ )
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.5;
		self.SendWeaponAnim( EGON_HOLSTER );
		
		EndAttack();
	}
	
	void PrimaryAttack()
	{
		m_fireMode = FIRE_WIDE;
		Attack();
	}
	
	void SecondaryAttack()
	{
		m_fireMode = FIRE_NARROW;
		Attack();
	}
	
	void Attack()
	{
		// don't fire underwater
		if ( m_pPlayer.pev.waterlevel == 3 )
		{
			if ( m_fireState != FIRE_OFF || m_pBeam !is null )
			{
				EndAttack();
			}
			else
			{
				PlayEmptySound();
			}
			return;
		}
		
		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecAiming = g_Engine.v_forward;
		Vector vecSrc = m_pPlayer.GetGunPosition();
		
		switch( m_fireState )
		{
			case FIRE_OFF:
			{
				if ( !HasAmmo() )
				{
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.25;
					PlayEmptySound();
					return;
				}
				
				m_flAmmoUseTime = g_Engine.time;// start using ammo ASAP.
				
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, EGON_SOUND_STARTUP, 1.0, ATTN_NORM, 0, 125 );
				
				m_shakeTime = 0;
				
				m_pPlayer.m_iWeaponVolume = EGON_PRIMARY_VOLUME;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.1;
				self.pev.fuser1 = WeaponTimeBase() + 2;
				
				self.pev.dmgtime = g_Engine.time + GetPulseInterval();
				m_fireState = FIRE_CHARGE;
				break;
			}
			case FIRE_CHARGE:
			{
				Fire( vecSrc, vecAiming );
				m_pPlayer.m_iWeaponVolume = EGON_PRIMARY_VOLUME;
			
				if ( self.pev.fuser1 <= WeaponTimeBase() )
				{
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, EGON_SOUND_RUN, 1.0, ATTN_NORM, 0, 125 );
					self.pev.fuser1 = 1000;
				}

				if ( !HasAmmo() )
				{
					EndAttack();
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 1.0;
				}
				break;
			}
		}
	}
	
	void Fire( const Vector& in vecOrigSrc, const Vector& in vecDir )
	{
		Vector vecDest = vecOrigSrc + vecDir * 2048;
		edict_t@ pentIgnore;
		TraceResult tr;
		
		@pentIgnore = @m_pPlayer.edict();
		Vector tmpSrc = vecOrigSrc + g_Engine.v_up * -8 + g_Engine.v_right * 3;
		
		g_Utility.TraceLine( vecOrigSrc, vecDest, dont_ignore_monsters, pentIgnore, tr );

		if ( tr.fAllSolid > 0 )
			return;
		
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

		if ( pEntity is null )
			return;
		
		if ( m_pSprite !is null && pEntity.pev.takedamage > 0 )
		{
			m_pSprite.pev.effects &= ~EF_NODRAW;
		}
		else if ( m_pSprite !is null )
		{
			m_pSprite.pev.effects |= EF_NODRAW;
		}
		
		float timedist;

		switch( m_fireMode )
		{
			case FIRE_NARROW:
			{
				if ( self.pev.dmgtime < g_Engine.time )
				{
					// Narrow mode only does damage to the entity it hits
					g_WeaponFuncs.ClearMultiDamage();
					if ( pEntity.pev.takedamage > 0 )
					{
						pEntity.TraceAttack( m_pPlayer.pev, 45, vecDir, tr, DMG_ENERGYBEAM );
					}
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev);
					
					// multiplayer uses 1 ammo every 1/10th second
					if ( g_Engine.time >= m_flAmmoUseTime )
					{
						UseAmmo( 1 );
						m_flAmmoUseTime = g_Engine.time + 0.1;
					}
					
					self.pev.dmgtime = g_Engine.time + GetPulseInterval();
				}
				
				timedist = ( self.pev.dmgtime - g_Engine.time ) / GetPulseInterval();
				break;
			}
			case FIRE_WIDE:
			{
				if ( self.pev.dmgtime < g_Engine.time )
				{
					// wide mode does damage to the ent, and radius damage
					g_WeaponFuncs.ClearMultiDamage();
					if ( pEntity.pev.takedamage > 0 )
					{
						pEntity.TraceAttack( m_pPlayer.pev, 15, vecDir, tr, ( DMG_ENERGYBEAM | DMG_ALWAYSGIB ) );
					}
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
					
					// radius damage a little more potent in multiplayer.
					g_WeaponFuncs.RadiusDamage( tr.vecEndPos, self.pev, m_pPlayer.pev, 15/4, 128, CLASS_NONE, ( DMG_ENERGYBEAM | DMG_BLAST | DMG_ALWAYSGIB ) );
					
					if ( !m_pPlayer.IsAlive() )
						return;

					// multiplayer uses 5 ammo/second
					if ( g_Engine.time >= m_flAmmoUseTime )
					{
						UseAmmo( 1 );
						m_flAmmoUseTime = g_Engine.time + 0.2;
					}
					
					self.pev.dmgtime = g_Engine.time + GetDischargeInterval();
					if ( m_shakeTime < g_Engine.time )
					{
						g_PlayerFuncs.ScreenShake( tr.vecEndPos, 5.0, 150.0, 0.75, 250.0 );
						m_shakeTime = g_Engine.time + 1.5;
					}
				}
				
				timedist = ( pev.dmgtime - g_Engine.time ) / GetDischargeInterval();
				break;
			}
		}

		if ( timedist < 0 )
			timedist = 0;
		else if ( timedist > 1 )
			timedist = 1;
		timedist = 1 - timedist;
		
		UpdateEffect( tmpSrc, tr.vecEndPos, timedist );
	}
	
	void UpdateEffect( const Vector& in startPoint, const Vector& in endPoint, float timeBlend )
	{
		if ( m_pBeam is null )
		{
			CreateEffect();
		}
		
		m_pBeam.SetStartPos( endPoint );
		m_pBeam.SetBrightness( 255 - ( int( timeBlend ) * 180 ) );
		m_pBeam.SetWidth( 40 - ( int( timeBlend ) * 20 ) );
		
		if ( m_fireMode == FIRE_WIDE )
			m_pBeam.SetColor( 30 + ( 25 * int( timeBlend ) ), 30 + ( 30 * int( timeBlend ) ), 64 + 80 * int( abs( sin( g_Engine.time * 10 ) ) ) );
		else
			m_pBeam.SetColor( 60 + ( 25 * int( timeBlend ) ), 120 + ( 30 * int( timeBlend ) ), 64 + 80 * int( abs( sin( g_Engine.time * 10 ) ) ) );
		
		g_EntityFuncs.SetOrigin( m_pSprite, endPoint );
		m_pSprite.pev.frame += 8 * g_Engine.frametime;
		if ( m_pSprite.pev.frame > m_pSprite.Frames() )
			m_pSprite.pev.frame = 0;
		
		m_pNoise.SetStartPos( endPoint );
	}

	void CreateEffect()
	{
		DestroyEffect();
		
		@m_pBeam = @g_EntityFuncs.CreateBeam( EGON_BEAM_SPRITE, 40 );
		m_pBeam.PointEntInit( self.pev.origin, m_pPlayer.entindex() );
		m_pBeam.SetFlags( BEAM_FSINE );
		m_pBeam.SetEndAttachment( 1 );
		m_pBeam.pev.spawnflags |= SF_BEAM_TEMPORARY; // Flag these to be destroyed on save/restore or level transition
		//m_pBeam.pev.flags |= FL_SKIPLOCALHOST;
		@m_pBeam.pev.owner = @m_pPlayer.edict();
		
		@m_pNoise = @g_EntityFuncs.CreateBeam( EGON_BEAM_SPRITE, 55 );
		m_pNoise.PointEntInit( self.pev.origin, m_pPlayer.entindex() );
		m_pNoise.SetScrollRate( 25 );
		m_pNoise.SetBrightness( 100 );
		m_pNoise.SetEndAttachment( 1 );
		m_pNoise.pev.spawnflags |= SF_BEAM_TEMPORARY;
		//m_pNoise.pev.flags |= FL_SKIPLOCALHOST;
		@m_pNoise.pev.owner = @m_pPlayer.edict();
		
		@m_pSprite = @g_EntityFuncs.CreateSprite( EGON_FLARE_SPRITE, self.pev.origin, false );
		m_pSprite.pev.scale = 1.0;
		m_pSprite.SetTransparency( kRenderGlow, 255, 255, 255, 255, kRenderFxNoDissipation );
		m_pSprite.pev.spawnflags |= 0x8000; // SF_SPRITE_TEMPORARY
		//m_pSprite.pev.flags |= FL_SKIPLOCALHOST;
		@m_pSprite.pev.owner = @m_pPlayer.edict();

		if ( m_fireMode == FIRE_WIDE )
		{
			m_pBeam.SetScrollRate( 50 );
			m_pBeam.SetNoise( 20 );
			m_pNoise.SetColor( 50, 50, 255 );
			m_pNoise.SetNoise( 8 );
		}
		else
		{
			m_pBeam.SetScrollRate( 110 );
			m_pBeam.SetNoise( 5 );
			m_pNoise.SetColor( 80, 120, 255 );
			m_pNoise.SetNoise( 2 );
		}
	}
	
	void DestroyEffect()
	{
		if ( m_pBeam !is null )
		{
			g_EntityFuncs.Remove( m_pBeam );
			@m_pBeam = @null;
		}
		if ( m_pNoise !is null )
		{
			g_EntityFuncs.Remove( m_pNoise );
			@m_pNoise = @null;
		}
		if ( m_pSprite !is null )
		{
			if ( m_fireMode == FIRE_WIDE )
				m_pSprite.Expand( 10, 500 );
			else
				g_EntityFuncs.Remove( m_pSprite );
			@m_pSprite = @null;
		}
	}
	
	void EndAttack()
	{
		bool bMakeNoise = false;
		
		if ( m_fireState != FIRE_OFF ) //Checking the button just in case!
			bMakeNoise = true;
		
		if ( bMakeNoise )
		{
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, EGON_SOUND_RUN );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, EGON_SOUND_OFF, 1.0, ATTN_NORM );
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 2.0;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5;
		
		m_fireState = FIRE_OFF;
		
		DestroyEffect();
	}
	
	bool HasAmmo()
	{
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return false;

		return true;
	}

	void UseAmmo( int count )
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if ( iAmmo >= count )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo - count );
		else
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 0 );
	}
	
	float GetPulseInterval()
	{
		return EGON_PULSE_INTERVAL;
	}

	float GetDischargeInterval()
	{
		return EGON_DISCHARGE_INTERVAL;
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		
		if ( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
		if ( m_fireState != FIRE_OFF )
			EndAttack();
		
		int iAnim;
		
		float flRand = Math.RandomFloat( 0, 1 );
		
		if ( flRand <= 0.5 )
		{
			iAnim = EGON_IDLE1;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
		}
		else 
		{
			iAnim = EGON_FIDGET1;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 3;
		}
		
		self.SendWeaponAnim( iAnim );
		m_deployed = true;
	}
}

string GetHLEgonName()
{
	return "weapon_hlegon";
}

void RegisterHLEgon()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hlegon", GetHLEgonName() );
	g_ItemRegistry.RegisterWeapon( GetHLEgonName(), "hl_weapons", "uranium" );
}