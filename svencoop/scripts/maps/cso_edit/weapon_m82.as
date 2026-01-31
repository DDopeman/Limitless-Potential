namespace cso_m82
{

	const bool USE_PENETRATION = true;

	const int M82_SLOT = 4;
	const int M82_POSITION = 15;
	const int M82_WEIGHT = 30;
	const int CSOW_DEFAULT_GIVE = 7;
	const int CSOW_MAX_CLIP = 7;
	const int CSOW_MAX_AMMO = 90; // 90
	const int CSOW_TRACERFREQ = 0;
	const float CSOW_DAMAGE = 75;
	const float CSOW_TIME_DELAY1 = 1.05;
	const float CSOW_TIME_DELAY2 = 0.3;
	const float CSOW_TIME_DRAW = 0.7;
	const float CSOW_TIME_IDLE = 60.0;
	const float CSOW_TIME_RELOAD = 3.25;
	const float CSOW_RECOIL = 2.0;
	const Vector CSOW_SHELL_ORIGIN = Vector(16.0, 9.0, -9.0); // forward, right, up

	const string CSOW_ANIMEXT = "sniper";					  // rifle

	const string MODEL_VIEW = "models/cso_edit/v_m82.mdl";
	const string MODEL_PLAYER = "models/cso_edit/p_m82.mdl";
	const string MODEL_WORLD = "models/cso_edit/w_m82.mdl";
	const string MODEL_SHELL = "models/cso_edit/rshell_big.mdl";
	const string MODEL_AMMO	= "models/cso_edit/sniper_ammo2.mdl";

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
			"cso_edit/dryfire_rifle.wav",
			"cso_edit/zoom.wav",
			"cso_edit/m82-1.wav",
			"cso_edit/awp_deploy.wav",
			"cso_edit/m82_clipin2.wav",
			"cso_edit/m82_clipout2.wav",
			"cso_edit/m82_clipin1.wav",
			"cso_edit/m82_clipout1.wav",
			"cso_edit/boltup.wav"};

	class weapon_m82 : CBaseCSOWeapon
	{
		private bool m_bResumeZoom;
		private int m_iLastZoom;
		private float m_flEjectBrass;

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
			g_Game.PrecacheModel(MODEL_AMMO);

			m_iShell = g_Game.PrecacheModel(MODEL_SHELL);

			if (cso::bUseDroppedItemEffect)
				g_Game.PrecacheModel(cso::CSO_ITEMDISPLAY_MODEL);

			for (uint i = 1; i < cso::pSmokeSprites.length(); ++i)
				g_Game.PrecacheModel(cso::pSmokeSprites[i]);

			for (uint i = 0; i < pCSOWSounds.length(); ++i)
				g_SoundSystem.PrecacheSound(pCSOWSounds[i]);

			// Precache these for downloading
			for (uint i = 0; i < pCSOWSounds.length(); ++i)
				g_Game.PrecacheGeneric("sound/" + pCSOWSounds[i]);

			g_Game.PrecacheGeneric("sprites/cso_edit/weapon_m82.txt");
			g_Game.PrecacheGeneric("sprites/cso_edit/640hud2.spr");
			g_Game.PrecacheGeneric("sprites/cso_edit/640hud5.spr");
			g_Game.PrecacheGeneric("sprites/cso_edit/640hud7.spr");
			g_Game.PrecacheGeneric("sprites/cso_edit/sniper_scope.spr");
		}

		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1 = CSOW_MAX_AMMO;
			info.iMaxClip = CSOW_MAX_CLIP;
			info.iAmmo1Drop = CSOW_MAX_CLIP;
			info.iSlot = M82_SLOT;
			info.iPosition = M82_POSITION;
			info.iWeight = M82_WEIGHT;

			return true;
		}

		bool AddToPlayer(CBasePlayer @pPlayer)
		{
			if (!BaseClass.AddToPlayer(pPlayer))
				return false;

			@m_pPlayer = pPlayer;

			NetworkMessage m(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
			m.WriteLong(g_ItemRegistry.GetIdForName("weapon_m82"));
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

			m_flEjectBrass = 0.0;

			BaseClass.Holster(skiplocal);
		}

		bool Deploy()
		{
			bool bResult;
			{
				bResult = self.DefaultDeploy(self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, CSOW_ANIMEXT, 0, (m_bSwitchHands ? g_iCSOWHands : 0));
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + CSOW_TIME_DRAW;
				self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

				m_bResumeZoom = false;
				m_iLastZoom = 0;

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

			if (!m_pPlayer.pev.FlagBitSet(FL_ONGROUND))
				M82Fire(0.85, CSOW_TIME_DELAY1);
			else if (m_pPlayer.pev.velocity.Length2D() > 140)
				M82Fire(0.25, CSOW_TIME_DELAY1);
			else if (m_pPlayer.pev.velocity.Length2D() > 10)
				M82Fire(0.1, CSOW_TIME_DELAY1);
			else if (m_pPlayer.pev.FlagBitSet(FL_DUCKING))
				M82Fire(0.0, CSOW_TIME_DELAY1);
			else
				M82Fire(0.001, CSOW_TIME_DELAY1);
		}

		void M82Fire(float flSpread, float flCycleTime)
		{
			if (m_pPlayer.pev.fov != 0)
			{
				m_bResumeZoom = true;
				m_iLastZoom = m_pPlayer.m_iFOV;
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
			}
			else
				flCycleTime += 0.08;

			m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
			m_pPlayer.SetAnimation(PLAYER_ATTACK1);

			Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);

			m_flEjectBrass = g_Engine.time + 0.55;
			m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

			float flDamage = CSOW_DAMAGE;
			if (self.m_flCustomDmg > 0)
				flDamage = self.m_flCustomDmg;

			Vector vecSrc = m_pPlayer.GetGunPosition();
			int iPenetration = USE_PENETRATION ? 3 : 1;
			FireBullets3(vecSrc, g_Engine.v_forward, flSpread * 0, iPenetration, BULLET_PLAYER_338MAG, CSOW_TRACERFREQ, flDamage, 0.99, CSOF_ALWAYSDECAL);

			self.SendWeaponAnim(Math.RandomLong(ANIM_SHOOT1, ANIM_SHOOT2), 0, (m_bSwitchHands ? g_iCSOWHands : 0));

			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, pCSOWSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15));

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flCycleTime;

			HandleAmmoReduction(1);

			self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
			m_pPlayer.pev.punchangle.x -= CSOW_RECOIL;
		}

		void SecondaryAttack()
		{
			switch (m_pPlayer.m_iFOV)
			{
				case 0:
					m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 40;
					m_pPlayer.m_szAnimExtension = "sniperscope";
					break;
				case 40:
					m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10;
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
			if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 or self.m_iClip >= CSOW_MAX_CLIP or m_flEjectBrass > 0.0 or (m_pPlayer.pev.button & IN_ATTACK) != 0)
				return;

			if (m_pPlayer.m_iFOV != 0)
			{
				m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 10;
				// SecondaryAttack();
				ResetZoom();
			}

			self.DefaultReload(CSOW_MAX_CLIP, ANIM_RELOAD, CSOW_TIME_RELOAD, (m_bSwitchHands ? g_iCSOWHands : 0));
			self.m_flTimeWeaponIdle = g_Engine.time + CSOW_TIME_RELOAD;

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
				self.SendWeaponAnim(ANIM_IDLE, 0, (m_bSwitchHands ? g_iCSOWHands : 0));
			}
		}

		void ItemPostFrame()
		{
			if (self.m_flNextPrimaryAttack <= g_Engine.time)
			{
				if (m_bResumeZoom)
				{
					m_pPlayer.pev.fov = m_pPlayer.m_iFOV = m_iLastZoom;

					if (m_pPlayer.m_iFOV == m_iLastZoom)
						m_bResumeZoom = false;
				}
			}

			if (m_flEjectBrass > 0.0 and m_flEjectBrass < g_Engine.time)
			{
				m_flEjectBrass = 0.0;
				EjectBrass(m_pPlayer.GetGunPosition() + g_Engine.v_forward * CSOW_SHELL_ORIGIN.x + g_Engine.v_right * CSOW_SHELL_ORIGIN.y + g_Engine.v_up * CSOW_SHELL_ORIGIN.z, m_iShell, TE_BOUNCE_SHELL, false, true);
			}

			BaseClass.ItemPostFrame();
		}

		void ResetZoom()
		{
			m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
			m_pPlayer.m_szAnimExtension = "sniper";
		}

		/*float GetMaxSpeed()
		{
			if( m_pPlayer.m_iFOV == 0 )
				return 210;

			return 150;
		}*/
	}

	class M82_MAG : ScriptBasePlayerAmmoEntity
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

			if (pOther.GiveAmmo(iGive, "cso_sniper2", CSOW_MAX_AMMO) != -1)
			{
				g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM);
				return true;
			}

			return false;
		}
	}

	string GetName()
	{
		return "weapon_m82";
	}

	string GetAmmoName()
	{
		return "ammo_cso_sniper2";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity("cso_m82::weapon_m82", GetName());
		g_CustomEntityFuncs.RegisterCustomEntity("cso_m82::M82_MAG", GetAmmoName());
		g_ItemRegistry.RegisterWeapon(GetName(), "cso_edit", "cso_sniper2", "", GetAmmoName()); // 7.62 Nato
	}

} // namespace cso_m82 END
