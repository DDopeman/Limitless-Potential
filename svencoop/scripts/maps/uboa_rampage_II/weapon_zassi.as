/* 
 * 雑誌（PlayerClassチェンジャー）
 */
#include "CPlayerClassUtil"

enum playerClasschanger_e {
    PLAYERCLASSCHANGE_IDLE = 0,
    PLAYERCLASSCHANGE_CLOSEIDLE,
    PLAYERCLASSCHANGE_DRAW,
    PLAYERCLASSCHANGE_OPEN,
    PLAYERCLASSCHANGE_CLOSE,
    PLAYERCLASSCHANGE_TURNPAGE
};

/** 雑誌クラス */
class weapon_zassi : ScriptBasePlayerWeaponEntity {
    private CBasePlayer@ m_pPlayer = null;
    private CPlayerClassUtil mPcUtil;
    private int mCurrent = 0; // 選択PlayerClass
    private bool mIsOpened = false;
    
    /** Spawn時 */
    void Spawn() {
        self.Precache();
        self.m_iDefaultAmmo = 100;
        mCurrent = 0;
        
        g_EntityFuncs.SetModel( self, self.GetW_Model( "models/uboa_rampage_II/w_zassi.mdl") );
        self.FallInit();
    }

    /** プリキャッシュ */
    private void Precache() {
        self.PrecacheCustomModels();

        g_Game.PrecacheModel( "models/uboa_rampage_II/v_zassi.mdl" );
        g_Game.PrecacheModel( "models/uboa_rampage_II/w_zassi.mdl" );
        g_Game.PrecacheModel( "models/uboa_rampage_II/p_zassi.mdl" );
        
        g_SoundSystem.PrecacheSound( "items/r_item2.wav" );
        
        g_SoundSystem.PrecacheSound( "uboa_rampage_II/turnpage.wav" );
        
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = UBOAPLAYERCLASS_MAX_AMMO;
        info.iMaxAmmo2 = -1;
        info.iMaxClip  = 0;
        info.iSlot     = 0;
        info.iPosition = 5;
        info.iFlags    = 0;
        info.iWeight   = 1;
        return true;
    }    
    
    /** プレイヤーが武器を取得時 */
    bool AddToPlayer( CBasePlayer@ pPlayer ) {
        if (!BaseClass.AddToPlayer( pPlayer )) {
            return false;
        }
        @m_pPlayer = pPlayer;
        return true;
    }

    /** 武器取り出し時 */
    bool Deploy() {
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 1.0;
        
        mIsOpened = false;
        
        mPcUtil.CheckStatus(m_pPlayer, false);
        
        return self.DefaultDeploy( self.GetV_Model( "models/uboa_rampage_II/v_zassi.mdl" ),
            self.GetP_Model( "models/uboa_rampage_II/p_zassi.mdl" ), PLAYERCLASSCHANGE_DRAW, "trip" );
    }

    /** 武器ホルスター時 */
    void Holster(int skiplocal) {
        self.m_fInReload = false;
        mIsOpened = true;
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 本を開いているなら、ページめくる
        if (mIsOpened) {
            mCurrent++;
            mCurrent = (mCurrent > 3) ? 0 : mCurrent;
            self.SendWeaponAnim(PLAYERCLASSCHANGE_TURNPAGE, 0, mCurrent);
            
        // 本を閉じているので開く
        } else {
            self.SendWeaponAnim(PLAYERCLASSCHANGE_OPEN, 0, mCurrent);
            mIsOpened = true;
        }
        SetThink(ThinkFunction(this.DispMessageDelay));
        self.pev.nextthink = g_Engine.time + 0.6;
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 1.0;            
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "uboa_rampage_II/turnpage.wav", 1, ATTN_NORM, 0, PITCH_NORM);
        
    }
    
    /** セカンダリアタック */
    void SecondaryAttack() {
        // 本を開いているなら、PlayerClass編ｋ脳
        if (mIsOpened) {
            // 消費量以下なら何もしない
            if (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < 100) {
                g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "You don't have enough Class points!!\n");
                
            } else {
                // 武器を除去
                if (mPcUtil.PreChangePlayerClass(m_pPlayer, mCurrent)) {
                    m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 1);
                    
                    // 武器を追加
                    SetThink(ThinkFunction(this.ProvideWeaponDelay));
                    self.pev.nextthink = g_Engine.time + 0.5;
                }
                m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 1.0;
            }
            
        // 本を閉じているので開く
        } else {
            PrimaryAttack();
        }
    }
    
    
    /** サードアタック */
    void TertiaryAttack() {
        // 本を開いているなら、ページめくる
        if (mIsOpened) {
            mCurrent--;
            mCurrent = (mCurrent < 0) ? 3 : mCurrent;
            self.SendWeaponAnim(PLAYERCLASSCHANGE_TURNPAGE, 0, mCurrent);
            
        // 本を閉じているので開く
        } else {
            self.SendWeaponAnim(PLAYERCLASSCHANGE_OPEN, 0, mCurrent);
            mIsOpened = true;
        }
        SetThink(ThinkFunction(this.DispMessageDelay));
        self.pev.nextthink = g_Engine.time + 0.6;
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
        m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 1.0;            
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "uboa_rampage_II/turnpage.wav", 1, ATTN_NORM, 0, PITCH_NORM);
        
    }
    
    /** リロード */
    void Reload() {
        if (mIsOpened) {
            self.SendWeaponAnim(PLAYERCLASSCHANGE_CLOSE, 0, mCurrent);
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "uboa_rampage_II/turnpage.wav", 1, ATTN_NORM, 0, PITCH_NORM);
            mIsOpened = false;
        }
    }
    
    // メッセージ表示
    private void DispMessageDelay() {
        mPcUtil.DescriptionPlayerClass(m_pPlayer, mCurrent);
        
        g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTCENTER, "[PRIMARY ATTACK]: Next\n[SECONDARY ATTACK]: Select\n");
    }
    
    // PLAYERCLASSチェンジ処理
    private void ProvideWeaponDelay() {
        mPcUtil.PostChangePlayerClass(m_pPlayer, mCurrent);
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "items/r_item2.wav", 1, ATTN_NORM, 0, PITCH_NORM);
    }
    
}

string GetZassiName() {
    return "weapon_zassi";
}

void RegisterZassi() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zassi", GetZassiName() );
    g_ItemRegistry.RegisterWeapon( GetZassiName(), "uboa_rampage_II", UBOAPLAYERCLASS_AMMO_NAME);
}


// -----------------------------------------------------

const string UBOAPLAYERCLASS_AMMO_NAME = "ammo_playerclass";
const int UBOAPLAYERCLASS_MAX_AMMO = 100;

/** パークチェンジ用ゲージクラス */
class PlayerClassAmmo : ScriptBasePlayerAmmoEntity {
    void Spawn() {
        g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
        g_Game.PrecacheModel( "models/uboa_rampage_II/rirekisho.mdl" );
        
        g_EntityFuncs.SetModel( self, "models/uboa_rampage_II/rirekisho.mdl" );
        
        BaseClass.Spawn();
        self.pev.rendermode  = kRenderNormal;
        self.pev.renderfx    = kRenderFxGlowShell;
        self.pev.renderamt   = 4;
        self.pev.rendercolor = Vector(128, 128, 128);
    }
    
    bool AddAmmo( CBaseEntity@ pither ) {
        if (pither.GiveAmmo( UBOAPLAYERCLASS_MAX_AMMO, UBOAPLAYERCLASS_AMMO_NAME, UBOAPLAYERCLASS_MAX_AMMO ) != -1 ) {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterPlayerClassAmmo() {
    g_CustomEntityFuncs.RegisterCustomEntity( "PlayerClassAmmo", UBOAPLAYERCLASS_AMMO_NAME );
}