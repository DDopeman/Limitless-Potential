/* 
 * 取得武器
 */
#include "weapon_base"
#include "CPlayerClassUtil"

enum pickupbase_e {
    PICKUPWEP_FIDGET = 0,
    PICKUPWEP_IDLE,
    PICKUPWEP_DRAW,
    PICKUPWEP_1_NORMAL_1,
    PICKUPWEP_1_NORMAL_2,
    PICKUPWEP_2_NORMAL_1,
    PICKUPWEP_2_NORMAL_2,
    PICKUPWEP_SPECIAL_1,
    PICKUPWEP_SPECIAL_2,
    PICKUPWEP_ALTSPECIAL_1,
    PICKUPWEP_ALTSPECIAL_2
};

/** 取得武器クラス */
abstract class weapon_pickupbase : weapon_base {
        
    protected int mPlayerClassType; // 選択中のクラスのタイプ
    protected int mDurability;      // 耐久力
    protected int mBreakCnt;        // 破壊時カウンター
    protected float mNonBreakTime;
    
    protected float mBonusDurRate = 1.0;   // ボーナス耐久力
    
    weapon_pickupbase() {
        this.mMotion     = "crowbar";
        
        this.mVoiceSound = "uboa_rampage/koraa.wav";
        this.mHitSound1  = "weapons/cbar_hitbod1.wav";
        this.mHitSound2  = "weapons/cbar_hitbod2.wav";
        this.mDmgSound   = "uboa_rampage/bishi.wav";
        this.mSwingSound = "uboa_rampage_II/swing.wav";
        
        this.mModels.insertLast("models/mbarrel.mdl");
        this.mSounds.insertLast("ambience/wood2.wav");
    }
    
    /** プレイヤーへの武器追加 */
    bool AddToPlayer(CBasePlayer@ pPlayer) {
        CPlayerClassUtil pcUtil;
        
        if (pcUtil.CountWeapons(pPlayer) >= 2) {
            return false;
        }
        
        if (weapon_base::AddToPlayer(pPlayer)) {
            mPlayerClassType = pcUtil.GetPlayerClassIndex(pPlayer);
            
            if (mPlayerClassType == CLASSTYPE_WEAPONMASTER) {
                mBonusDurRate = 1.25; 
            }
            
            mDurability = int(mDurability * mBonusDurRate);
                
            return true;
        }
        return false;
    }
        
    /** 武器取り出し時 */
    bool Deploy() {
        // HUDへ反映
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, mDurability);
                
        this.mDispColorType = 1;
        this.mBreakCnt      = 0;
        this.mNonBreakTime  = g_Engine.time;
        return weapon_base::Deploy();
    }
    
    /** リロード */
    void Reload() {
        // しゃがみリロードで破壊
        if( (( m_pPlayer.pev.button & IN_DUCK ) != 0) && ( g_Engine.time >= this.mNonBreakTime + 1.0) ) {
            g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "[DESTROYING WEAPON]");
            
            // 破壊音
            if (this.mBreakCnt == 0) {
                g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_WEAPON, "ambience/wood2.wav", 1.0f, ATTN_NONE, 0, Math.RandomLong( 90, 110 ));
                self.SendWeaponAnim( WEAPONBASE_FIDGET ,0 ,0);
            }
            this.mBreakCnt += 1;
            this.mBreakCnt = (this.mBreakCnt > 30) ? 0 : this.mBreakCnt;
            
            // 耐久力減
            if (ConsumeDurability(1)) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
            
        // 通常表示処理
        } else {
            weapon_base::Deploy();
        }
    }    
    
    /** アイドル時 */
    void WeaponIdle() {
        // HUDへ反映
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, mDurability);
        
        weapon_base::WeaponIdle();
    }
    
    /** Rage発動条件 */
    protected bool IsEnableRage() {
        return ((mRageLevel == 0) 
            && (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType ) == UBOAKIAI_MAX_AMMO));
    }
    
    /** 耐久力消費処理 */
    protected bool ConsumeDurability(int durabilityCost) {
        // 通常時は普通に耐久力減
        if (mRageLevel == 0) { 
            mDurability -= durabilityCost;
            
        // Rage中は1/3の確率で耐久力減らない
        } else {
            if (Math.RandomLong(0, 2) != 0) {
                mDurability -= durabilityCost;
            }
        }
        mDurability = (mDurability < 0) ? 0 : mDurability;
        
        // HUD反映
        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, mDurability);
        
        // 壊れてるなら攻撃できない
        if (mDurability <= 0) {
            return true; // →壊れた
        }
        return false;
    }
    
    /** 武器破損時エフェクト */
    protected void BrokenEffect() {
        g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_WEAPON, "ambience/wood2.wav", 1.0f, ATTN_NONE, 0, Math.RandomLong( 90, 110 ));
        g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "WEAPON BROKEN!!\n");
        
        NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        m.WriteByte(TE_EXPLODEMODEL);
        m.WriteCoord(m_pPlayer.pev.origin.x);
        m.WriteCoord(m_pPlayer.pev.origin.y);
        m.WriteCoord(m_pPlayer.pev.origin.z);
        m.WriteCoord(300);     // velocity
        m.WriteShort(g_EngineFuncs.ModelIndex("models/mbarrel.mdl"));
        m.WriteShort(12);    // count
        m.WriteByte(30);  // life
        m.End();
    }
}
