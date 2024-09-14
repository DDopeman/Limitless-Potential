/* 
 * PlayerClass基本武器
 */
#include "weapon_base"

enum playerclassbase_e {
    BASEPLAYERCLASSS_FIDGET = 0,
    BASEPLAYERCLASSS_IDLE,
    BASEPLAYERCLASSS_DRAW,
    BASEPLAYERCLASSS_1_NORMAL_1,
    BASEPLAYERCLASSS_1_NORMAL_2,
    BASEPLAYERCLASSS_2_NORMAL_1,
    BASEPLAYERCLASSS_2_NORMAL_2,
    BASEPLAYERCLASSS_L_SPECIAL_1,
    BASEPLAYERCLASSS_L_SPECIAL_2,
    BASEPLAYERCLASSS_R_SPECIAL_1,
    BASEPLAYERCLASSS_R_SPECIAL_2,
    BASEPLAYERCLASSS_F_SPECIAL_1,
    BASEPLAYERCLASSS_F_SPECIAL_2,
    BASEPLAYERCLASSS_B_SPECIAL_1,
    BASEPLAYERCLASSS_B_SPECIAL_2
};

/** PlayerClass基本武器クラス */
abstract class weapon_playerclassbase : weapon_base {
    
    // 攻撃情報
    protected int mLastSpDirection = IN_FORWARD;
    protected float mWazaRegene;
    
    weapon_playerclassbase() {
        this.mMotion     = "crowbar";
        
        this.mVoiceSound = "uboa_rampage/koraa.wav";
        this.mHitSound1  = "weapons/bullet_hit2.wav";
        this.mHitSound2  = "weapons/cbar_hitbod2.wav";
        this.mDmgSound   = "uboa_rampage/bishi.wav";
        this.mSwingSound = "weapons/knife1.wav";
    }
    
    /** Spawn時 */
    void Spawn() {
        self.m_iDefaultAmmo = UBOAWAZA_MAX_AMMO;
        mWazaRegene = 0;
        
        weapon_base::Spawn();
    }
    
    /** Rage発動条件 */
    protected bool IsEnableRage() {
        return ((mRageLevel == 0) 
            && (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType ) == UBOAKIAI_MAX_AMMO));
    }
    
    /** アイドル時 */
    void WeaponIdle() {
        weapon_base::WeaponIdle();
        
        // 特殊攻撃ゲージ自動回復
        if ((g_Engine.time >= mWazaRegene + 0.1) && (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < UBOAWAZA_MAX_AMMO)) {
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + 1);
            
            mWazaRegene = g_Engine.time;
        }
    }
    
    /** Rage、特殊攻撃の最低値セット */
    protected void SetMinimumAmmo() {
        weapon_base::SetMinimumAmmo();
        
        // 特殊攻撃ゲージ最低値１
        if (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType ) < 1) {
            m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, 1);
        }
    }
    
    /** スキル消費処理 */
    protected bool ConsumeSkill(int skillCost) {
        if (mRageLevel == 0) {
            // 消費量以下なら何もしない
            if (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < skillCost) {    
                return true;
            }
            
            // 特殊攻撃ゲージ消費
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - skillCost);
            if (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0) {
                m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 1);
            }
        }
        return false;
    }
    
    /** 最終SP方向の更新 */
    protected void updateDirection() {
        if(( m_pPlayer.pev.button & IN_FORWARD ) != 0) {
            this.mLastSpDirection = IN_FORWARD;
        } else if(( m_pPlayer.pev.button & IN_BACK ) != 0) {
            this.mLastSpDirection = IN_BACK;
        }
        
        if(( m_pPlayer.pev.button & IN_MOVELEFT ) != 0) {
            this.mLastSpDirection = IN_MOVELEFT;
        } else if(( m_pPlayer.pev.button & IN_MOVERIGHT ) != 0) {
            this.mLastSpDirection = IN_MOVERIGHT;
        }
    }
    
    /** 最終SP方向状態からアニメーション割り出し */
    protected int animFromDirection() {
        switch (this.mLastSpDirection) {
        case IN_FORWARD:   return ((mRageLevel <= 0) ? BASEPLAYERCLASSS_F_SPECIAL_1 : BASEPLAYERCLASSS_F_SPECIAL_2);
        case IN_BACK:      return ((mRageLevel <= 0) ? BASEPLAYERCLASSS_B_SPECIAL_1 : BASEPLAYERCLASSS_B_SPECIAL_2);
        case IN_MOVELEFT:  return ((mRageLevel <= 0) ? BASEPLAYERCLASSS_L_SPECIAL_1 : BASEPLAYERCLASSS_L_SPECIAL_2);
        case IN_MOVERIGHT: return ((mRageLevel <= 0) ? BASEPLAYERCLASSS_R_SPECIAL_1 : BASEPLAYERCLASSS_R_SPECIAL_2);
        }
        return BASEPLAYERCLASSS_F_SPECIAL_1;
    }
    
}
