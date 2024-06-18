namespace PCP_MISC 
{
    void SetAnim(CBaseAnimating@ pEntity, int animIndex) 
    {
        pEntity.pev.sequence = animIndex;
        pEntity.pev.frame = 0;
        pEntity.ResetSequenceInfo();
    }

    string GetSteamID(CBasePlayer@ pPlayer)
    {
        string SteamID = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
        return (SteamID == 'STEAM_ID_LAN' || SteamID == 'STEAM_ID_BOT') ? string(pPlayer.pev.netname) : SteamID;
    }

    bool IsEnabled(CBaseAnimating@ pEntity) 
    { 
        return pEntity.pev.health != 0.0f; 
    }

    bool IsActivated(CBaseAnimating@ pEntity) 
    { 
        return pEntity.pev.frags != 0.0f; 
    }

    bool IsDrawable(CBaseAnimating@ pEntity)
    {
        return pEntity.pev.speed != 0.0f;
    }

    bool IsReenable(CBaseAnimating@ pEntity)
    {
        return pEntity.pev.dmg != 0.0f;
    }

    void SetEnabled(CBaseAnimating@ pEntity, const bool bEnabled)
    {
        if( bEnabled == IsEnabled( pEntity ) )
            return;
    
        if( bEnabled && !IsActivated( pEntity ) )
            pEntity.pev.effects &= ~EF_NODRAW;
        else
            pEntity.pev.effects |= EF_NODRAW;
        
        pEntity.pev.health = bEnabled ? 1.0f : 0.0f;
    }

    void SetCKV(CBasePlayer@ pPlayer, string valuename, int value)
    {
        CustomKeyvalues@ ckvSpawns = pPlayer.GetCustomKeyvalues();
        ckvSpawns.SetKeyvalue(valuename, ckvSpawns.GetKeyvalue(valuename).GetInteger() + value );
    }

    int GetCKV(CBasePlayer@ pPlayer, string valuename)
    {
        CustomKeyvalues@ ckvSpawns = pPlayer.GetCustomKeyvalues();
        return ckvSpawns.GetKeyvalue(valuename).GetInteger();
    }

    void FindPlayerEquip(CBasePlayer@ pPlayer, CBaseEntity@ pEntity)
    {
        CBaseEntity@ pEquipEntity = null;
        while((@pEquipEntity = g_EntityFuncs.FindEntityByClassname(pEquipEntity, 'game_player_equip')) !is null)
            pEquipEntity.Use(pPlayer, pEntity, USE_TOGGLE);
    }

    void SpawnCountHUDText(CBasePlayer@ pPlayer)
    {
        HUDTextParams SpawnCountHudText;

        SpawnCountHudText.x = 0.05;
        SpawnCountHudText.y = 0.05;
        SpawnCountHudText.effect = 0;
        SpawnCountHudText.r1 = (GetCKV(pPlayer,'$i_pcp_spawns') > 0) ? RGBA_SVENCOOP.r : RGBA_RED.r;
        SpawnCountHudText.g1 = (GetCKV(pPlayer,'$i_pcp_spawns') > 0) ? RGBA_SVENCOOP.g : RGBA_RED.g;
        SpawnCountHudText.b1 = (GetCKV(pPlayer,'$i_pcp_spawns') > 0) ? RGBA_SVENCOOP.b : RGBA_RED.b;
        SpawnCountHudText.a1 = 0;
        SpawnCountHudText.r2 = (GetCKV(pPlayer,'$i_pcp_spawns') > 0) ? RGBA_SVENCOOP.r : RGBA_RED.r;
        SpawnCountHudText.g2 = (GetCKV(pPlayer,'$i_pcp_spawns') > 0) ? RGBA_SVENCOOP.g : RGBA_RED.g;
        SpawnCountHudText.b2 = (GetCKV(pPlayer,'$i_pcp_spawns') > 0) ? RGBA_SVENCOOP.b : RGBA_RED.b;
        SpawnCountHudText.a2 = 0;
        SpawnCountHudText.fadeinTime = 0; 
        SpawnCountHudText.fadeoutTime = 0;
        SpawnCountHudText.holdTime = 0.5;
        SpawnCountHudText.fxTime = 0;
        SpawnCountHudText.channel = 15;

        g_PlayerFuncs.HudMessage(pPlayer, SpawnCountHudText, 'Spawns: ' + GetCKV(pPlayer,'$i_pcp_spawns'));
    }

    void CreatePlayerSpawnEffect(Vector pos)
    {
        CSprite@ m_pSprite = g_EntityFuncs.CreateSprite( 'sprites/exit1.spr', pos, true, 10 );
        m_pSprite.TurnOn();
        m_pSprite.pev.rendermode = kRenderTransAdd;
        m_pSprite.pev.renderamt = 128;

        g_Scheduler.SetTimeout( 'KillSprite', 3.0f, @m_pSprite );
    }

    void KillSprite(CSprite@ m_pSprite)
    {
        if(m_pSprite !is null)
            g_EntityFuncs.Remove(m_pSprite);
    }

    void CreateSpawnEffect(Vector pos)
    {
        int iBeamCount = 8;
        Vector vBeamColor = Vector(217,226,146);
        int iBeamAlpha = 128;
        float flBeamRadius = 256;

        Vector vLightColor = Vector(39,209,137);
        float flLightRadius = 160;

        Vector vStartSpriteColor = Vector(65,209,61);
        float flStartSpriteScale = 1.0f;
        float flStartSpriteFramerate = 12;
        int iStartSpriteAlpha = 255;

        Vector vEndSpriteColor = Vector(159,240,214);
        float flEndSpriteScale = 1.0f;
        float flEndSpriteFramerate = 12;
        int iEndSpriteAlpha = 255;

        // create the clientside effect

        NetworkMessage msg( MSG_PVS, NetworkMessages::TE_CUSTOM, pos );
            msg.WriteByte( 2 /*TE_C_XEN_PORTAL*/ );
            msg.WriteVector( pos );
            // for the beams
            msg.WriteByte( iBeamCount );
            msg.WriteVector( vBeamColor );
            msg.WriteByte( iBeamAlpha );
            msg.WriteCoord( flBeamRadius );
            // for the dlight
            msg.WriteVector( vLightColor );
            msg.WriteCoord( flLightRadius );
            // for the sprites
            msg.WriteVector( vStartSpriteColor );
            msg.WriteByte( int( flStartSpriteScale*10 ) );
            msg.WriteByte( int( flStartSpriteFramerate ) );
            msg.WriteByte( iStartSpriteAlpha );
            
            msg.WriteVector( vEndSpriteColor );
            msg.WriteByte( int( flEndSpriteScale*10 ) );
            msg.WriteByte( int( flEndSpriteFramerate ) );
            msg.WriteByte( iEndSpriteAlpha );
        msg.End();
    }

    dictionary SaveCheckPoint(CBaseAnimating@ pEntity, dictionary@ pDictionary, string music, string sprite, float DelayBeforeReactivation, int IsInfinite)
    {
        int spfgs = pEntity.pev.spawnflags;
        spfgs &= (IsInfinite == 0) ? ~SF_CHECKPOINT_STARTOFF : ~(SF_CHECKPOINT_STARTOFF | SF_CHECKPOINT_REUSABLE);

        pDictionary.set('origin', pEntity.GetOrigin().ToString());
        pDictionary.set('minhullsize', (pEntity.pev.vuser1).ToString());
        pDictionary.set('maxhullsize', (pEntity.pev.vuser2).ToString());
        pDictionary.set('music', music);
        pDictionary.set('sprite', sprite);
        pDictionary.set('DelayBeforeReactivation', '' + DelayBeforeReactivation);
        pDictionary.set('spawnflags', '' + spfgs);
        pDictionary.set('model', '' + pEntity.pev.model);
        pDictionary.set('netname', '' + pEntity.pev.netname);
        pDictionary.set('targetname', '' + pEntity.pev.targetname);
        pDictionary.set('target', '' + pEntity.pev.target);

        return pDictionary;
    }

    void SetData(string name, int value)
    {
        CBaseKeepData pData;
        pData.spawn_number = int(dicPlayersData[name]) + value;
        dicPlayersData[name] = pData.spawn_number;
    }

    int GetData(string name)
    {
        if(!dicPlayersData.exists(name)) dicPlayersData[name] = 0;
        return int(dicPlayersData[name]);		
    }

    int SetAndGetData(string name, int value)
    {
        SetData(name, value);
        return GetData(name);
    }
}
