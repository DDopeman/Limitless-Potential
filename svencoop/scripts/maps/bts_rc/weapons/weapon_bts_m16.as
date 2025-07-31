/*
 * M16A3 Full Auto
 */
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_m16
{
	enum m16a3_e
	{
		DRAW = 0,
		HOLSTER,
		IDLE,
		FIDGET,
		SHOOT1,
		SHOOT2,
		RELOAD,
		LAUNCH,
		RELOAD2 // m203 reload
	};

	// Weapon info
	int MAX_CARRY = 150;
	int MAX_CARRY2 = 10;
	int MAX_CLIP = 30;
	int MAX_CLIP2 = WEAPON_NOCLIP;
	// int DEFAULT_GIVE = Math.RandomLong( 15, 30 );
	// int DEFAULT_GIVE2 = Math.RandomLong( 0, 1 );
	int AMMO_GIVE = MAX_CLIP;
	int AMMO_GIVE2 = 2;
	int AMMO_DROP = AMMO_GIVE;
	int AMMO_DROP2 = 1;
	int WEIGHT = 5;
	// Weapon HUD
	int SLOT = 2;
	int POSITION = 10;
	// Vars
	int DAMAGE = 19;
	float DAMAGE2 = 100.0f;
	Vector CROUCH_CONE(0.01f, 0.01f, 0.01f);
	Vector SHELL(32.0f, 6.0f, -12.0f);

	class weapon_bts_m16 : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
	{
		private CBasePlayer @m_pPlayer
		{
			get const
			{
				return get_player();
			}
		}

		private int m_iTracerCount;
		private float m_flGrenadeLaunchTime;
		private bool m_bGrenadeFire;

		void Spawn()
		{
			g_EntityFuncs.SetModel(self, self.GetW_Model("models/bts_rc/weapons/w_m16.mdl"));
			self.m_iDefaultAmmo = Math.RandomLong(15, MAX_CLIP);
			self.m_iDefaultSecAmmo = Math.RandomLong(0, 1);
			self.FallInit();

			m_iTracerCount = 0;
		}

		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1 = MAX_CARRY;
			info.iAmmo1Drop = AMMO_DROP;
			info.iMaxAmmo2 = MAX_CARRY2;
			info.iAmmo2Drop = AMMO_DROP2;
			info.iMaxClip = MAX_CLIP;
			info.iSlot = SLOT;
			info.iPosition = POSITION;
			info.iId = g_ItemRegistry.GetIdForName(pev.classname);
			info.iFlags = m_flags;
			info.iWeight = WEIGHT;
			return true;
		}

		bool Deploy()
		{
			m_bGrenadeFire = false;

			return bts_deploy("models/bts_rc/weapons/v_m16a2.mdl", "models/bts_rc/weapons/p_m16.mdl", DRAW, "m16", 2);
		}

		void Holster(int skiplocal = 0)
		{
			m_bGrenadeFire = false;
			self.m_fInReload = false;

			BaseClass.Holster(skiplocal);
		}

		bool PlayEmptySound()
		{
			if (self.m_bPlayEmptySound)
			{
				self.m_bPlayEmptySound = false;
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8f, ATTN_NORM, 0, PITCH_NORM);
			}
			return false;
		}

		void PrimaryAttack()
		{
			// don't fire underwater
			if (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0)
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 0.10f;
				return;
			}

			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

			--self.m_iClip;

			m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
			pev.effects |= EF_MUZZLEFLASH;

			// player "shoot" animation
			m_pPlayer.SetAnimation(PLAYER_ATTACK1);

			Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecAiming = m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);

			bool is_trained_personal = g_PlayerClass.is_trained_personal(m_pPlayer);

			float CONE = (is_trained_personal ? (m_pPlayer.IsMoving() ? 0.02618f : 0.01f) : (m_pPlayer.IsMoving() ? 0.1f : 0.05f));

			float x, y;
			g_Utility.GetCircularGaussianSpread(x, y);

			Vector vecDir = vecAiming + x * CONE * g_Engine.v_right + y * CONE * g_Engine.v_up;
			Vector vecEnd = vecSrc + vecDir * 8192.0f;

			TraceResult tr;
			g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);
			self.FireBullets(1, vecSrc, vecDir, g_vecZero, 8192.0f, BULLET_PLAYER_CUSTOMDAMAGE, 0, DAMAGE, m_pPlayer.pev);
			bts_post_attack(tr);

			// each 4 bullets
			if ((m_iTracerCount++ % 4) == 0)
			{
				Vector vecTracerSrc = vecSrc + Vector(0.0f, 0.0f, -4.0f) + g_Engine.v_right * 2.0f + g_Engine.v_forward * 16.0f;
				NetworkMessage tracer(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecTracerSrc);
				tracer.WriteByte(TE_TRACER);
				tracer.WriteCoord(vecTracerSrc.x);
				tracer.WriteCoord(vecTracerSrc.y);
				tracer.WriteCoord(vecTracerSrc.z);
				tracer.WriteCoord(tr.vecEndPos.x);
				tracer.WriteCoord(tr.vecEndPos.y);
				tracer.WriteCoord(tr.vecEndPos.z);
				tracer.End();
			}

			if (tr.flFraction < 1.0f && tr.pHit !is null)
			{
				CBaseEntity @pHit = g_EntityFuncs.Instance(tr.pHit);
				if ((pHit is null || pHit.IsBSPModel()) && !pHit.pev.FlagBitSet(FL_WORLDBRUSH))
					g_WeaponFuncs.DecalGunshot(tr, BULLET_PLAYER_CUSTOMDAMAGE);
			}

			switch (g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed, 0, 2))
			{
				case 0:
					self.SendWeaponAnim(SHOOT1, 0, pev.body);
					break;
				case 1:
					self.SendWeaponAnim(SHOOT2, 0, pev.body);
					break;
				case 2:
					self.SendWeaponAnim(SHOOT1, 0, pev.body);
					break;
			}

			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/m16_fire1.wav", 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong(0, 10));

			if (is_trained_personal)
				m_pPlayer.pev.punchangle.x = -3.0f;
			else
				m_pPlayer.pev.punchangle.x = m_pPlayer.pev.FlagBitSet(FL_DUCKING) ? float(Math.RandomLong(-3, 2)) : float(Math.RandomLong(-8, 3));

			Vector vecForward, vecRight, vecUp;
			g_EngineFuncs.AngleVectors(m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp);
			Vector vecOrigin = m_pPlayer.GetGunPosition() + vecForward * SHELL.x + vecRight * SHELL.y + vecUp * SHELL.z;
			Vector vecVelocity = m_pPlayer.pev.velocity + vecForward * 25.0f + vecRight * Math.RandomFloat(50.0f, 70.0f) + vecUp * Math.RandomFloat(100.0f, 150.0f);
			g_EntityFuncs.EjectBrass(vecOrigin, vecVelocity, m_pPlayer.pev.v_angle.y, models::saw_shell, TE_BOUNCE_SHELL);

			if (self.m_iClip <= 0 && m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET)
				m_pPlayer.SetSuitUpdate("!HEV_AMO0", false, 0);

			self.m_flNextPrimaryAttack = g_Engine.time + 0.142f;
			self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 10.0f, 15.0f);
		}

		void SecondaryAttack()
		{
			// don't fire underwater
			if (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0)
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 0.15f;
				return;
			}

			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

			m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
			m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

			m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) - 1);

			g_PlayerFuncs.ScreenShake(m_pPlayer.pev.origin, 7, 150.0, 0.3, 120);
			// m_pPlayer.pev.punchangle.x = -8.0; //Sven Co-op's Grenade Launcher doesn't have any punch angles.

			self.SendWeaponAnim(LAUNCH, 0, pev.body);

			m_pPlayer.SetAnimation(PLAYER_ATTACK1);

			// Manually set M203 Shoot animation on the player
			m_pPlayer.m_Activity = ACT_RELOAD;
			m_pPlayer.pev.frame = 0;
			m_pPlayer.pev.sequence = 148;
			m_pPlayer.ResetSequenceInfo();

			if (g_PlayerFuncs.SharedRandomLong(m_pPlayer.random_seed, 0, 1) != 0)
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/glauncher.wav", 1.0, ATTN_NORM, 0, 98 + Math.RandomLong(0, 4));
			else
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/glauncher2.wav", 1.0, ATTN_NORM, 0, 98 + Math.RandomLong(0, 4));

			Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);

			// we don't add in player velocity anymore.
			if ((m_pPlayer.pev.button & IN_DUCK) != 0)
				g_EntityFuncs.ShootContact(m_pPlayer.pev, m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 1000);								// 800
			else
				g_EntityFuncs.ShootContact(m_pPlayer.pev, m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 1000); // 800

			if (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0)
			{
				m_bGrenadeFire = true;

				m_flGrenadeLaunchTime = g_Engine.time;

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 2.79f; // Launch + Reload duration.
			}
			else
			{
				m_bGrenadeFire = false;

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 1.01f;
				self.m_flTimeWeaponIdle = g_Engine.time + 5.0f; // idle pretty soon after shooting.
			}

			// Low Ammo Warning
			if (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) == 3)
			{
				g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_STATIC, "fvox/ammowarning.wav", 1.0, ATTN_NORM);
			}

			if (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0)
				m_pPlayer.SetSuitUpdate("!HEV_AMO0", false, 0);
		}

		void Reload()
		{
			if (self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0)
				return;

			self.DefaultReload(MAX_CLIP, RELOAD, 3.25f, pev.body);
			self.m_flTimeWeaponIdle = g_Engine.time + 3.25f;
			BaseClass.Reload();
		}

		void ItemPreFrame()
		{
			BaseClass.ItemPreFrame();
		}

		void ItemPostFrame()
		{
			// Speed up player reload anim
			if ((m_bGrenadeFire && g_Engine.time < m_flGrenadeLaunchTime + 2.9f) && (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) >= 0))
				m_pPlayer.pev.framerate = 1.25;

			BaseClass.ItemPostFrame();
		}

		void WeaponIdle()
		{
			if (!self.m_bFireOnEmpty)
				self.ResetEmptySound();

			m_pPlayer.GetAutoaimVector(AUTOAIM_5DEGREES);

			if ((m_bGrenadeFire && g_Engine.time >= m_flGrenadeLaunchTime + 1.0f) && (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0))
			{
				self.SendWeaponAnim(RELOAD2, 0, pev.body);

				if (m_bGrenadeFire)
				{
					m_bGrenadeFire = false;
					m_flGrenadeLaunchTime = 0;
				}

				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/gl_reload.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

				// Manually set M203 Reload animation on the player
				m_pPlayer.m_Activity = ACT_RELOAD;
				m_pPlayer.pev.frame = 0;
				m_pPlayer.pev.sequence = 150;
				m_pPlayer.ResetSequenceInfo();

				self.m_flTimeWeaponIdle = (g_Engine.time + 1.8f) + 5.0f;
			}

			if (self.m_flTimeWeaponIdle <= g_Engine.time)
			{
				int iAnim;
				const float flNextIdle = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0.0, 1.0);

				if (flNextIdle <= 0.66)
				{
					iAnim = IDLE;
					self.m_flTimeWeaponIdle = g_Engine.time + (50.0 / 15.0);
				}
				else
				{
					iAnim = FIDGET;
					self.m_flTimeWeaponIdle = g_Engine.time + (86.0 / 30.0);
				}

				self.SendWeaponAnim(iAnim, 0, pev.body);
			}
		}
	}
}
