## The team's Union meter.
##
## Fills as lines are cleared. Once [constant THRESHOLD] lines have accumulated the Union Assault
## fires automatically and the meter resets. Because a single clear can carry the total past the
## threshold (nine lines plus a four-line clear reaches thirteen), each line over the threshold adds
## [constant BONUS_PER_OVERFLOW_LINE] to the Assault's damage.
class_name UnionMeter extends RefCounted

## Lines needed to trigger the Union Assault.
const THRESHOLD: = 10

## Extra damage per line cleared beyond the threshold, as a fraction.
const BONUS_PER_OVERFLOW_LINE: = 0.10

## Lines banked toward the next Union Assault.
var lines: = 0


## Adds cleared lines. Returns the Union Assault's damage multiplier when the threshold is reached,
## or 0.0 when the meter is still filling.
func add_lines(count: int) -> float:
	lines += count
	if lines < THRESHOLD:
		return 0.0

	var overflow: = lines - THRESHOLD
	lines = 0
	return 1.0 + overflow*BONUS_PER_OVERFLOW_LINE


## Progress toward the next Union Assault, 0..1.
func get_ratio() -> float:
	return clampf(float(lines) / float(THRESHOLD), 0.0, 1.0)
