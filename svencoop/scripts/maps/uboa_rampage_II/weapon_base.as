/* 
 * 武器基本クラス
 */
#include "CUboaAmmo"
#include "CRageEffect"
#include "CPlayerClassUtil"

// ※継承先で必ず順番をあわせること
enum weaponbase_e {
    WEAPONBASE_FIDGET = 0,
    WEAPONBASE_IDLE,
    WEAPONBASE_DRAW
}

/** 共通武器クラス */
abstract class weapon_base : ScriptBasePlayerWeaponEntity {
    protected CBasePlayer@ m_pPlayer = null;
    // モーション
    protected string mMotion;
    
    // モデル情報
    protected string mVmodel;
    protected string mPmodel;
    protected string mWmodel;
    protected array<string> mModels;
    protected array<string> mSounds;
    
    // サウンド
    protected string mHitSound1;
    protected string mHitSound2;
    protected string mDmgSound;
    protected string mSwingSound;
    protected string mVoiceSound;
    
    // Rage情報
    protected int   mRageLevel;
    protected float mRageTime;
    protected float mDmgRate;
    protected CRageEffect mRageEffect;
    
    // 攻撃情報
    protected int mCombo;
    protected int mMaxCombo;
    protected array<AttackInfo> mSpAtk; // 多段ヒット用
    
    // 武器表示情報
    protected string mDispName;      // 名前
    protected string mDispSkill;     // スキル説明
    protected int    mDispPower;     // パワー
    protected int    mDispSpeed;     // スピード
    protected int    mDispReach;     // リーチ
    protected int    mDispColorType; // 表示色タイプ
    
    
    /** Spawn時 */
    void Spawn() {
        // プリキャッシュ
        Precache();
        mRageEffect.Precache();
        
        // Wモデル設定
        g_EntityFuncs.SetModel( self, self.GetW_Model(this.mWmodel) );
        
        // 値初期化
        mRageLevel  = 0;
        mRageTime   = 0;
        mDmgRate    = 1.0;
        mCombo      = 0;
        
        mDispName      = "";
        mDispSkill     = "";
        mDispPower     = 0;
        mDispSpeed     = 0;
        mDispReach     = 0;
        mDispColorType = 0;
        
        self.FallInit();// get ready to fall down.
        
        self.pev.rendermode  = kRenderNormal;
        self.pev.renderfx    = kRenderFxGlowShell;
        self.pev.renderamt   = 4;
        self.pev.rendercolor = Vector(128, 128, 128);
    }

    /** プリキャッシュ */
    protected void Precache() {
        g_Game.PrecacheModel( this.mVmodel );
        g_Game.PrecacheModel( this.mPmodel );
        g_Game.PrecacheModel( this.mWmodel );
        
        for (uint i = 0; i < mModels.length(); i++) {
            g_Game.PrecacheModel(mModels[i]);
        }
        for (uint i = 0; i < mSounds.length(); i++) {
            g_SoundSystem.PrecacheSound(mSounds[i]);
        }

        g_SoundSystem.PrecacheSound( this.mVoiceSound );
        
        g_SoundSystem.PrecacheSound( this.mHitSound1 );
        g_SoundSystem.PrecacheSound( this.mHitSound2 );
        g_SoundSystem.PrecacheSound( this.mDmgSound );
        g_SoundSystem.PrecacheSound( this.mSwingSound );
    }
    
    /** プレイヤーへの武器追加 */
    bool AddToPlayer(CBasePlayer@ pPlayer) {
        CPlayerClassUtil pcUtil;
        // 拾えるかチェック
        if (!pcUtil.ShouldWeaponRemove(pPlayer, self.GetClassname())) {
            if( BaseClass.AddToPlayer(pPlayer) ) {
                @m_pPlayer = pPlayer;
                
                NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                message.WriteLong( self.m_iId );
                message.End();
                
                SetMinimumAmmo();
                return true;
            }
        }
        return false;
    }

    /** 武器取り出し時 */
    bool Deploy() {
        TurnOffRage();
        SetMinimumAmmo();
        mCombo = 0;
        
        CPlayerClassUtil pcUtil;
        pcUtil.CheckStatus(m_pPlayer, false);
        
        self.m_flNextPrimaryAttack   = g_Engine.time + 1.0;
        self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
        
        // 武器表示
        DisplayStatus();
        
        return self.DefaultDeploy(self.GetV_Model( this.mVmodel ), self.GetP_Model( this.mPmodel ), WEAPONBASE_DRAW, this.mMotion );
    }

    /** 武器ホルスター時 */
    void Holster(int skiplocal) {
        self.m_fInReload = false;
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;
        
        TurnOffRage();
        SetMinimumAmmo();
    }
    
    /** リロード */
    void Reload() {        
        // 武器表示
        DisplayStatus();
    }
    
    /** RageモードON */
    protected void TurnOnRage() {
        // 条件に合わない場合発動しない
        if (!IsEnableRage()) {
            return;
        }
        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, 1);
        
        mRageTime = g_Engine.time + RAGE_ACTIVE_TIME;
        mRageLevel = mRageEffect.TurnOnRage(m_pPlayer);
        
        CalcRageBuffer();
        
        int dmgInt   = int((mDmgRate - 1) * 1000);
        float dmgFloat = dmgInt * 0.1;
        g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "DAMAGE: +" + dmgFloat + "%%\n");
    }
    
    /** Rage発動条件 */
    protected bool IsEnableRage() {
        // (継承先で実装)
        return true;
    }
    
    /** Rageモード倍率計算 */
    protected void CalcRageBuffer() {
        mDmgRate = 1.0;
        
        // 1→ x0.1、4→ x0.2、10→ x0.29、32→ x0.4
        for (int i = 1; i <= mRageLevel; i++) {
            mDmgRate += (1.0 / (10.0 * i));
        }
    }
    
    /** RageモードOff */
    protected void TurnOffRage() {
        mRageEffect.TurnOffRage(m_pPlayer);
        
        mRageTime  = 0;
        mRageLevel = 0;
        mDmgRate   = 1.0;
    }
    
    /** 攻撃処理 */
    protected bool NormalAttack(AttackInfo &in atk) {
        if ((self is null) || (m_pPlayer is null)) {
            return false;
        }
        
        bool fDidHit = false;

        TraceResult tr;
        Math.MakeVectors( m_pPlayer.pev.v_angle );
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecEnd = vecSrc + g_Engine.v_forward * atk.rangeDir.x
                               + g_Engine.v_right * atk.rangeDir.y
                               + g_Engine.v_up * atk.rangeDir.z;
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        if ( tr.flFraction >= 1.0 ) {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
            if ( tr.flFraction < 1.0 ) {
                // 交点の計算。FindHullIntersectionでより正確になるらしい。
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
                if ((pHit is null) || (pHit.IsBSPModel()) ) {
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
                }
                vecEnd = tr.vecEndPos;
            }
        }
        
        // debug
        /*
        g_PlayerFuncs.ClientPrintAll(HUD_PRINTCENTER, "(" +  vecSrc.x + ", " + vecSrc.y + ", " + vecSrc.z + ")\n("
                                                        +  vecEnd.x + ", " + vecEnd.y + ", " + vecEnd.z + ")"
                 + "\n" + "tr.flFraction=" + tr.flFraction + "\n"); 
        */
        
        float dmgBuf = atk.dmg * mDmgRate; 
        // クリティカル
        if (atk.critical) {
            if (atk.swingSound) {
                g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_VOICE, this.mVoiceSound, 1.0f, ATTN_NONE, 0, Math.RandomLong( 100, 150 ));
            }
            dmgBuf *= atk.criticalRate;
        }
        
        // 空振り
        if ( tr.flFraction >= 1.0 ) {
            if (atk.swingSound) {
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, this.mSwingSound, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
            }
            
        // ヒット
        } else {
            fDidHit = true;
            
            CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

            // プレイヤー以外ならダメージ
            if ((pEntity.Classify() != CLASS_PLAYER) && (pEntity.Classify() != CLASS_PLAYER_ALLY)) {
                g_WeaponFuncs.ClearMultiDamage();
                pEntity.TraceAttack( m_pPlayer.pev, dmgBuf, g_Engine.v_forward, tr, atk.dmgType ); 
                g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
            }

            // play thwack, smack, or dong sound
            float flVol = 1.0;
            bool fHitWorld = true;

            // プレイヤーやNPCにヒット時
            if( pEntity !is null ) {
                if (pEntity.Classify() != CLASS_NONE) {
                    
                    // 少し押し出す
                    pEntity.pev.velocity = pEntity.pev.velocity - ( self.pev.origin - pEntity.pev.origin ).Normalize() * atk.knockback;
                    
                    // 気合増加
                    GainRage(atk.rageGain);
                    
                    if (atk.hitSound) {
                        g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_WEAPON, atk.soundName, 1.0f, ATTN_NONE, 0, Math.RandomLong( 90, 110 ));
                    }
                    
                    m_pPlayer.m_iWeaponVolume = 128; 
                    if( !pEntity.IsAlive() ) {
                        return true;
                    } else {
                        flVol = 0.1;
                    }

                    fHitWorld = false;
                }
            }

            // 壁殴り時
            if( fHitWorld == true ) {
                float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
                
                // override the volume here, cause we don't play texture sounds in multiplayer, 
                // and fvolbar is going to be 0 from the above call.

                fvolbar = 1;

                // also play crowbar strike
                switch( Math.RandomLong( 0, 1 ) )
                {
                case 0:
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, this.mHitSound1, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
                    break;
                case 1:
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, this.mHitSound2, fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
                    break;
                }
            }

            // デカール
            g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CROWBAR );

            m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
        }
        return fDidHit;
    }
    
    /** アイドル時 */
    void WeaponIdle() {
        if ((mRageTime > 0) && (g_Engine.time >= mRageTime)) {
            TurnOffRage();
        }
    }
    /** サードアタック */
    void TertiaryAttack() {
        self.SendWeaponAnim( WEAPONBASE_FIDGET ,0 ,0);
        self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
        
        TurnOnRage();
    }
    
    /** Rage、特殊攻撃の最低値セット */
    protected void SetMinimumAmmo() {
        // Rageゲージ最低値１
        if (m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType ) < 1) {
            m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType, 1);
        }
    }
    
    /** Rageポイント獲得 */
    protected void GainRage(int ragePoint) {
        // Rageゲージ増加
        if ((mRageLevel == 0) && (m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) < UBOAKIAI_MAX_AMMO)) {
            m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) + ragePoint);
            
            if (m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) >= UBOAKIAI_MAX_AMMO) {
                m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, UBOAKIAI_MAX_AMMO);
                mRageEffect.ReadyEffect(m_pPlayer);
            }
        }
    }
    
    /** 攻撃方向計算 */
    protected Vector calcDirection(float baseLen, float degrees) {
        // degrees: 90度から +が右 -左
        float rad = Math.DegreesToRadians(90.0 - degrees);
        float plusMinus = (degrees >= 0) ? 1.0 : -1.0;
        
        Vector ret = Vector(baseLen * sin(rad), plusMinus * baseLen * cos(rad), 0);
        return ret;
    }
    
    
    // 画面表示
    protected void DisplayStatus() {
        string msg = "";
        msg += mDispName + "\n";
        msg += "  POWER:\n    " + DrawStatusParam(mDispPower);
        msg += "  SPEED:\n    " + DrawStatusParam(mDispSpeed);
        msg += "  REACH:\n    " + DrawStatusParam(mDispReach);
        
        if (mDispSkill != "") {
            msg += "-- SPECIAL ATTACK --------------\n";
            msg += mDispSkill + "\n";
        }
        
        HUDTextParams textParms;
        textParms.fxTime = 30;
        textParms.fadeinTime = 0.5;
        textParms.holdTime = 3.0;
        textParms.fadeoutTime = 1.0;
        textParms.effect = 0;
        textParms.channel = 2;
        textParms.x = 0.05;
        textParms.y = 0.20;
        
        if (mDispColorType == 0) {
            textParms.r1 = 0;
            textParms.g1 = 255;
            textParms.b1 = 255;
            textParms.r2 = 0;
            textParms.g2 = 0;
            textParms.b2 = 255;
        } else {
            textParms.r1 = 0;
            textParms.g1 = 255;
            textParms.b1 = 64;
            textParms.r2 = 0;
            textParms.g2 = 192;
            textParms.b2 = 16;
        }
        g_PlayerFuncs.HudMessage(m_pPlayer, textParms, msg);
    }
    
    // パラメータの描画
    private string DrawStatusParam(int value) {
        const string PARAM = ">";
        string ret = "";
        for (int i = 0; i < value; i++) {
            ret += PARAM;
        }
        ret += "\n";
        return ret;
    }
}

/** 攻撃情報 */
class AttackInfo {
    float  dmg          = 50;                            // ダメージ
    int    dmgType      = DMG_CLUB;                      // ダメージタイプ
    Vector rangeDir     = Vector(60.0, 0, 0);            // 方向ベクトル補正値(x=forward, y=right, z=up)
    bool   critical     = (Math.RandomLong(0, 50) == 0); // クリティカル条件
    float  criticalRate = 2.0;                           // クリティカル時ダメージ倍率
    float  knockback    = 100.0;                         // ノックバック
    int    rageGain     = Math.RandomLong(1, 3);         // 獲得Rageポイント
    bool   swingSound   = true;                          // 攻撃サウンド再生するか（多段攻撃用）
    bool   hitSound     = true;                          // ヒットサウンド再生するか（多段攻撃用）
    string soundName    = "uboa_rampage/bishi.wav";      // ヒットサウンド名
    
    float  delayTime    = 0.1;                           // 多段攻撃時のディレイ処理用
}

