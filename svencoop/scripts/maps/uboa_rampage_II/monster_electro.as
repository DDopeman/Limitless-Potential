////////////////////////////////////////////////////////
// electro
//
// 参考: Maestro Fénix氏のmonster_uber_pit_drone
////////////////////////////////////////////////////////

const string DENGEKI_SPRITE = "sprites/c-tele1.spr";

// アニメイベント
const int ELE_RANGE2 = 7;
const int ELE_RANGE1 = 1;
const int ELE_MELEE1 = 4;
const int ELE_MELEE2 = 6;

class monster_electro : ScriptBaseMonsterEntity {

    void Spawn() {
        Precache( ); 

        g_EntityFuncs.SetModel( self, "models/uboa_rampage_II/electro_dougi.mdl" );
        
        g_EntityFuncs.SetSize( pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX ); 
        pev.solid = SOLID_SLIDEBOX; 
        pev.movetype = MOVETYPE_STEP; 
        self.m_bloodColor = BLOOD_COLOR_RED;
        
        //pev.health = 100;
        pev.view_ofs = Vector ( 0, 0, 20 );
        self.m_flFieldOfView = 0.5; 
        
        // SPAWN後の警戒状態（何もしない）
        self.m_MonsterState = MONSTERSTATE_NONE; 
                
        // AI初期化
        self.MonsterInit(); 
        
        if ( (pev.spawnflags & 0x10 ) != 0 ) {
            self.SetClassification( CLASS_PLAYER_ALLY );
        } else {
            self.SetClassification( CLASS_ALIEN_MONSTER );
        }
    }

    void Precache() {
        g_Game.PrecacheModel( DENGEKI_SPRITE );
        g_Game.PrecacheModel( "models/uboa_rampage_II/electro_dougi.mdl" );
        g_Game.PrecacheModel( "sprites/laserbeam.spr" );
        
        g_SoundSystem.PrecacheSound("houndeye/he_blast1.wav");
        
        g_SoundSystem.PrecacheSound("crystal2/thunder.wav");
        g_SoundSystem.PrecacheSound("weapons/shock_impact.wav");
        
        g_SoundSystem.PrecacheSound( "uboa45/electro/attack1.wav" );
        g_SoundSystem.PrecacheSound( "uboa45/electro/attack2.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/attack3.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/die1.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/die2.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/idle1.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/idle2.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/idle3.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/pain01.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/pain02.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/pain03.wav");
        g_SoundSystem.PrecacheSound( "uboa45/electro/stomp1.wav");
    }
    
    // 振り向き速度？
    void SetYawSpeed( void ) {
        pev.yaw_speed = 90; 
    }
    
    // イベント動作
    void HandleAnimEvent( MonsterEvent@ pEvent ) {
        switch ( pEvent.event ) {
            case ELE_RANGE2:
            {
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "uboa45/electro/pain01.wav", 1, ATTN_NORM, 0, PITCH_NORM);
                SonicWave(pev.origin + Vector( 0, 0, 30 ), 300.0);      
                
                
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "crystal2/thunder.wav", 1, ATTN_NORM, 0, PITCH_NORM);
            }
            break;
            case ELE_RANGE1:
            {
                
                CBaseEntity@ ent = self.m_hEnemy;
                if ( ent is null ) {
                    break;
                }
                                
                ShootEleVolt(ent);                
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "uboa45/electro/attack1.wav", 1, ATTN_NORM, 0, PITCH_NORM);
                
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/shock_impact.wav", 1, ATTN_NORM, 0, PITCH_NORM);
            }
            break;
            case ELE_MELEE1:
            {
                // Only gonna comment on this one, cuz the rest are basically the same.
                // This gets the enemy and attacks at the same time.
                // The parameters after CheckTraceHullAttack are distance, amount of damage, and type
                CBaseEntity@ pHurt = CheckTraceHullAttack( self, 100, 10, DMG_SHOCK );

                if ( pHurt !is null ) {
                    pHurt.pev.punchangle.y = Math.RandomLong ( -15, 15 );
                    pHurt.pev.punchangle.x = 8;
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_up * -100;
                    
                    pHurt.pev.velocity = pHurt.pev.velocity - ( self.pev.origin - pHurt.pev.origin ).Normalize() * 200;
                    BeamEffects(self.pev.origin, pHurt.pev.origin - ( self.pev.origin - pHurt.pev.origin ).Normalize() * 200);
                    
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/shock_impact.wav", 1, ATTN_NORM, 0, PITCH_NORM);
                }
                
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "uboa45/electro/attack2.wav", 1, ATTN_NORM, 0, PITCH_NORM);
            }
            break;
            case ELE_MELEE2:
            {
                // ランダムで衝撃波
                if ( Math.RandomLong(0, 3) == 0 ) {
                     SonicWave(pev.origin + Vector( 0, 0, 30 ), 80.0); 
                }
                
                CBaseEntity@ pHurt = CheckTraceHullAttack( self, 100, 20, DMG_SHOCK );

                if ( pHurt !is null ) {
                    pHurt.pev.punchangle.x = 15;
                    pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_up * -100;
                    pHurt.pev.velocity = pHurt.pev.velocity - ( self.pev.origin - pHurt.pev.origin ).Normalize() * 500;
                    BeamEffects(self.pev.origin, pHurt.pev.origin - ( self.pev.origin - pHurt.pev.origin ).Normalize() * 500);
                    
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "crystal2/thunder.wav", 1, ATTN_NORM, 0, PITCH_NORM);
                }
                g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "uboa45/electro/attack3.wav", 1, ATTN_NORM, 0, PITCH_NORM);
            }
            break;
            default:
                BaseClass.HandleAnimEvent( pEvent );
                break; 
        }
    }
    
    // 電撃発射
    void ShootEleVolt(CBaseEntity@ ent) {
        // Define the vectors - an offset and a direction
        Vector vecspikeOffset;
        Vector vecspikeDir;

        // 発射位置
        Math.MakeVectors( pev.angles );
        vecspikeOffset = ( g_Engine.v_forward * 40 + g_Engine.v_up * 40 + g_Engine.v_right * Math.RandomLong(-100, 100));
        vecspikeOffset = ( pev.origin + vecspikeOffset );

        // 発射方向
        vecspikeDir = ( ( ent.pev.origin + ent.pev.view_ofs ) - vecspikeOffset ).Normalize();

        // ブレ
        vecspikeDir.x += Math.RandomFloat( -0.01, 0.01 );
        vecspikeDir.y += Math.RandomFloat( -0.01, 0.01 );
        vecspikeDir.z += Math.RandomFloat( -0.01, 0.01 );

        // prop entity作成
        CBaseEntity@ pSpike = g_EntityFuncs.Create( "electro_shot", vecspikeOffset, pev.angles, false, null );
        
        pSpike.pev.velocity = vecspikeDir * 1000;  // 発射速度
        @pSpike.pev.owner = self.edict();
        pSpike.pev.nextthink = g_Engine.time + 0.1;
        pSpike.pev.friction = 0;
        pSpike.pev.angles = Math.VecToAngles( pSpike.pev.velocity );

    }
    

    // 行動スケジュール
    Schedule@ GetSchedule( void ) {
        switch ( self.m_MonsterState ) {
            // Manly monster needs to fight
            case MONSTERSTATE_COMBAT:
            {
                // ターゲットが死亡した場合
                if ( self.HasConditions( bits_COND_ENEMY_DEAD ) ) {
                    return BaseClass.GetSchedule(); // ベースの行動パターンへ
                }

                // 近接攻撃チェック
                if ( self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) ) {
                    
                    // 低確率で範囲特殊攻撃
                    if ( Math.RandomLong(0, 12) == 0 ) {
                        
                        ThunderEffects();
                        // 特殊攻撃
                        return BaseClass.GetScheduleOfType ( SCHED_RANGE_ATTACK2 );
                    }
                    
                    switch ( Math.RandomLong ( 0, 1 ) ) {
                        case 0: return BaseClass.GetScheduleOfType ( SCHED_MELEE_ATTACK1 );
                        case 1: return BaseClass.GetScheduleOfType ( SCHED_MELEE_ATTACK2 );
                    }
                }

                // 遠距離攻撃チェック  
                if ( self.HasConditions( bits_COND_CAN_RANGE_ATTACK1 ) ) {
                    
                    // ターゲットがいない
                    CBaseEntity@ ent = self.m_hEnemy;
                    if ( ent is null ) {
                        return BaseClass.GetSchedule(); // ベースの行動パターンへ
                    }
                                        
                    // 距離が近い
                    if ( ( pev.origin - ent.pev.origin ).Length() <= 256 ) {
                        return BaseClass.GetScheduleOfType ( SCHED_CHASE_ENEMY );   // 追いかける
                    }
                    
                    // 距離がやや遠い
                    if ( ( pev.origin - ent.pev.origin ).Length() <= 512 ) {
                        
                        if ( Math.RandomLong(0, 2) == 0 ) {
                        
                            // 電撃発射
                            return BaseClass.GetScheduleOfType ( SCHED_RANGE_ATTACK1 );
                            
                        } else {
                            // No.
                            if ( ( pev.origin - ent.pev.origin ).Length() <= 312 ) 
                            {
                                // I'm close, I can go and attack.
                                if ( self.HasConditions( bits_COND_CAN_MELEE_ATTACK1 ) ) 
                                {
                                    switch ( Math.RandomLong ( 0, 1 ) )
                                    {
                                        case 0:
                                        return BaseClass.GetScheduleOfType ( SCHED_MELEE_ATTACK1 );
                                    
                                        case 1:
                                        return BaseClass.GetScheduleOfType ( SCHED_MELEE_ATTACK2 );
                                    }
                                }
                                
                                // 距離が微妙に遠いので近づく
                                else 
                                {    
                                    return BaseClass.GetScheduleOfType ( SCHED_CHASE_ENEMY );
                                }
                            }
                            
                            // He's too far to melee. I'll just reload
                            else 
                            {
                                //return BaseClass.GetScheduleOfType ( SCHED_RELOAD );
                                return BaseClass.GetScheduleOfType ( SCHED_CHASE_ENEMY );
                            }
                        }
                    }
                    
                    // 距離が遠いので、もっと近づく
                    else {
                        return BaseClass.GetScheduleOfType ( SCHED_CHASE_ENEMY );
                    }
                }
                
                // 他、とりあへず追いかける
                return BaseClass.GetScheduleOfType ( SCHED_CHASE_ENEMY );
            }
        }
        
        // ベースの行動パターンへ
        return BaseClass.GetSchedule();
    }
    
    private void ThunderEffects() {
        
        Vector randVec;
        Vector vecSrc;
        Vector vecDest;
        
        for (int i = 0; i < 6; i++) {
            randVec.x = pev.origin.x + Math.RandomFloat(-100, 100);
            randVec.y = pev.origin.y + Math.RandomFloat(-100, 100);
            randVec.z = pev.origin.z;
            vecSrc  = randVec + g_Engine.v_up * 200;
            vecDest = randVec + g_Engine.v_up * -200;
            
            // 電撃
            BeamEffects(vecSrc, vecDest);
        }
        
    }
    
    void BeamEffects(Vector startPos, Vector endPos) {
        const int r = 128;
        const int g = 255;
        const int b = 255;
        const int a = 192;
        
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
        msgBeam.WriteByte(30);   // life
        msgBeam.WriteByte(48);  // width
        msgBeam.WriteByte(64);  // noise
        msgBeam.WriteByte(r);
        msgBeam.WriteByte(g);
        msgBeam.WriteByte(b);
        msgBeam.WriteByte(a);   // actually brightness
        msgBeam.WriteByte(5);   // scroll
        msgBeam.End();
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
        messageWave.WriteByte(128); // R
        messageWave.WriteByte(255); // G
        messageWave.WriteByte(255); // B
        messageWave.WriteByte(192); // A
        messageWave.WriteByte(0);   // スクロールスピード
        messageWave.End();
        
        // 当たり判定計算
        CBaseEntity@ pEntity = null;        
        while ((@pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pos, radius, "*", "classname" )) !is null) {
            if (( pEntity.pev.takedamage != DAMAGE_NO) && ( pEntity.Classify() != self.Classify() ) ){
                    
                float flAdjustedDamage = (400.0 + Math.RandomFloat(-10.0, 10.0)) + 100.0;

                float flDist = (pEntity.Center() - pos).Length();
                flAdjustedDamage -= ( flDist / radius ) * flAdjustedDamage;

                if (flAdjustedDamage > 0 ) {
                    pEntity.TakeDamage ( pev, pev, flAdjustedDamage , DMG_SHOCK );
                }
            }
        }
        
    }
    
}

/** ダメージ処理 */
CBaseEntity@ CheckTraceHullAttack( CBaseMonster@ pThis, float flDist, int iDamage, int iDmgType ) {
    TraceResult tr;

    if (pThis.IsPlayer()) {
        Math.MakeVectors( pThis.pev.angles );
    } else {
        Math.MakeAimVectors( pThis.pev.angles );
    }

    Vector vecStart = pThis.pev.origin;
    vecStart.z += pThis.pev.size.z * 0.5;
    Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

    g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, pThis.edict(), tr );
    
    if ( tr.pHit !is null ) {
        CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
        if ( iDamage > 0 ) {
            pEntity.TakeDamage( pThis.pev, pThis.pev, iDamage, iDmgType );
        }
        return pEntity;
    }
    return null;
}

string GetElectroName() {
    return "monster_electro";
}

void RegisterElectro() {
    g_CustomEntityFuncs.RegisterCustomEntity( "monster_electro", GetElectroName() );
}


/////////////////////////////////////////////////////////////////////////////
// 電撃

class electro_shot : ScriptBaseEntity {
    int mSpriteWave;
    Vector mFirePos;    // 初回発射位置
    
    void Spawn() {
        Precache();
        pev.solid = SOLID_SLIDEBOX;
        pev.rendermode  = kRenderTransAdd;
        pev.scale       = 3;
        pev.renderamt   = 128;
        pev.rendercolor = Vector(64, 128, 255);
        
        mFirePos = pev.origin;
        
        pev.movetype = MOVETYPE_FLY;
        g_EntityFuncs.SetModel( self, DENGEKI_SPRITE);
        
        SetThink( ThinkFunction( this.BulletThink ) );
    }

    void Precache() {
        g_SoundSystem.PrecacheSound( "crystal2/thunder.wav" );
        mSpriteWave = g_Game.PrecacheModel("sprites/laserbeam.spr");
        g_Game.PrecacheModel( DENGEKI_SPRITE ); 
    }
    
    void Touch ( CBaseEntity@ pOther ) {
        
        // 壁ヒット後の残像
        if ( ( pOther.TakeDamage ( pev, pev, 0, DMG_SHOCK ) ) != 1 ) {
            
                pev.solid = SOLID_NOT;
                pev.rendermode  = kRenderTransAdd;
                pev.scale       = 1;
                pev.renderamt   = 128;
                pev.rendercolor = Vector(0, 85, 255);
                pev.movetype = MOVETYPE_FLY;
                pev.velocity = Vector( 0, 0, 0 );
                g_Utility.Sparks( pev.origin );
                
                g_Scheduler.SetTimeout( @this, "RemoveElectroShot", 1.0);
        // 直撃
        } else {
            pOther.TakeDamage ( pev, pev, 20, DMG_SHOCK );
            g_EntityFuncs.Remove( self ); 
        }
    }
    
    void RemoveElectroShot() {
        g_EntityFuncs.Remove( self );
    }
    
    void BulletThink() {
        pev.nextthink = g_Engine.time + 0.1;
        
        const int r = 128;
        const int g = 255;
        const int b = 255;
        
        // 発光
        NetworkMessage msgLight(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        msgLight.WriteByte(TE_DLIGHT);
        msgLight.WriteCoord(pev.origin.x);
        msgLight.WriteCoord(pev.origin.y);
        msgLight.WriteCoord(pev.origin.z);
        msgLight.WriteByte(16);
        msgLight.WriteByte(r);
        msgLight.WriteByte(g);
        msgLight.WriteByte(b);
        msgLight.WriteByte(100);
        msgLight.WriteByte(50);
        msgLight.End();
        
        int ownerIndex = g_EngineFuncs.IndexOfEdict(pev.owner);
        int selfIndex = g_EngineFuncs.IndexOfEdict(self.edict());

        // 光弾まで
        BeamEffects(mFirePos, pev.origin);
        
        Vector randVec;
        for (int i = 0; i < Math.RandomLong(2, 6); i++) {
            randVec.x = pev.origin.x + Math.RandomFloat(-100, 100);
            randVec.y = pev.origin.y + Math.RandomFloat(-100, 100);
            randVec.z = pev.origin.z + Math.RandomFloat(-100, 100);
            
            BeamEffects(pev.origin, randVec);
        }
        
        
    }
    
    void BeamEffects(Vector startPos, Vector endPos) {
        const int r = 128;
        const int g = 255;
        const int b = 255;
        const int a = 192;
        
        NetworkMessage msgBeam(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        msgBeam.WriteByte(TE_BEAMPOINTS);
        msgBeam.WriteCoord(startPos.x);
        msgBeam.WriteCoord(startPos.y);
        msgBeam.WriteCoord(startPos.z);
        msgBeam.WriteCoord(endPos.x);
        msgBeam.WriteCoord(endPos.y);
        msgBeam.WriteCoord(endPos.z);
        msgBeam.WriteShort(mSpriteWave);
        msgBeam.WriteByte(0);   // frameStart
        msgBeam.WriteByte(100); // frameRate
        msgBeam.WriteByte(1);   // life
        msgBeam.WriteByte(16);  // width
        msgBeam.WriteByte(20);  // noise
        msgBeam.WriteByte(r);
        msgBeam.WriteByte(g);
        msgBeam.WriteByte(b);
        msgBeam.WriteByte(a);   // actually brightness
        msgBeam.WriteByte(5);   // scroll
        msgBeam.End();
    }

}
string GetElectroVoltName() {
    return "electro_shot";
}

void RegisterElectroVolt() {
    g_CustomEntityFuncs.RegisterCustomEntity( "electro_shot", GetElectroVoltName() );
}