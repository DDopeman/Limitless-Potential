/* 
 * 警棒
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_policebaton : weapon_pickupbase {
    
    weapon_policebaton() {
        this.mVmodel = "models/uboa_rampage_II/v_policebaton.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_policebaton.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_policebaton.mdl";
        
        this.mSounds.insertLast("uboa_rampage_II/strikeattack.wav");
        
        mMaxCombo = 6;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 10;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 80;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Tactical baton] (WEAPON MASTER)";
        this.mDispSkill = (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) 
                ? "  Whiplash (Forward)\n" : "";
        this.mDispPower = 3;
        this.mDispSpeed = 5;
        this.mDispReach = 4;
        
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.2 : 0.35;
        
        int anim;
        if (mRageLevel == 0) {
            anim = (mCombo % 2 == 0) ? PICKUPWEP_1_NORMAL_1 : PICKUPWEP_2_NORMAL_1;
        } else {
            anim = (Math.RandomLong(0, 1) == 0) ? PICKUPWEP_1_NORMAL_2 : PICKUPWEP_2_NORMAL_2;
        }
        self.SendWeaponAnim(anim, 0, 0);
        
        // コンボ制限
        float delay = 0;
        if (mCombo < mMaxCombo -1) {
            delay = 0;
            mCombo++;
        } else {
            delay = 0.4;
            mCombo = 0;
        }
        if (mRageLevel > 0) {
            delay = 0;
        }
        
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
        
        SetThink(ThinkFunction(this.AttackDelay1));
        self.pev.nextthink = g_Engine.time + 0.05;
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf + delay;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf;
        
        WeaponIdle();
    }
    
    /** セカンダリアタック */
    void SecondaryAttack() {
        mCombo = 0;
        
        // 攻撃速度
        float spdBuf;
        float spdDelay;
            
        // モーション
        int anim;
        
        if (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) {
            
            if ((m_pPlayer.pev.button & IN_FORWARD ) != 0) {
                spdBuf = (mRageLevel > 0) ? 0.18 : 0.3;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay2));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.18 : 0.3;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.18 : 0.3;
            spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
            
            anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
            self.SendWeaponAnim( anim, 0, 0);        
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            
            SetThink(ThinkFunction(this.SpDelay1));
            self.pev.nextthink = g_Engine.time + 0.13;
        }
        
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 85.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(76.0, 0, 0);
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
        
    }
    
    // 強攻撃
    private void SpDelay1() {
        AttackInfo atk;
        atk.dmg = 120.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 3.0;
        atk.rangeDir = Vector(76.0, 0, 0);
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
    
    
    // 特殊攻撃
    private void SpDelay2() {
        AttackInfo atk;
        atk.dmg = 150.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 3.0;
        atk.knockback = 1000.0;
        atk.rangeDir = Vector(76.0, 0, 0);
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
}

string GetPolicebatonName() {
    return "weapon_policebaton";
}

void RegisterPolicebaton() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_policebaton", GetPolicebatonName() );
    g_ItemRegistry.RegisterWeapon( GetPolicebatonName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

