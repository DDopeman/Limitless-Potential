/*
escape sequences. These can be used anywhere.

/t : 

format: /ttarget/key/
seeks the target entity keyvalue by targetname and replaces the /t struture for this value. Supports !activator and !caller.

*/

// transforms /t escape sequences into common text
string ProcessTextT(string ptext, CBaseEntity@ pActivator, CBaseEntity@ pCaller)
{
	uint i = 0;
	uint k = 0;
	string ptarget = ""; 
	string pkeyvalue = "";
	string newtext = "";
	bool ptargetok = false;
	bool pkeyvalueok = false;
	
	while ( i < ptext.Length() )
	{
		if (ptext[i] == "/" && ptext[i+1] == "t")
		{
			g_EngineFuncs.ServerPrint("/t detected"+"\n");
			k = i+2;
			pkeyvalueok = false;
			ptargetok = false;
			while ( k < ptext.Length() && pkeyvalueok == false)
			{
				if (ptext[k] != "/" && ptargetok == false)
				{
					ptarget = ptarget + ptext[k]; 
				}
				else
				{
					if (ptext[k] == "/" && ptargetok == false)
					{
						k++;
					}
					ptargetok = true;
											
					if (ptext[k] != "/" && ptargetok == true && pkeyvalueok == false)
					{
						pkeyvalue = pkeyvalue + ptext[k];
						g_EngineFuncs.ServerPrint(string(pkeyvalue)+"\n");
					}
					else
					{
						if (ptext[k] == "/")
						{
							pkeyvalueok = true;
						}
					}
				}
				
				k++;
			}
			
			if (pkeyvalueok)
			{
				CBaseEntity@ pEntity;
				if (ptarget == "!activator")	{@pEntity = @pActivator;} else
				if (ptarget == "!caller")		{@pEntity = @pCaller;} else
												{@pEntity = g_EntityFuncs.FindEntityByTargetname( @pEntity, ptarget );}
				
				if (@pEntity != null)
				{
					string ntext = getKeyValue( @pEntity, pkeyvalue);
					if (ntext.Length() > 64) { ntext = ntext.SubString(0,64);}
					
					ptext = ptext.SubString(0, i)+ ntext +ptext.SubString(i+ uint(pkeyvalue.Length() + 4)+ uint(ptarget.Length()), uint(ptext.Length()));
					i = i + uint(ntext.Length()) - 1;
				}
				else
				{
					g_EngineFuncs.ServerPrint("[game_sprite_text]: entity failed to find target in /t"+"\n");
				}
			}
		}
	i++;
	}

	return ptext;
}

string sstring(string vin)
{
	return string(vin);
}

string sstring(string_t vin)
{
	return string(vin);
}

string sstring(double vin)
{
	return string(vin);
}

string sstring(int vin)
{
	return string(vin);
}

string sstring(uint vin)
{
	return string(vin);
}

string sstring(bool vin)
{
	return string(vin);
}

string sstring(char vin)
{
	return string(vin);
}

string sstring(Vector vin)
{
	string sComp = string(vin.x)+" "+string(vin.y)+" "+string(vin.z);
	return sComp;
}

string getKeyValue(CBasePlayer@ pPlayer, string sKey)
{
	return getKeyValue(cast<CBaseEntity@>(pPlayer), sKey);
}

string getKeyValue(CBaseEntity@ pEntity, string sKey)
{
	if(sKey == "classname")
	{
		return string(pEntity.pev.classname);
	}else if(sKey == "globalname"){
		return string(pEntity.pev.globalname);
	}else if(sKey == "origin")
	{
		return sstring(pEntity.pev.origin);
	}else if(sKey == "oldorigin")
	{
		return sstring(pEntity.pev.oldorigin);
	}else if(sKey == "velocity")
	{
		return sstring(pEntity.pev.velocity);
	}else if(sKey == "basevelocity")
	{
		return sstring(pEntity.pev.basevelocity);
	}else if(sKey == "movedir")
	{
		return sstring(pEntity.pev.movedir);
	}else if(sKey == "angles")
	{
		return sstring(pEntity.pev.angles);
	}else if(sKey == "avelocity")
	{
		return sstring(pEntity.pev.avelocity);
	}else if(sKey == "punchangle")
	{
		return sstring(pEntity.pev.punchangle);
	}else if(sKey == "v_angle")
	{
		return sstring(pEntity.pev.v_angle);
	}else if(sKey == "endpos")
	{
		return sstring(pEntity.pev.endpos);
	}else if(sKey == "startpos")
	{
		return sstring(pEntity.pev.startpos);
	}else if(sKey == "impacttime")
	{
		return sstring(pEntity.pev.impacttime);
	}else if(sKey == "starttime")
	{
		return sstring(pEntity.pev.starttime);
	}else if(sKey == "fixangle")
	{
		return sstring(pEntity.pev.fixangle);
	}else if(sKey == "idealpitch")
	{
		return sstring(pEntity.pev.idealpitch);
	}else if(sKey == "pitch_speed")
	{
		return sstring(pEntity.pev.pitch_speed);
	}else if(sKey == "ideal_yaw")
	{
		return sstring(pEntity.pev.yaw_speed);
	}else if(sKey == "modelindex")
	{
		return sstring(pEntity.pev.modelindex);
	}else if(sKey == "model")
	{
		return sstring(pEntity.pev.model);
	}else if(sKey == "viewmodel")
	{
		return sstring(pEntity.pev.viewmodel);
	}else if(sKey == "weaponmodel")
	{
		return sstring(pEntity.pev.weaponmodel);
	}else if(sKey == "absmin")
	{
		return sstring(pEntity.pev.absmin);
	}else if(sKey == "absmax")
	{
		return sstring(pEntity.pev.absmax);
	}else if(sKey == "mins")
	{
		return sstring(pEntity.pev.mins);
	}else if(sKey == "maxs")
	{
		return sstring(pEntity.pev.maxs);
	}else if(sKey == "size")
	{
		return sstring(pEntity.pev.size);
	}else if(sKey == "ltime")
	{
		return sstring(pEntity.pev.ltime);
	}else if(sKey == "nextthink")
	{
		return sstring(pEntity.pev.nextthink);
	}else if(sKey == "movetype")
	{
		return sstring(pEntity.pev.movetype);
	}else if(sKey == "solid")
	{
		return sstring(pEntity.pev.solid);
	}else if(sKey == "skin")
	{
		return sstring(pEntity.pev.skin);
	}else if(sKey == "body")
	{
		return sstring(pEntity.pev.body);
	}else if(sKey == "effects")
	{
		return sstring(pEntity.pev.effects);
	}else if(sKey == "gravity")
	{
		return sstring(pEntity.pev.gravity);
	}else if(sKey == "friction")
	{
		return sstring(pEntity.pev.friction);
	}else if(sKey == "light_level")
	{
		return sstring(pEntity.pev.light_level);
	}else if(sKey == "sequence")
	{
		return sstring(pEntity.pev.sequence);
	}else if(sKey == "gaitsequence")
	{
		return sstring(pEntity.pev.gaitsequence);
	}else if(sKey == "frame")
	{
		return sstring(pEntity.pev.frame);
	}else if(sKey == "animtime")
	{
		return sstring(pEntity.pev.animtime);
	}else if(sKey == "framerate")
	{
		return sstring(pEntity.pev.framerate);
	}else if(sKey == "scale")
	{
		return sstring(pEntity.pev.scale);
	}else if(sKey == "rendermode")
	{
		return sstring(pEntity.pev.rendermode);
	}else if(sKey == "renderamt")
	{
		return sstring(pEntity.pev.renderamt);
	}else if(sKey == "rendercolor")
	{
		return sstring(pEntity.pev.rendercolor);
	}else if(sKey == "renderfx")
	{
		return sstring(pEntity.pev.renderfx);
	}else if(sKey == "health")
	{
		return sstring(pEntity.pev.health);
	}else if(sKey == "frags")
	{
		return sstring(pEntity.pev.frags);
	}else if(sKey == "weapons")
	{
		return sstring(pEntity.pev.weapons);
	}else if(sKey == "takedamage")
	{
		return sstring(pEntity.pev.takedamage);
	}else if(sKey == "deadflag")
	{
		return sstring(pEntity.pev.deadflag);
	}else if(sKey == "view_ofs")
	{
		return sstring(pEntity.pev.view_ofs);
	}else if(sKey == "button")
	{
		return sstring(pEntity.pev.button);
	}else if(sKey == "impulse")
	{
		return sstring(pEntity.pev.impulse);
	}else if(sKey == "spawnflags")
	{
		return sstring(pEntity.pev.spawnflags);
	}else if(sKey == "flags")
	{
		return sstring(pEntity.pev.flags);
	}else if(sKey == "colormap")
	{
		return sstring(pEntity.pev.colormap);
	}else if(sKey == "team")
	{
		return sstring(pEntity.pev.team);
	}else if(sKey == "max_health")
	{
		return sstring(pEntity.pev.max_health);
	}else if(sKey == "teleport_time")
	{
		return sstring(pEntity.pev.teleport_time);
	}else if(sKey == "armortype")
	{
		return sstring(pEntity.pev.armortype);
	}else if(sKey == "armorvalue")
	{
		return sstring(pEntity.pev.armorvalue);
	}else if(sKey == "waterlevel")
	{
		return sstring(pEntity.pev.waterlevel);
	}else if(sKey == "watertype")
	{
		return sstring(pEntity.pev.watertype);
	}else if(sKey == "target")
	{
		return sstring(pEntity.pev.target);
	}else if(sKey == "targetname")
	{
		return sstring(pEntity.pev.targetname);
	}else if(sKey == "netname")
	{
		return sstring(pEntity.pev.netname);
	}else if(sKey == "message")
	{
		return sstring(pEntity.pev.message);
	}else if(sKey == "dmg_take")
	{
		return sstring(pEntity.pev.dmg_take);
	}else if(sKey == "dmg_save")
	{
		return sstring(pEntity.pev.dmg_save);
	}else if(sKey == "dmg")
	{
		return sstring(pEntity.pev.dmg);
	}else if(sKey == "dmgtime")
	{
		return sstring(pEntity.pev.dmgtime);
	}else if(sKey == "noise")
	{
		return sstring(pEntity.pev.noise);
	}else if(sKey == "noise1")
	{
		return sstring(pEntity.pev.noise1);
	}else if(sKey == "noise2")
	{
		return sstring(pEntity.pev.noise2);
	}else if(sKey == "noise3")
	{
		return sstring(pEntity.pev.noise3);
	}else if(sKey == "speed")
	{
		return sstring(pEntity.pev.speed);
	}else if(sKey == "air_finished")
	{
		return sstring(pEntity.pev.air_finished);
	}else if(sKey == "pain_finished")
	{
		return sstring(pEntity.pev.pain_finished);
	}else if(sKey == "radsuit_finished")
	{
		return sstring(pEntity.pev.radsuit_finished);
	}else if(sKey == "playerclass")
	{
		return sstring(pEntity.pev.playerclass);
	}else if(sKey == "maxspeed")
	{
		return sstring(pEntity.pev.maxspeed);
	}else if(sKey == "fov")
	{
		return sstring(pEntity.pev.fov);
	}else if(sKey == "weaponanim")
	{
		return sstring(pEntity.pev.weaponanim);
	}else if(sKey == "pushmsec")
	{
		return sstring(pEntity.pev.pushmsec);
	}else if(sKey == "bInDuck")
	{
		return sstring(pEntity.pev.bInDuck);
	}else if(sKey == "fltimesteps0ound")
	{
		return sstring(pEntity.pev.flTimeStepSound);
	}else if(sKey == "flswimtime")
	{
		return sstring(pEntity.pev.flSwimTime);
	}else if(sKey == "flducktime")
	{
		return sstring(pEntity.pev.flDuckTime);
	}else if(sKey == "istepleft")
	{
		return sstring(pEntity.pev.iStepLeft);
	}else if(sKey == "flfallvelocity")
	{
		return sstring(pEntity.pev.flFallVelocity);
	}else if(sKey == "gamestate")
	{
		return sstring(pEntity.pev.gamestate);
	}else if(sKey == "oldbuttons")
	{
		return sstring(pEntity.pev.oldbuttons);
	}else if(sKey == "groupinfo")
	{
		return sstring(pEntity.pev.groupinfo);
	}else if(sKey == "iuser1")
	{
		return sstring(pEntity.pev.iuser1);
	}else if(sKey == "iuser2")
	{
		return sstring(pEntity.pev.iuser2);
	}else if(sKey == "iuser3")
	{
		return sstring(pEntity.pev.iuser3);
	}else if(sKey == "iuser4")
	{
		return sstring(pEntity.pev.iuser4);
	}else if(sKey == "fuser1")
	{
		return sstring(pEntity.pev.fuser1);
	}else if(sKey == "fuser2")
	{
		return sstring(pEntity.pev.fuser2);
	}else if(sKey == "fuser3")
	{
		return sstring(pEntity.pev.fuser3);
	}else if(sKey == "fuser4")
	{
		return sstring(pEntity.pev.fuser4);
	}else if(sKey == "vuser1")
	{
		return sstring(pEntity.pev.vuser1);
	}else if(sKey == "vuser2")
	{
		return sstring(pEntity.pev.vuser2);
	}else if(sKey == "vuser3")
	{
		return sstring(pEntity.pev.vuser3);
	}else if(sKey == "vuser4")
	{
		return sstring(pEntity.pev.vuser4);
	}else if(sKey == "entindex")
	{
		return sstring(pEntity.entindex());
	}else{
		return "ERROR";
	}
}

/*string GetIntertedSlash ()
{
string InvertedSlash = "\c";
//InvertedSlash = InvertedSlash[0];
//InvertedSlash = InvertedSlash.SubString(0, 0);

return InvertedSlash;
}*/

