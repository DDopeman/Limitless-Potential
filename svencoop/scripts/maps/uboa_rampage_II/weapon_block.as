/* 
 * ブロック
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_block : weapon_pickupbase {
    
    private int mSpCnt; // 特殊攻撃の回数
    
    weapon_block() {
        this.mVmodel = "models/uboa_rampage_II/v_block.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_block.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_block.mdl";
        
        this.mModels.insertLast("sprites/laserbeam.spr");
        this.mSounds.insertLast("houndeye/he_blast1.wav");
        
        this.mSounds.insertLast("weapons/knife1.wav");
        this.mSwingSound = "weapons/knife1.wav";
        mMaxCombo = 5;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 14;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 140;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Brick] (KARATEKA)";
        this.mDispSkill = (this.mPlayerClassType == CLASSTYPE_KARATEKA) 
                ? "  Karate shock wave (Stand)\n" : "";
        this.mDispPower = 3;
        this.mDispSpeed = 4;
        this.mDispReach = 2;
        
        this.mSpCnt = 0;
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.25 : 0.4;
        
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
        
        
        if (this.mPlayerClassType == CLASSTYPE_KARATEKA) {
            
            if ((m_pPlayer.pev.button & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) ) != 0) {
                spdBuf = (mRageLevel > 0) ? 0.3 : 0.6;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.3;
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.4 : 0.8;
                spdDelay = (mRageLevel > 0) ? 0.4 : 0.6;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay2));
                self.pev.nextthink = g_Engine.time + 0.5;
                
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.3 : 0.6;
            spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
            
            anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
            self.SendWeaponAnim( anim, 0, 0);        
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            
            SetThink(ThinkFunction(this.SpDelay1));
            self.pev.nextthink = g_Engine.time + 0.3;
            
        }
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 90.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(68.0, 0, 0);
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
        
    }
    
    // 強攻撃
    private void SpDelay1() {
        AttackInfo atk;
        atk.dmg = 120.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(68.0, 0, 0);
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 3))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
    
    // 特殊攻撃
    private void SpDelay2() {
        // 衝撃波
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "houndeye/he_blast1.wav", 1, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5));
        
        this.mSpCnt = 3;
        SetThink(ThinkFunction(this.SpWaveRecursive));
        self.pev.nextthink = g_Engine.time + 0.05;
        
        if (ConsumeDurability(Math.RandomLong(5, 10))) {
            BrokenEffect();
            g_EntityFuncs.Remove( self ); 
            return;
        }
    }
    
    // 衝撃波繰り返し処理
    private void SpWaveRecursive() {
                
        if (this.mSpCnt > 0) {
            SonicWave(m_pPlayer.pev.origin, 300.0);
            
            SetThink(ThinkFunction(this.SpWaveRecursive));
            self.pev.nextthink = g_Engine.time + 0.1;
        }
        this.mSpCnt--;
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
        messageWave.WriteByte(16);  // 幅
        messageWave.WriteByte(0);   // ノイズ
        messageWave.WriteByte(255); // R
        messageWave.WriteByte(201); // G
        messageWave.WriteByte(14);  // B
        messageWave.WriteByte(100); // A
        messageWave.WriteByte(0);   // スクロールスピード
        messageWave.End();
        
        // 当たり判定計算
        CBaseEntity@ pEntity = null;        
        while ((@pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pos, radius, "*", "classname" )) !is null) {
            if (( pEntity.pev.takedamage != DAMAGE_NO) && (pEntity.Classify() != CLASS_PLAYER) && (pEntity.Classify() != CLASS_PLAYER_ALLY) ){
                    
                float flAdjustedDamage = (100.0 + Math.RandomFloat(-20.0, 20.0)) + 50.0 * mDmgRate;

                float flDist = (pEntity.Center() - pos).Length();
                flAdjustedDamage -= ( flDist / radius ) * flAdjustedDamage;

                if (flAdjustedDamage > 0 ) {
                    pEntity.TakeDamage ( pev, pev.owner.vars, flAdjustedDamage , DMG_SONIC | DMG_ALWAYSGIB );
                    GainRage(Math.RandomLong(0, 2));
                }
            }
        }
        
    }
}

string GetBlockName() {
    return "weapon_block";
}

void RegisterBlock() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_block", GetBlockName() );
    g_ItemRegistry.RegisterWeapon( GetBlockName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

