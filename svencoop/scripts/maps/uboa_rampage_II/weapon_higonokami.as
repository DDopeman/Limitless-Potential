/* 
 * ナイフ
 */
#include "weapon_playerclassbase"

/** ナイフクラス */
class weapon_higonokami : weapon_playerclassbase {
    
    weapon_higonokami() {
        this.mVmodel = "models/uboa_rampage_II/v_higonokami.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_higonokami.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_higonokami.mdl";
        
        this.mModels.insertLast("models/uboa_rampage_II/throwknife.mdl");
        this.mModels.insertLast("sprites/laserbeam.spr");
        
        this.mSounds.insertLast("weapons/xbow_hit1.wav");
        this.mSounds.insertLast("weapons/cbar_miss1.wav");
        
        this.mSounds.insertLast("uboa_rampage_II/bladeattack.wav");
        
        mMaxCombo = 3;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = UBOAWAZA_MAX_AMMO;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 1;
        info.iPosition = 7;
        info.iFlags    = 0;
        info.iWeight   = 10;
        return true;
    }    
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Folding metal knife] (WEAPON MASTER)";
        this.mDispSkill = "  Throw knife -6SP\n";
        this.mDispPower = 3;
        this.mDispSpeed = 2;
        this.mDispReach = 2;
        
        return weapon_playerclassbase::Deploy();
    }
   
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.2 : 0.35;
        
        int anim;
        if (mRageLevel == 0) {
            anim = (mCombo % 2 == 0) ? BASEPLAYERCLASSS_1_NORMAL_1 : BASEPLAYERCLASSS_2_NORMAL_1;
        } else {
            anim = (Math.RandomLong(0, 1) == 0) ? BASEPLAYERCLASSS_1_NORMAL_2 : BASEPLAYERCLASSS_2_NORMAL_2;
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
        const int SKILLCOST = 6;
        if (ConsumeSkill(SKILLCOST)) {
            return;
        }
        mCombo = 0;
        
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.18 : 0.3;
        float spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
        
        // 最終SP攻撃方向キー更新
        updateDirection();
            
        // モーション
        self.SendWeaponAnim( animFromDirection(), 0, 0);        
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
        if (mRageLevel > 0) {
            SetThink(ThinkFunction(this.SpDelay2));
        } else {
            SetThink(ThinkFunction(this.SpDelay1));
        }
        self.pev.nextthink = g_Engine.time + 0.13;
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 80.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.critical = (Math.RandomLong(0, 45) == 0);
        atk.rageGain = Math.RandomLong(1, 3);
        atk.dmgType = DMG_SLASH;
        atk.soundName = "uboa_rampage_II/bladeattack.wav";
        atk.rangeDir = Vector(65.0, 0, 0);
        NormalAttack(atk);
        
    }
    
    // 特殊攻撃（ナイフ投げ）
    private void SpDelay1() {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "weapons/cbar_miss1.wav", 1, ATTN_NORM, 0, PITCH_NORM);
        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
        ShootKnife(m_pPlayer.pev,
                     m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * 2 + g_Engine.v_right * -2,
                     g_Engine.v_forward * 500);
        
    }
    // 特殊攻撃（ナイフ投げ x3）
    private void SpDelay2() {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "weapons/cbar_miss1.wav", 1, ATTN_NORM, 0, PITCH_NORM);
        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
        
        ShootKnife(m_pPlayer.pev,
                     m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * 2 + g_Engine.v_right * -2,
                     g_Engine.v_forward * 500);
        ShootKnife(m_pPlayer.pev,
                     m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * 2 + g_Engine.v_right * -30 ,
                    g_Engine.v_forward * 500 + g_Engine.v_up * Math.RandomFloat(-200, 200) + g_Engine.v_right * Math.RandomFloat(-200, 200));
        ShootKnife(m_pPlayer.pev,
                     m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * 2 + g_Engine.v_right * 30 ,
                    g_Engine.v_forward * 500 + g_Engine.v_up * Math.RandomFloat(-200, 200) + g_Engine.v_right * Math.RandomFloat(-200, 200));
        
    }
    
    
    /** ナイフ投げ処理 */
    private void ShootKnife(entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity) {
        
        CBaseEntity@ cbeKnife = g_EntityFuncs.CreateEntity( "throwknife_shot", null,  false);
        throwknife_shot@ pKnife = cast<throwknife_shot@>(CastToScriptClass(cbeKnife));
        
        g_EntityFuncs.SetOrigin( pKnife.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pKnife.self.edict() );
        
        pKnife.pev.velocity = vecVelocity;
        @pKnife.pev.owner = pevOwner.pContainingEntity;
        pKnife.pev.angles = Math.VecToAngles( pKnife.pev.velocity );
        pKnife.SetThink( ThinkFunction( pKnife.BulletThink ) );
        pKnife.pev.nextthink = g_Engine.time + 0.1;
        pKnife.SetTouch( TouchFunction( pKnife.Touch ) );
        
        // プレイヤーのインデックスをセット
        pKnife.pev.iuser4 = (mRageLevel == 0) ? g_EngineFuncs.IndexOfEdict(m_pPlayer.edict()) : 0; 
        
        switch (this.mLastSpDirection) {
        case IN_BACK:      pKnife.pev.angles.z = pKnife.pev.angles.z - 180.0; break;
        case IN_MOVELEFT:  pKnife.pev.angles.z = pKnife.pev.angles.z + 90.0;  break;
        case IN_MOVERIGHT: pKnife.pev.angles.z = pKnife.pev.angles.z - 90.0;  break;
        }
        
    }
}

string GetHigonokamiName() {
    return "weapon_higonokami";
}

void RegisterHigonokami() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_higonokami", GetHigonokamiName() );
    g_ItemRegistry.RegisterWeapon( GetHigonokamiName(), "uboa_rampage_II", UBOAWAZA_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

// --------------------------------------------------------------

class throwknife_shot : ScriptBaseMonsterEntity {
    private float mLifeTime;    // 寿命
    
    void Spawn() {
        Precache();
        pev.solid = SOLID_SLIDEBOX;
        pev.movetype = MOVETYPE_FLY;
        pev.takedamage = DAMAGE_YES;
        pev.scale = 1;
        self.ResetSequenceInfo();
        
        pev.movetype = MOVETYPE_FLY;
        g_EntityFuncs.SetModel( self, "models/uboa_rampage_II/throwknife.mdl");
        
        this.mLifeTime = 0;
        
        SetThink( ThinkFunction( this.BulletThink ) );
    }

    private void Precache() {
        g_Game.PrecacheModel( "models/uboa_rampage_II/throwknife.mdl" ); 
        g_Game.PrecacheModel("sprites/laserbeam.spr");
        g_SoundSystem.PrecacheSound( "weapons/xbow_hit1.wav" );
        g_SoundSystem.PrecacheSound( "weapons/cbar_miss1.wav" );
        g_SoundSystem.PrecacheSound("uboa_rampage_II/bladeattack.wav");
    }
    
    void Touch ( CBaseEntity@ pOther ) {
        const float HITDAMAGE = 90.0 + Math.RandomFloat(-20.0, 20.0);
        
        // プレイヤーにはダメージ通らない
        if ((pOther.Classify() == CLASS_PLAYER) || (pOther.Classify() == CLASS_PLAYER_ALLY)) {
            return;
        }
        
        // 壁ヒット後の残像
        if ( ( pOther.TakeDamage ( pev, pev, 0, DMG_SLASH ) ) != 1 ) {
            
            pev.solid = SOLID_NOT;
            pev.movetype = MOVETYPE_FLY;
            pev.velocity = Vector( 0, 0, 0 );
            g_Utility.Sparks( pev.origin );
            self.StopAnimation();
        
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "weapons/xbow_hit1.wav", 1, ATTN_NORM, 0, PITCH_NORM);
            
            this.mLifeTime = g_Engine.time + 1.0;
            
        // 直撃
        } else {
            
            g_WeaponFuncs.SpawnBlood(pev.origin, pOther.BloodColor(), HITDAMAGE);
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "uboa_rampage_II/bladeattack.wav", 1, ATTN_NORM, 0, PITCH_NORM);
            
            // pev.iuser4からプレイヤー情報を復元
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(pev.iuser4);
            if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive())) {
                pPlayer.GiveAmmo(Math.RandomLong(0, 1), UBOAKIAI_AMMO_NAME, UBOAKIAI_MAX_AMMO);
            }
            
            pOther.TakeDamage ( pev, pev.owner.vars, HITDAMAGE, DMG_SLASH );
            g_EntityFuncs.Remove( self ); 
        }
    }
    
    void BulletThink() {
        pev.nextthink = g_Engine.time + 0.1;
        pev.velocity = pev.velocity + g_Engine.v_up * -30;
        
        int tailId = g_EntityFuncs.EntIndex(self.edict());
        int sprId  = g_EngineFuncs.ModelIndex("sprites/laserbeam.spr");
        NetworkMessage nm(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        nm.WriteByte(TE_BEAMFOLLOW);
        nm.WriteShort(tailId);
        nm.WriteShort(sprId);
        nm.WriteByte(2);    // 描画時間
        nm.WriteByte(2);    // サイズ
        nm.WriteByte(128);  // R
        nm.WriteByte(128);  // G
        nm.WriteByte(128);  // B
        nm.WriteByte(64);   // A
        nm.End();
        
        // ヒットしてたら、時間で消える
        if ((this.mLifeTime > 0) && (g_Engine.time  >= this.mLifeTime)) {
            g_EntityFuncs.Remove( self );
        }
    }

}

string GetThrowknifeName() {
    return "throwknife_shot";
}

void RegisterThrowknife() {
    g_CustomEntityFuncs.RegisterCustomEntity( "throwknife_shot", GetThrowknifeName() );
}
