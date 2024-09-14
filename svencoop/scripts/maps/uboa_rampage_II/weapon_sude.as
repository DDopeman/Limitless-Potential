/* 
 * 徒手空拳
 */
#include "weapon_playerclassbase"

/** 徒手空拳クラス */
class weapon_sude : weapon_playerclassbase {
    
    weapon_sude() {
        this.mVmodel = "models/uboa_rampage_II/v_sude.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_sude.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_sude.mdl";
        
        this.mSounds.insertLast("uboa_rampage_II/strikeattack.wav");
        
        mMaxCombo = 8;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = UBOAWAZA_MAX_AMMO;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 1;
        info.iPosition = 6;
        info.iFlags    = 0;
        info.iWeight   = 10;
        return true;
    }   
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Bare hands] (KARATEKA)";
        this.mDispSkill = "  Combination attack -25SP\n";
        this.mDispPower = 1;
        this.mDispSpeed = 5;
        this.mDispReach = 1;
        
        return weapon_playerclassbase::Deploy();
    } 
   
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.1 : 0.2;
        
        int anim;
        if (mRageLevel == 0) {
            switch (mCombo) {
                case 4:
                case 5:
                case 6:
                    anim = BASEPLAYERCLASSS_1_NORMAL_1; break;
                case 7:
                    anim = BASEPLAYERCLASSS_F_SPECIAL_1; break;
                default:
                    anim = BASEPLAYERCLASSS_2_NORMAL_1;
            }
        } else {
            switch (Math.RandomLong(0, 7)) {
                case 4:
                case 5:
                case 6:
                    anim = BASEPLAYERCLASSS_1_NORMAL_2; break;
                case 7:
                    anim = BASEPLAYERCLASSS_F_SPECIAL_2; break;
                default:
                    anim = BASEPLAYERCLASSS_2_NORMAL_2;
            }
        }
        self.SendWeaponAnim(anim, 0, 0);
        
        // コンボ制限
        float delay = 0;
        if (mCombo < mMaxCombo -1) {
            delay = 0;
            mCombo++;
        } else {
            delay = 0.6;
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
        const int SKILLCOST = 25;
        if (ConsumeSkill(SKILLCOST)) {
            return;
        }
        
        mCombo = 0;
        
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.18 : 0.3;
        float spdDelay = (mRageLevel > 0) ? 0.8 : 1.2;
        
        // 最終SP攻撃方向キー更新
        updateDirection();
        
        AttackInfo atk;
        mSpAtk.resize(0);
        
        atk.dmg = 45.0 + Math.RandomFloat(-10.0, 10.0);
        atk.criticalRate = 2.5;
        atk.critical = (Math.RandomLong(0, 40) == 0);
        
        // 動作
        switch (this.mLastSpDirection) {
        case IN_FORWARD:
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
            break;
            
        case IN_BACK:
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
            break;
            
        case IN_MOVELEFT:
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
            break;
            
        case IN_MOVERIGHT: 
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
            break;
        }
        
        SetThink(ThinkFunction(this.SpDelayRecursive));
        self.pev.nextthink = g_Engine.time + 0.15;
        
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    // 通常攻撃
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 45.0 + Math.RandomFloat(-10.0, 10.0);
        atk.rageGain = Math.RandomLong(1, 2);
        atk.criticalRate = 2.5;
        atk.critical = (Math.RandomLong(0, 40) == 0);
        NormalAttack(atk);
        
    }
    
    // 特殊攻撃（連続攻撃）
    private void SpDelayRecursive() {
        // 配列数で再帰処理
        if (mSpAtk.length() > 0) {
            updateDirection();
            // 最後の攻撃時にキー情報読み取り
            if (mSpAtk.length() == 1) {
                switch (this.mLastSpDirection) {
                case IN_FORWARD:
                    mSpAtk[0].knockback = 800.0;
                    break;
                    
                case IN_BACK:
                    mSpAtk[0].knockback = 600.0;
                    break;
                    
                case IN_MOVELEFT:
                    mSpAtk[0].knockback = 300.0;
                    break;
                    
                case IN_MOVERIGHT: 
                    mSpAtk[0].knockback = 300.0;
                    break;
                }
                mSpAtk[0].dmg = 60.0 + Math.RandomFloat(-5.0, 5.0);
            }
            
            NormalAttack(mSpAtk[0]);
            mSpAtk.removeAt(0);
            
            if (mSpAtk.length() == 0) {
                // モーション
                self.SendWeaponAnim( animFromDirection(), 0, 0);
            } else {
                self.SendWeaponAnim( BASEPLAYERCLASSS_2_NORMAL_2, 0, 0);
            }
            
            SetThink(ThinkFunction(this.SpDelayRecursive));
            self.pev.nextthink = g_Engine.time + ((mSpAtk.length() == 1) ? 0.26 : 0.1);
        }
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
    }
    
}

string GetSudeName() {
    return "weapon_sude";
}

void RegisterSude() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_sude", GetSudeName() );
    g_ItemRegistry.RegisterWeapon( GetSudeName(), "uboa_rampage_II", UBOAWAZA_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}
