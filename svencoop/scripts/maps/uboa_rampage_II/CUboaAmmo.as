/* 
 * Rage、特殊攻撃用
 */
#include "CRageEffect"

const string UBOAKIAI_AMMO_NAME   = "ammo_kiai";
const string UBOAWAZA_AMMO_NAME   = "ammo_waza";
const string DURABILITY_AMMO_NAME = "ammo_durability";

const int UBOAKIAI_MAX_AMMO = 100;
const int UBOAWAZA_MAX_AMMO = 100;

/** Rageゲージ */
class CUboaAmmo : ScriptBasePlayerAmmoEntity {
    void Spawn() {
        g_Game.PrecacheModel( "models/uboa_rampage/sincube.mdl" );
        g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
        
        g_EntityFuncs.SetModel( self, "models/uboa_rampage/sincube.mdl" );
        BaseClass.Spawn();
        
        self.pev.rendermode  = kRenderNormal;
        self.pev.renderfx    = kRenderFxGlowShell;
        self.pev.renderamt   = 4;
        self.pev.rendercolor = Vector(128, 128, 128);
    }
    
    bool AddAmmo( CBaseEntity@ pither ) {
        if( pither.GiveAmmo( UBOAKIAI_MAX_AMMO, UBOAKIAI_AMMO_NAME, UBOAKIAI_MAX_AMMO ) != -1 ) { 
            int playerIndex = g_EngineFuncs.IndexOfEdict(pither.edict());
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
            
            // RAGE発動可能メッセージ
            CRageEffect rgeff;
            rgeff.ReadyEffect(pPlayer);
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
            return true;
        }
        return false;
    }
}

void RegisterKiaiAmmo() {
    g_CustomEntityFuncs.RegisterCustomEntity( "CUboaAmmo", UBOAKIAI_AMMO_NAME);
}

// -----------------------------------------------------

/** 特殊攻撃 */
class WazaAmmo : ScriptBasePlayerAmmoEntity {
    void Spawn() {
        g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pither ) {
        return false;
    }
    
}

void RegisterWazaAmmo() {
    g_CustomEntityFuncs.RegisterCustomEntity( "WazaAmmo", UBOAWAZA_AMMO_NAME );
}


// -----------------------------------------------------

/** 耐久力 */
class DurabilityAmmo : ScriptBasePlayerAmmoEntity {
    void Spawn() {
        g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ pither ) {
        return false;
    }
    
}

void RegisterDurabilityAmmo() {
    g_CustomEntityFuncs.RegisterCustomEntity( "DurabilityAmmo", DURABILITY_AMMO_NAME );
}
