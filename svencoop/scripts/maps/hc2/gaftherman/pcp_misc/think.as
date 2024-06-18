namespace PCP_Think
{
    CScheduledFunction@ SchStartThinking = g_Scheduler.SetInterval('StartThinking', 0.0f, g_Scheduler.REPEAT_INFINITE_TIMES);

    void StartThinking()
    {
        CBaseEntity@ pFindPointCheckPoint = null;
        
        while((@pFindPointCheckPoint = g_EntityFuncs.FindEntityByClassname(pFindPointCheckPoint, 'point_checkpoint')) !is null)
        {
            if(!PCP_MISC::IsReenable(cast<CBaseAnimating@>(pFindPointCheckPoint)))
            {
                if(g_SurvivalMode.IsActive())
                {
                    pFindPointCheckPoint.pev.speed = 1.0f;
                    pFindPointCheckPoint.pev.health = 1.0f;
                    pFindPointCheckPoint.pev.effects &= ~EF_NODRAW;
                }
                else
                {
                    pFindPointCheckPoint.pev.speed = 0.0f;
                    pFindPointCheckPoint.pev.health = 0.0f;
                    pFindPointCheckPoint.pev.effects |= EF_NODRAW;
                }
            }
        }

        for(int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(iPlayer);

            if(pPlayer is null || !pPlayer.IsConnected())
                continue;

            PCP_MISC::SpawnCountHUDText(pPlayer);

            if(!pPlayer.GetObserver().IsObserver() || PCP_MISC::GetCKV(pPlayer, '$i_pcp_spawns') <= 0)
                continue;

            g_PlayerFuncs.PrintKeyBindingString(pPlayer, 'Press +ALT1 to spawn');

            if((pPlayer.m_afButtonReleased & (IN_ALT1)) != 0)
            {		
                while((@pFindPointCheckPoint = g_EntityFuncs.FindEntityByClassname(pFindPointCheckPoint, 'point_checkpoint')) !is null)
                {  
                    point_checkpoint@ pSave = cast<point_checkpoint@>(CastToScriptClass(pFindPointCheckPoint));
                    CBaseKeepData@ pData = pSave.GetPlayerSpawn(pPlayer);
                    string SteamID = PCP_MISC::GetSteamID(pPlayer);

                    if(pData.spawn_number != int(PCP_MISC::GetData(SteamID + '_spawned')) +1)
                        continue;

                    pPlayer.GetObserver().RemoveDeadBody();
                    pPlayer.SetOrigin(pFindPointCheckPoint.pev.origin);
                    pPlayer.Revive();

                    pPlayer.pev.health = Math.max(1, pData.health);
                    pPlayer.pev.max_health = Math.max(100, pData.max_health); 
                    pPlayer.pev.armorvalue = Math.max(0, pData.armor);
                    pPlayer.pev.armortype = Math.max(100, pData.max_armor);

                    PCP_MISC::SetData(PCP_MISC::GetSteamID(pPlayer) + '_spawned', +1);
                    PCP_MISC::SetCKV(pPlayer, '$i_pcp_spawns', -1);
                    PCP_MISC::FindPlayerEquip(pPlayer, pFindPointCheckPoint);
                    PCP_MISC::CreatePlayerSpawnEffect(pPlayer.pev.origin);

                    g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, pFindPointCheckPoint.pev.message, 1.0f, ATTN_NORM);

                    pSave.dicPlayerSaved.delete(SteamID);
                    break;
                }
            }
        }
    }
}