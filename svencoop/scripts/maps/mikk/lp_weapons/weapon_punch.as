/**
*	@file
*
*	The original Half-Life version of the crowbar
*   modified to include a variation of Sven Co-op's electric crowbar attack.
*/

enum punch_e
{
	PUNCH_IDLE = 0,
	PUNCH_DRAW,
	PUNCH_HOLSTER,
	PUNCH_ATTACK1HIT,
	PUNCH_ATTACK1MISS,
	PUNCH_ATTACK2MISS,
	PUNCH_ATTACK2HIT,
	PUNCH_ATTACK3MISS,
	PUNCH_ATTACK3HIT
};

/**
*	Amount of battery power to take every time a player gets hit.
*/
const int ELECTRIC_PUNCH_BATTERY_USAGE_PLAYER = 1;

/**
*	Amount of battery power to take every time something gets hit. Also the minimum amount of power needed to activate and use electric attacks.
*/
const int ELECTRIC_PUNCH_BATTERY_USAGE = 1;

const string g_VeeMdl = "models/hlclassic/v_punch.mdl";

enum PunchSound
{
	PUNCHSOUND_HIT1 = 0,
	PUNCHSOUND_HIT2,
	PUNCHSOUND_HITBOD1,
	PUNCHSOUND_HITBOD2,
	PUNCHSOUND_HITBOD3,
	PUNCHSOUND_MISS1
};

/**
*	Gets the sound for the given sound event and electric state.
*/
string GetPunchSound( const PunchSound sound, const bool bIsElectric )
{
	switch( sound )
	{
	case PUNCHSOUND_HIT1:			return bIsElectric ? "hlclassic/weapons/punch/cbar_hit1.wav" : "hlclassic/weapons/punch/cbar_hit1.wav";
	case PUNCHSOUND_HIT2:			return bIsElectric ? "hlclassic/weapons/punch/cbar_hit2.wav" : "hlclassic/weapons/punch/cbar_hit2.wav";
	case PUNCHSOUND_HITBOD1:		return bIsElectric ? "hlclassic/weapons/punch/cbe_hitbod1.wav" : "hlclassic/weapons/punch/cbe_hitbod1.wav";
	case PUNCHSOUND_HITBOD2:		return bIsElectric ? "hlclassic/weapons/punch/cbe_hitbod2.wav" : "hlclassic/weapons/punch/cbe_hitbod2.wav";
	case PUNCHSOUND_HITBOD3:		return bIsElectric ? "hlclassic/weapons/punch/cbe_hitbod3.wav" : "hlclassic/weapons/punch/cbe_hitbod3.wav";
	case PUNCHSOUND_MISS1:
		{
			if( !bIsElectric )
				return "hlclassic/weapons/punch/cbar_miss1.wav";
				
			if( Math.RandomLong( 0, 1 ) != 0 )
			{
				return "hlclassic/weapons/punch/cbe/cbe_miss1.wav";
			}
			else
			{
				return "hlclassic/weapons/punch/cbe/cbe_miss2.wav";
			}
		}
	}
	
	//TODO: default sound? - Solokiller
	return "";
}

class weapon_punch : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	int m_iSwing;
	TraceResult m_trHit;
	
	bool m_bIsElectric = false;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/hlclassic/w_crowbar.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/hlclassic/v_punch.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_crowbar.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_crowbar.mdl" );

		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbar_hit1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbar_hit2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbar_miss1.wav" );

		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_idle1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbar_hit1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbar_hit2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_miss1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_miss2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_off.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/punch/cbe_on.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 6;
		info.iFlags  		= 0;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		return true;
	}

	bool Deploy()
	{
		SetElectricState( false, true );
		
		return self.DefaultDeploy( self.GetV_Model( g_VeeMdl ), self.GetP_Model( string_t() ), PUNCH_DRAW, "crowbar" );
		
	}
	
	CBasePlayerItem@ DropItem() // Doesn't let the player drop the weapon
	{
		return null;
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// cancel any reload in progress.

		//Does not use the local WeaponTimeBase() because m_flNextAttack is not a CBasePlayerWeapon member. - Solokiller
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = string_t();
		
		SetElectricState( false, true );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = WeaponTimeBase() + 0.1;
		}
	}
	
	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.2;
		ToggleElectric();
	}
	
	void ToggleElectric()
	{
		SetElectricState( !m_bIsElectric );
	}
	
	bool OwnerHasEnoughArmor() const
	{
		return m_pPlayer !is null && m_pPlayer.pev.armorvalue >= ELECTRIC_PUNCH_BATTERY_USAGE;
	}
	
	void UseArmor( const int iAmount )
	{
		m_pPlayer.pev.armorvalue -= iAmount;
	}
	
	bool OwnerCanUseElectric() const
	{
		if( m_pPlayer is null )
			return false;
	
		if( ( m_pPlayer.pev.flags & FL_INWATER ) != 0 || !OwnerHasEnoughArmor() )
		{
			return false;
		}
		
		return true;
	}
	
	void SetElectricState( const bool bState, const bool bForce = false )
	{
		const bool bCurrentState = m_bIsElectric;
		
		m_bIsElectric = bState;
		
		if( m_pPlayer is null )
			return;
			
		if( !OwnerCanUseElectric() )
		{
			m_bIsElectric = false;
		}
		
		if( !bForce && m_bIsElectric == bCurrentState )
			return;
			
		const int iBit = ( bState ? 1 : 0 ) << 6;
	
		NetworkMessage msg( MSG_ALL, NetworkMessages::CbElec );
			msg.WriteByte( iBit | m_pPlayer.entindex() );
		msg.End();
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}


	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
				case 0:
					self.SendWeaponAnim( PUNCH_ATTACK1MISS ); break;
				case 1:
					self.SendWeaponAnim( PUNCH_ATTACK2MISS ); break;
				case 2:
					self.SendWeaponAnim( PUNCH_ATTACK3MISS ); break;
				}
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, GetPunchSound( PUNCHSOUND_MISS1, m_bIsElectric ), 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
			case 0:
				self.SendWeaponAnim( PUNCH_ATTACK1HIT ); break;
			case 1:
				self.SendWeaponAnim( PUNCH_ATTACK2HIT ); break;
			case 2:
				self.SendWeaponAnim( PUNCH_ATTACK3HIT ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			float flDamage = 6;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End
			
			//Called here so external armor drainage is caught on time. - Solokiller
			if( !OwnerHasEnoughArmor() )
				SetElectricState( false );
			
			if( m_bIsElectric )
				flDamage *= 3.5;

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 1 < WeaponTimeBase() )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				const float flMultiplier = m_bIsElectric ? 1.0f : 0.5f;
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * flMultiplier, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 0.6;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.49; //0.25

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, GetPunchSound( PUNCHSOUND_HITBOD1, m_bIsElectric ), 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, GetPunchSound( PUNCHSOUND_HITBOD2, m_bIsElectric ), 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, GetPunchSound( PUNCHSOUND_HITBOD3, m_bIsElectric ), 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					
					//Hitting players uses a different amount - Solokiller
					if( m_bIsElectric )
						UseArmor( pEntity.IsPlayer() ? ELECTRIC_PUNCH_BATTERY_USAGE_PLAYER : ELECTRIC_PUNCH_BATTERY_USAGE );
					
					if( !OwnerHasEnoughArmor() )
						SetElectricState( false );
					
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.49; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, GetPunchSound( PUNCHSOUND_HIT1, m_bIsElectric ), fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, GetPunchSound( PUNCHSOUND_HIT2, m_bIsElectric ), fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				}
			}

			// delay the decal a bit
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
	
	void ItemPostFrame()
	{
		if( !OwnerCanUseElectric() )
			SetElectricState( false, true );
			
		BaseClass.ItemPostFrame();
	}
}

string GetPunchName()
{
	return "weapon_punch";
}

void RegisterPunch()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_punch", GetPunchName() );
	g_ItemRegistry.RegisterWeapon( GetPunchName(), "custom" );
}
