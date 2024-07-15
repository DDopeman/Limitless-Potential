#include "vectorUtils"
/* Natural Selection Base Weapon Script
By Meryilla

Models, Sounds, and Sprites by Unknown Worlds

Additional Credit to the below for providing guidance in creating these scripts:

https://anggaranothing.gitlab.io/as/svencoop/# Angelscript for SC Docs
INS2 Weapon Scripts for SC - by Kerncore
Natural Selection Source Code - by Unknown Worlds
*/

namespace NSBASE
{

const string szSoundEmpty = "hl/weapons/357_cock1.wav";

const float flDeployIdleInterval = 10.0;

mixin class WeaponBase
{
	void CommonPrecache()
	{
		g_SoundSystem.PrecacheSound( szSoundEmpty );
		g_Game.PrecacheGeneric( "sound/" + szSoundEmpty );
	}	
	
	bool Deploy( string vmodel, string pmodel, int iAnim, string pAnim, int iBodygroup, float deployTime ) // deploys the weapon
	{
		self.DefaultDeploy( self.GetV_Model( vmodel ), self.GetP_Model( pmodel ), iAnim, pAnim, 0, iBodygroup );
		//self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
		self.m_flTimeWeaponIdle = g_Engine.time + deployTime;
		return true;
	}	

	void Reload( int iAmmo, int iAnim, float iTimer, int iBodygroup ) // things commonly executed in reloads
	{
		self.m_fInReload = true;
		self.DefaultReload( iAmmo, iAnim, iTimer, iBodygroup );
		self.m_flTimeWeaponIdle = g_Engine.time + iTimer;
	}
	
	bool CommonPlayEmptySound( const string emptySound = szSoundEmpty ) // plays a empty sound when the player has no ammo left in the magazine
	{
		if( self.m_bPlayEmptySound )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STREAM, emptySound, 0.9, 1.5, 0, PITCH_NORM );
		}

		return false;
	}

	void ShootWeapon( Vector vecSrc, Vector vecAiming, const uint numShots, Vector& in CONE, float maxDist, int Damage, const bool shouldTrace = false, const int DmgType = DMG_GENERIC )
	{
		
		TraceResult tr;
		float x, y;

		for( uint uiPellet = 0; uiPellet < numShots; ++uiPellet )
		{
			g_Utility.GetCircularGaussianSpread( x, y );

			Vector vecDir = vecAiming + x * CONE.x * g_Engine.v_right + y * CONE.y * g_Engine.v_up;
			Vector vecEnd = vecSrc + vecDir * maxDist;

			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

			//if( shouldTrace )
			//{
			//	if( Math.RandomLong( 0, 10 ) < 4 )
			//	{
			//		Vector vecTracerOr, vecTracerAn;
			//		PlayTracer( (WeaponADSMode == IRON_OUT) ? vecTracerOr : vecSrc, vecTracerAn, tr );
			//	}
			//}

			if( tr.flFraction < 1.0 )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					if( DmgType != DMG_GENERIC )
					{
						if( pHit !is null )
						{
							g_WeaponFuncs.ClearMultiDamage();
							pHit.TraceAttack( m_pPlayer.pev, (DmgType & DMG_BLAST != 0) ? (Damage * 0.2) : (Damage * 0.3636), vecEnd, tr, DmgType );
							g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
						}
					}

					g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CUSTOMDAMAGE );

					//if( tr.fInWater == 0.0 )
					//	water_bullet_effects( vecSrc, tr.vecEndPos );
					
					if( pHit is null || pHit.IsBSPModel() == true )
					{
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CUSTOMDAMAGE );
						//g_Utility.Sparks( tr.vecEndPos );
					}
				}
			}
		}
	}
	
	// Precise shell casting
	void GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale )
	{
		Vector vecForward, vecRight, vecUp;

		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );

		const float fR =  Math.RandomFloat( 50, 70 );
		const float fU =  Math.RandomFloat( 100, 150 );

		for( int i = 0; i < 3; ++i )
		{
			ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
			ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
		}
	}	
	
	void ShellEject( CBasePlayer@ pPlayer, int& in mShell, Vector& in Pos, TE_BOUNCE shelltype = TE_BOUNCE_SHELL ) // eject spent shell casing
	{
		Vector vecShellVelocity, vecShellOrigin;
		GetDefaultShellInfo( pPlayer, vecShellVelocity, vecShellOrigin, Pos.x, Pos.y, Pos.z ); //23 4.75 -5.15
		vecShellVelocity.y *= 1;
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, pPlayer.pev.angles.y, mShell, shelltype );
	}

	void DestroyThink() // destroys the item
	{
		SetThink( null );
		self.DestroyItem();
	}	
}
mixin class MeleeWeaponBase
{
	protected TraceResult m_trHit;
	protected int m_iSwing = 0;

	bool Swing( float flDamage, string szSwingSound, string szHitFleshSound, string szHitWallSound, int& in iAnimAtk1, int& in iAnimAtk2, int& in iBodygroup, 
		float flHitDist = 48.0f, float flMissNextPriAtk = 0.35f, float flHitNextPriAtk = 0.4f, float flNextSecAtk = 0.5f )
	{
		TraceResult tr;
		bool fDidHit = false;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * flHitDist;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( pHit is null || pHit.IsBSPModel() == true )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if( tr.flFraction >= 1.0 ) //Missed
		{
			switch( (m_iSwing++) % 2 )
			{
				case 0:
				{
					self.SendWeaponAnim( iAnimAtk1, 0, iBodygroup );
					break;
				}

				case 1:
				{
					self.SendWeaponAnim( iAnimAtk2, 0, iBodygroup );
					break;
				}
			}

			self.m_flNextPrimaryAttack = g_Engine.time + flMissNextPriAtk;
			self.m_flNextSecondaryAttack = g_Engine.time + flNextSecAtk;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

			// play wiff or swish sound
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, szSwingSound, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); // player "shoot" animation
		}
		else
		{
			// hit
			fDidHit = true;
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( (m_iSwing++) % 2 )
			{
				case 0:
				{
					self.SendWeaponAnim( iAnimAtk1, 0, iBodygroup );
					break;
				}

				case 1:
				{
					self.SendWeaponAnim( iAnimAtk2, 0, iBodygroup );
					break;
				}
			}

			self.m_flNextPrimaryAttack = g_Engine.time + flHitNextPriAtk;
			self.m_flNextSecondaryAttack = g_Engine.time + flNextSecAtk;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			// AdamR: Custom damage option
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();

			if( self.m_flNextPrimaryAttack + 0.4f < g_Engine.time )
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB ); // first swing does full damage
			else
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.75, g_Engine.v_forward, tr, DMG_SLASH | DMG_CLUB ); // subsequent swings do 75% (Changed -Sniper)

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() ) // aone: lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + (self.pev.origin - pEntity.pev.origin).Normalize() * 120;
					} // aone: end

					// play thwack or smack sound
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, szHitFleshSound, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
					m_pPlayer.m_iWeaponVolume = 128;

					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				//self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.35; //0.25

				fvolbar = 1;

				// also play melee strike
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, szHitWallSound, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int(flVol * 512);
		}

		return fDidHit;
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}	
}
}