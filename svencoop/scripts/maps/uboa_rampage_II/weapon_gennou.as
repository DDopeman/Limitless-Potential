/* 
 * 金槌
 */
#include "weapon_playerclassbase"

/** 金槌 */
class weapon_gennou : weapon_playerclassbase {
    
    weapon_gennou() {
        this.mVmodel = "models/uboa_rampage_II/v_gennou.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_gennou.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_gennou.mdl";
        
        this.mModels.insertLast("sprites/laserbeam.spr");
        
        this.mSounds.insertLast("houndeye/he_blast1.wav");
        
        this.mSounds.insertLast("uboa_rampage/doka.wav");
        this.mSounds.insertLast("uboa_rampage_II/strikeattack.wav");
        
        mMaxCombo = 2;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = UBOAWAZA_MAX_AMMO;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 1;
        info.iPosition = 8;
        info.iFlags    = 0;
        info.iWeight   = 10;
        return true;
    }    
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Genno hammer] (WORKER)";
        this.mDispSkill = 
                  "  impact -20SP (Forward)\n"
                + "  Hammer swing -10SP (Left/Right)\n"
                + "  Shock wave -40SP (Back)\n";
        this.mDispPower = 4;
        this.mDispSpeed = 1;
        this.mDispReach = 2;
        
        return weapon_playerclassbase::Deploy();
    }
   
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.125 : 0.6;
                
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
            delay = 0.2;
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
        const int SKILLCOST = 10;
        if (ConsumeSkill(SKILLCOST)) {
            return;
        }
        mCombo = 0;
        
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.23 : 0.3;
        float spdDelay = (mRageLevel > 0) ? 1.0 : 1.5;
        
        // 最終SP攻撃方向キー更新
        updateDirection();
        
        AttackInfo atk;
        mSpAtk.resize(0);
        
        // 動作
        switch (this.mLastSpDirection) {
        case IN_FORWARD: 
            
            SetThink(ThinkFunction(this.SpFowardDelay));
            self.pev.nextthink = g_Engine.time + 0.15;
            break;
            
        case IN_BACK:
            
            SetThink(ThinkFunction(this.SpBackDelay));
            self.pev.nextthink = g_Engine.time + 0.3;
            break;
            
        case IN_MOVELEFT:
            
            atk.dmgType = DMG_CRUSH;
            atk.dmg = 60.0 + Math.RandomFloat(-20.0, 20.0);
            atk.criticalRate = 2.3;
            atk.critical = (Math.RandomLong(0, 60) == 0);
            atk.rageGain = Math.RandomLong(1, 3);
            atk.soundName = "uboa_rampage_II/strikeattack.wav";
            atk.rangeDir = calcDirection(68.0, -30);
            mSpAtk.insertLast(atk);
            atk.swingSound = false;            
            atk.rangeDir = calcDirection(68.0, 10);
            mSpAtk.insertLast(atk);
            
            SetThink(ThinkFunction(this.SpDelayRecursive));
            self.pev.nextthink = g_Engine.time + 0.2; 
            break;
            
        case IN_MOVERIGHT: 
            
            atk.dmgType = DMG_CRUSH;
            atk.dmg = 60.0 + Math.RandomFloat(-20.0, 20.0);
            atk.criticalRate = 2.3;
            atk.critical = (Math.RandomLong(0, 60) == 0);
            atk.rageGain = Math.RandomLong(1, 3);
            atk.soundName = "uboa_rampage_II/strikeattack.wav";
            atk.rangeDir = calcDirection(68.0, 30);
            mSpAtk.insertLast(atk);
            atk.swingSound = false;
            atk.rangeDir = calcDirection(68.0, -10);
            mSpAtk.insertLast(atk);
            
            SetThink(ThinkFunction(this.SpDelayRecursive));
            self.pev.nextthink = g_Engine.time + 0.2;
            break;
        }
        
        // モーション
        self.SendWeaponAnim( animFromDirection(), 0, 0);
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    // 衝撃波
    private void SonicWave(Vector pos, float radius) {
        
        // 波動
        NetworkMessage messageWave(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        messageWave.WriteByte(TE_BEAMCYLINDER);
        messageWave.WriteCoord(pos.x);
        messageWave.WriteCoord(pos.y);
        messageWave.WriteCoord(pos.z);
        messageWave.WriteCoord(pos.x);
        messageWave.WriteCoord(pos.y);
        messageWave.WriteCoord(pos.z + radius * 3);
        messageWave.WriteShort(g_EngineFuncs.ModelIndex("sprites/laserbeam.spr"));
        messageWave.WriteByte(0);   // スタートフレーム
        messageWave.WriteByte(16);  // フレームレート
        messageWave.WriteByte(2);   // LIFE
        messageWave.WriteByte(16);   // 幅
        messageWave.WriteByte(0);   // ノイズ
        messageWave.WriteByte(255); // R
        messageWave.WriteByte(255); // G
        messageWave.WriteByte(255); // B
        messageWave.WriteByte(100); // A
        messageWave.WriteByte(0);   // スクロールスピード
        messageWave.End();
        
        // 当たり判定計算
        CBaseEntity@ pEntity = null;        
        while ((@pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pos, radius, "*", "classname" )) !is null) {
            if (( pEntity.pev.takedamage != DAMAGE_NO) && (pEntity.Classify() != CLASS_PLAYER) && (pEntity.Classify() != CLASS_PLAYER_ALLY) ){
                    
                float flAdjustedDamage = (300.0 + Math.RandomFloat(-50.0, 50.0)) + 100.0 * mDmgRate;

                float flDist = (pEntity.Center() - pos).Length();
                flAdjustedDamage -= ( flDist / radius ) * flAdjustedDamage;

                if (flAdjustedDamage > 0 ) {
                    pEntity.TakeDamage ( pev, pev.owner.vars, flAdjustedDamage , DMG_SONIC | DMG_ALWAYSGIB );
                    GainRage(Math.RandomLong(0, 2));
                }
            }
        }
        
    }
    // 通常攻撃
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 90.0 + Math.RandomFloat(-20.0, 20.0);
        atk.criticalRate = 2.3;
        atk.critical = (Math.RandomLong(0, 60) == 0);
        atk.rageGain = Math.RandomLong(1, 2);
        atk.dmgType = DMG_CRUSH;
        atk.soundName = "uboa_rampage/doka.wav";
        atk.rangeDir = Vector(68.0, 0, 0);
        NormalAttack(atk);
        
    }
    // 前方特殊攻撃
    private void SpFowardDelay() {
        AttackInfo atk;
        atk.dmg = 130.0 + Math.RandomFloat(-20.0, 20.0);
        atk.critical = (Math.RandomLong(0, 60) == 0);
        atk.rageGain = Math.RandomLong(1, 3);
        atk.dmgType = DMG_CRUSH;
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        atk.rangeDir = Vector(68.0, 0, 0);
        NormalAttack(atk);
        
        
        // 追加で消費
        if (ConsumeSkill(10)) {
            return;
        }
        // 前方へ衝撃波
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "houndeye/he_blast1.wav", 1, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5));
        
        // 壁との衝突チェック
        TraceResult tr;
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Math.MakeVectors( m_pPlayer.pev.v_angle );
        g_Utility.TraceLine( vecSrc, vecSrc + g_Engine.v_forward * 100.0, dont_ignore_monsters, m_pPlayer.edict(), tr );
        SonicWave(tr.vecEndPos, (mRageLevel > 0) ? 65.0 : 50.0);
        
    }
    
    // 後方特殊攻撃
    private void SpBackDelay() {        
        AttackInfo atk;
        atk.dmg = 130.0 + Math.RandomFloat(-20.0, 20.0);
        atk.critical = (Math.RandomLong(0, 60) == 0);
        atk.rageGain = Math.RandomLong(1, 3);
        atk.dmgType = DMG_CRUSH;
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        atk.rangeDir = Vector(68.0, 0, 0);
        NormalAttack(atk);
        
        
        // 追加で消費
        if (ConsumeSkill(30)) {
            return;
        }
        // 中心に衝撃波
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "houndeye/he_blast1.wav", 1, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5));
        SonicWave(m_pPlayer.pev.origin, (mRageLevel > 0) ? 250.0 : 200.0);
    }
    
    // 左右特殊攻撃（多段ヒット）
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

string GetGennouName() {
    return "weapon_gennou";
}

void RegisterGennou() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_gennou", GetGennouName() );
    g_ItemRegistry.RegisterWeapon( GetGennouName(), "uboa_rampage_II", UBOAWAZA_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}
