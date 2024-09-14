/* 
 * つるはし
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_pickaxe : weapon_pickupbase {
    
    weapon_pickaxe() {
        this.mVmodel = "models/uboa_rampage_II/v_pickaxe.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_pickaxe.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_pickaxe.mdl";
        
        this.mSounds.insertLast("uboa_rampage_II/bladeattack.wav");
        this.mDmgSound = "uboa_rampage_II/bladeattack.wav";
        
        mMaxCombo = 4;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 12;
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
        this.mDispName = "[Pickaxe] (WORKER/WEAPON MASTER)";
        this.mDispSkill = 
               (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) 
            || (this.mPlayerClassType == CLASSTYPE_WORKER) 
                ? "  Digging blow (Forward)\n" : "";
        this.mDispPower = 4;
        this.mDispSpeed = 2;
        this.mDispReach = 4;
        
        return weapon_pickupbase::Deploy();
    }
    
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.26 : 0.52;
        
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
            || (this.mPlayerClassType == CLASSTYPE_WORKER)) {
            
            if ((m_pPlayer.pev.button & IN_FORWARD ) != 0) {
                spdBuf = (mRageLevel > 0) ? 0.4 : 0.6;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                // 連続判定
                AttackInfo atk;
                mSpAtk.resize(0);
                
                atk.dmg = 65.0 + Math.RandomFloat(-10.0, 10.0);
                atk.rageGain = Math.RandomLong(0, 1);
                atk.criticalRate = 2.5;
                atk.critical = (Math.RandomLong(0, 40) == 0);
                
                atk.rangeDir = Vector(84.0, 0, 0);
                atk.soundName = this.mDmgSound;
                
                mSpAtk.insertLast(atk);
                atk.swingSound = false;
                mSpAtk.insertLast(atk);
                mSpAtk.insertLast(atk);
                mSpAtk.insertLast(atk);
                
                SetThink(ThinkFunction(this.SpDelayRecursive));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.4 : 0.6;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.13;
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.4 : 0.6;
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
        atk.dmg = 110.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(84.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
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
        atk.dmg = 150.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(84.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
    
    // 特殊攻撃（多段ヒット）
    private void SpDelayRecursive() {
        // 配列数で再帰処理
        if (mSpAtk.length() > 0) {
            if (NormalAttack(mSpAtk[0])) {
                if (ConsumeDurability(Math.RandomLong(0, 2))) {
                    BrokenEffect();
                    g_EntityFuncs.Remove( self );
                    return;
                }
            }
            mSpAtk.removeAt(0);
            
            SetThink(ThinkFunction(this.SpDelayRecursive));
            self.pev.nextthink = g_Engine.time + 0.1;
        }
    }
}

string GetPickaxeName() {
    return "weapon_pickaxe";
}

void RegisterPickaxe() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_pickaxe", GetPickaxeName() );
    g_ItemRegistry.RegisterWeapon( GetPickaxeName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

