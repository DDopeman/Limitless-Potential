/* 
* Custom Player Medkit for bts_rc (january 2025)
* Credits: Gaftherman
* Ref: https://github.com/wootguy/SevenKewp/blob/0fd4ca7d7598712e122aeef83e8a4f88150301c4/dlls/weapon/CMedkit.cpp
*      https://github.com/Rizulix/Classic-Weapons/blob/main/scripts/maps/opfor/weapon_ofshockrifle.as
*      && kmkz && Rizulix
*/

namespace weapon_bts_medkit
{
    enum medkit_e
    {
        IDLE = 0,
        LONGIDLE,
        LONGUSE,
        SHORTUSE,
        HOLSTER,
        DRAW,
    };

    // Weapon info
    const int MAX_CARRY = 100;
    const int MAX_CARRY2 = WEAPON_NOCLIP;
    const int MAX_CLIP = WEAPON_NOCLIP;
    const int MAX_DROP = 10;
    const int DEFAULT_GIVE = 50;
    const int AMMO_DROP = 10;
    const int AMMO_DROP2 = WEAPON_NOCLIP;
    const int WEIGHT = 0;

    // Weapon HUD
    const int SLOT = 0;
    const int POSITION = 14;

    // Vars
    const int HEAL_AMMOUNT = 10;
    const int REVIVE_COST = 49;
    const int VOLUME = 128;
    const int REVIVE_RADIUS = 64;
    const int RECHARGE_AMOUNT = 1;
    const float RECHARGE_DELAY = 0.6f;

    class weapon_bts_medkit : ScriptBasePlayerWeaponEntity, bts_rc_base_weapon
    {
        private CBasePlayer@ m_pPlayer { get const { return get_player(); } }

        private float m_reviveChargedTime; // time when target will be revive charge will complete
        private float m_rechargeTime; // time until regenerating ammo

        void Spawn()
        {
            g_EntityFuncs.SetModel(self, self.GetW_Model("models/bts_rc/weapons/w_pmedkit.mdl"));
            self.m_iDefaultAmmo = DEFAULT_GIVE;
            self.FallInit();
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = MAX_CARRY;
            info.iAmmo1Drop = AMMO_DROP;
            info.iMaxAmmo2 = MAX_CARRY2;
            info.iAmmo2Drop = AMMO_DROP2;
            info.iMaxClip = MAX_CLIP;
            info.iSlot = SLOT;
            info.iPosition = POSITION;
            info.iId = g_ItemRegistry.GetIdForName( self.GetClassname() );
            info.iFlags = m_flags;
            info.iWeight = WEIGHT;
            return true;
        }

        bool CanDeploy()
        {
            return true;
        }

        bool Deploy()
        {
            return bts_deploy( "models/bts_rc/weapons/v_medkit.mdl", "models/bts_rc/weapons/p_medkit.mdl", DRAW, "trip", 1, 0.6f );
        }

        void Holster( int skiplocal /*= 0*/ )
        {
            m_pPlayer.m_flNextAttack = g_Engine.time + 0.5f;
            self.SendWeaponAnim( HOLSTER );
            BaseClass.Holster( skiplocal );
        }

        void AttachToPlayer(CBasePlayer@ pPlayer)
        {
            if (self.m_iDefaultAmmo == 0)
            self.m_iDefaultAmmo = 1;

            BaseClass.AttachToPlayer(pPlayer);
        }

        void ItemPreFrame()
        {
            if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) == MAX_CARRY)
                return;
            
            if((m_pPlayer.pev.button & IN_USE) == 0)
                return;

            if(m_pPlayer.pev.health < m_pPlayer.pev.max_health)
                return;

            TraceResult tr;
            Math.MakeVectors(m_pPlayer.pev.v_angle);
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecEnd = vecSrc + g_Engine.v_forward * 64;
            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

            if(tr.pHit is null)
                return;

            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
            bool blDecrease = false;
            float flLastHealth = 0.0f;

            if(pEntity.GetClassname() != "func_healthcharger")
                return;

            if(pEntity.pev.frame == 1)
                return;

            if(m_pPlayer.pev.health >= m_pPlayer.pev.max_health)
            {
                flLastHealth = m_pPlayer.pev.health;
                blDecrease = true;
                m_pPlayer.pev.health = m_pPlayer.pev.max_health - 0.45;
            }

            int iFloor = int(Math.Floor( m_pPlayer.pev.health ));
            pEntity.Use(m_pPlayer, m_pPlayer, USE_ON);
            iFloor = int(m_pPlayer.pev.health - iFloor);

            if(iFloor > 0)
            {
                m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + iFloor);

                if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > MAX_CARRY)
                {
                    m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, MAX_CARRY);
                    m_rechargeTime = g_Engine.time + RECHARGE_DELAY;
                }
            }
            
            if(blDecrease)
                m_pPlayer.pev.health = flLastHealth;

            m_pPlayer.pev.button &= ~IN_USE;
            m_pPlayer.m_afButtonPressed &= ~IN_USE;

            BaseClass.ItemPreFrame();
        }

        void InactiveItemPostFrame()
        {
            RechargeAmmo();
            BaseClass.InactiveItemPostFrame();
        }

        void WeaponIdle()
        {
            if(m_reviveChargedTime != 0.0f)
            {
                m_reviveChargedTime = 0.0f;
                self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM);
            }

            if(self.m_flTimeWeaponIdle > g_Engine.time)
                return;

            int iAnim;
            float flRand = g_PlayerFuncs.SharedRandomFloat(m_pPlayer.random_seed, 0.0f, 1.0f);

            if(flRand <= 0.2f)
            {
                iAnim = IDLE;
                self.m_flTimeWeaponIdle = g_Engine.time + 1.2*2;
            }
            else
            {
                iAnim = LONGIDLE;
                self.m_flTimeWeaponIdle = g_Engine.time + 2.4*2;
            }

            self.SendWeaponAnim(iAnim, 0, pev.body);
        }

        // void GiveScorePoints(entvars_t@ pevAttacker, entvars_t@ pevInflictor, const float &in flDamage)
        // {
        //     float flFrags = Math.min( 4, (flDamage / pevAttacker.pev.max_health) * (4 * (pevAttacker.pev.max_health / pevInflictor.pev.max_health)) );
        //     pevAttacker.frags += flFrags;
        // }

        void PrimaryAttack()
        {
            TraceResult tr;
            Math.MakeVectors(m_pPlayer.pev.v_angle);
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecEnd = vecSrc + g_Engine.v_forward * 32;

            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

            if (tr.flFraction >= 1.0)
            {
                g_Utility.TraceHull(vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr);
            }

            CBaseMonster@ pMonster = (tr.pHit !is null) ? g_EntityFuncs.Instance( tr.pHit ).MyMonsterPointer() : null;
            int iAmmoLeft = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);

            if(pMonster is null || iAmmoLeft <= 0)
                return;

            float flHealthAmount = Math.min(HEAL_AMMOUNT, pMonster.pev.max_health - pMonster.pev.health);

            // slowly lower pitch
            if (iAmmoLeft < HEAL_AMMOUNT*2) 
            {
                flHealthAmount = Math.min(HEAL_AMMOUNT*0.5f, flHealthAmount);
            }
            else if (iAmmoLeft < HEAL_AMMOUNT) 
            {
                flHealthAmount = Math.min(HEAL_AMMOUNT*0.2f, flHealthAmount);
            }

            flHealthAmount = int(Math.Ceil(Math.min(float(iAmmoLeft), flHealthAmount)));

            if(pMonster.IsAlive() && pMonster.IRelationship( m_pPlayer ) == R_AL && CanHealTarget(pMonster) && flHealthAmount > 0)
            {
                m_pPlayer.SetAnimation(PLAYER_ATTACK1);
                self.SendWeaponAnim(SHORTUSE, 0, pev.body);
                m_pPlayer.m_iWeaponVolume = VOLUME;

                pMonster.TakeHealth(flHealthAmount, DMG_MEDKITHEAL);
                // m_pPlayer.GetPointsForDamage(-flHealthAmount);

                //https://github.com/KernCore91/-SC-Cry-of-Fear-Weapons-Project/blob/aeb624bd55b890c90df20f993a76979c86eac25b/scripts/maps/cof/special/weapon_cofsyringe.as#L306-L307
                pMonster.Forget( bits_MEMORY_PROVOKED | bits_MEMORY_SUSPICIOUS );
                pMonster.ClearSchedule();

                m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, int(Math.Ceil(iAmmoLeft - flHealthAmount)));
            
                int pitch = 100;

                if (iAmmoLeft < HEAL_AMMOUNT * 2) 
                {
                    pitch = int((float(iAmmoLeft) / (HEAL_AMMOUNT*2)) * 20.5f + 80);
                }

                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "items/medshot4.wav", 1.0f, ATTN_NORM, 0, pitch);

                self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
            }
        }

        void SecondaryAttack()
        {
            if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= REVIVE_COST) 
            {
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM);
                self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                m_reviveChargedTime = 0;
                return;
            }

            CBaseEntity@ pBestTarget = null;
            float flBestDist = REVIVE_RADIUS;

            CBaseEntity@ pEntity;
            while ((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, m_pPlayer.GetOrigin(), REVIVE_RADIUS, "*", "classname")) !is null)
            {
                if (pEntity is null || !IsValidReviveTarget(pEntity))
                    continue;

                float flDist = (pEntity.pev.origin - m_pPlayer.pev.origin).Length();

                if (pBestTarget is null)
                {
                    flBestDist = flDist;
                    @pBestTarget = pEntity;
                    continue;
                }

                if (IsBetterReviveTarget(pEntity, pBestTarget, flDist, flBestDist))
                {
                    flBestDist = flDist;
                    @pBestTarget = pEntity;
                }
            }

            if (pBestTarget is null) 
            {
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, ATTN_NORM);
                self.m_flNextSecondaryAttack = g_Engine.time + 0.5f;
                m_reviveChargedTime = 0;
                return;
            }

            if (pBestTarget.m_fCanFadeStart) 
            {
                pBestTarget.pev.renderamt = 255;
                pBestTarget.pev.nextthink = g_Engine.time + 2.0f;
            }

            if (m_reviveChargedTime == 0.0f) 
            {
                self.SendWeaponAnim(LONGUSE, 0, pev.body);
                m_reviveChargedTime = g_Engine.time + 2.0f;
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "items/suitchargeok1.wav", 1.0f, ATTN_NORM);
                return;
            }

            if (m_reviveChargedTime < g_Engine.time)
            {
                m_reviveChargedTime = 0;
                m_pPlayer.SetAnimation(PLAYER_ATTACK1);
                self.SendWeaponAnim(SHORTUSE, 0, pev.body);
                g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro4.wav", 1.0f, ATTN_NORM);
                self.m_flNextSecondaryAttack = g_Engine.time + 2.0f;
                
                CBaseMonster@ pMonster = (pBestTarget.GetClassname() == "deadplayer") ? cast<CBaseMonster@>(g_EntityFuncs.Instance(int(pBestTarget.pev.renderamt))) : pBestTarget.MyMonsterPointer();
                pMonster.Revive();
                pMonster.pev.health = (pMonster.pev.max_health / 2);

                // m_pPlayer.GetPointsForDamage(-pBestTarget.pev.health);

                //https://github.com/KernCore91/-SC-Cry-of-Fear-Weapons-Project/blob/aeb624bd55b890c90df20f993a76979c86eac25b/scripts/maps/cof/special/weapon_cofsyringe.as#L306-L307
                pMonster.Forget( bits_MEMORY_PROVOKED | bits_MEMORY_SUSPICIOUS );
                pMonster.ClearSchedule();

                m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - REVIVE_COST);
            }

            self.m_flNextSecondaryAttack = g_Engine.time + 2.0f;
        }

        bool CanHealTarget(CBaseEntity@ pEntity)
        {
            CBaseMonster@ pMonster = (pEntity !is null) ? pEntity.MyMonsterPointer() : null;

            if(pMonster is null)
                return false;
            
            if(pMonster.pev.health >= pMonster.pev.max_health)
                return false;

            return true;
        }

        bool IsValidReviveTarget(CBaseEntity@ pEntity)
        {
            // if (pEntity.IRelationship(m_pPlayer) >= R_NO || pEntity.IsAlive() || pEntity.IsMachine())
            //     return false;

            // if(pEntity.IsPlayer() && cast<CBasePlayer@>(pEntity).GetObserver().HasCorpse())
            //     return true;

            // if(pEntity.GetClassname() == "deadplayer")
            //     return true;

            // if(pEntity.IsMonster() && !pEntity.IsPlayer())
            //     return true;

            // return (pEntity.IsPlayer() && (pEntity.pev.deadflag != DEAD_NO && cast<CBasePlayer@>(pEntity).GetObserver().HasCorpse()) && pEntity.pev.iuser1 == 0) ||
            //        (pEntity.GetClassname() == "deadplayer") ||
            //        (pEntity.IsMonster() && !pEntity.IsPlayer());

            return pEntity.IsRevivable() && pEntity.IRelationship(m_pPlayer) == R_AL;
        }

        bool IsBetterReviveTarget(CBaseEntity@ pEntity, CBaseEntity@ pBestTarget, float flDist, float flBestDist)
        {
            bool isBetterClass = pEntity.IsPlayer() && !pBestTarget.IsPlayer();
            bool isWorseClass = !pEntity.IsPlayer() && pBestTarget.IsPlayer();

            return (flDist < flBestDist && !isWorseClass) || isBetterClass;
        }

        void RechargeAmmo()
        {
            if(m_rechargeTime != 0.0f)
            {
                while(m_rechargeTime < g_Engine.time)
                {   
                    m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + RECHARGE_AMOUNT);

                    if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > MAX_CARRY)
                    {
                        m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, MAX_CARRY);
                        m_rechargeTime = g_Engine.time + RECHARGE_DELAY;
                        break;
                    }

                    m_rechargeTime = m_rechargeTime + RECHARGE_DELAY;
                }
            }
        }
    }
}