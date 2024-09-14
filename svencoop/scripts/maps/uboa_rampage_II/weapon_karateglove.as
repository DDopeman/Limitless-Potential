/* 
 * 空手グローブ
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_karateglove : weapon_pickupbase {
    
    weapon_karateglove() {
        this.mVmodel = "models/uboa_rampage_II/v_karateglove.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_karateglove.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_karateglove.mdl";
        
        this.mSounds.insertLast("weapons/knife1.wav");
        this.mSounds.insertLast("uboa_rampage_II/strikeattack.wav");
        
        this.mSwingSound = "weapons/knife1.wav";
        mMaxCombo = 8;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 16;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 100;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Karate glove] (KARATEKA)";
        this.mDispSkill = (this.mPlayerClassType == CLASSTYPE_KARATEKA) 
                ? "  Karate combination attack (Forward)\n" : "";
        this.mDispPower = 1;
        this.mDispSpeed = 5;
        this.mDispReach = 1;
        
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.2 : 0.35;
        
        int anim;
        if (mRageLevel == 0) {
            anim = (mCombo % 3 == 0) ? PICKUPWEP_1_NORMAL_1 : PICKUPWEP_2_NORMAL_1;
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
        
        AttackInfo atk;
        mSpAtk.resize(0);       
        
        if (this.mPlayerClassType == CLASSTYPE_KARATEKA) {
            
            if ((m_pPlayer.pev.button & IN_FORWARD ) == 0) {
                spdBuf = (mRageLevel > 0) ? 0.18 : 0.3;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.2 : 0.4;
                spdDelay = (mRageLevel > 0) ? 0.8 : 1.2;
                
                
                atk.dmg = 40.0 + Math.RandomFloat(-5.0, 5.0);
                atk.rageGain = Math.RandomLong(0, 1);
                atk.criticalRate = 2.5;
                atk.critical = (Math.RandomLong(0, 40) == 0);
                atk.rangeDir = Vector(60.0, 0, 0);
                atk.soundName = "uboa_rampage_II/strikeattack.wav";
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                atk.dmg = 80.0 + Math.RandomFloat(-5.0, 5.0);
                atk.rageGain = Math.RandomLong(0, 1);
                mSpAtk.insertLast(atk);
                
                SetThink(ThinkFunction(this.SpDelayRecursive));
                self.pev.nextthink = g_Engine.time + 0.15;
                
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
        atk.dmg = 48.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(60.0, 0, 0);
        
        
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
        atk.dmg = 70 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 3.0;
        atk.rangeDir = Vector(60.0, 0, 0);
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
    
    
    // 特殊攻撃（連続攻撃）
    private void SpDelayRecursive() {
        // 配列数で再帰処理
        if (mSpAtk.length() > 0) {            
            if (NormalAttack(mSpAtk[0])) {
                if (ConsumeDurability(Math.RandomLong(0, 1))) {
                    BrokenEffect();
                    g_EntityFuncs.Remove( self ); 
                    return;
                }
            }
            mSpAtk.removeAt(0);
            
            if (mSpAtk.length() == 0) {
                // モーション
                self.SendWeaponAnim( PICKUPWEP_ALTSPECIAL_1, 0, 0);
            } else {
                self.SendWeaponAnim( PICKUPWEP_1_NORMAL_2, 0, 0);
            }
            
            SetThink(ThinkFunction(this.SpDelayRecursive));
            self.pev.nextthink = g_Engine.time + ((mSpAtk.length() == 1) ? 0.26 : 0.1);
        }
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
    }
}

string GetKarategloveName() {
    return "weapon_karateglove";
}

void RegisterKarateglove() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_karateglove", GetKarategloveName() );
    g_ItemRegistry.RegisterWeapon( GetKarategloveName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

