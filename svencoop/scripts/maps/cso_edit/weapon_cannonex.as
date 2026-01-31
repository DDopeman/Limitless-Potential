// CSO Red Dragon Cannon (weapon_cannonex)
// Assets: Nexon Studios, Valve
// Scripts: Gaftherman, Nero0

bool gold = false; // true to turn on gold model

namespace cso_cannonex
{
	const float RDC_DRAW_TIME = 1.0f;

	const string RDC_FIRE_CLASSNAME = "rdc_fire";
	const string RDC_DRAGON_CLASSNAME = "rdc_dragon";
	const string RDC_DRAGONSPIRIT_CLASSNAME = "rdc_dragon_spirit";
	const string RDC_EXPLOSION_CLASSNAME = "rdc_explosion";
	const string AMMO_TYPE = "cso_cannonrounds";

	const float WEAPON_ATTACH_F = 30.0;
	const float WEAPON_ATTACH_R = 10.0;
	const float WEAPON_ATTACH_U = -5.0;

	enum MODE
	{
		MODE_A = 0,
		MODE_B
	}

	enum ANIMATION
	{
		RDC_IDLE = 0,
		RDC_IDLEB,
		RDC_DRAW,
		RDC_DRAWB,
		RDC_SHOOTA,
		RDC_SHOOTB,
		RDC_D_TRANSFORM,
		RDC_D_RELOAD1,
		RDC_D_RELOAD2
	}

	enum MODEL
	{
		RDC_P_MODEL = 0,
		RDC_P_MODELB,
		RDC_W_MODEL,
		RDC_W_MODELB
	}

	const string MODEL_V = gold ? "models/cso_edit/v_cannonexgold.mdl" : "models/cso_edit/v_cannonex.mdl";
	const string MODEL_P = "models/cso_edit/p_cannonex.mdl";
	const string MODEL_PB = "models/cso_edit/p_cannonexb.mdl";
	const string MODEL_W = "models/cso_edit/w_cannonex.mdl";
	const string MODEL_WB = "models/cso_edit/w_cannonexb.mdl";
	const string MODEL_AMMO = "models/w_argrenade.mdl";
	const int MAG_BDYGRP = 1;

	array<string> RDC_Models =
		{
			MODEL_P,
			MODEL_PB,
			MODEL_W,
			MODEL_WB,
			MODEL_V};

	const string SOUND_SHOOTA = "cso_edit/cannonex_shoota.wav";
	const string SOUND_RELOAD1 = "cso_edit/cannonex_d_reload1.wav";
	const string SOUND_RELOAD2 = "cso_edit/cannonex_d_reload2.wav";
	const string SOUND_TRANSFORM = "cso_edit/cannonex_dtransform.wav";
	const string SOUND_DRAGON_FIRE_END = "cso_edit/cannonex_dragon_fire_end.wav";
	const string SOUND_EXPLO = "cso_edit/cannonexplo.wav";

	array<string> RDC_Sounds =
		{
			SOUND_SHOOTA,
			SOUND_RELOAD1,
			SOUND_RELOAD2,
			SOUND_TRANSFORM,
			SOUND_DRAGON_FIRE_END,
			SOUND_EXPLO};

	const string EFFECT_DRAGON = "models/cso_edit/cannonexdragon.mdl";
	const string EFFECT_DRAGONFX = "models/cso_edit/p_cannonexdragonfx.mdl";
	const string EFFECT_EXPLO = "models/cso_edit/p_cannonexplo.mdl";

	array<string> RDC_Effects =
		{
			EFFECT_DRAGON,
			EFFECT_DRAGONFX,
			EFFECT_EXPLO};

	const string SPRITE_WEAPON_CANNONEX = "sprites/cso_edit/weapon_cannonex.txt";
	const string SPRITE_640HUD2_47 = "sprites/cso_edit/640hud2_47.spr";
	const string SPRITE_640HUD161 = "sprites/cso_edit/640hud161.spr";
	const string SPRITE_FIRE_CANNON = "sprites/cso_edit/fire_cannon.spr";

	array<string> RDC_Sprites =
		{
			SPRITE_WEAPON_CANNONEX,
			SPRITE_640HUD2_47,
			SPRITE_640HUD161,
			SPRITE_FIRE_CANNON};

	namespace weapon_info
	{
		const int cvar_rdc_ammo = gold ? 120 : 60;
		const int cvar_rdc_ammo_give = 5;
		const float cvar_rdc_dmg = gold ? 700 : 500.0f;
		const float cvar_rdc_duration = gold ? 30 : 20.0f;
		const float cvar_rdc_cooldown = gold ? 15 : 20.0f;
		const int cvar_rdc_refill = gold ? 30 : 20;
		const float cvar_one_round = gold ? 0.0f : 0.0f;

		const int cvar_rdc_slot = 4;
		const int cvar_rdc_position = 22;
		const int cvar_rdc_weight = 20;
	}

	class weapon_cannonex : CBaseCSOWeapon // ScriptBasePlayerWeaponEntity // test weapon
	{
		private EHandle dragon_spirit;
		private CBasePlayer @m_pPlayer = null;
		private array<int> m_iBlood(2);
		private int g_explo_spr;
		private MODE m_iMode = MODE_A;

		void Spawn()
		{
			self.Precache();

			g_EntityFuncs.SetModel(self, MODEL_W);
			self.m_iDefaultAmmo = weapon_info::cvar_rdc_refill;
			self.m_flCustomDmg = (pev.dmg == 0) ? weapon_info::cvar_rdc_dmg : pev.dmg;
			pev.body = 0;
			self.FallInit();
		}

		void Precache()
		{
			self.PrecacheCustomModels();

			for (uint i = 0; i < RDC_Models.length(); i++)
			{
				g_Game.PrecacheModel(RDC_Models[i]);
				g_Game.PrecacheGeneric(RDC_Models[i]);
			}

			for (uint i = 0; i < RDC_Sounds.length(); i++)
			{
				g_SoundSystem.PrecacheSound(RDC_Sounds[i]);
				g_Game.PrecacheGeneric("sound/" + RDC_Sounds[i]);
			}

			for (uint i = 0; i < RDC_Effects.length(); i++)
			{
				g_Game.PrecacheModel(RDC_Effects[i]);
				g_Game.PrecacheGeneric(RDC_Effects[i]);
			}

			g_SoundSystem.PrecacheSound("items/9mmclip1.wav");
			g_SoundSystem.PrecacheSound("weapons/357_cock1.wav");

			g_Game.PrecacheGeneric(SPRITE_WEAPON_CANNONEX);
			g_Game.PrecacheGeneric(SPRITE_640HUD2_47);
			g_Game.PrecacheGeneric(SPRITE_640HUD161);

			m_iBlood[0] = g_Game.PrecacheModel("sprites/blood.spr");
			m_iBlood[1] = g_Game.PrecacheModel("sprites/bloodspray.spr");
			g_explo_spr = g_Game.PrecacheModel("sprites/ef_cannonex.spr");

			g_Game.PrecacheOther("rdc_fire");
		}

		bool GetItemInfo(ItemInfo& out info)
		{
			info.iMaxAmmo1 = weapon_info::cvar_rdc_ammo;
			info.iMaxAmmo2 = -1;
			info.iMaxClip = WEAPON_NOCLIP;
			info.iSlot = weapon_info::cvar_rdc_slot;
			info.iPosition = weapon_info::cvar_rdc_position;
			info.iFlags = ITEM_FLAG_NOAUTOSWITCHEMPTY;
			info.iWeight = weapon_info::cvar_rdc_weight;
			return true;
		}

		bool AddToPlayer(CBasePlayer @pPlayer)
		{
			if (!BaseClass.AddToPlayer(pPlayer))
				return false;

			@m_pPlayer = pPlayer;
			NetworkMessage cannonex(MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict());
			cannonex.WriteLong(g_ItemRegistry.GetIdForName("weapon_cannonex"));
			cannonex.End();
			return true;
		}

		bool PlayEmptySound()
		{
			if (self.m_bPlayEmptySound)
			{
				self.m_bPlayEmptySound = false;
				g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8f, ATTN_NORM);
			}
			return false;
		}

		bool Deploy()
		{
			bool bResult;
			{
				bResult = self.DefaultDeploy(self.GetV_Model(MODEL_V), self.GetP_Model((m_iMode == MODE_A ? MODEL_P : MODEL_PB)), m_iMode == MODE_A ? RDC_DRAW : RDC_DRAWB, "saw");
				self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + RDC_DRAW_TIME;
				return bResult;
			}
		}

		void PrimaryAttack()
		{
			int ammo1 = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
			if (ammo1 <= 0)
				return;

			// self.SendWeaponAnim(m_iMode == MODE_A ? RDC_SHOOTA : RDC_SHOOTB, 0, 0);
			// g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_SHOOTA, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			m_pPlayer.SetAnimation(PLAYER_ATTACK1);
			// m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			// m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

			--ammo1;
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo1);

			switch (m_iMode)
			{
				case MODE_A:
				{
					self.SendWeaponAnim(RDC_SHOOTA, 0, 0);
					g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_SHOOTA, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					break;
				}
				case MODE_B:
				{
					CBaseEntity @pTarget = @g_EntityFuncs.FindEntityByTargetname(null, "rdc_dragon" + string(m_pPlayer.entindex()));

					if (pTarget !is null && pTarget.pev.fuser1 - g_Engine.time <= 0.0)
					{
						m_iMode = MODE_A;
						self.SendWeaponAnim(RDC_D_RELOAD1, 0, 0);
						g_EntityFuncs.Remove(pTarget);
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_RELOAD1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

						m_pPlayer.pev.weaponmodel = MODEL_P;

						SetThink(ThinkFunction(this.BackToModeB));
						pev.nextthink = g_Engine.time + 2.5f;
					}
					else
					{
						self.SendWeaponAnim(RDC_SHOOTB, 0, 0);
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_SHOOTA, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

						m_pPlayer.pev.weaponmodel = MODEL_PB;
					}
					break;
				}
			}
			MakeFireEffect();
			self.pev.punchangle = Vector(Math.RandomFloat(-7.0, -3.5), Math.RandomFloat(-3.0, 3.0), 0.0f);
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 3.5f;
		}

		void BackToModeB()
		{
			if (!m_pPlayer.IsAlive())
				return;

			self.SendWeaponAnim(RDC_D_RELOAD2);

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + 2.5f;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.5f;
		}

		void MakeFireEffect()
		{
			const int MAX_FIRE = 12;
			Vector vecStartOrigin;
			array<Vector> vecTargetOrigin(MAX_FIRE);
			array<float> Speed(MAX_FIRE);

			// -- Left
			get_position(100.0, Math.RandomFloat(-10.0, -30.0), WEAPON_ATTACH_U, vecTargetOrigin[0]);
			Speed[0] = 150.0;
			get_position(100.0, Math.RandomFloat(-10.0, -30.0), WEAPON_ATTACH_U, vecTargetOrigin[1]);
			Speed[1] = 180.0;
			get_position(100.0, Math.RandomFloat(-10.0, -30.0), WEAPON_ATTACH_U, vecTargetOrigin[2]);
			Speed[2] = 210.0;
			get_position(100.0, Math.RandomFloat(-10.0, -30.0), WEAPON_ATTACH_U, vecTargetOrigin[3]);
			Speed[3] = 240.0;
			get_position(100.0, Math.RandomFloat(-10.0, -30.0), WEAPON_ATTACH_U, vecTargetOrigin[4]);
			Speed[4] = 300.0;

			// -- Center
			get_position(100.0, 0.0, WEAPON_ATTACH_U, vecTargetOrigin[5]);
			Speed[5] = 150.0;
			get_position(100.0, 0.0, WEAPON_ATTACH_U, vecTargetOrigin[6]);
			Speed[6] = 300.0;

			// -- Right
			get_position(100.0, Math.RandomFloat(10.0, 30.0), WEAPON_ATTACH_U, vecTargetOrigin[7]);
			Speed[7] = 150.0;
			get_position(100.0, Math.RandomFloat(10.0, 30.0), WEAPON_ATTACH_U, vecTargetOrigin[8]);
			Speed[8] = 180.0;
			get_position(100.0, Math.RandomFloat(10.0, 30.0), WEAPON_ATTACH_U, vecTargetOrigin[9]);
			Speed[9] = 210.0;
			get_position(100.0, Math.RandomFloat(10.0, 30.0), WEAPON_ATTACH_U, vecTargetOrigin[10]);
			Speed[10] = 240.0;
			get_position(100.0, Math.RandomFloat(10.0, 30.0), WEAPON_ATTACH_U, vecTargetOrigin[11]);
			Speed[11] = 300.0;

			for (uint i = 0; i < MAX_FIRE; i++)
			{
				get_position(Math.RandomFloat(30.0, 40.0), 0.0, WEAPON_ATTACH_U, vecStartOrigin);
				CreateFire(vecStartOrigin, vecTargetOrigin[i], Speed[i]);
			}
		}

		void CreateFire(Vector vecOrigin, Vector vecTargetOrigin, float flSpeed, bool dragon = false)
		{
			Vector vecAngles = pev.angles; //? v_angles
			Vector vecVelocity;
			vecAngles.z = Math.RandomFloat(0, 340);

			CBaseEntity @pEnt = g_EntityFuncs.Create("rdc_fire", vecOrigin, vecAngles, false, m_pPlayer.edict());

			if (pEnt is null || !g_EntityFuncs.IsValidEntity(pEnt.edict()))
				return;

			get_speed_vector(vecOrigin, vecTargetOrigin, flSpeed, vecVelocity);

			rdc_fire @cf = cast<rdc_fire @>(CastToScriptClass(@pEnt));
			cf.dragon = dragon;
			cf.pev.velocity = vecVelocity;
		}

		void get_position(float forw, float right, float up, Vector&out vOut)
		{
			Vector vOrigin, vAngle, vForward, vRight, vUp;

			vOrigin = m_pPlayer.pev.origin;
			vUp = m_pPlayer.pev.view_ofs;	// for player, can also use GetGunPosition()
			vOrigin = vOrigin + vUp;
			vAngle = m_pPlayer.pev.v_angle; // if normal entity: use pev.angles

			g_EngineFuncs.AngleVectors(vAngle, vForward, vRight, vUp);

			vOut.x = vOrigin.x + vForward.x * forw + vRight.x * right + vUp.x * up;
			vOut.y = vOrigin.y + vForward.y * forw + vRight.y * right + vUp.y * up;
			vOut.z = vOrigin.z + vForward.z * forw + vRight.z * right + vUp.z * up;
		}

		/*
		void SecundaryAttack()
		{
			self.SendWeaponAnim(m_iMode == MODE_A ? RDC_SHOOTA : RDC_SHOOTB, 0, 0);
			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_SHOOTA, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 3.5f;
		}
		*/

		void SecondaryAttack()
		{
			int ammo3 = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
			if (ammo3 <= 0)
				return;

			--ammo3;
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, ammo3);

			if (m_iMode == MODE_A)
			{
				dragon_spirit = MakeDragonSpirit();
				m_iMode = MODE_B;
				self.SendWeaponAnim(RDC_D_TRANSFORM, 0, 0);

				m_pPlayer.pev.weaponmodel = MODEL_PB;
			}

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 3.5f;
		}

		EHandle MakeDragonSpirit()
		{
			return EHandle(g_EntityFuncs.Create("rdc_dragon_spirit", m_pPlayer.pev.origin, g_vecZero, false, m_pPlayer.edict()));
		}
	}

	class rdc_dragon_spirit : ScriptBaseAnimating
	{
		void Spawn()
		{
			self.Precache();

			pev.movetype = MOVETYPE_FOLLOW;
			pev.solid = SOLID_NOT;
			@pev.aiment = @pev.owner;
			pev.animtime = g_Engine.time;
			pev.framerate = 1.0f;
			pev.sequence = 1;
			pev.fuser1 = g_Engine.time + 3.5f;

			g_Game.AlertMessage(at_console, "Dragon Name: " + "rdc_dragon_spirit" + string(g_EngineFuncs.IndexOfEdict(pev.owner)) + "\n");
			g_EntityFuncs.SetModel(self, EFFECT_DRAGONFX);
			g_EntityFuncs.SetSize(pev, g_vecZero, g_vecZero);

			pev.nextthink = g_Engine.time + 0.1f;
		}

		void Precache()
		{
			g_Game.PrecacheModel(EFFECT_DRAGONFX);
			g_Game.PrecacheGeneric(EFFECT_DRAGONFX);
		}

		void Think()
		{
			if (g_Engine.time < pev.fuser1)
			{
				pev.nextthink = g_Engine.time + 0.1f;
				return;
			}

			Vector vecOrigin = Vector(pev.owner.vars.origin.x, pev.owner.vars.origin.y, pev.owner.vars.origin.z + 75.0f);

			CBaseEntity @pEnt = g_EntityFuncs.Create("rdc_dragon", vecOrigin, g_vecZero, false, @pev.owner);

			if (pEnt is null || !g_EntityFuncs.IsValidEntity(pEnt.edict()))
				return;

			g_EntityFuncs.Remove(self);
		}
	}

	class rdc_dragon : ScriptBaseAnimating
	{
		void Spawn()
		{
			self.Precache();

			pev.movetype = MOVETYPE_FLY;
			pev.solid = SOLID_NOT;
			pev.animtime = g_Engine.time;
			pev.framerate = 1.0f;
			pev.sequence = 1;
			pev.fuser1 = g_Engine.time + weapon_info::cvar_rdc_duration;
			pev.targetname = "rdc_dragon" + string(g_EngineFuncs.IndexOfEdict(pev.owner));

			g_EntityFuncs.SetModel(self, EFFECT_DRAGON);
			g_EntityFuncs.SetSize(pev, g_vecZero, g_vecZero);

			pev.nextthink = g_Engine.time + 0.1f;
		}

		void Precache()
		{
			g_Game.PrecacheModel(EFFECT_DRAGON);
			g_Game.PrecacheGeneric(EFFECT_DRAGON);
		}

		void Think()
		{
			Vector vecOrigin, vecTargetOrigin;
			float flSpeed, flRate;

			flRate = 0.2;
			vecOrigin = pev.origin;
			flSpeed = pev.owner.vars.maxspeed - 5.0;

			fm_get_aim_origin(vecTargetOrigin);
			npc_turntotarget(vecTargetOrigin);

			if (pev.fuser1 - g_Engine.time >= 0.0 && pev.fuser2 - g_Engine.time <= 0.0)
			{
				CreateFire(vecOrigin, vecTargetOrigin, 300.0, true);
				pev.fuser2 = g_Engine.time + flRate;
			}

			hook_ent2(flSpeed);
			pev.nextthink = g_Engine.time + 0.1f;
		}

		void CreateFire(Vector vecOrigin, Vector vecTargetOrigin, float flSpeed, bool dragon = false)
		{
			Vector vecAngles = pev.owner.vars.angles; //? v_angles
			Vector vecVelocity;
			vecAngles.z = Math.RandomFloat(0, 340);

			CBaseEntity @pEnt = g_EntityFuncs.Create("rdc_fire", vecOrigin, vecAngles, false, @pev.owner);

			if (pEnt is null || !g_EntityFuncs.IsValidEntity(pEnt.edict()))
				return;

			get_speed_vector(vecOrigin, vecTargetOrigin, flSpeed, vecVelocity);

			rdc_fire @cf = cast<rdc_fire @>(CastToScriptClass(@pEnt));
			cf.dragon = dragon;
			cf.pev.velocity = vecVelocity;
		}

		void hook_ent2(float flSpeed)
		{
			Vector vecVelocity, vecEntOrigin, vecOrigin;
			float flDist, flTime;

			vecEntOrigin = pev.origin;
			vecOrigin = pev.owner.vars.origin;

			flDist = (vecEntOrigin - vecOrigin).Length();
			flTime = flDist / flSpeed;

			if (pev.fuser1 - g_Engine.time >= 0.0)
			{
				vecOrigin.z += 50.0;

				if (flDist >= 20.0)
				{
					vecVelocity.x = (vecOrigin.x - vecEntOrigin.x) / flTime;
					vecVelocity.y = (vecOrigin.y - vecEntOrigin.y) / flTime;
					vecVelocity.z = (vecOrigin.z - vecEntOrigin.z) / flTime;
				}
				else
				{
					vecVelocity.x = 1.0;
					vecVelocity.y = 1.0;
					vecVelocity.z = 1.0;
				}
			}
			else
			{
				if (flDist >= 150.0)
				{
					vecVelocity.x = (vecOrigin.x - vecEntOrigin.x) / flTime;
					vecVelocity.y = (vecOrigin.y - vecEntOrigin.y) / flTime;
					vecVelocity.z = (vecOrigin.z - vecEntOrigin.z) / flTime + 125;
				}
				else
				{
					vecVelocity.x = 1.0;
					vecVelocity.y = 1.0;
					vecVelocity.z = 1.0;
				}
			}

			pev.velocity = vecVelocity;
		}

		void get_position(float forw, float right, float up, Vector&out vOut)
		{
			Vector vOrigin, vAngle, vForward, vRight, vUp;

			vOrigin = pev.owner.vars.origin;
			vUp = pev.owner.vars.view_ofs;	 // for player, can also use GetGunPosition()
			vOrigin = vOrigin + vUp;
			vAngle = pev.owner.vars.v_angle; // if normal entity: use pev.angles

			g_EngineFuncs.AngleVectors(vAngle, vForward, vRight, vUp);

			vOut.x = vOrigin.x + vForward.x * forw + vRight.x * right + vUp.x * up;
			vOut.y = vOrigin.y + vForward.y * forw + vRight.y * right + vUp.y * up;
			vOut.z = vOrigin.z + vForward.z * forw + vRight.z * right + vUp.z * up;
		}

		void get_speed_vector(const Vector&in origin1, const Vector&in origin2, const float&in speed, Vector&out new_velocity)
		{
			new_velocity.x = origin2.x - origin1.x;
			new_velocity.y = origin2.y - origin1.y;
			new_velocity.z = origin2.z - origin1.z;

			float num = sqrt(speed * speed / (new_velocity.y * new_velocity.y + new_velocity.x * new_velocity.x + new_velocity.z * new_velocity.z));
			new_velocity.y *= num;
			new_velocity.x *= num;
			new_velocity.z *= num;
		}

		void fm_get_aim_origin(Vector& out vecTargetOrigin)
		{
			Vector vecStart, vecViewofs;
			vecStart = pev.owner.vars.origin;
			vecViewofs = pev.owner.vars.view_ofs;
			vecStart = vecStart + vecViewofs;

			Vector vecDest;
			vecDest = pev.owner.vars.v_angle;

			g_EngineFuncs.MakeVectors(vecDest);
			vecDest = g_Engine.v_forward * 9999;
			vecDest = vecDest + vecStart;

			TraceResult tr;
			g_Utility.TraceLine(vecStart, vecDest, dont_ignore_monsters, @pev.owner, tr);
			vecTargetOrigin = tr.vecEndPos;
		}

		void npc_turntotarget(const Vector& in vecTargetOrigin)
		{
			Vector vecDirection = vecTargetOrigin - pev.origin;

			Vector vecIdealAngles = Math.VecToAngles(vecDirection);

			Vector vecCurrentAngles = pev.angles;
			vecCurrentAngles.y = vecIdealAngles.y;
			pev.angles = vecCurrentAngles;
		}
	}

	class rdc_fire : ScriptBaseAnimating
	{
		int iMaxFrames = 0;
		bool dragon = false;
		bool stayFire = false;

		void Spawn()
		{
			self.Precache();

			pev.movetype = MOVETYPE_FLY;
			pev.rendermode = kRenderTransAdd;
			pev.renderamt = 250.0f;
			pev.scale = dragon ? 0.1f : 1.0f;
			pev.gravity = 0.01f;
			pev.solid = SOLID_TRIGGER;
			pev.dmg = weapon_info::cvar_rdc_dmg;
			pev.frame = 0;
			pev.framerate = 1.0f;

			pev.fuser1 = g_Engine.time;
			pev.fuser2 = dragon ? 1.5f : 3.5f;
			pev.fuser3 = g_Engine.time;

			g_EntityFuncs.SetModel(self, SPRITE_FIRE_CANNON);
			g_EntityFuncs.SetSize(pev, Vector(-1.0f, -1.0f, -1.0f), Vector(1.0f, 1.0f, 1.0f));

			pev.nextthink = g_Engine.time + 0.05f;
		}

		void Precache()
		{
			iMaxFrames = g_EngineFuncs.ModelFrames(g_Game.PrecacheModel(SPRITE_FIRE_CANNON)) - 1;
		}

		/* // Old Think function, kept for reference
		void Think()
		{
			float flElapsedTime = g_Engine.time - pev.fuser1;
			if (flElapsedTime >= pev.fuser2)
			{
				g_EntityFuncs.Remove(self);
				return;
			}

			float difference = flElapsedTime / pev.fuser2;
			pev.renderamt = int(250.0f * (1.0f - difference));
			pev.scale = (dragon ? 0.1f : 1.0f) * (1.0f - difference);
			pev.dmg = 10.0f * (1.0f - difference);
			pev.frame = iMaxFrames * (1.0f - difference);

			if (stayFire && pev.fuser4 < g_Engine.time)
			{
				g_WeaponFuncs.RadiusDamage(pev.origin, self.pev, pev.owner.vars, pev.dmg / 2, pev.dmg * 2.5f, CLASS_NONE, DMG_BURN);
				pev.fuser4 = g_Engine.time + 0.25f;
			}

			pev.fuser3 = g_Engine.time;
			pev.nextthink = g_Engine.time + 0.05f;
		}
		*/
		void Think()
		{
			float flFrame, flNextThink, flScale;
			flFrame = pev.frame;
			flScale = pev.scale;

			// effect exp
			if (pev.movetype == MOVETYPE_NONE)
			{
				flNextThink = 0.0015f;
				flFrame += 0.5;

				if (flFrame > iMaxFrames)
				{
					g_EntityFuncs.Remove(self);
					return;
				}
			}
			// effect normal
			else
			{
				flNextThink = 0.045;

				flFrame += 0.5;
				flScale += 0.01;

				flFrame = Math.min(iMaxFrames, flFrame);
				flScale = Math.min(1.5f, flFrame);
			}

			pev.frame = flFrame;
			pev.scale = flScale;
			pev.nextthink = g_Engine.time + flNextThink;

			// time remove
			float flTimeRemove = pev.fuser1;
			if (g_Engine.time >= flTimeRemove)
			{
				float flAmount = pev.renderamt;
				if (flAmount <= 5.0f)
				{
					g_EntityFuncs.Remove(self);
					return;
				}
				else
				{
					flAmount -= 5.0f;
					pev.renderamt = flAmount;
				}
			}
		}

		/* 		// Old Touch function, kept for reference
		void Touch(CBaseEntity@ pOther)
		{
			if (pOther.GetClassname() == self.GetClassname() || pOther.edict() is pev.owner)
				return;

			if (!stayFire)
			{
				pOther.TakeDamage(self.pev, pev.owner.vars, pev.dmg, DMG_BURN);
			}

			pev.movetype = MOVETYPE_NONE;
			pev.velocity = g_vecZero;
			stayFire = true;
		}
		*/
		void Touch(CBaseEntity @pOther)
		{
			if (pOther.GetClassname() == self.GetClassname() || pOther.edict() is pev.owner)
				return;

			pev.movetype = MOVETYPE_NONE;
			pev.solid = SOLID_NOT;
			// make_victim_effects(iTouchedEnt, DMG_BURN, 226, 88, 34)
			// fm_create_velocity_vector(iTouchedEnt, id, 50.0)
			pOther.TakeDamage(pev.owner.vars, pev.owner.vars, pev.dmg, DMG_NEVERGIB | DMG_BURN);
		}
	}

	class CANNONEX_MAG : ScriptBasePlayerAmmoEntity
	{
		void Spawn()
		{
			g_EntityFuncs.SetModel(self, MODEL_AMMO);

			pev.scale = 1.25;

			BaseClass.Spawn();
		}

		bool AddAmmo(CBaseEntity @pOther)
		{
			int iGive;

			iGive = weapon_info::cvar_rdc_ammo_give;

			if (pOther.GiveAmmo(iGive, AMMO_TYPE, weapon_info::cvar_rdc_ammo) != -1)
			{
				g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM);
				return true;
			}

			return false;
		}
	}

	string GetName()
	{
		return "weapon_cannonex";
	}

	string GetAmmoName()
	{
		return "ammo_cannonex";
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity("cso_cannonex::rdc_fire", "rdc_fire");
		g_CustomEntityFuncs.RegisterCustomEntity("cso_cannonex::rdc_dragon_spirit", "rdc_dragon_spirit");
		g_CustomEntityFuncs.RegisterCustomEntity("cso_cannonex::rdc_dragon", "rdc_dragon");
		g_CustomEntityFuncs.RegisterCustomEntity("cso_cannonex::weapon_cannonex", GetName());
		g_CustomEntityFuncs.RegisterCustomEntity("cso_cannonex::CANNONEX_MAG", GetAmmoName());
		g_ItemRegistry.RegisterWeapon(GetName(), "cso_edit", AMMO_TYPE, "", GetAmmoName());
		g_Game.PrecacheOther("weapon_cannonex");
		// g_CustomEntityFuncs.RegisterCustomEntity("cso_cannonex::CANNONEX_MAG", GetAmmoName());
	}
}
