#include "common"

/*
  this used to have an array of "slots", each with predefined relation class,
  about 13 in total, which would limit the amount of DM players
  but now you can just hack through any classification in PlayerTakeDamage
*/

void MapInit() {
  q1_InitCommon();
  q1_Deathmatch = true;
}
