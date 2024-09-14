#include "common"

// coop shit
#include "monsters/monster_qarmy"
#include "monsters/monster_qdog"
#include "monsters/monster_qogre"
#include "monsters/monster_qfiend"
#include "monsters/monster_qscrag"
#include "monsters/monster_qknight"
#include "monsters/monster_qshambler"
#include "monsters/monster_qzombie"
#include "monsters/monster_qboss"
#include "../point_checkpoint"


void MapInit() {
  q1_InitCommon();
  q1_RegisterMonsters();
	RegisterPointCheckPointEntity();
}

void q1_RegisterMonsters() {
  q1_RegisterMonster_ARMY();
  q1_RegisterMonster_DOG();
  q1_RegisterMonster_OGRE();
  q1_RegisterMonster_FIEND();
  q1_RegisterMonster_SCRAG();
  q1_RegisterMonster_KNIGHT();
  q1_RegisterMonster_SHAMBLER();
  q1_RegisterMonster_ZOMBIE();
  q1_RegisterMonster_BOSS();
}
