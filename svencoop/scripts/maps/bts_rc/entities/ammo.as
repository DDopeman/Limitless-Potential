mixin class bts_ammo_base
{
    void Spawn( const string &in model )
    {
        g_EntityFuncs.SetModel( self, model );
        BaseClass.Spawn();
    }

    bool AddAmmo( CBaseEntity@ other, const int give, const string&in type, const int max, const string &in sound = "hlclassic/items/9mmclip1.wav" )
    {
        if( other !is null && other.GiveAmmo( give, type, max ) != -1 )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, sound, 1.0f, ATTN_NORM );
            return true;
        }
        return false;
    }
};

class ammo_bts_beretta : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_beretta::AMMO_GIVE, "9mm", weapon_bts_beretta::MAX_CARRY);
    }
}

class ammo_bts_beretta_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_beretta::AMMO_GIVE2, "bts:battery", weapon_bts_beretta::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_eagle : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dreagle" == pev.classname ? Math.RandomLong( 1, 4 ) : weapon_bts_eagle::AMMO_GIVE ), "357", weapon_bts_eagle::MAX_CARRY);
    }
}

class ammo_bts_eagle_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_eagle::AMMO_GIVE2, "bts:battery", weapon_bts_eagle::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_flarebox : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_flaregun_clip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_flaregun::AMMO_GIVE, "bts:flare", weapon_bts_flaregun::MAX_CARRY, "bts_rc/weapons/flare_pickup.wav");
    }
}

class ammo_bts_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? weapon_bts_flashlight::AMMO_DROP : weapon_bts_flashlight::AMMO_GIVE, "bts:battery", weapon_bts_flashlight::MAX_CARRY, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_glock : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_glock::AMMO_GIVE, "9mm", weapon_bts_glock::MAX_CARRY);
    }
}

class ammo_bts_glock17f : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_glock17f::AMMO_GIVE, "9mm", weapon_bts_glock17f::MAX_CARRY);
    }
}

class ammo_bts_glock17f_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl");
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_glock17f::AMMO_GIVE2, "bts:battery", weapon_bts_glock17f::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav");
    }
}

class ammo_bts_glock18 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_glock18::AMMO_GIVE, "9mm", weapon_bts_glock18::MAX_CARRY );
     }
}

class ammo_bts_glocksd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dglocksd" == pev.classname ? Math.RandomLong( 8, 13 ) : weapon_bts_glocksd::AMMO_GIVE ), "9mm", weapon_bts_glocksd::MAX_CARRY );
    }
}

class ammo_bts_m4 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_556mag" == pev.classname ? Math.RandomLong( 6, 12 ) : weapon_bts_m4::AMMO_GIVE ), "556", weapon_bts_m4::MAX_CARRY );
    }
}

class ammo_bts_m4sd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_556nato.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_m4sd::AMMO_GIVE, "556", weapon_bts_m4sd::MAX_CARRY );
    }
}

class ammo_bts_m16 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_556round" == pev.classname ? Math.RandomLong( 9, 23 ) : weapon_bts_m16::AMMO_GIVE ), "556", weapon_bts_m16::MAX_CARRY );
    }
}

class ammo_bts_m16_grenade : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_argrenade.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? weapon_bts_m16::AMMO_DROP2 : weapon_bts_m16::AMMO_GIVE2, "ARgrenades", weapon_bts_m16::MAX_CARRY2 );
    }
}

class ammo_bts_m79 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/w_argrenade.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? weapon_bts_m79::AMMO_DROP : weapon_bts_m79::AMMO_GIVE, "ARgrenades", weapon_bts_m79::MAX_CARRY );
    }
}

class ammo_bts_mp5 : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dmp5" == pev.classname ? Math.RandomLong( 9, 21 ) : weapon_bts_mp5::AMMO_GIVE ), "9mm", weapon_bts_mp5::MAX_CARRY );
    }
}

class ammo_bts_mp5gl : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_9mmarclip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_9mmbox" == pev.classname ? Math.RandomLong( 17, 20 ) : weapon_bts_mp5gl::AMMO_GIVE ), "9mm", weapon_bts_mp5gl::MAX_CARRY );
    }
}

class ammo_bts_mp5gl_grenade : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_argrenade.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, pev.SpawnFlagBitSet( SF_CREATEDWEAPON ) ? weapon_bts_mp5gl::AMMO_DROP2 : weapon_bts_mp5gl::AMMO_GIVE2, "ARgrenades", weapon_bts_mp5gl::MAX_CARRY2 );
    }
}

class ammo_bts_python : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn(( "ammo_bts_357cyl" == pev.classname ? "models/hlclassic/w_357ammo.mdl" : "models/hlclassic/w_357ammobox.mdl" ) );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_357cyl" == pev.classname ? Math.RandomLong( 2, 4 ) : weapon_bts_python::AMMO_GIVE ), "357", weapon_bts_python::MAX_CARRY );
    }
}

class ammo_bts_saw : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/w_saw_clip.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_dsaw" == pev.classname ? Math.RandomLong( 25, 30 ) : weapon_bts_saw::AMMO_GIVE ), "556", weapon_bts_saw::MAX_CARRY );
    }
}

class ammo_bts_sbshotgun : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/hlclassic/w_shotbox.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_sbshotgun::AMMO_GIVE, "buckshot", weapon_bts_sbshotgun::MAX_CARRY );
    }
}

class ammo_bts_sbshotgun_battery : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/furniture/w_flashlightbattery.mdl" );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_sbshotgun::AMMO_GIVE2, "bts:battery", weapon_bts_sbshotgun::MAX_CARRY2, "bts_rc/items/battery_pickup1.wav" );
    }
}

class ammo_bts_shotgun : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn(( "ammo_bts_shotshell" == pev.classname ? "models/w_shotshell.mdl" : "models/hlclassic/w_shotbox.mdl" ) );
    }
    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, ( "ammo_bts_shotshell" == pev.classname ? 3 : weapon_bts_shotgun::AMMO_GIVE ), "buckshot", weapon_bts_shotgun::MAX_CARRY );
    }
}

class ammo_bts_uzi : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_uzi_clip.mdl" );
    }

    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_uzi::AMMO_GIVE, "9mm", weapon_bts_uzi::MAX_CARRY );
    }
}

class ammo_bts_uzisd : ScriptBasePlayerAmmoEntity, bts_ammo_base
{
    void Spawn() {
        Spawn("models/bts_rc/weapons/w_uzi_clip.mdl" );
    }

    bool AddAmmo( CBaseEntity@ other ) {
        return AddAmmo(other, weapon_bts_uzisd::AMMO_GIVE, "9mm", weapon_bts_uzisd::MAX_CARRY );
    }
}
