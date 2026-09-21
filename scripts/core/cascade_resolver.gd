# cascade_resolver.gd — Orchestrates the remove → fall → refill → re-match loop.
# Tracks cascade depth for combo scoring.
extends Node

## Reference to grid controller
var grid_controller = null

## Current cascade depth (resets each turn)
var cascade_depth: int = 0

## Maximum cascade iterations to prevent infinite loops (safety net)
const MAX_CASCADE_STEPS := 100


func _ready() -> void:
	pass  # Phase 4: wire up


## Start cascade resolution. Called after a match is found.
func resolve_cascade() -> void:
	cascade_depth = 0
	# Phase 4: implement full loop
	# while matches exist:
	#   cascade_depth += 1
	#   remove matched pieces → emit pieces_removed
	#   apply gravity → emit pieces_fallen
	#   spawn new pieces → emit pieces_spawned
	#   check for new matches
	#   emit cascade_step(cascade_depth)
	#   if cascade_depth >= MAX_CASCADE_STEPS: break (safety)
	# emit cascade_complete
	EventBus.cascade_complete.emit()
