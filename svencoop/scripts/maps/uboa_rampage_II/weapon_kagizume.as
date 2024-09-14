/* 
 * 鉤爪
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_kagizume : weapon_pickupbase {
    private bool mIsRightArm = true;
    
    weapon_kagizume() {
        this.mVmodel = "models/uboa_rampage_II/v_kagizume.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_kagizume.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_kagizume.mdl";
        
        this.mSounds.insertLast("uboa_rampage_II/bladeattack.wav");
        this.mDmgSound = "uboa_rampage_II/bladeattack.wav";
        
        mMaxCombo = 6;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 9;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 85;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Iron claws] (WEAPON MASTER)";
        this.mDispSkill = (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) 
                ? "  High speed slash (Moving Forward)\n" : "";
        this.mDispPower = 4;
        this.mDispSpeed = 5;
        this.mDispReach = 3;
        
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.25 : 0.4;
        
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

        // アニメーション切り替え
        if (mIsRightArm) {
            anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
        } else { 
            anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
        }
        mIsRightArm = !mIsRightArm;
        
        if (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) {           
            
            if ((m_pPlayer.pev.button & IN_FORWARD ) != 0) {
                spdBuf = (mRageLevel > 0) ? 0.11 : 0.12;
                spdDelay = (mRageLevel > 0) ? 0.1 : 0.1;
                
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay2));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            } else {                
                spdBuf = (mRageLevel > 0) ? 0.25 : 0.55;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.13;
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.25 : 0.55;
            spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
            
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
        atk.dmg = 85.0 + Math.RandomFloat(-25.0, 25.0);
        atk.criticalRate = 2.0;
        atk.rangeDir = Vector(75.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
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
        atk.dmg = 120.0 + Math.RandomFloat(-25.0, 25.0);
        atk.criticalRate = 2.0;
        atk.rangeDir = Vector(75.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 3))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
    
    // 特殊攻撃
    private void SpDelay2() {
        AttackInfo atk;
        atk.dmg = 75.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.0;
        atk.rangeDir = Vector(75.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
}

string GetKagizumeName() {
    return "weapon_kagizume";
}

void RegisterKagizume() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_kagizume", GetKagizumeName() );
    g_ItemRegistry.RegisterWeapon( GetKagizumeName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

