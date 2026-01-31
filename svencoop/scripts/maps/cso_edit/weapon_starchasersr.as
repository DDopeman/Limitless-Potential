/*
Weapon suggested by KEZÆIV
Counter-Strike: Online Star Chaser SR
Assets: Nexon Studios, Valve Corps
Scripts: Nero0
Advices/Supports: KernCore, Mikk155, TEXHAPb!!!
- Trail Effects reference to AT4 Rocket IgniteThink(): https://github.com/Neyami/CSO-Weapons/blob/main/scripts/cso_edit/weapon_at4.as#L263
- Instant Impact reference to weapon_hlcrossbow.as by Giegue's FireSniperBolt(): https://github.com/JulianR0/TPvP/blob/master/src/map_scripts/hl_weapons/weapon_hlcrossbow.as#L335
*/

namespace cso_starchasersr
{
	const string CSOW_NAME = "weapon_starchasersr";
	const string AMMO_TYPE = "cso_starbullet"; // adjustable

	const int STARCHASERSR_SLOT = 6;
	const int STARCHASERSR_POSITION = 19;
	const int STARCHASERSR_WEIGHT = 30;

	const int CSOW_DEFAULT_GIVE = 60;
	const int CSOW_DEFAULT_AMMO = 30;
	const int CSOW_MAX_CLIP = 15;
	const int CSOW_MAX_AMMO = 600;
	const int CSOW_TRACERFREQ = 2;
	const float CSOW_DAMAGE = 150.0;
	const float CSOW_RADIUS = 200.0;
	const float CSOW_TIME_DELAY1 = 1.0;
	const float CSOW_TIME_DELAY2 = 1.0;
	const float CSOW_TIME_DRAW = 1.3;
	const float CSOW_TIME_IDLE = 60.0;
	const float CSOW_TIME_RELOAD = 3.5;
	const float CSOW_SPREAD_JUMPING = 0.185;
	const float CSOW_SPREAD_RUNNING = 0.025;
	const float CSOW_SPREAD_WALKING = 0.01;
	const float CSOW_SPREAD_STANDING = 0.001;
	const float CSOW_SPREAD_DUCKING = 0.0;
	const float CSOW_RECOIL_X = 2.0;
	const float CSOW_RECOIL_Y = 2.25;
	const Vector CSOW_SHELL_ORIGIN = Vector(20.0, 12.0, -4.0); // forward, right, up
	const string CSOW_ANIMEXT = "m16";						   // rifle

	const string MODEL_VIEW = "models/cso_edit/v_starchasersr.mdl";
	const string MODEL_PLAYER = "models/cso_edit/p_starchasersr.mdl";
	const string MODEL_WORLD = "models/cso_edit/w_starchasersr.mdl";
	// const string MODEL_SHELL					= "models/cso_edit/pshell.mdl";
	const string MODEL_AMMO = "models/w_9mmarclip.mdl";
	// const string MODEL_NULL = "models/cso_edit/null.mdl";
	// const string MODEL_VIEW_SCOPE = "models/cso_edit/scope.mdl";

	const string SPRITE_STARCHASER_SR = "sprites/cso_edit/ef_starchasersr.spr";
	const string SPRITE_STARCHASER_EXPLOSION = "sprites/cso_edit/ef_starchasersr_explosion.spr";
	const string SPRITE_STARCHASER_LINE = "sprites/cso_edit/ef_starchasersr_line.spr";
	const string SPRITE_STARCHASER_STAR = "sprites/cso_edit/ef_starchasersr_star.spr";
	// const string SPRITE_BEAM = "sprites/laserbeam.spr";

	enum csow_e
	{
		ANIM_IDLE = 0,
		ANIM_SHOOT1,
		ANIM_SHOOT2,
		ANIM_RELOAD,
		ANIM_DRAW
	};

	enum csowsounds_e
	{
		SND_EMPTY = 0,
		SND_ZOOM,
		SND_SHOOT
	};

	const array<string> pCSOWSounds =
		{
			"custom_weapons/cs16/dryfire_rifle.wav",
			"cso_edit/zoom.wav",
			"cso_edit/starchasersr-1.wav",
			"cso_edit/starchasersr_draw.wav",
			"cso_edit/starchasersr_clipin.wav",
			"cso_edit/starchasersr_clipout.wav"};

	class weapon_starchasersr : ScriptBasePlayerWeaponEntity // CBaseCSOWeapon
	{
		private CBasePlayer @m_pPlayer = null;

		void Spawn()
		{
			Precache();
			g_EntityFuncs.SetModel(self, MODEL_WORLD);
			self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
			self.m_flCustomDmg = pev.dmg;

			/*
				m_flSpreadJumping = CSOW_SPREAD_JUMPING;
				m_flSpreadRunning = CSOW_SPREAD_RUNNING;
				m_flSpreadWalking = CSOW_SPREAD_WALKING;
				m_flSpreadStanding = CSOW_SPREAD_STANDING;
				m_flSpreadDucking = CSOW_SPREAD_DUCKING;
			*/

			self.FallInit();
		}

		void Precache()
		{
			self.PrecacheCustomModels();

			g_Game.PrecacheModel(MODEL_VIEW);
			g_Game.PrecacheModel(MODEL_PLAYER);
			g_Game.PrecacheModel(MODEL_WORLD);
			// g_Game.PrecacheModel(MODEL_VIEW_SCOPE);

			// m_iShell = g_Game.PrecacheModel(MODEL_SHELL);

			// if (cso::bUseDroppedItemEffect)
			//	g_Game.PrecacheModel(cso::CSO_ITEMDISPLAY_MODEL);

			g_Game.PrecacheModel(SPRITE_STARCHASER_EXPLOSION);
			g_Game.PrecacheModel(SPRITE_STARCHASER_LINE);
			g_Game.PrecacheModel(SPRITE_STARCHASER_SR);
			g_Game.PrecacheModel(SPRITE_STARCHASER_STAR);
			// g_Game.PrecacheModel(SPRITE_BEAM);

			// for (uint i = 1; i < cso::pSmokeSprites.length(); ++i)
			//	g_Game.PrecacheModel(cso::pSmokeSprites[i]);

			for (uint i = 0; i < pCSOWSounds.length(); ++i)
				g_SoundSystem.PrecacheSound(pCSOWSounds[i]);

			// Precache these for downloading
			for (uint i = 0; i < pCSOWSounds.length(); ++i)
				g_Game.PrecacheGeneric("sound/" + pCSOWSounds[i]);

			g_Game.PrecacheGeneric("sprites/cso_edit/weapon_starchasersr.txt");
			g_Game.PrecacheGeneric("sprites/cso_edit/640hud18.spr");
			g_Game.PrecacheGeneric("sprites/cso_edit/640hud171.spr");
			g_Game.PrecacheGeneric("sprites/cso_edit/sniper_scope.spr");
		}

		bool GetItemInfo(ItemInfo& out info)		// Weapon information goes here
		{
			info.iMaxAmmo1 = CSOW_MAX_AMMO;			// Maximum primary ammo
			info.iMaxAmmo2 = -1;					// Maximum secondary ammo
			info.iMaxClip = CSOW_MAX_CLIP;			// Weapon's primary magazine
			info.iAmmo1Drop = CSOW_MAX_CLIP;		// How much ammo to drop
			info.iAmmo2Drop = -1;					// How much secondary ammo to drop
			info.iSlot = STARCHASERSR_SLOT;			// Weapon's slot
			info.iPosition = STARCHASERSR_POSITION; // Weapon's position on the weapon bucket
			info.iFlags = 0;						// Weapon's flags
			info.iWeight = STARCHASERSR_WEIGHT;		// Weapon's weight
			return true;
		}

		bool AddToPlayer(CBasePlayer @pPlayer)
		{
			if (!BaseClass.AddToPlayer(pPlayer))
				return false;

			@m_pPlayer = pPlayer;

			NetworkMessage m(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
			m.WriteLong(g_ItemRegistry.GetIdForName(CSOW_NAME));
			m.End();

			return true;
		}

		bool PlayEmptySound()
		{
			if (self.m_bPlayEmptySound)
			{
				self.m_bPlayEmptySound = false;
				g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_EMPTY], VOL_NORM, ATTN_NORM);
			}

			return false;
		}

		void Holster(int skiplocal)
		{
			if (m_pPlayer.m_iFOV != 0)
				ResetZoom();

			BaseClass.Holster(skiplocal);
		}

		bool Deploy()
		{
			bool bResult;
			{
				bResult = self.DefaultDeploy(self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, 0);
				self.m_flNextPrimaryAttack = g_Engine.time + (CSOW_TIME_DRAW - 0.4);
				self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_DRAW;
				self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

				return bResult;
			}
		}

		void PrimaryAttack()
		{
			if (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD or self.m_iClip <= 0)
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
				return;
			}

			// HandleAmmoReduction(1);

			if (self.m_iClip == 0 && m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0)
				m_pPlayer.SetSuitUpdate("!HEV_AMO0", false, 0);

			--self.m_iClip;

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;
			m_pPlayer.SetAnimation(PLAYER_ATTACK1);
			// m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

			switch (g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed, 0, 1))
			{
				case 0:
					self.SendWeaponAnim(ANIM_SHOOT1, 0, 0);
					break;
				case 1:
					self.SendWeaponAnim(ANIM_SHOOT2, 0, 0);
					break;
			}

			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, 0.4, 0, 94 + Math.RandomLong(0, 15));

			Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);

			if (self.m_fInZoom)
			{
				StarExplode();
				return;
			}
			else
			{
				Vector vecSrc = m_pPlayer.GetGunPosition();
				Vector vecDir = g_Engine.v_forward;

				CBaseEntity @pTrail = g_EntityFuncs.Create("ef_starchaser_sr", vecSrc, vecDir * 8192, false, m_pPlayer.edict());

				Vector vecVelocity = vecDir * 4096;

				pTrail.pev.velocity = vecVelocity;
				pTrail.pev.angles = Math.VecToAngles(pTrail.pev.velocity.Normalize());
				pTrail.pev.avelocity.z = 10;

				StarExplode();
			}

			self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
		}

		void StarExplode()
		{
			pev.effects |= EF_NODRAW;
			pev.velocity = g_vecZero;
			pev.movetype = MOVETYPE_NONE;
			pev.solid = SOLID_NOT;

			TraceResult tr;
			Vector vecSrc = m_pPlayer.GetGunPosition() - g_Engine.v_up * 2;
			Vector vecDir = g_Engine.v_forward;

			// g_Utility.TraceLine(vecSrc, vecSrc + vecDir * 8192, dont_ignore_monsters, m_pPlayer.edict(), tr);
			g_Utility.TraceLine(vecSrc, vecSrc + vecDir * 8192, dont_ignore_monsters, dont_ignore_glass, m_pPlayer.edict(), tr);

			CBaseEntity @hit = g_EntityFuncs.Instance(tr.pHit);
			if (hit.pev.takedamage > 0)
			{
				g_WeaponFuncs.ClearMultiDamage();
				CBaseEntity @entity = g_EntityFuncs.Instance(tr.pHit);
				entity.TraceAttack(m_pPlayer.pev, CSOW_DAMAGE, vecDir, tr, DMG_MORTAR | DMG_NEVERGIB);
				g_WeaponFuncs.ApplyMultiDamage(self.pev, m_pPlayer.pev);
			}
			else
			{
				// Silly stuff to play a sound at the other side, if it hit the world instead of a player/monster

				CBaseEntity @ef_star = g_EntityFuncs.Create("info_target", tr.vecEndPos, g_vecZero, false, null);
				g_EntityFuncs.SetModel(ef_star, SPRITE_STARCHASER_STAR);

				g_EntityFuncs.Remove(ef_star);
			}

			tr = g_Utility.GetGlobalTrace();

			// Pull out of the wall a bit
			if (tr.flFraction != 1.0f)
				pev.origin = tr.vecEndPos + (tr.vecPlaneNormal * 24.0f);

			Vector vecOrigin = pev.origin;

			NetworkMessage m3(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin);
			m3.WriteByte(TE_EXPLOSION);
			m3.WriteCoord(vecOrigin.x);
			m3.WriteCoord(vecOrigin.y);
			m3.WriteCoord(vecOrigin.z);
			m3.WriteShort(g_EngineFuncs.ModelIndex(SPRITE_STARCHASER_EXPLOSION));
			m3.WriteByte(20); // scale * 10
			m3.WriteByte(46); // framerate
			m3.WriteByte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NONE | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
			m3.End();

			float flDamage = CSOW_DAMAGE / 2;
			float flRadius = CSOW_RADIUS;

			g_WeaponFuncs.RadiusDamage(pev.origin, self.pev, pev.owner.vars, flDamage, flRadius, CLASS_NONE, DMG_SHOCK | DMG_NEVERGIB);

			self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
			self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY1 / 2;

			m_pPlayer.pev.punchangle.x -= 15.0f; // CSOW_RECOIL_X;
												 // m_pPlayer.pev.punchangle.y -= CSOW_RECOIL_Y;

			SetTouch(null);
		}

		void SecondaryAttack()
		{
			switch (m_pPlayer.m_iFOV)
			{
				case 0:
					// m_pPlayer.pev.viewmodel = MODEL_VIEW_SCOPE;
					self.m_fInZoom = true;
					m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 40;
					m_pPlayer.m_szAnimExtension = "sniperscope";
					break;
				case 40:
					self.m_fInZoom = true;
					// m_pPlayer.pev.viewmodel = MODEL_VIEW_SCOPE;
					m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 15;
					break;
				default:
					ResetZoom();
					break;
			}

			g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_ITEM, pCSOWSounds[SND_ZOOM], 0.2, 2.4);
			self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DELAY2;
		}

		void Reload()
		{
			if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or (m_pPlayer.pev.button & IN_ATTACK) != 0)
				return;

			if (m_pPlayer.m_iFOV != 0)
			{
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10;
				SecondaryAttack();
			}

			self.DefaultReload(CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, 0);
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_RELOAD + 0.5);

			BaseClass.Reload();
		}

		void WeaponIdle()
		{
			self.ResetEmptySound();
			m_pPlayer.GetAutoaimVector(AUTOAIM_10DEGREES);

			if (self.m_flTimeWeaponIdle > g_Engine.time)
				return;

			if (self.m_iClip > 0)
			{
				self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_IDLE;
				self.SendWeaponAnim(ANIM_IDLE, 0, 0);
			}
		}

		void ResetZoom()
		{
			self.m_fInZoom = false;
			m_pPlayer.pev.viewmodel = MODEL_VIEW;
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
			m_pPlayer.m_szAnimExtension = "m16";
		}
	}

	class ef_starchaser_sr : ScriptBaseEntity
	{
		void Spawn()
		{
			self.Precache();

			g_EntityFuncs.SetSize(self.pev, Vector(-1, -1, -1), Vector(1, 1, 1));
			g_EntityFuncs.SetOrigin(self, self.pev.origin);

			pev.movetype = MOVETYPE_FLY;
			pev.solid = SOLID_BBOX;

			SetTouch(TouchFunction(this.TrailTouch));
			SetThink(ThinkFunction(this.TrailThink));
			pev.nextthink = g_Engine.time + 0.01;
		}

		void Precache()
		{
			g_Game.PrecacheModel(SPRITE_STARCHASER_LINE);
			g_Game.PrecacheModel(SPRITE_STARCHASER_STAR);
		}

		void TrailThink()
		{
			Vector vecOrigin = pev.origin - pev.velocity.Normalize() * 4;

			// Star
			NetworkMessage m1(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			m1.WriteByte(TE_EXPLOSION);
			m1.WriteCoord(vecOrigin.x);
			m1.WriteCoord(vecOrigin.y);
			m1.WriteCoord(vecOrigin.z - 10);
			m1.WriteShort(g_EngineFuncs.ModelIndex(SPRITE_STARCHASER_STAR));
			m1.WriteByte(2);	  // scale
			m1.WriteByte(15 * 5); // framerate //15
			m1.WriteByte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
			m1.End();

			// Trail Line
			NetworkMessage m2(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			m2.WriteByte(TE_EXPLOSION);
			m2.WriteCoord(pev.origin.x);
			m2.WriteCoord(pev.origin.y);
			m2.WriteCoord(pev.origin.z - 10);
			m2.WriteShort(g_EngineFuncs.ModelIndex(SPRITE_STARCHASER_LINE));
			m2.WriteByte(2);	  // scale
			m2.WriteByte(16 * 4); // framerate //16
			m2.WriteByte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
			m2.End();

			// Star Explode Loop
			NetworkMessage m3(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			m3.WriteByte(TE_EXPLOSION);
			m3.WriteCoord(pev.origin.x);
			m3.WriteCoord(pev.origin.y);
			m3.WriteCoord(pev.origin.z - 10);
			m3.WriteShort(g_EngineFuncs.ModelIndex(SPRITE_STARCHASER_SR));
			m3.WriteByte(2);	  // scale
			m3.WriteByte(45 * 4); // framerate //45
			m3.WriteByte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
			m3.End();

			pev.nextthink = g_Engine.time + 0.005;
		}

		void TrailTouch(CBaseEntity @pOther)
		{
			g_EntityFuncs.Remove(self);
		}
	}

	// Ammo class
	class STARCHASERSR_MAG : ScriptBasePlayerAmmoEntity
	{
		void Spawn()
		{
			g_EntityFuncs.SetModel(self, MODEL_AMMO);

			pev.scale = 1.0;

			BaseClass.Spawn();
		}

		bool AddAmmo(CBaseEntity @pOther)
		{
			int iGive;

			iGive = CSOW_MAX_CLIP;

			if (pOther.GiveAmmo(iGive, AMMO_TYPE, CSOW_MAX_AMMO) != -1)
			{
				g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM);
				return true;
			}

			return false;
		}
	}

	string GetName()
	{
		return "weapon_starchasersr";
	}

	string GetAmmoName()
	{
		return "ammo_starchasersr";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity("cso_starchasersr::ef_starchaser_sr", "ef_starchaser_sr");
		g_CustomEntityFuncs.RegisterCustomEntity("cso_starchasersr::weapon_starchasersr", GetName());
		g_CustomEntityFuncs.RegisterCustomEntity("cso_starchasersr::STARCHASERSR_MAG", GetAmmoName());
		g_ItemRegistry.RegisterWeapon(GetName(), "cso_edit", AMMO_TYPE, "", GetAmmoName());
	}

} // namespace cso_starchasersr END
