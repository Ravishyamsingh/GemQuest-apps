# piece_data.gd — Resource class defining a gem piece type.
# Each gem type (Diamond, Ruby, etc.) has its own PieceData resource file.
class_name PieceData
extends Resource

## Unique identifier for this piece type (e.g., "diamond", "ruby").
@export var piece_id: StringName = &""

## Human-readable display name.
@export var display_name: String = ""

## The colour associated with this piece (used for tinting and particles).
@export var colour: Color = Color.WHITE

## The texture/sprite for this piece.
@export var texture: Texture2D = null

## Sound effect played when this piece is matched.
@export var match_sfx: AudioStream = null
