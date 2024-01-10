/*
    Message_Begin_Intercept(2,gmsgChangeSky,(float *)g_vecZero,(edict_s *)0x0);
    (*g_engfuncs._184_4_)(2,iVar7,g_vecZero,0);
    
    Stupid MSG_ALL
*/

enum CHANGESKY_SPAWNFLAG{
    SF_ALLPLAYER = 1 << 0,
    SF_NOCLIENT = 1 << 1,
    SF_UPDATESERVER = 1 << 2
}
class CChangeSky : ScriptBaseEntity{
    private string szSkyName = "";
    private Vector vecColor = Vector(255, 255, 255);
    bool KeyValue(const string& in szKeyName, const string& in szValue){
        if(szKeyName == "skyname"){
            szSkyName = szValue;
            return true;
        }
        else if(szKeyName == "color"){
            g_Utility.StringToVector(vecColor, szValue);
            return true;
        }
        return BaseClass.KeyValue(szKeyName, szValue);
    }
    void Precache(){
        //bk dn ft lf rt up
        if( !szSkyName.IsEmpty() ){
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "bk.bmp" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "bk.tga" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "dn.bmp" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "dn.tga" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "ft.bmp" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "ft.tga" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "lf.bmp" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "lf.tga" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "rt.bmp" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "rt.tga" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "up.bmp" );
            g_Game.PrecacheGeneric( "gfx/env/" + szSkyName + "up.tga" );
        }
    }
    void Spawn(){
        BaseClass.Spawn();
        if(szSkyName.IsEmpty()){
            g_EntityFuncs.Remove(self);
            return;
        }
        Precache();
    }
    void SendMessage(NetworkMessageDest t, edict_t@ e){
        NetworkMessage m(t, NetworkMessages::NetworkMessageType(146), e);
            m.WriteString(szSkyName);
            m.WriteVector(vecColor);
        m.End();
    }
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f){
        if(self.pev.spawnflags & SF_NOCLIENT == 0){
            if(self.pev.spawnflags & SF_ALLPLAYER == 0){
                if(pCaller.IsPlayer())
                    SendMessage(MSG_ONE_UNRELIABLE, pCaller.edict());
            }
            else
                SendMessage(MSG_BROADCAST, null);
        }
        if(self.pev.spawnflags & SF_UPDATESERVER != 0){
            g_EngineFuncs.CVarSetString("sv_skyname", szSkyName);
            g_EngineFuncs.CVarSetFloat("sv_skycolor_r", vecColor.x);
            g_EngineFuncs.CVarSetFloat("sv_skycolor_g", vecColor.y);
            g_EngineFuncs.CVarSetFloat("sv_skycolor_b", vecColor.z);
        }
    }
}
