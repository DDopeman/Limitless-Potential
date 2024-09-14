/* 
 * 鉄骨
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_tekkotsu : weapon_pickupbase {
    
    weapon_tekkotsu() {
        this.mVmodel = "models/uboa_rampage_II/v_tekkotsu.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_tekkotsu.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_tekkotsu.mdl";
        
        this.mModels.insertLast("sprites/laserbeam.spr");
        this.mSounds.insertLast("houndeye/he_blast1.wav");
        
        this.mSounds.insertLast("uboa_rampage/doka.wav");
        this.mSounds.insertLast("uboa_rampage_II/strikeattack.wav");
        
        mMaxCombo = 2;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 11;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 150;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Steel frame] (WORKER)";
        this.mDispSkill = (this.mPlayerClassType == CLASSTYPE_WORKER) 
                ? "  Ground strike (Stand and hit ground)\n" : "";
        this.mDispPower = 5;
        this.mDispSpeed = 1;
        this.mDispReach = 5;
        
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.34 : 0.58;
        
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
                spdBuf = (mRageLevel > 0) ? 0.5 : 1.0;
                spdDelay = (mRageLevel > 0) ? 0.4 : 0.6;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.3;          
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.5 : 1.0;
                spdDelay = (mRageLevel > 0) ? 0.4 : 0.6;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay2));
                self.pev.nextthink = g_Engine.time + 0.5;      
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.5 : 1.0;
            spdDelay = (mRageLevel > 0) ? 0.4 : 0.6;
            
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
        atk.dmg = 120.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(94.0, 0, 0);
        atk.soundName = "uboa_rampage/doka.wav";
        
        
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
        atk.dmg = 180.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(94.0, 0, 0);
        atk.soundName = "uboa_rampage_II/strikeattack.wav";
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
    }
    
    // 特殊攻撃
    private void SpDelay2() {
        SpDelay1();
                
        TraceResult tr;
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Math.MakeVectors( m_pPlayer.pev.v_angle );
        g_Utility.TraceLine( vecSrc, vecSrc + g_Engine.v_forward * 300, ignore_monsters, m_pPlayer.edict(), tr );
        
        // 地面を殴る距離の場合、波動
        if ((tr.vecEndPos - vecSrc).Length() <= 200) {
            
            // 電撃
            BeamEffects(tr.vecEndPos + g_Engine.v_forward * 100.0 + Vector( 0, 0, 500 ),
                        tr.vecEndPos + g_Engine.v_forward * 100.0);
            // 前方へ衝撃波
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "houndeye/he_blast1.wav", 1, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5));
            SonicWave(tr.vecEndPos + Vector( 0, 0, 30 ), 300.0);            
            
            if (ConsumeDurability(Math.RandomLong(10, 20))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
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
        messageWave.WriteByte(0);   // G
        messageWave.WriteByte(0);   // B
        messageWave.WriteByte(100); // A
        messageWave.WriteByte(0);   // スクロールスピード
        messageWave.End();
        
        // 当たり判定計算
        CBaseEntity@ pEntity = null;        
        while ((@pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pos, radius, "*", "classname" )) !is null) {
            if (( pEntity.pev.takedamage != DAMAGE_NO) && (pEntity.Classify() != CLASS_PLAYER) && (pEntity.Classify() != CLASS_PLAYER_ALLY) ){
                    
                float flAdjustedDamage = (400.0 + Math.RandomFloat(-100.0, 100.0)) + 50.0 * mDmgRate;

                float flDist = (pEntity.Center() - pos).Length();
                flAdjustedDamage -= ( flDist / radius ) * flAdjustedDamage;

                if (flAdjustedDamage > 0 ) {
                    pEntity.TakeDamage ( pev, pev.owner.vars, flAdjustedDamage , DMG_SONIC | DMG_ALWAYSGIB );
                    GainRage(Math.RandomLong(0, 2));
                }
            }
        }
        
    }
    
    // 電撃
    void BeamEffects(Vector startPos, Vector endPos) {
        NetworkMessage msgBeam(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        msgBeam.WriteByte(TE_BEAMPOINTS);
        msgBeam.WriteCoord(startPos.x);
        msgBeam.WriteCoord(startPos.y);
        msgBeam.WriteCoord(startPos.z);
        msgBeam.WriteCoord(endPos.x);
        msgBeam.WriteCoord(endPos.y);
        msgBeam.WriteCoord(endPos.z);
        msgBeam.WriteShort(g_EngineFuncs.ModelIndex("sprites/laserbeam.spr"));
        msgBeam.WriteByte(0);   // frameStart
        msgBeam.WriteByte(100); // frameRate
        msgBeam.WriteByte(10);  // life
        msgBeam.WriteByte(32);  // width
        msgBeam.WriteByte(20);  // noise
        msgBeam.WriteByte(255);
        msgBeam.WriteByte(0);
        msgBeam.WriteByte(0);
        msgBeam.WriteByte(192);   // actually brightness
        msgBeam.WriteByte(5);   // scroll
        msgBeam.End();
    }
}

string GetTekkotsuName() {
    return "weapon_tekkotsu";
}

void RegisterTekkotsu() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_tekkotsu", GetTekkotsuName() );
    g_ItemRegistry.RegisterWeapon( GetTekkotsuName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}

