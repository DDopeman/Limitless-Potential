class item_bts_armorvest : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bshift/barney_vest.mdl" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        if( other is null || !other.IsPlayer() || !other.IsAlive() )
            return false;

        CBasePlayer@ player = cast<CBasePlayer@>( other );

        if( player is null )
            return false;

        if( PM::HELMET == g_PlayerClass[ player, true ] )
            return false;

        if( player.pev.armorvalue >= player.pev.armortype )
            return false;

        player.pev.armorvalue += Math.RandomFloat( 20, 30 );

        if( player.pev.armorvalue > player.pev.armortype )
            player.pev.armorvalue = player.pev.armortype;

        // From CItemBattery at items.cpp
        NetworkMessage m( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
            m.WriteString( "item_battery" );
        m.End();

        g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "bts_rc/items/armor_pickup1.wav", 1, ATTN_NORM );

        self.UpdateOnRemove();
        pev.flags |= FL_KILLME;
        pev.targetname = String::EMPTY_STRING;

        return true;
    }
}

class item_bts_helmet : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bshift/barney_helmet.mdl" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        if( other is null || !other.IsPlayer() || !other.IsAlive() )
            return false;

        CBasePlayer@ player = cast<CBasePlayer@>( other );

        if( player is null )
            return false;

        if( PM::HELMET == g_PlayerClass[ player, true ] )
            return false;

        if( player.pev.armorvalue >= player.pev.armortype )
            return false;

        player.pev.armorvalue += Math.RandomFloat( 7, 10 );

        if( player.pev.armorvalue > player.pev.armortype )
            player.pev.armorvalue = player.pev.armortype;

        // From CItemBattery at items.cpp
        NetworkMessage m( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
            m.WriteString( "item_battery" );
        m.End();

        g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "bts_rc/items/armor_pickup1.wav", 1, ATTN_NORM );

        self.UpdateOnRemove();
        pev.flags |= FL_KILLME;
        pev.targetname = String::EMPTY_STRING;

        return true;
    }
}

class item_bts_hevbattery : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/hlclassic/w_battery.mdl" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        if( other is null || !other.IsPlayer() || !other.IsAlive() )
            return false;

        CBasePlayer@ player = cast<CBasePlayer@>( other );

        if( player is null )
            return false;

        if( PM::HELMET != g_PlayerClass[ player, true ] )
            return false;

        if( player.pev.armorvalue >= player.pev.armortype )
            return false;

        player.pev.armorvalue += Math.RandomFloat( 10, 25 );

        if( player.pev.armorvalue > player.pev.armortype )
            player.pev.armorvalue = player.pev.armortype;

        // From CItemBattery at items.cpp
        NetworkMessage m( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
            m.WriteString( "item_battery" );
        m.End();

        if( PM::HELMET == g_PlayerClass[ player, true ] )
        {
            int pct = int( float( player.pev.armorvalue * 100.0 ) * ( 1.0 / 100 ) + 0.5 );

            pct = ( pct / 5 );

            if( pct > 0 )
            {
                pct--;
            }

            string szcharge;
            snprintf( szcharge, "!HEV_%1P", pct );

            player.SetSuitUpdate( szcharge, false, 30 );
        }

        g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );

        self.UpdateOnRemove();
        pev.flags |= FL_KILLME;
        pev.targetname = String::EMPTY_STRING;

        return true;
    }
}

class item_bts_sprayaid : ScriptBasePlayerAmmoEntity
{
    void Spawn()
    {
        g_EntityFuncs.SetModel( self, "models/bts_rc/items/w_medkits.mdl" );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        if( other is null || !other.IsPlayer() || !other.IsAlive() )
            return false;

        CBasePlayer@ player = cast<CBasePlayer@>( other );

        if( player is null )
            return false;

        if( player.pev.health >= player.pev.max_health )
            return false;

        player.TakeHealth( Math.RandomFloat( 10, 12 ), DMG_GENERIC );

        NetworkMessage m( MSG_ONE, NetworkMessages::ItemPickup, player.edict() );
            m.WriteString( "item_healthkit" );
        m.End();

        g_SoundSystem.EmitSound( player.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );

        self.UpdateOnRemove();
        pev.flags |= FL_KILLME;
        pev.targetname = String::EMPTY_STRING;

        return true;
    }
}
