/*
 * Emergency Flare Gun
 * Credits: Nero0, KernCore, Mikk, RaptorSKA
 */
// Rewrited by Rizulix for bts_rc (december 2024)

namespace weapon_bts_flaregun
{
	enum btsflaregun_e
	{
		IDLE1 = 0,
		FIDGET,
		SHOOT,
		RELOAD,
		HOLSTER,
		DRAW,
		IDLE2,
		IDLE3
	};

	// Weapon info
	int MAX_CARRY = 6;
	int MAX_CLIP = 1;
	int DEFAULT_GIVE = 3;
	int AMMO_GIVE = MAX_CLIP;
	int AMMO_DROP = AMMO_GIVE;
	int WEIGHT = 15;
	// Weapon HUD
	int SLOT = 1;
	int POSITION = 13;
	// Vars
	float DAMAGE = 35.0f;
	float DURATION = 180.0f;
	float VELOCITY = 1500.0f;
	Vector OFFSET(8.0f, 4.0f, -2.0f); // for projectile

	// const Vector MUZZLE_ORIGIN       = Vector( 16.0, 4.0, -4.0 ); //forward, right, up
	// const string SPRITE_MUZZLE_GRENADE   = "sprites/bts_rc/muzzleflash12.spr";

	class weapon_bts_flaregun : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
	{
		private CBasePlayer @m_pPlayer
		{
			get const
			{
				return get_player();
			}
		}

		private int m_iSpecialReload;
		private int m_fInAttack;

		void Spawn()
		{
			g_EntityFuncs.SetModel(self, self.GetW_Model("models/bts_rc/weapons/w_flaregun.mdl"));
			self.m_iDefaultAmmo = DEFAULT_GIVE;
			self.FallInit();
		}

		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1 = MAX_CARRY;
			info.iAmmo1Drop = AMMO_DROP;
			info.iMaxAmmo2 = -1;
			info.iAmmo2Drop = -1;
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
			return bts_deploy("models/bts_rc/weapons/v_flaregun.mdl", "models/bts_rc/weapons/p_flaregun.mdl", DRAW, "python", 1);
		}

		void Holster(int skiplocal = 0)
		{
			SetThink(null);
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
			// don't fire underwater/without having ammo loaded
			if (m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0)
			{
				self.PlayEmptySound();
				self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
				return;
			}

			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

			// Notify the monsters about the grenade
			m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
			m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;

			--self.m_iClip;

			m_pPlayer.pev.effects |= EF_MUZZLEFLASH; // Add muzzleflash
			pev.effects |= EF_MUZZLEFLASH;

			// player "shoot" animation
			m_pPlayer.SetAnimation(PLAYER_ATTACK1);

			Math.MakeVectors(m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
			Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * OFFSET.x + g_Engine.v_right * OFFSET.y + g_Engine.v_up * OFFSET.z;
			Vector vecVelocity = g_Engine.v_forward * VELOCITY;

			auto flare = FLARE::Shoot(m_pPlayer.pev, vecSrc, vecVelocity, DAMAGE, DURATION);
			flare.pev.scale = 0.5f;
			// CreateMuzzleflash( SPRITE_MUZZLE_GRENADE, MUZZLE_ORIGIN.x, MUZZLE_ORIGIN.y, MUZZLE_ORIGIN.z, 0.05, 128, 20.0 );

			// View model animation
			self.SendWeaponAnim(SHOOT, 0, pev.body);
			// Custom Volume and Pitch
			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "bts_rc/weapons/flaregun_shot1.wav", Math.RandomFloat(0.95f, 1.0f), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf));
			// m_pPlayer.pev.punchangle.x = -10.0; // Recoil
			m_pPlayer.pev.punchangle.x = Math.RandomFloat(-2.0f, -3.0f);

			if (self.m_iClip <= 0 && m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 && g_PlayerClass[m_pPlayer] == PM::HELMET)
				m_pPlayer.SetSuitUpdate("!HEV_AMO0", false, 0);

			self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0f; // Idle pretty soon after shooting.
		}

		void Reload()
		{
			if (self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0)
				return;

			if (self.m_flNextPrimaryAttack > g_Engine.time)
				return;

			self.DefaultReload(MAX_CLIP, RELOAD, 3.5f, pev.body);
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 3.5f;
			SetThink(ThinkFunction(this.FinishAnim));
			pev.nextthink = g_Engine.time + 3.5f;
		}

		void WeaponIdle()
		{
			self.ResetEmptySound();
			m_pPlayer.GetAutoaimVector(AUTOAIM_10DEGREES);

			if (self.m_flTimeWeaponIdle > g_Engine.time)
				return;

			float flRand = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0.0f, 1.0f);
			if (flRand <= 0.5f)
			{
				self.SendWeaponAnim(IDLE1, 0, pev.body);
				self.m_flTimeWeaponIdle = g_Engine.time + 2.33f; // ( 70.0f / 30.0f );
			}
			else if (flRand <= 0.7f)
			{
				self.SendWeaponAnim(IDLE2, 0, pev.body);
				self.m_flTimeWeaponIdle = g_Engine.time + 2.0f; // ( 60.0f / 30.0f );
			}
			else if (flRand <= 0.9f)
			{
				self.SendWeaponAnim(IDLE3, 0, pev.body);
				self.m_flTimeWeaponIdle = g_Engine.time + 2.93f; // ( 88.0f / 30.0f );
			}
			else
			{
				self.SendWeaponAnim(FIDGET, 0, pev.body);
				self.m_flTimeWeaponIdle = g_Engine.time + 5.66f; // ( 170.0f / 30.0f );
			}
		}

		private void FinishAnim()
		{
			SetThink(null);
			self.SendWeaponAnim(DRAW, 0, pev.body);
			BaseClass.Reload();

			switch (Math.RandomLong(0, 1))
			{
				case 0:
					g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "bts_rc/weapons/flaregun_reload1.wav", 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong(0, 0x1f));
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "bts_rc/weapons/flaregun_reload2.wav", 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong(0, 0x1f));
					break;
			}
		}
	}
}
