/* 
 * 看板
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_kanban : weapon_pickupbase {
    
    weapon_kanban() {
        this.mVmodel = "models/uboa_rampage_II/v_kanban.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_kanban.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_kanban.mdl";
        
        this.mSounds.insertLast("player/pl_duct1.wav");
        this.mSounds.insertLast("player/pl_duct2.wav");
        this.mHitSound1  = "player/pl_duct1.wav";
        this.mHitSound2  = "player/pl_duct2.wav";
        mMaxCombo = 3;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 13;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 70;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Standing signboard] (WORKER)";
        this.mDispSkill = (this.mPlayerClassType == CLASSTYPE_WORKER) 
                ? "  Swing strike (Stand)\n" : "";
        this.mDispPower = 2;
        this.mDispSpeed = 4;
        this.mDispReach = 5;
        
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.25 : 0.48;
        
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
        
        
        if (this.mPlayerClassType == CLASSTYPE_WORKER) {
            
            if ((m_pPlayer.pev.button & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) ) != 0) {
                spdBuf = (mRageLevel > 0) ? 0.4 : 0.8;
                spdDelay = (mRageLevel > 0) ? 0.4 : 0.6;
                    
                // モーション
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.6 : 1.0;
                spdDelay = (mRageLevel > 0) ? 0.5 : 0.8;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                // 横殴り連続判定
                AttackInfo atk;
                mSpAtk.resize(0);
                
                atk.dmg = 57.0 + Math.RandomFloat(-20.0, 20.0);
                atk.rageGain = Math.RandomLong(0, 1);
                atk.criticalRate = 2.5;
                atk.critical = (Math.RandomLong(0, 40) == 0);
                
                atk.rangeDir = calcDirection(87.0, 80);
                mSpAtk.insertLast(atk);            
                atk.swingSound = false;
                atk.rangeDir = calcDirection(87.0, 60);
                mSpAtk.insertLast(atk);
                atk.rangeDir = calcDirection(87.0, 40);
                mSpAtk.insertLast(atk);
                atk.rangeDir = calcDirection(87.0, 20);
                mSpAtk.insertLast(atk);
                atk.rangeDir = Vector(87.0, 0, 0);
                mSpAtk.insertLast(atk);
                atk.rangeDir = calcDirection(87.0, -20);
                mSpAtk.insertLast(atk);
                atk.rangeDir = calcDirection(87.0, -40);
                mSpAtk.insertLast(atk);
                atk.rangeDir = calcDirection(87.0, -60);
                mSpAtk.insertLast(atk);
                atk.rangeDir = calcDirection(87.0, -80);
                mSpAtk.insertLast(atk);
                
                SetThink(ThinkFunction(this.SpDelayRecursive));
                self.pev.nextthink = g_Engine.time + 0.13;
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.4 : 0.8;
            spdDelay = (mRageLevel > 0) ? 0.4 : 0.6;
                
            // モーション
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
        atk.dmg = 65.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(87.0, 0, 0);
        
        
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
        atk.dmg = 100.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(87.0, 0, 0);
        
        
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

string GetKanbanName() {
    return "weapon_kanban";
}

void RegisterKanban() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_kanban", GetKanbanName() );
    g_ItemRegistry.RegisterWeapon( GetKanbanName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

