==Base== x ==PerfectStrike== x ==Randomizer== x ==Type== x ==Other==

==Base==
((([2 x PartyLevel / 5]) + 2) x SourcePower x (CharacterOffense / TargetDefense)) / 50) + 1 = Base
- If SourcePowerClass is Physical, CharacterOffense is compared to TargetDefense.
- If SourcePowerClass is Technical, CharacterTechOffense is compared to TargetTechDefense.
*Flat value after equation, no decimal. Creates minimum value of 1.*

==PerfectStrike==
If Perfect Strike:
- (total x PerfectStrikePower) = PerfectStrike
If not:
- (total x 1) = PerfectStrike
*This handles if the damage needs to be modified by the Perfect Strike Power bonus.*
*Flat value after equation, no decimal.*

==Randomizer==
(total x ((RNG 85-100) / 100)) = Randomizer
*This adds a 15% variance to the damage so that it is not a predictable and consistent value.*
*Flat value after equation, no decimal.*

==Type==
If :
- TypeStrong, (total x 2) = Type
- TypeEffective, (total x 1.5) = Type
- TypeNeutral, (total x 1) = Type
- TypeWeak, (total x 0.5) = Type
- TypeZero, (total x 0) = Type
*Flat value after equation, no decimal.*

==Other== 
To be accounted for from equipped items.
*Flat value after equation, no decimal.*

---

**Example:**
Soldier attacks Goblin at Party Level 2 versus Enemy Level 3
Soldier attack is Power 10 and Attack stat is 3
Goblin Defense is 4
No type bonus

((([2 x PartyLevel / 5]) + 2) x SourcePower x (CharacterAttack / TargetDefense)) / 50) + 1 = Base

| (2 x 2 / 5) + 2 = 2.8 | 2.8 x 10 = 28 | 28 x (3 / 4) = 21 | 21 / 50 = .42 | .42 + 1 = 1.42 | Base = 1 |
| --------------------- | ------------- | ----------------- | ------------- | -------------- | -------- |
**2nd Example:**
Soldier attacks Goblin at Party Level 5 versus Enemy Level 3
Soldier attack is Power 10 and Attack stat is 6
Goblin Defense is 4
No type bonus

((([2 x PartyLevel / 5]) + 2) x SourcePower x (CharacterAttack / TargetDefense)) / 50) + 1 = Base

| (2 x 5 / 5) + 2 = 4 | 4 x 10 = 40 | 40 x (6 / 4) = 60 | 60 / 50 = 1.2 | 1.2 + 1 = 2.2 | Base = 2 |
| ------------------- | ----------- | ----------------- | ------------- | ------------- | -------- |
*Both examples use the same Offense value against the same Defense value, showing a scaling gain as Party Level and Offense increase.*

| Av D>   | Arcane   | Beast    | Martial  | Spirit   | Xeno   |
| ------- | -------- | -------- | -------- | -------- | ------ |
| Arcane  | x1       | x1       | **x1.5** | ==x2==   | *x0.5* |
| Beast   | **x1.5** | x1       | x1       | *x0.5*   | ==x2== |
| Martial | x1       | **x1.5** | x1       | ~~x0~~   | *x0.5* |
| Spirit  | x1       | x1       | *x0.5*   | **x1.5** | ==x2== |
| Xeno    | ==x2==   | x1       | ==x2==   | *x0.5*   | x1     |

Arcane - Anything magical
Martial - Anything standard warfare
Xeno - Anything with alien origins
Spirit - Anything otherworldly (ghosts, hexes)
Beast - Anything with monster origins

--------------
% = Armor/(Armor + x)
x = tuning knob for potency of Armor per point

Defense Chart

| Value | Reduction |
| ----- | --------- |
| 0     | 0%        |
| 1     | 9%        |
| 2     | 17%       |
| 3     | 23%       |
| 4     | 29%       |
| 5     | 33%       |
| 6     | 37%       |
| 7     | 41%       |
| 8     | 45%       |
| 9     | 48%       |
| 10    | 50%       |
