enum PILA_e
{
	PILA_IDLE = 0,
	PILA_DRAW,
	PILA_DRAW_EMPTY,
	PILA_ATTACK_S,
	PILA_ATTACK_L,
	PILA_ATTACK_E,
	PILA_RELOAD,
	PILA_SLASH1,
	PILA_SLASH2,
	PILA_SLASH3,
	PILA_SLASH4,
	PILA_EMPTY
};

class weapon_pila : ScriptBasePlayerWeaponEntity
{
	bool m_IsPullingBack = false;
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/metalarena/weapons/w_pila.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/metalarena/weapons/v_pila.mdl" );
		g_Game.PrecacheModel( "models/metalarena/weapons/w_pila.mdl" );
		g_Game.PrecacheModel( "models/metalarena/weapons/p_pila.mdl" );

		g_SoundSystem.PrecacheSound( "weapons/chainsaw_draw.wav" );
		g_SoundSystem.PrecacheSound( "weapons/chainsaw_hit1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/chainsaw_idle.wav" );
		g_SoundSystem.PrecacheSound( "weapons/chainsaw_slash1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		return true;
	}
	
	CBasePlayer@ getPlayer()
	{
		CBaseEntity@ e_plr = self.m_hPlayer;
		return cast<CBasePlayer@>(e_plr);
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/metalarena/weapons/v_pila.mdl" ), self.GetP_Model( "models/metalarena/weapons/p_pila.mdl" ), PILA_DRAW, "wrench" );

			getPlayer().m_szAnimExtension = "crowbar";

			float deployTime = 0;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void PrimaryAttack()
	{
		if( !m_IsPullingBack )
		{
			// We don't want the player to break/stop the animation or sequence.
			m_IsPullingBack = true;
			
			// We are pulling back our spear
			switch ( g_PlayerFuncs.SharedRandomLong( getPlayer().random_seed, 0, 1 ) )
			{
				case 0: self.SendWeaponAnim( PILA_SLASH1, 0, 0 ); break;
				case 1: self.SendWeaponAnim( PILA_SLASH2, 0, 0 ); break;
			}

			getPlayer().m_szAnimExtension = "wrench";
			
			// Lets wait for the 'heavy smack'
			SetThink( ThinkFunction( this.DoHeavyAttack ) );
			self.pev.nextthink = g_Engine.time + 0.0;

			g_SoundSystem.EmitSound( getPlayer().edict(), CHAN_WEAPON, "weapons/chainsaw_slash1.wav", 1, ATTN_NORM );
			m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + g_Engine.v_forward * 400;
		}
	}
	
	void DoHeavyAttack()
	{
		HeavySmack();
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}
	
	bool HeavySmack()
	{
		TraceResult tr;
		
		bool fDidHit = false;

		Math.MakeVectors( getPlayer().pev.v_angle );
		Vector vecSrc	= getPlayer().GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 76;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, getPlayer().edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, getPlayer().edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() == true )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, getPlayer().edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + 0.9;
			// play wiff or swish sound
			// player "shoot" animation
			getPlayer().SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			// hit
			fDidHit = true;
			
			// The entity we hit
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			pEntity.pev.velocity = pEntity.pev.velocity - ( self.pev.origin - pEntity.pev.origin ).Normalize() * m_pPlayer.pev.velocity;

			// player "shoot" animation
			getPlayer().SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			float flDamage = 85;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( getPlayer().pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( getPlayer().pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( getPlayer().pev, getPlayer().pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.9;

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + 0.9;
				
				/*
					TODO: Is entity electrecuted?
						If true
							Play 'Electrecuted' animation and sound
							Player is already getting hurt from the trigger
						If false
							Stabby stab
				*/

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() == true )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					g_SoundSystem.EmitSound( getPlayer().edict(), CHAN_WEAPON, "weapons/chainsaw_hit1.wav", 1, ATTN_NORM );
					getPlayer().m_iWeaponVolume = 128; 
					
					if( pEntity.IsAlive() == false )
					{
						SetThink( ThinkFunction( this.NoPulling ) );
						self.pev.nextthink = g_Engine.time + 0.9;
						return true;
					}
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CUSTOMDAMAGE );
				
				self.m_flNextPrimaryAttack = g_Engine.time + 0.9;
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				g_SoundSystem.EmitSoundDyn( getPlayer().edict(), CHAN_WEAPON, "weapons/chainsaw_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			}

			getPlayer().m_iWeaponVolume = int( flVol * 512 ); 
		}
		
		// Lets wait until we can attack again
		SetThink( ThinkFunction( this.NoPulling ) );
		self.pev.nextthink = g_Engine.time + 0.9;
		
		return fDidHit;
	}

	void NoPulling()
	{
		// We are no longer pulling back
		m_IsPullingBack = false;
	}

}

string GetWeaponName_PILA()
{
	return "weapon_pila";
}

void RegisterWeapon_PILA()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_pila", GetWeaponName_PILA() );
	g_ItemRegistry.RegisterWeapon( GetWeaponName_PILA(), "wpn" );
}
