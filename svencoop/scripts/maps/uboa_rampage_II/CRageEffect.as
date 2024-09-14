/* 
 * Rageモード処理
 */
const float RAGE_ACTIVE_TIME = 15.0;
class CRageEffect {
    
    private int mSpriteWave;
    private int mR = 128;
    private int mG = 128;
    private int mB = 255;
    
    void Precache() {
        g_SoundSystem.PrecacheSound( "crystal2/thunder.wav" );
        mSpriteWave = g_Game.PrecacheModel("sprites/laserbeam.spr");
    }
    
    // RageモードON
    int TurnOnRage(CBasePlayer@ pPlayer) {        
        g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, "crystal2/thunder.wav", 1, 1.0);
        
        const float RANGE = 300.0;
        
        int bufCounter = 0;
        // 影響範囲プレイヤー調査
        int playerIndex = g_EngineFuncs.IndexOfEdict(pPlayer.edict());
        int targetIndex;
        for (int i = 1; i <= g_Engine.maxClients; i++ ) {
            CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex(i);
            if ((pTarget !is null) && (pTarget.IsConnected())) {
                targetIndex = g_EngineFuncs.IndexOfEdict(pTarget.edict());
                if ((pPlayer.pev.origin - pTarget.pev.origin).Length() <= RANGE) {
                    bufCounter++;
                }
            }
        }
        int a = 100;
        
        // 赤
        if (bufCounter >= 10) {
            mR = 255;
            mG = 0;
            mB = 0;
        // オレンジ
        } else if (bufCounter >= 8) {
            mR = 255;
            mG = 128;
            mB = 0;
        
        // 黄色
        } else if (bufCounter >= 6) {
            mR = 255;
            mG = 255;
            mB = 0;
        
        // 薄緑
        } else if (bufCounter >= 4) {
            mR = 128;
            mG = 255;
            mB = 192;
        // 薄い青
        } else if (bufCounter >= 2) {
            mR = 128;
            mG = 255;
            mB = 255;
            
        } else {
            mR = 128;
            mG = 128;
            mB = 255;
        }
        
        
        // ビーム描画
        for (int i = 1; i <= g_Engine.maxClients; i++ ) {
            CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex(i);
            if ((pTarget !is null) && (pTarget.IsConnected())) {
                targetIndex = g_EngineFuncs.IndexOfEdict(pTarget.edict());
                
                if ((pPlayer.pev.origin - pTarget.pev.origin).Length() <= RANGE) {
                    NetworkMessage messageBeam(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
                    messageBeam.WriteByte(TE_BEAMENTS);
                    messageBeam.WriteShort(targetIndex);   // start
                    messageBeam.WriteShort(playerIndex);   // end
                    messageBeam.WriteShort(mSpriteWave);
                    messageBeam.WriteByte(0);
                    messageBeam.WriteByte(100);
                    messageBeam.WriteByte(30);  // life
                    messageBeam.WriteByte(32); // width
                    messageBeam.WriteByte(100); // noise
                    messageBeam.WriteByte(mR);
                    messageBeam.WriteByte(mG);
                    messageBeam.WriteByte(mB);
                    messageBeam.WriteByte(a); // actually brightness
                    messageBeam.WriteByte(0); // scroll
                    messageBeam.End();
                }
            }
        }
        
        // Glow
        pPlayer.pev.rendermode  = kRenderNormal;
        pPlayer.pev.renderfx    = kRenderFxGlowShell;
        pPlayer.pev.renderamt   = 4;
        pPlayer.pev.rendercolor = Vector(mR, mG, mB);
        
        
        // 発光
        NetworkMessage messageLight(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        messageLight.WriteByte(TE_DLIGHT);
        messageLight.WriteCoord(pPlayer.pev.origin.x);
        messageLight.WriteCoord(pPlayer.pev.origin.y);
        messageLight.WriteCoord(pPlayer.pev.origin.z);
        messageLight.WriteByte(16);
        messageLight.WriteByte(mR);
        messageLight.WriteByte(mG);
        messageLight.WriteByte(mB);
        messageLight.WriteByte(int(200)); // LIFE
        messageLight.WriteByte(100);
        messageLight.End();
        
        // 集中線
        NetworkMessage messageImplosion(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        messageImplosion.WriteByte(TE_IMPLOSION);
        messageImplosion.WriteCoord(pPlayer.pev.origin.x);
        messageImplosion.WriteCoord(pPlayer.pev.origin.y);
        messageImplosion.WriteCoord(pPlayer.pev.origin.z);
        messageImplosion.WriteByte(50);
        messageImplosion.WriteByte(10);
        messageImplosion.WriteByte(2);
        messageImplosion.End();
        
        // 波動
        NetworkMessage messageWave(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        messageWave.WriteByte(TE_BEAMTORUS);
        messageWave.WriteCoord(pPlayer.pev.origin.x);
        messageWave.WriteCoord(pPlayer.pev.origin.y);
        messageWave.WriteCoord(pPlayer.pev.origin.z);
        messageWave.WriteCoord(pPlayer.pev.origin.x);
        messageWave.WriteCoord(pPlayer.pev.origin.y);
        messageWave.WriteCoord(pPlayer.pev.origin.z + 200); // radius
        messageWave.WriteShort(mSpriteWave);
        messageWave.WriteByte(0);
        messageWave.WriteByte(16);
        messageWave.WriteByte(8);
        messageWave.WriteByte(8);
        messageWave.WriteByte(0);
        messageWave.WriteByte(mR);
        messageWave.WriteByte(mG);
        messageWave.WriteByte(mB);
        messageWave.WriteByte(a);
        messageWave.WriteByte(0);
        messageWave.End();
        
        return bufCounter;
    }
    
    // RageOff
    void TurnOffRage(CBasePlayer@ pPlayer) {
        pPlayer.pev.rendermode  = kRenderNormal;
        pPlayer.pev.renderfx    = kRenderFxNone;
        pPlayer.pev.renderamt   = 255;
        pPlayer.pev.rendercolor = Vector(255,255,255);
    }
    
    void ReadyEffect(CBasePlayer@ pPlayer) {
        int a = 100;
        
        // 発光
        NetworkMessage messageLight(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        messageLight.WriteByte(TE_DLIGHT);
        messageLight.WriteCoord(pPlayer.pev.origin.x);
        messageLight.WriteCoord(pPlayer.pev.origin.y);
        messageLight.WriteCoord(pPlayer.pev.origin.z);
        messageLight.WriteByte(16);
        messageLight.WriteByte(mR);
        messageLight.WriteByte(mG);
        messageLight.WriteByte(mB);
        messageLight.WriteByte(int(200)); // LIFE
        messageLight.WriteByte(100);
        messageLight.End();
        
        // 集中線
        NetworkMessage messageImplosion(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
        messageImplosion.WriteByte(TE_IMPLOSION);
        messageImplosion.WriteCoord(pPlayer.pev.origin.x);
        messageImplosion.WriteCoord(pPlayer.pev.origin.y);
        messageImplosion.WriteCoord(pPlayer.pev.origin.z);
        messageImplosion.WriteByte(30);
        messageImplosion.WriteByte(20);
        messageImplosion.WriteByte(3);
        messageImplosion.End();
        
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "RAGE MODE is ready!!\n(Press Throw crowbar key)");
    }
}
