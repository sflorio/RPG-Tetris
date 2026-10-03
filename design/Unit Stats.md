Some stats are shared across all units, both friendly and hostile.
Negative effects cannot reduce a stat to less than 1.

| Stat                  | Tag  | Function                                                                                                                                        |
| --------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Name                  | NAME | The name of the unit.                                                                                                                           |
| Level                 | LVL  | The level of the unit. For allies, this is the Party Level.                                                                                     |
| Type                  | TYPE | The type of the unit.                                                                                                                           |
| Hit Points            | HP   | The maximum health value of the unit. When a unit takes equal to or more damage than their current Hit Point value, they become Downed.         |
| Offense               | OFF  | The physical strength of a specific unit. Offense is modified by various sources before factoring into unit or technique efficiency.            |
| Defense               | DEF  | The physical resistance of a specific unit. Defense is modified by various sources before factoring into unit or technique efficiency.          |
| Tech Offense          | TCHO | The non-physical strength of a specific unit. Tech Offense is modified by various sources before factoring into unit or technique efficiency.   |
| Tech Defense          | TCHD | The non-physical resistance of a specific unit. Tech Defense is modified by various sources before factoring into unit or technique efficiency. |
| Perfect Strike Chance | PSC  | The chance for any given source of damage or healing to be a Perfect Strike, increasing its efficiency. <br>By default, this is 1%.             |
| Perfect Strike Power  | PSP  | The efficiency gained when a Perfect Strike occurs. <br>By default, this is a 50% gain.                                                         |
| Dodge                 | DOD  | The chance for a unit to avoid any given source of damage. Note that some sources of damage are unavoidable. <br>By default, this is 1%.        |
| Accuracy              | ACC  | The chance for a unit to hit in combat. Some attacks have a lower base Accuracy.<br>By default this is 100%.                                    |
| Speed                 | SPD  | The chance for a given unit's Block Type to appear. <br>By default, this is 1.                                                                  |

## Party Stats

| Stat           | Tag  | Function                                                                                                                                   |
| -------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Level          | LVL  | The level of the party. All allies level up together, including those not in the active team.                                              |
| Experience     | EXP  | The amount of experience the party has towards the next level.                                                                             |
| Tech Points    | TP   | The total amount of Tech Points the party has. All allies in the active team contribute their Tech Point value to the party's Tech Points. |
| Luck           | LUCK | The total amount of Luck the party has. All allies in the active team contribute their Luck value to the party's Luck.                     |
| Crowns         | CRWN | The amount of currency the party has.                                                                                                      |
| Play Time      | TIME | The total active playtime of the current file.                                                                                             |
| Battle Count   | BATL | The total number of battles won by the party.                                                                                              |
| Gravity        | GRAV | Determines how quickly blocks fall down the board. Gravity can be modified multiple sources, including enemy attacks.                      |
| Move Speed     | MOVE | Determines how quickly the player moves around the Field Map.                                                                              |
| Encounter Rate | ENCR | Determines how often a random encounter is spawned on the Field Map. Random Encounters are spawned as avoidable enemy units.               |
## Ally Stats

| Stat           | Tag  | Function                                                                                                                                                 |
| -------------- | ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tech Skill     | TP   | The amount of Tech Points the ally provides to the party.                                                                                                |
| Luck           | LUCK | The amount of Luck the ally provides to the party.                                                                                                       |
| Mastery Points | MP   | The amount of Mastery Points the ally currently has. Mastery Points are acquired by allies when enemies are defeated and the ally is on the active team. |

## Enemy Stats

| Stat           | Tag | Function                                 |
| -------------- | --- | ---------------------------------------- |
| Tech Points    |     | The amount of Tech Points the enemy has. |

## Stat Modifiers

Most stats can be modified by other sources (such as Soul Gems). These modifications are shown as + and - on the stat, with multiple indicating increases to the positive or negative modification.

| Stat Name    | Effect                                                                |
| ------------ | --------------------------------------------------------------------- |
| HP           | Modifies maximum HP by 5% per +/-                                     |
| Offense      | Modifies Offense by 2 per +/-                                         |
| Defense      | Modifies Defense by 2 per +/-                                         |
| Tech Offense | Modifies Tech Offense by 2 per +/-                                    |
| Tech Defense | Modifies Tech Defense by 2 per +/-                                    |
| PSChance     | Modifies Perfect Strike Chance by 3% per +/-                          |
| PSPower      | Modifies Perfect Strike Power by 5% per +/-                           |
| Dodge        | Modifies Dodge by 1% per +/-                                          |
| Accuracy     | Modifies Accuracy by 10% per +/-                                      |
| Speed        | Modifies Speed by 1 per +/-                                           |
| Luck         | Modifies Luck by 1 per +/-                                            |
| Tech         | Modifies Tech Skill by 1 per +/-                                      |
| Wrath        | Modifies Perfect Strike Chance and Perfect Strike Power by 2% per +/- |
| Might        | Modifies Offense and Tech Offense by 1 per +/-                        |
| Guard        | Modifies Defense and Tech Defense by 1 per +/-                        |
| Trained      | Modifies Dodge by 1% and Accuracy by 10% per +/-                      |
