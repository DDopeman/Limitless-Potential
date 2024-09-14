/* 
 * デュアルメリケンサック
 */
#include "weapon_playerclassbase"

/** デュアルメリケンサッククラス */
class weapon_merikensack2 : weapon_playerclassbase {
    
    weapon_merikensack2() {
        this.mVmodel = "models/uboa_rampage_II/v_merikensack2.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_merikensack2.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_merikensack2.mdl";
        
        this.mSounds.insertLast("uboa_rampage_II/hardattack.wav");
        this.mSounds.insertLast("uboa_rampage_II/strikeattack.wav");
        
        
        mMaxCombo = 6;
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Brass knuckles] (BRAWLER)";
        this.mDispSkill = 
                  "  Upper cut -12SP (Stand/Back)\n"
                + "  Swing blow -12SP (Left/Right)\n"
                + "  Elbow strike -12SP (Moving Forward)\n";
        this.mDispPower = 2;
        this.mDispSpeed = 4;
        this.mDispReach = 1;
        
        return weapon_playerclassbase::Deploy();
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = UBOAWAZA_MAX_AMMO;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 1;
        info.iPosition = 5;
        info.iFlags    = 0;
        info.iWeight   = 10;
        return true;
    }    
   
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.125 : 0.25;
        
        // コンボ制限
        float delay = 0;
        if (mCombo < mMaxCombo -1) {
            delay = 0;
            mCombo++;
        } else {
            delay = 0.5;
            mCombo = 0;
        }
        if (mRageLevel > 0) {
            delay = 0;
        }
        
        int anim;
        if (mRageLevel == 0) {
            anim = (mCombo % 2 == 1) ? BASEPLAYERCLASSS_1_NORMAL_1 : BASEPLAYERCLASSS_2_NORMAL_1;
        } else {
            anim = (Math.RandomLong(0, 1) == 0) ? BASEPLAYERCLASSS_1_NORMAL_2 : BASEPLAYERCLASSS_2_NORMAL_2;
        }
        self.SendWeaponAnim(anim, 0, 0);
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
        
        SetThink(ThinkFunction(this.AttackDelay1));
        self.pev.nextthink = g_Engine.time + 0.05;
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf + delay;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf;
        
        WeaponIdle();
    }
    
    /** セカンダリアタック */
    void SecondaryAttack() {
        const int SKILLCOST = 12;        
        if (ConsumeSkill(SKILLCOST)) {
            return;
        }
        
        mCombo = 0;
        
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.18 : 0.3;
        float spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
        
        // 最終SP攻撃方向キー更新
        updateDirection();
        
        AttackInfo atk;
        mSpAtk.resize(0);
        
        atk.dmg = 50.0 + Math.RandomFloat(-10.0, 10.0);
        
        // 動作
        switch (this.mLastSpDirection) {
        case IN_FORWARD: 
            
            // 前進中ならエルボー
            if (m_pPlayer.pev.velocity.Length() >= m_pPlayer.pev.maxspeed * 0.75) {
                m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + g_Engine.v_forward * 400;
                atk.knockback = 200.0;
                atk.soundName = "uboa_rampage_II/strikeattack.wav";
            // 速度足りない場合は、アッパー
            } else {
                this.mLastSpDirection = IN_BACK;
                atk.soundName = "uboa_rampage_II/hardattack.wav";
                atk.knockback = 250.0;
            }
            
            atk.rangeDir = Vector(60.0, 0, 0);
            atk.rageGain = Math.RandomLong(0, 1); 
            mSpAtk.insertLast(atk);
            atk.swingSound = false;
            mSpAtk.insertLast(atk);
            mSpAtk.insertLast(atk);
            mSpAtk.insertLast(atk);
            mSpAtk.insertLast(atk);            
            break;
            
        case IN_BACK:
            atk.knockback = 250.0;
            atk.soundName = "uboa_rampage_II/hardattack.wav";
            atk.rangeDir = Vector(60.0, 0, 0);
            atk.rageGain = Math.RandomLong(0, 1); 
            mSpAtk.insertLast(atk);
            atk.swingSound = false;
            mSpAtk.insertLast(atk);
            mSpAtk.insertLast(atk);
            mSpAtk.insertLast(atk);
            mSpAtk.insertLast(atk);            
            break;
            
        case IN_MOVELEFT:
            atk.knockback = 220.0;
            atk.soundName = "uboa_rampage_II/hardattack.wav";
            atk.rageGain = Math.RandomLong(0, 1); 
            atk.rangeDir = calcDirection(60.0, 40);
            mSpAtk.insertLast(atk);
            atk.swingSound = false;
            atk.rangeDir = calcDirection(60.0, 20);
            mSpAtk.insertLast(atk);
            atk.rangeDir = Vector(60.0, 0, 0);
            mSpAtk.insertLast(atk);
            atk.rangeDir = calcDirection(60.0, -20);
            mSpAtk.insertLast(atk);            
            break;
            
        case IN_MOVERIGHT: 
            atk.knockback = 220.0;
            atk.rageGain = Math.RandomLong(0, 1); 
            atk.soundName = "uboa_rampage_II/hardattack.wav";
            atk.rangeDir = calcDirection(60.0, -40);
            mSpAtk.insertLast(atk);
            atk.swingSound = false;
            atk.rangeDir = calcDirection(60.0, -20);
            mSpAtk.insertLast(atk);
            atk.rangeDir = Vector(60.0, 0, 0);
            mSpAtk.insertLast(atk);
            atk.rangeDir = calcDirection(60.0, 20);
            mSpAtk.insertLast(atk);            
            break;
        }
        
        SetThink(ThinkFunction(this.SpDelayRecursive));
        self.pev.nextthink = g_Engine.time + 0.15;
        
        // モーション
        self.SendWeaponAnim( animFromDirection(), 0, 0);        
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    // 通常攻撃
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 60.0 + Math.RandomFloat(-10.0, 10.0);
        NormalAttack(atk);
        
    }
    
    // 特殊攻撃（多段ヒット）
    private void SpDelayRecursive() {
        // 配列数で再帰処理
        if (mSpAtk.length() > 0) {
            NormalAttack(mSpAtk[0]);
            mSpAtk.removeAt(0);
            
            SetThink(ThinkFunction(this.SpDelayRecursive));
            self.pev.nextthink = g_Engine.time + 0.1;
        }
    }
    
}

string GetMerikensack2Name() {
    return "weapon_merikensack2";
}

void RegisterMerikensack2() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_merikensack2", GetMerikensack2Name() );
    g_ItemRegistry.RegisterWeapon( GetMerikensack2Name(), "uboa_rampage_II", UBOAWAZA_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}
