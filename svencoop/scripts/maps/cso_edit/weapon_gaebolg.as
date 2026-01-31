namespace cso_gaebolg
{

	const string CSOW_NAME = "weapon_gaebolg";

	// Weapon info
	const int CSOW_DEFAULT_GIVE = 10;
	const int CSOW_MAX_CLIP = 5;
	const int CSOW_MAX_AMMO = 100;
	const float CSOW_DAMAGE = 100.0;	// 42 ??
	const float CSOW_GRENADE_DAMAGE = 200.0;
	const float CSOW_GRENADE_RADIUS = 150.0;
	const float CSOW_TIME_DELAY1 = 0.8; // 430 RPM ??
	const float CSOW_TIME_DELAY2 = 0.1;
	const float CSOW_TIME_DRAW = 1.0;
	const float CSOW_TIME_IDLE = 1.9;
	const float CSOW_TIME_FIRE_TO_IDLE = 2.0;
	const float CSOW_TIME_RELOAD = 2.2;

	// Recoil
	const Vector2D CSOW_RECOIL_STANDING_X = Vector2D(-0.5, -1.0);
	const Vector2D CSOW_RECOIL_STANDING_Y = Vector2D(-0.5, 0.5);
	const Vector2D CSOW_RECOIL_DUCKING_X = Vector2D(-0.5, -1.0);
	const Vector2D CSOW_RECOIL_DUCKING_Y = Vector2D(-0.5, 0.5);

	// Weapon slot info
	const int GAEBOLG_SLOT = 6;
	const int GAEBOLG_POSITION = 18;
	const int GAEBOLG_WEIGHT = 25;

	// Weapon flags/logics
	const int BOLT_AIR_VELOCITY = 3000;
	const int BOLT_WATER_VELOCITY = 2000;

	const string CSOW_ANIMEXT = "bow";
	const string CSOW_ANIMEXT_ZOOM = "bowscope";

	// Models
	const string MODEL_VIEW = "models/cso_edit/v_speargun.mdl";
	const string MODEL_PLAYER = "models/cso_edit/p_speargun.mdl";
	const string MODEL_WORLD = "models/cso_edit/w_speargun.mdl";
	const string MODEL_SPEAR = "models/cso_edit/spear.mdl";
	const string A_MODEL = "models/w_crossbow_clip.mdl";

	// Sprites
	const string SPRITE_BEAM = "sprites/laserbeam.spr";
	const string SPRITE_EXPLOSION1 = "sprites/cso_edit/spear_exp.spr";
	const string SPRITE_SMOKE = "sprites/steam1.spr";

	enum csow_e
	{
		ANIM_IDLE1 = 0,
		ANIM_SHOOT1,
		ANIM_RELOAD,
		ANIM_DRAW,
		ANIM_DRAW_EMPTY,
		ANIM_IDLE_EMPTY
	};

	enum csowsounds_e
	{
		SND_EMPTY = 0,
		SND_SHOOT,
		SND_HIT_WALL,
		SND_HIT
	};

	const array<string> pCSOWSounds =
		{
			"custom_weapons/cs16/dryfire_rifle.wav",
			"cso_edit/speargun-1.wav",
			"cso_edit/speargun_hit1.wav",
			"cso_edit/speargun_hit1.wav",
			"cso_edit/speargun_draw.wav",
			"cso_edit/speargun_clipin.wav"};

	class weapon_gaebolg : CBaseCSOWeapon
	{
		void Spawn()
		{
			Precache();
			g_EntityFuncs.SetModel(self, MODEL_WORLD);
			self.m_iDefaultAmmo = CSOW_DEFAULT_GIVE;
			self.m_flCustomDmg = pev.dmg;

			self.FallInit();
		}

		void Precache()
		{
			self.PrecacheCustomModels();

			g_Game.PrecacheModel(MODEL_VIEW);
			g_Game.PrecacheModel(MODEL_PLAYER);
			g_Game.PrecacheModel(MODEL_WORLD);
			g_Game.PrecacheModel(MODEL_SPEAR);
			g_Game.PrecacheModel(A_MODEL);
			g_Game.PrecacheModel(SPRITE_BEAM);
			g_Game.PrecacheModel(SPRITE_EXPLOSION1);
			g_Game.PrecacheModel(SPRITE_SMOKE);

			if (cso::bUseDroppedItemEffect)
				g_Game.PrecacheModel(cso::CSO_ITEMDISPLAY_MODEL);

			for (uint i = 1; i < cso::pSmokeSprites.length(); ++i)
				g_Game.PrecacheModel(cso::pSmokeSprites[i]);

			for (uint i = 0; i < pCSOWSounds.length(); ++i)
				g_SoundSystem.PrecacheSound(pCSOWSounds[i]);

			// Precache these for downloading
			for (uint i = 0; i < pCSOWSounds.length(); ++i)
				g_Game.PrecacheGeneric("sound/" + pCSOWSounds[i]);

			g_Game.PrecacheGeneric("sprites/cso_edit/" + CSOW_NAME + ".txt");
			g_Game.PrecacheGeneric("sprites/cso_edit/640hud103_2.spr");
			g_Game.PrecacheGeneric("sprites/cso_edit/640hud12_2.spr");
		}

		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1 = CSOW_MAX_AMMO;
			info.iMaxClip = WEAPON_NOCLIP;
			info.iSlot = GAEBOLG_SLOT;
			info.iPosition = GAEBOLG_POSITION;
			info.iWeight = GAEBOLG_WEIGHT;

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

		bool Deploy()
		{
			bool bResult;
			{
				bResult = self.DefaultDeploy(self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0));
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CSOW_TIME_DRAW;
				self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_DRAW + Math.RandomFloat(0.5, (CSOW_TIME_DRAW * 2)));

				return bResult;
			}
		}

		void PrimaryAttack()
		{
			int ammo1 = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
			if (ammo1 <= 0)
				return;

			--ammo1;
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo1);

			m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
			m_pPlayer.SetAnimation(PLAYER_ATTACK1);
			self.SendWeaponAnim(ANIM_SHOOT1, 0, (m_bSwitchHands ? g_iCSOWHands : 0));
			g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM);

			g_EngineFuncs.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);

			Vector vecSrc = m_pPlayer.GetGunPosition() - g_Engine.v_up * 2 + g_Engine.v_right * 2;
			Vector vecDir = g_Engine.v_forward;

			float flDamage = CSOW_DAMAGE;
			if (self.m_flCustomDmg > 0)
				flDamage = self.m_flCustomDmg;

			CBaseEntity @pSpear = g_EntityFuncs.Create("csoproj_gaebolg", vecSrc, vecDir, false, m_pPlayer.edict());

			Vector vecVelocity;
			if (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD)
				vecVelocity = vecDir * BOLT_WATER_VELOCITY;
			else
				vecVelocity = vecDir * BOLT_AIR_VELOCITY;

			float flSpread = 8.0;

			vecVelocity = vecVelocity + g_Engine.v_right * Math.RandomFloat(-flSpread, flSpread) + g_Engine.v_up * Math.RandomFloat(-flSpread, flSpread);

			pSpear.pev.velocity = vecVelocity;
			pSpear.pev.angles = Math.VecToAngles(pSpear.pev.velocity.Normalize());
			pSpear.pev.avelocity.z = 10;
			pSpear.pev.dmg = flDamage;

			float flRecoilMult = 1.0;

			if (m_pPlayer.m_iFOV != 0)
				flRecoilMult = 0.25;

			HandleRecoil(CSOW_RECOIL_STANDING_X * flRecoilMult, CSOW_RECOIL_STANDING_Y * flRecoilMult, CSOW_RECOIL_DUCKING_X * flRecoilMult, CSOW_RECOIL_DUCKING_Y * flRecoilMult);

			self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DELAY1;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_FIRE_TO_IDLE;

			// Reload after every shot
			SetThink(ThinkFunction(this.IsReloading));
			pev.nextthink = g_Engine.time + 0.5;
		}

		void SecondaryAttack()
		{
			CBaseEntity @pSpear = null;
			while ((@pSpear = g_EntityFuncs.FindEntityInSphere(pSpear, m_pPlayer.pev.origin, 4096, "*", "classname")) !is null)
			{
				string cname = pSpear.pev.classname;
				if (cname == "csoproj_gaebolg")
				{
					CBaseEntity @pevOwner = g_EntityFuncs.Instance(pSpear.pev.owner);
					if (pevOwner == m_pPlayer)
					{
						pSpear.Use(m_pPlayer, m_pPlayer, USE_ON, 0);
						self.pev.iuser1 = 2;
					}
				}
			}

			self.pev.iuser1 = 2;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.001;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.01;
		}

		void IsReloading()
		{
			if (!m_pPlayer.IsAlive())
				return;

			self.SendWeaponAnim(ANIM_RELOAD, 0, (m_bSwitchHands ? g_iCSOWHands : 0));

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 2.5f;
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;
		}

		void WeaponIdle()
		{
			self.ResetEmptySound();

			if (self.m_flTimeWeaponIdle > g_Engine.time)
				return;

			self.SendWeaponAnim(ANIM_IDLE1, 0, (m_bSwitchHands ? g_iCSOWHands : 0));
			self.m_flTimeWeaponIdle = g_Engine.time + (CSOW_TIME_IDLE + Math.RandomFloat(0.5, (CSOW_TIME_IDLE * 2)));
		}
	}

	/*
	 * Gae Bolg's Spear Projectile Entity
	 */
	class csoproj_gaebolg : ScriptBaseEntity
	{
		void Spawn()
		{
			pev.movetype = MOVETYPE_FLY;
			pev.solid = SOLID_BBOX;
			pev.gravity = 0.5;
			self.SetClassification(CLASS_NONE);

			g_EntityFuncs.SetModel(self, MODEL_SPEAR);
			g_EntityFuncs.SetOrigin(self, pev.origin);
			g_EntityFuncs.SetSize(self.pev, g_vecZero, g_vecZero);

			SetTouch(TouchFunction(this.SpearTouch));
			SetThink(ThinkFunction(this.BubbleThink));
			SetUse(UseFunction(DetonateUse));
			pev.nextthink = g_Engine.time + 0.1;
		}

		void SpearTouch(CBaseEntity @pOther)
		{
			if (g_EngineFuncs.PointContents(self.pev.origin) == CONTENTS_SKY)
			{
				g_EntityFuncs.Remove(self);
				return;
			}

			SetTouch(null);
			SetThink(null);

			if (pOther.pev.takedamage != DAMAGE_NO)
			{
				TraceResult tr = g_Utility.GetGlobalTrace();
				entvars_t @pevOwner = pev.owner.vars;

				g_WeaponFuncs.ClearMultiDamage();

				if (pOther.IsPlayer())
					pOther.TraceAttack(pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_NEVERGIB);
				else
					pOther.TraceAttack(pevOwner, pev.dmg, pev.velocity.Normalize(), tr, DMG_BLAST | DMG_NEVERGIB);

				g_WeaponFuncs.ApplyMultiDamage(pev, pevOwner);

				pev.velocity = g_vecZero;

				g_SoundSystem.EmitSound(self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT], 1, ATTN_NORM);

				self.Killed(pev, GIB_NEVER);
			}
			else
			{
				g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_BODY, pCSOWSounds[SND_HIT_WALL], Math.RandomFloat(0.95, 1.0), ATTN_NORM, 0, 98 + Math.RandomLong(0, 7));

				SetThink(ThinkFunction(this.SUB_Remove));
				pev.nextthink = g_Engine.time;

				if (pOther.pev.ClassNameIs("worldspawn"))
				{
					Vector vecDir = pev.velocity.Normalize();
					g_EntityFuncs.SetOrigin(self, pev.origin - vecDir); // Pull out of the wall a bit
					pev.angles = Math.VecToAngles(vecDir);
					pev.solid = SOLID_NOT;
					pev.movetype = MOVETYPE_FLY;
					pev.velocity = Vector(0, 0, 0);
					pev.avelocity.z = 0;
					pev.angles.z = Math.RandomLong(0, 360);
					pev.nextthink = g_Engine.time + 10.0;
				}

				if (g_EngineFuncs.PointContents(pev.origin) != CONTENTS_WATER)
					g_Utility.Sparks(pev.origin);
			}
		}

		void DetonateUse(CBaseEntity @pActivator, CBaseEntity @pCaller, USE_TYPE useType, float flValue)
		{
			CBaseEntity @pThis = g_EntityFuncs.Instance(pev);

			TraceResult tr;
			Vector vecSpot; // trace starts here!

			vecSpot = pev.origin + Vector(0, 0, 8);
			g_Utility.TraceLine(vecSpot, vecSpot + Vector(0, 0, -40), ignore_monsters, pThis.edict(), tr);

			// g_EntityFuncs.CreateExplosion( tr.vecEndPos, Vector( 0, 0, -90 ), pev.owner, int( pev.dmg ), false );
			// g_WeaponFuncs.RadiusDamage( tr.vecEndPos, self.pev, self.pev.owner.vars, self.pev.dmg, ( self.pev.dmg * 3.0 ), CLASS_NONE, DMG_BLAST );

			// Custom explosion called here to allow for custom radius damage and sprites
			Explode();

			g_EntityFuncs.Remove(pThis);
		}

		void Explode()
		{
			TraceResult tr;
			Vector vecSpot = pev.origin - pev.velocity.Normalize() * 32;
			Vector vecEnd = pev.origin + pev.velocity.Normalize() * 64;

			g_Utility.TraceLine(vecSpot, vecEnd, ignore_monsters, self.edict(), tr);

			g_Utility.DecalTrace(tr, DECAL_SCORCH1 + Math.RandomLong(0, 1));

			int sparkCount = Math.RandomLong(0, 3);
			for (int i = 0; i < sparkCount; i++)
				g_EntityFuncs.Create("spark_shower", pev.origin, tr.vecPlaneNormal, false);

			tr = g_Utility.GetGlobalTrace();

			// Pull out of the wall a bit
			if (tr.flFraction != 1.0f)
				pev.origin = tr.vecEndPos + (tr.vecPlaneNormal * 24.0f);

			Vector vecOrigin = pev.origin;

			NetworkMessage m1(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin);
			m1.WriteByte(TE_EXPLOSION);
			m1.WriteCoord(vecOrigin.x);
			m1.WriteCoord(vecOrigin.y);
			m1.WriteCoord(vecOrigin.z);
			m1.WriteShort(g_EngineFuncs.ModelIndex(SPRITE_EXPLOSION1));
			m1.WriteByte(20); // scale * 10
			m1.WriteByte(30); // framerate
			m1.WriteByte(TE_EXPLFLAG_NONE);
			m1.End();

			float flDamage = CSOW_GRENADE_DAMAGE;
			float flRadius = CSOW_GRENADE_RADIUS;

			g_WeaponFuncs.RadiusDamage(pev.origin, self.pev, pev.owner.vars, flDamage, flRadius, CLASS_NONE, DMG_MORTAR | DMG_LAUNCH);

			pev.effects |= EF_NODRAW;
			pev.velocity = g_vecZero;
			pev.movetype = MOVETYPE_NONE;
			pev.solid = SOLID_NOT;

			SetTouch(null);

			SetThink(ThinkFunction(this.Smoke));
			pev.nextthink = g_Engine.time + 0.5;
		}

		void Smoke()
		{
			NetworkMessage msg1(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin);
			msg1.WriteByte(TE_SMOKE);
			msg1.WriteCoord(pev.origin.x);
			msg1.WriteCoord(pev.origin.y);
			msg1.WriteCoord(pev.origin.z);
			msg1.WriteShort(g_EngineFuncs.ModelIndex(SPRITE_SMOKE));
			msg1.WriteByte(20); // scale * 10
			msg1.WriteByte(6);	// framerate
			msg1.End();

			g_EntityFuncs.Remove(self);
		}

		void BubbleThink()
		{
			pev.nextthink = g_Engine.time + 0.1;

			if (pev.waterlevel == WATERLEVEL_DRY)
				return;

			g_Utility.BubbleTrail(pev.origin - pev.velocity * 0.1, pev.origin, 1);
		}

		void SUB_Remove()
		{
			self.SUB_Remove();
		}
	}
	// end namespace csoproj_gaebolg

	class GAEBOLG_MAG : ScriptBasePlayerAmmoEntity
	{
		void Spawn()
		{
			g_EntityFuncs.SetModel(self, A_MODEL);

			pev.scale = 1.0;

			BaseClass.Spawn();
		}

		bool AddAmmo(CBaseEntity @pOther)
		{
			int iGive;

			iGive = CSOW_MAX_CLIP;

			if (pOther.GiveAmmo(iGive, "cso_spears", CSOW_MAX_AMMO) != -1)
			{
				g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM);
				return true;
			}

			return false;
		}
	}

	string GetName()
	{
		return "weapon_gaebolg";
	}

	string GetAmmoName()
	{
		return "ammo_gaebolg";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity("cso_gaebolg::csoproj_gaebolg", "csoproj_gaebolg");
		g_CustomEntityFuncs.RegisterCustomEntity("cso_gaebolg::weapon_gaebolg", GetName());
		g_CustomEntityFuncs.RegisterCustomEntity("cso_gaebolg::GAEBOLG_MAG", GetAmmoName());
		g_ItemRegistry.RegisterWeapon(GetName(), "cso_edit", "cso_spears", "", GetAmmoName());
	}

} // namespace cso_crossbow END
