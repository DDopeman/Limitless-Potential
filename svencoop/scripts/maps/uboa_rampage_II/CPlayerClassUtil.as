/* 
 * プレイヤークラス状態管理
 */
enum classtype_e {
    CLASSTYPE_BRAWLER = 0,
    CLASSTYPE_KARATEKA,
    CLASSTYPE_WEAPONMASTER,
    CLASSTYPE_WORKER
};

class CPlayerClassUtil {
    private string NOPLAYERCLASS_MODEL = "uboac";
    private array<string> PLAYERCLASS_MODEL = {
        "uboac_rampage2_p1",
        "uboac_rampage2_p2",
        "uboac_rampage2_p3",
        "uboac_rampage2_p4"
    };
    
    private string PLAYERCLASS_CHANGER = "weapon_zassi";
    private array<string> PLAYERCLASS_WEAPON = {
        "weapon_merikensack2",
        "weapon_sude",
        "weapon_higonokami",
        "weapon_gennou"
    };
    
    private array<string> BREAKABLE_WEAPON = {
        "weapon_ironpipe",
        "weapon_butterflyknife",
        "weapon_lucille",
        "weapon_katana",
        "weapon_kagizume",
        "weapon_policebaton",
        "weapon_tekkotsu",
        "weapon_pickaxe",
        "weapon_kanban",
        "weapon_block",
        "weapon_guidelight",
        "weapon_karateglove",
        "weapon_kukri",
        "weapon_golfclub",
        "weapon_kitchenknife"
    };
    
    private array<string> ARROWED_WEAPON = {
        "weapon_medkit" 
    };
    
    // ランダムに武器名を取得する
    string ChooseRandomWeapon() {
        int targetIndex = Math.RandomLong(0, BREAKABLE_WEAPON.length() -1);
        return BREAKABLE_WEAPON[targetIndex];
    }
    
    // 武器を除去
    void Removes(array<string> items, CBasePlayer@ pPlayer) {
        for (uint i = 0; i < items.length(); i++) {
            CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem(items[i]);
            if (pItem !is null) {
                pPlayer.RemovePlayerItem(pItem);
            }
        }
    }
    
    // 武器を所持しているか
    int CountWeapons(CBasePlayer@ pPlayer) {
        int carryCount = 0;
        for (uint i = 0; i < BREAKABLE_WEAPON.length(); i++) {    
            if (pPlayer.HasNamedPlayerItem(BREAKABLE_WEAPON[i]) !is null) {
                carryCount++;
            }
        }
        return carryCount;
    }
    
    // モデル初期化
    void InitModel(CBasePlayer@ pPlayer) {
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        pInfos.SetValue("model", NOPLAYERCLASS_MODEL);
    }
        
    // 指定モデルかチェック
    private bool isPlayerClassModel(CBasePlayer@ pPlayer) {
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        string modelName = pInfos.GetValue("model");
        
        for (uint i = 0; i < PLAYERCLASS_MODEL.length(); i++) {
            if (modelName == PLAYERCLASS_MODEL[i]) {
                return true;
            }
        }
        return false;
    }
    
    // 状態チェック
    void CheckStatus(CBasePlayer@ pPlayer, bool isInit) {
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        
        // 指定モデル外なら、変更
        if (!isPlayerClassModel(pPlayer)) {
            pInfos.SetValue("model", NOPLAYERCLASS_MODEL);
        }
        
        float speed  = 300.0;
        float health = 100.0;
        float armor  = 100.0;
        
        pPlayer.pev.maxspeed = 300.0;
        string model = pInfos.GetValue("model");
        for (uint i = 0; i < PLAYERCLASS_MODEL.length(); i++) {
            if (PLAYERCLASS_MODEL[i] == model) {
                // PlayerClassごとの特典設定
                switch (i) {
                case CLASSTYPE_BRAWLER: 
                    speed  = 350.0;
                    health = 125.0;
                    armor  = 100.0;
                    break;
                case CLASSTYPE_KARATEKA: 
                    speed  = 400.0;
                    health = 100.0;
                    armor  = 100.0;
                    break;
                case CLASSTYPE_WEAPONMASTER: 
                    speed  = 350.0;
                    health = 110.0;
                    armor  = 110.0;
                    break;
                case CLASSTYPE_WORKER: 
                    speed  = 300.0;
                    health = 150.0;
                    armor  = 100.0;
                    break;
                }
                
                // 初期化時なら武器提供
                if (isInit) {
                    pPlayer.GiveNamedItem(PLAYERCLASS_WEAPON[i], 1, UBOAKIAI_MAX_AMMO);
                    pPlayer.GiveNamedItem(ARROWED_WEAPON[0], 1, 0);
                
                    // 指定武器を選択する
                    CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem(PLAYERCLASS_WEAPON[i]);
                    if (pItem !is null) {
                        pPlayer.SwitchWeapon(pItem);
                    }
                }
                
            }
        }
        
        // 適用
        pPlayer.pev.maxspeed = speed;
        
        // 各種補正処理
        pPlayer.pev.max_health = health;
        if (isInit) {
            pPlayer.pev.health = health;
        }
        
        pPlayer.pev.armortype = armor;
        if (isInit) {
            pPlayer.pev.armorvalue = armor;
        }
        
        // 該当以外武器は没収
        for (uint i = 0; i < MAX_ITEM_TYPES; i++ ) {
            CBasePlayerItem@ pItem = pPlayer.m_rgpPlayerItems(i);
            if (pItem !is null) {
                string checkWepName = pItem.GetClassname();
                if (ShouldWeaponRemove(pPlayer, checkWepName)) {
                    pPlayer.RemovePlayerItem(pItem);
                }
            }
        }
        
    }
    
    // 武器表示
    void DescriptionWeaopn(CBasePlayer@ pPlayer, string wepName,
                int power, int speed, int reach, int durability, string special
    ) {

        string msg = "";
        msg += "[" + wepName + "]\n";
        msg += "Power      : " + DrawParam(power) + "\n";
        msg += "Speed      : " + DrawParam(speed) + "\n";
        msg += "Reach      : " + DrawParam(reach) + "\n";
        msg += "Durability : " + DrawParam(durability) + "\n";
        msg += "Special    : " + special + "\n";
        
        HUDTextParams textParms;
        textParms.fxTime = 30;
        textParms.fadeinTime = 0.5;
        textParms.holdTime = 3.0;
        textParms.fadeoutTime = 1.0;
        textParms.effect = 0;
        textParms.channel = 2;
        textParms.x = 0.05;
        textParms.y = 0.40;
        textParms.r1 = 0;
        textParms.g1 = 255;
        textParms.b1 = 255;
        textParms.r2 = 0;
        textParms.g2 = 0;
        textParms.b2 = 255;
        g_PlayerFuncs.HudMessage(pPlayer, textParms, msg);
    }
    
    private string DrawParam(int val) {
        string ret = "";        
        for (int i = 0; i < val; i++){
            ret += ">";
        }
        return ret;
    }
    
    
    // クラス説明表示
    void DescriptionPlayerClass(CBasePlayer@ pPlayer, int playerClassNo) {
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        string modelName = pInfos.GetValue("model");
        
        string msg = "";
        switch (playerClassNo) {
        case CLASSTYPE_BRAWLER:
            msg += "#1: <BRAWLER>\n";
            msg += "----------------------------\n";
            msg += "  VITALITY:\n";
            msg += "    >>>> \n";
            msg += "  STRENGTH:\n";
            msg += "    >>>> \n";
            msg += "  AGILITY:\n";
            msg += "    >>> \n";
            msg += "  WEAPON:\n";
            msg += "    >> \n";
            msg += "  COMBO:\n";
            msg += "    >>>> \n";
            break;
        case CLASSTYPE_KARATEKA:
            msg += "#2: <KARATEKA>\n";
            msg += "----------------------------\n";
            msg += "  VITALITY:\n";
            msg += "    >> \n";
            msg += "  STRENGTH:\n";
            msg += "    >> \n";
            msg += "  AGILITY:\n";
            msg += "    >>>>> \n";
            msg += "  WEAPON:\n";
            msg += "    > \n";
            msg += "  COMBO:\n";
            msg += "    >>>>> \n";
            break;
        case CLASSTYPE_WEAPONMASTER:
            msg += "#3: <WEAPON MASTER>\n";
            msg += "----------------------------\n";
            msg += "  VITALITY:\n";
            msg += "    >>> \n";
            msg += "  STRENGTH:\n";
            msg += "    >>> \n";
            msg += "  AGILITY:\n";
            msg += "    >>> \n";
            msg += "  WEAPON:\n";
            msg += "    >>>>> \n";
            msg += "  COMBO:\n";
            msg += "    >> \n";
            break;
        case CLASSTYPE_WORKER:
            msg += "#4: <WORKER>\n";
            msg += "----------------------------\n";
            msg += "  VITALITY:\n";
            msg += "    >>>>> \n";
            msg += "  STRENGTH:\n";
            msg += "    >>>> \n";
            msg += "  AGILITY:\n";
            msg += "    >> \n";
            msg += "  WEAPON:\n";
            msg += "    >> \n";
            msg += "  COMBO:\n";
            msg += "    > \n";
            break;
        }
        
        
        uint r1 = 255;
        uint g1 = 128;
        uint b1 = 64;
        uint r2 = 255;
        uint g2 = 101;
        uint b2 = 14;
        if (modelName == PLAYERCLASS_MODEL[playerClassNo]) {
            r1 = 64;
            g1 = 64;
            b1 = 64;
            r2 = 96;
            g2 = 96;
            b2 = 96;
        }
        
        HUDTextParams textParms;
        textParms.fxTime = 30;
        textParms.fadeinTime = 0.5;
        textParms.holdTime = 6.0;
        textParms.fadeoutTime = 1.0;
        textParms.effect = 0;
        textParms.channel = 2;
        textParms.x = 0.05;
        textParms.y = 0.05;
        textParms.r1 = r1;
        textParms.g1 = g1;
        textParms.b1 = b1;
        textParms.r2 = r2;
        textParms.g2 = g2;
        textParms.b2 = b2;
        g_PlayerFuncs.HudMessage(pPlayer, textParms, msg);
    }
    
    // PlayerClass変更前処理（武器除去）
    bool PreChangePlayerClass(CBasePlayer@ pPlayer, int playerClassNo) {
        // モデルと、変更先PlayerClassをチェック
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        if (pInfos.GetValue("model") == PLAYERCLASS_MODEL[playerClassNo]) {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You have already selected this class.\n");
            return false;
        }
        
        // 武器除去
        Removes(PLAYERCLASS_WEAPON, pPlayer);
        Removes(BREAKABLE_WEAPON, pPlayer);
        
        return true;
    }
    
    // クラス変更後実行
    void PostChangePlayerClass(CBasePlayer@ pPlayer, int playerClassNo) {
        // 武器とモデル切り替え
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        pInfos.SetValue("model", PLAYERCLASS_MODEL[playerClassNo]);
        
        // 状態更新
        CheckStatus(pPlayer, true);
        
        /*
        HUDTextParams textParms;
        textParms.fxTime = 30;
        textParms.fadeinTime = 0.5;
        textParms.holdTime = 2.0;
        textParms.fadeoutTime = 1.0;
        textParms.effect = 0;
        textParms.channel = 2;
        textParms.x = 0.4;
        textParms.y = 0.6;
        textParms.r1 = 0;
        textParms.g1 = 255;
        textParms.b1 = 255;
        textParms.r2 = 0;
        textParms.g2 = 0;
        textParms.b2 = 255;
        g_PlayerFuncs.HudMessage(pPlayer, textParms, "CHANGED CLASS!!");
        */
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "CHANGED CLASS!!\n");
        
    }
    
    // 武器を除去すべきか
    bool ShouldWeaponRemove(CBasePlayer@ pPlayer, string className) {
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        string modelName = pInfos.GetValue("model");
        
        // PlayerClass選択武器
        if (className == PLAYERCLASS_CHANGER) {
            return false; // →OK
        }
        // NoPlayerClass状態
        if (modelName == NOPLAYERCLASS_MODEL) {
            return true; // →NG
        }
        
        // PlayerClass武器で、該当PlayerClass以外
        for (uint i = 0; i < PLAYERCLASS_WEAPON.length(); i++) {
            if ((className == PLAYERCLASS_WEAPON[i]) && (modelName != PLAYERCLASS_MODEL[i])) {
                return true; // →NG
            }
        }
        
        // 余分な武器
        if ( (!IsInItems(PLAYERCLASS_WEAPON, className)) 
            && (!IsInItems(BREAKABLE_WEAPON, className)) 
            && (!IsInItems(ARROWED_WEAPON, className)) 
        ) {
            return true; // →NG
        }
        
        return false; // →OK
    }
    
    // 配列にあるか
    private bool IsInItems(array<string> items, string target) {
        for (uint i = 0; i < items.length(); i++) {
            if (items[i] == target) {
                return true;
            }
        }
        return false;
    }
    
    // プレイヤークラスのENUM値を返す
    int GetPlayerClassIndex(CBasePlayer@ pPlayer) {
        KeyValueBuffer@ pInfos = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
        string modelName = pInfos.GetValue("model");
        for (uint i = 0; i < PLAYERCLASS_MODEL.length(); i++) {
            if (modelName == PLAYERCLASS_MODEL[i]) {
                return i;
            }
        }
        return -1;
    }
}