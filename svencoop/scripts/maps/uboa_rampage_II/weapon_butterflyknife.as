/* 
 * バタフライナイフ
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_butterflyknife : weapon_pickupbase {
    
    weapon_butterflyknife() {
        this.mVmodel = "models/uboa_rampage_II/v_butterflyknife.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_butterflyknife.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_butterflyknife.mdl";
        
        this.mSounds.insertLast("weapons/knife1.wav");
        this.mSounds.insertLast("uboa_rampage_II/bladeattack.wav");
        
        this.mDmgSound   = "uboa_rampage_II/bladeattack.wav";
        this.mSwingSound = "weapons/knife1.wav";
        mMaxCombo = 6;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 6;
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
        this.mDispName = "[Butterfly knife] (BRAWLER/WEAPON MASTER)";
        this.mDispSkill = (
               (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER)
            || (this.mPlayerClassType == CLASSTYPE_BRAWLER)) ?
                  "  Close stab (Get close)\n" : "";
        this.mDispPower = 3;
        this.mDispSpeed = 4;
        this.mDispReach = 2;
        
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.18 : 0.32;
        
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
                
        if ((this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) 
            || (this.mPlayerClassType == CLASSTYPE_BRAWLER)) {
                
            TraceResult tr;
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Math.MakeVectors( m_pPlayer.pev.v_angle );
            g_Utility.TraceLine( vecSrc, vecSrc + g_Engine.v_forward * 100, dont_ignore_monsters, m_pPlayer.edict(), tr );
            // 至近距離で技
            if ((tr.vecEndPos - vecSrc).Length() <= 45) {
                spdBuf = (mRageLevel > 0) ? 0.15 : 0.2;
                spdDelay = (mRageLevel > 0) ? 0.05 : 0.1;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                SetThink(ThinkFunction(this.SpDelay2));
                self.pev.nextthink = g_Engine.time + 0.08;
            } else {
                spdBuf = (mRageLevel > 0) ? 0.2 : 0.4;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.5;
            }
            self.SendWeaponAnim( anim, 0, 0);        
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.2 : 0.4;
            spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
            
            anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
            self.SendWeaponAnim( anim, 0, 0);        
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            
            SetThink(ThinkFunction(this.SpDelay1));
            self.pev.nextthink = g_Engine.time + 0.3;
            
        }        
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 80.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(69.0, 0, 0);
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
        atk.dmg = 130.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(69.0, 0, 0);
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
        atk.dmg = 120.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(69.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 3))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
}

string GetButterflyknifeName() {
    return "weapon_butterflyknife";
}

void RegisterButterflyknife() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_butterflyknife", GetButterflyknifeName() );
    g_ItemRegistry.RegisterWeapon( GetButterflyknifeName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

