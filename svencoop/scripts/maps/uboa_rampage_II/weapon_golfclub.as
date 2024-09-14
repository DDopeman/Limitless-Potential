/* 
 * ゴルフクラブ
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_golfclub : weapon_pickupbase {
    
    weapon_golfclub() {
        this.mVmodel = "models/uboa_rampage_II/v_golfclub.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_golfclub.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_golfclub.mdl";
        
        this.mSounds.insertLast("uboa_rampage_II/strikeattack.wav");
        
        mMaxCombo = 4;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 17;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 110;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Golf club] (BRAWLER)";
        this.mDispSkill = 
               (this.mPlayerClassType == CLASSTYPE_BRAWLER) 
                ? "  Golf swing (Stand)\n" : "";
        this.mDispPower = 4;
        this.mDispSpeed = 3;
        this.mDispReach = 4;
        
        return weapon_pickupbase::Deploy();
    }
    
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.24 : 0.45;
        
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
        
        if (this.mPlayerClassType == CLASSTYPE_BRAWLER) {
            
            if ((m_pPlayer.pev.button & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) ) != 0) {
                spdBuf = (mRageLevel > 0) ? 0.3 : 0.5;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.3 : 0.5;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay2));
                self.pev.nextthink = g_Engine.time + 0.13;
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.3 : 0.5;
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
        atk.dmg = 100.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(83.0, 0, 0);
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
        
    }
    
    // 特殊攻撃
    private void SpDelay1() {
        AttackInfo atk;
        atk.dmg = 160.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(83.0, 0, 0);
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
        atk.dmg = 160.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 3.0;
        atk.knockback = 2000.0;
        atk.rangeDir = Vector(83.0, 0, 0);
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
}

string GetGolfclubName() {
    return "weapon_golfclub";
}

void RegisterGolfclub() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_golfclub", GetGolfclubName() );
    g_ItemRegistry.RegisterWeapon( GetGolfclubName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

