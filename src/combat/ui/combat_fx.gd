## A one-shot effect sprite: pops in, expands slightly, fades out, frees itself.
##
## Used for the moments the player should feel rather than read — a line going, an attack landing, a
## Xenoblock arriving. The code-drawn flashes and shakes stay; these sit on top of them.
##
## Art is Oryx 16-bit Fantasy FX, credited in CREDITS.md.
class_name CombatFX extends TextureRect

const FX_DIR: = "res://assets/fx/"

## Effect names, matching the files in [constant FX_DIR].
const HIT_SMALL: = "hit_small"
const HIT_SLASH: = "hit_slash"
const HIT_BIG: = "hit_big"
const RALLY: = "rally"
const UNION: = "union"
const LINE_CLEAR: = "line_clear"
const XENO: = "xeno"
const GUARD: = "guard"

## Which effect suits each attack, so a jab and a Union Assault do not look alike.
const ATTACK_EFFECTS: = {
	AttackResolver.Kind.BASIC: HIT_SMALL,
	AttackResolver.Kind.ADVANCED: HIT_SLASH,
	AttackResolver.Kind.ADVANCED_BOOSTED: HIT_BIG,
	AttackResolver.Kind.RALLY_STRIKE: RALLY,
	AttackResolver.Kind.UNION_ASSAULT: UNION,
}

# Cached so a burst does not hit the filesystem mid-battle.
static var _textures: Dictionary = {}


## Spawns an effect centred on `centre`, drawn `size_px` across. Returns null when the art is
## missing, so a absent file degrades to no effect rather than an error.
static func spawn(
	parent: Node,
	effect: String,
	centre: Vector2,
	size_px: float,
	z: int = 12,
	duration: float = 0.45
) -> CombatFX:
	var texture: = _get_texture(effect)
	if texture == null or parent == null:
		return null

	var fx: = CombatFX.new()
	fx.texture = texture
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.size = Vector2(size_px, size_px)
	fx.position = centre - fx.size*0.5
	fx.pivot_offset = fx.size * 0.5
	fx.z_index = z
	parent.add_child(fx)
	fx._play(duration)
	return fx


## Spawns the effect that matches an attack.
static func spawn_for_attack(
	parent: Node, kind: int, centre: Vector2, size_px: float, z: int = 12
) -> CombatFX:
	return spawn(parent, ATTACK_EFFECTS.get(kind, HIT_SMALL), centre, size_px, z)


static func _get_texture(effect: String) -> Texture2D:
	if _textures.has(effect):
		return _textures[effect]

	var path: = "%s%s.png" % [FX_DIR, effect]
	var texture: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_textures[effect] = texture
	return texture


func _play(duration: float) -> void:
	scale = Vector2(0.55, 0.55)
	modulate.a = 0.0

	var tween: = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, duration*0.18)
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), duration*0.45)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration*0.55)
	tween.parallel().tween_property(self, "scale", Vector2(1.35, 1.35), duration*0.55)
	tween.tween_callback(queue_free)
