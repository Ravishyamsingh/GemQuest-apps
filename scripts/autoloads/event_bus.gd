# event_bus.gd — Global signal bus for decoupled cross-system communication.
# All project-wide signals are defined here. Systems emit and connect to
# these signals without direct references to each other.
extends Node

## ----- Input / Swap -----
signal piece_selected(position: Vector2i)
signal piece_deselected()
signal swap_requested(from_pos: Vector2i, to_pos: Vector2i)
signal swap_completed(from_pos: Vector2i, to_pos: Vector2i)
signal swap_rejected(from_pos: Vector2i, to_pos: Vector2i)

## ----- Match / Cascade -----
signal match_found(matches: Array)
signal pieces_removed(positions: Array)
signal pieces_fallen(movements: Array)
signal pieces_spawned(positions: Array)
signal cascade_step(depth: int)
signal cascade_complete()
signal board_shuffled()
signal board_ready()

## ----- Score / Moves / Objectives -----
signal score_changed(new_score: int, delta: int)
signal moves_changed(remaining: int)
signal moves_exhausted()
signal objective_progress(current: int, target: int)
signal objective_complete()

## ----- Level Flow -----
signal level_started(level_id: int)
signal level_won()
signal level_lost()
signal level_restarted()

## ----- Navigation / UI -----
signal screen_change_requested(screen_name: String)
signal game_paused()
signal game_resumed()
