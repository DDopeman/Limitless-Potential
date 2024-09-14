/* 
 * 刀
 */
#include "weapon_pickupbase"
#include "CPlayerClassUtil"

class weapon_katana : weapon_pickupbase {
    
    weapon_katana() {
        this.mVmodel = "models/uboa_rampage_II/v_katana.mdl";
        this.mPmodel = "models/uboa_rampage_II/p_katana.mdl";
        this.mWmodel = "models/uboa_rampage_II/w_katana.mdl";
        
        this.mModels.insertLast("models/uboa_rampage_II/swordwave.mdl");
        
        this.mSounds.insertLast("weapons/xbow_hit1.wav");
        this.mSounds.insertLast("uboa_rampage_II/bladeattack.wav");
        
        this.mDmgSound = "uboa_rampage_II/bladeattack.wav";
        
        mMaxCombo = 5;
    }

    /** 武器情報 */
    bool GetItemInfo( ItemInfo& out info ) {
        info.iMaxAmmo1 = 1;
        info.iMaxAmmo2 = UBOAKIAI_MAX_AMMO;
        info.iMaxClip  = 0;
        info.iSlot     = 2;
        info.iPosition = 8;
        info.iFlags    = 0;
        info.iWeight   = 20;
        return true;
    }
    
    /** Spawn時 */
    void Spawn() {
        mDurability = 90;
        
        weapon_pickupbase::Spawn();
    }
    
    /* 武器取り出し */
    bool Deploy() {
        this.mDispName = "[Katana] (WEAPON MASTER)";
        this.mDispSkill = (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) 
                ? "  Wave slash (Stand)\n" : "";
        this.mDispPower = 5;
        this.mDispSpeed = 4;
        this.mDispReach = 4;
        
        return weapon_pickupbase::Deploy();
    }
    
    /** プライマリアタック */
    void PrimaryAttack() {
        // 攻撃速度
        float spdBuf = (mRageLevel > 0) ? 0.2 : 0.35;
        
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
        
        if (this.mPlayerClassType == CLASSTYPE_WEAPONMASTER) {
            
            if ((m_pPlayer.pev.button & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) ) != 0) {                
                spdBuf = (mRageLevel > 0) ? 0.3 : 0.6;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay1));
                self.pev.nextthink = g_Engine.time + 0.13;
                
            } else {
                spdBuf = (mRageLevel > 0) ? 0.25 : 0.35;
                spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
                
                anim = (mRageLevel <= 0) ? PICKUPWEP_ALTSPECIAL_1 : PICKUPWEP_ALTSPECIAL_2;
                self.SendWeaponAnim( anim, 0, 0);        
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                SetThink(ThinkFunction(this.SpDelay2));
                self.pev.nextthink = g_Engine.time + 0.4;
            }
            
        } else {
            spdBuf = (mRageLevel > 0) ? 0.25 : 0.35;
            spdDelay = (mRageLevel > 0) ? 0.2 : 0.3;
            
            anim = (mRageLevel <= 0) ? PICKUPWEP_SPECIAL_1 : PICKUPWEP_SPECIAL_2;
            self.SendWeaponAnim( anim, 0, 0);        
            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
            
            SetThink(ThinkFunction(this.SpDelay1));
            self.pev.nextthink = g_Engine.time + 0.13;
        }
        
        self.m_flNextPrimaryAttack = g_Engine.time + spdBuf;
        self.m_flNextSecondaryAttack = g_Engine.time + spdBuf + spdDelay;
        
        WeaponIdle();
    }
    
    // 通常攻撃
    private void AttackDelay1() {
        AttackInfo atk;
        atk.dmg = 110.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(82.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
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
        atk.dmg = 150.0 + Math.RandomFloat(-15.0, 15.0);
        atk.criticalRate = 2.25;
        atk.rangeDir = Vector(82.0, 0, 0);
        atk.soundName = this.mDmgSound;
        
        
        if (NormalAttack(atk)) {
            if (ConsumeDurability(Math.RandomLong(0, 2))) {
                BrokenEffect();
                g_EntityFuncs.Remove( self ); 
            }
        }
        
    }
    
    // 特殊攻撃
    private void SpDelay2() {
        AttackDelay1();
        
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, this.mSwingSound, 1, ATTN_NORM, 0, PITCH_NORM);
        Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
        ShootWaveshot(m_pPlayer.pev,
                     m_pPlayer.GetGunPosition() + g_Engine.v_forward * 40 + g_Engine.v_up * 2, g_Engine.v_forward * 600);
        
    }
    
    /** 剣波処理 */
    private void ShootWaveshot(entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity) {
        
        CBaseEntity@ cbeWaveshot = g_EntityFuncs.CreateEntity( "swordwave_shot", null,  false);
        swordwave_shot@ pWaveshot = cast<swordwave_shot@>(CastToScriptClass(cbeWaveshot));
        
        g_EntityFuncs.SetOrigin( pWaveshot.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pWaveshot.self.edict() );
        
        pWaveshot.pev.velocity = vecVelocity;
        @pWaveshot.pev.owner = pevOwner.pContainingEntity;
        pWaveshot.pev.angles = Math.VecToAngles( pWaveshot.pev.velocity );
        pWaveshot.SetThink( ThinkFunction( pWaveshot.BulletThink ) );
        pWaveshot.pev.nextthink = g_Engine.time + 0.1;
        pWaveshot.SetTouch( TouchFunction( pWaveshot.Touch ) );
        
        // プレイヤーのインデックスをセット
        pWaveshot.pev.iuser4 = (mRageLevel == 0) ? g_EngineFuncs.IndexOfEdict(m_pPlayer.edict()) : 0; 
        
        pWaveshot.pev.angles.z = pWaveshot.pev.angles.z + Math.RandomFloat(-20.0, 20.0);
        
        if (ConsumeDurability(Math.RandomLong(0, 1))) {
            BrokenEffect();
            g_EntityFuncs.Remove( self ); 
        }
    }
}

string GetKatanaName() {
    return "weapon_katana";
}

void RegisterKatana() {
    g_CustomEntityFuncs.RegisterCustomEntity( "weapon_katana", GetKatanaName() );
    g_ItemRegistry.RegisterWeapon( GetKatanaName(), "uboa_rampage_II", DURABILITY_AMMO_NAME, UBOAKIAI_AMMO_NAME);
}


// --------------------------------------------------------------

// 剣波
class swordwave_shot : ScriptBaseMonsterEntity {
    private float mLifeTime;    // 寿命
    private float mHitTime;     // 攻撃無効時間
    
    void Spawn() {
        Precache();
        pev.solid = SOLID_SLIDEBOX;
        pev.movetype = MOVETYPE_FLY;
        pev.takedamage = DAMAGE_YES;
        pev.scale = 1;
        self.ResetSequenceInfo();
        
        g_EntityFuncs.SetModel( self, "models/uboa_rampage_II/swordwave.mdl");
        
        this.mLifeTime = g_Engine.time + 1.0;
        this.mHitTime  = g_Engine.time;
        
        
        g_EntityFuncs.SetSize( pev, Vector(-30, -30, -5), Vector(30, 30, 5) ); 
        
        SetThink( ThinkFunction( this.BulletThink ) );
    }

    private void Precache() {
        g_Game.PrecacheModel( "models/uboa_rampage_II/swordwave.mdl" ); 
        g_SoundSystem.PrecacheSound("uboa_rampage_II/bladeattack.wav");
        g_SoundSystem.PrecacheSound( "weapons/xbow_hit1.wav" );
    }
    
    void Touch ( CBaseEntity@ pOther ) {
        const float HITDAMAGE = 75.0 + Math.RandomFloat(-30.0, 30.0);
        
        // プレイヤーにはダメージ通らない
        if ((pOther.Classify() == CLASS_PLAYER) || (pOther.Classify() == CLASS_PLAYER_ALLY)) {
            return;
        }
        
        // 壁ヒット後
        if ( ( pOther.TakeDamage ( pev, pev, 0, DMG_SLASH ) ) != 1 ) {
                pev.solid = SOLID_NOT;
            
        // 直撃
        } else {
            if (g_Engine.time >= mHitTime) {
                this.mHitTime  = g_Engine.time + 0.15;
                
                g_WeaponFuncs.SpawnBlood(pev.origin, pOther.BloodColor(), HITDAMAGE);
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "uboa_rampage_II/bladeattack.wav", 1, ATTN_NORM, 0, PITCH_NORM);
                
                // pev.iuser4からプレイヤー情報を復元
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(pev.iuser4);
                if ((pPlayer !is null) && (pPlayer.IsConnected()) && (pPlayer.IsAlive())) {
                    pPlayer.GiveAmmo(Math.RandomLong(0, 1), UBOAKIAI_AMMO_NAME, UBOAKIAI_MAX_AMMO);
                }
                
                pOther.TakeDamage ( pev, pev.owner.vars, HITDAMAGE, DMG_SLASH );
            }
        }
        pev.velocity = Vector( 0, 0, 0 );
    }
    
    private void RemoveWave() {
        g_EntityFuncs.Remove( self );
    }
    
    void BulletThink() {
        pev.nextthink = g_Engine.time + 0.1;
        
        if (g_Engine.time >= this.mLifeTime) {
            RemoveWave();
        }
    }
    

}

string GetSwordwaveName() {
    return "swordwave_shot";
}

void RegisterSwordwave() {
    g_CustomEntityFuncs.RegisterCustomEntity( "swordwave_shot", GetSwordwaveName() );
}
