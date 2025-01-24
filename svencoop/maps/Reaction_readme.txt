Gut Reaction: Sven Co-op version readme 11/07/01

http://www.svencoop.com

------------------------

This is the first release of Gut Reaction as a Sven Co-op level. This map pack is a modified version of the original version released November 1999 by Tim Johnston which recieved incredible critical acclaim from numerous map release sites. 

The Lambda Map Complex described the map as:

"..an excellent map featuring excellence in all areas of mapping." 8/10

We are extremely lucky to have the support of a excellent mapper like Tim in converting Gut Reaction to Co-op and I'm pleased that the idea worked out for the best.

Have fun

Mad Jonesy (madjonesy@svencoop.com)

--------------------------

There are a few issues and differences with the Single Player version of Gut Reaction and they are listed below.

General Additions:

- Modified levels to include more monsters, unnecessary to fix anything, but gives the players more to kill on maps

- Stopped backwards transitions through cfg file, going back a level is not currently supported.

- Added gr_ prefix to level names to show them as maps in the gut reaction series.

Gut_Reaction.bsp (formally security):

- Changed the 'info_player_start' entity into a 'info_player_deathmatch' so the first map could be selected from the 'Create Game' menu.

Tunnel3.bsp

- Removed sentry turret at player spawn point

- Slowed down the speed of the pistons slightly to enable players with poorer connections to stand more of a chance with the jumps

- Reduced the damage of the electric shock to give players with lag more of a chance to get across. You'll get hurt badly if you jump into it, but it won't be fatal.

Corentry.bsp

- Removed the transition back to Tunnel3 to enable both routes to the surface to be taken. Previously using nomaptrans forced the players to use one route.

Coremain.bsp

- Moved the player start back into the elevator for continuity from previous level.

Reactors.bsp

- Changed houndeyes into Alien Grunts and Slaves for more challenge

Finale.bsp

- Removed the trigger_endsection, this causes dedicated servers to lock up on completion of the series.

- Reduced the length of the credits to stop the players sitting around for too long, full list of credits is availiable in reaction.txt