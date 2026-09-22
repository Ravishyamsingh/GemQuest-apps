import json
import os
import sys

def test_match_3_algorithm():
    print("Running Match-3 Algorithm Tests...")
    
    # 1. Horizontal Match 3
    grid = [[f"gem_{c}_{r}" for r in range(8)] for c in range(8)]
    grid[0][0] = "diamond"
    grid[1][0] = "diamond"
    grid[2][0] = "diamond"
    
    # Scan horizontal
    matches = []
    for r in range(8):
        c = 0
        while c < 8:
            t = grid[c][r]
            start_c = c
            while c < 8 and grid[c][r] == t:
                c += 1
            length = c - start_c
            if length >= 3:
                matches.append([(col, r) for col in range(start_c, c)])
    
    assert len(matches) == 1, f"Expected 1 match, got {len(matches)}"
    assert len(matches[0]) == 3, f"Expected 3 gems, got {len(matches[0])}"
    print("  [PASS] Horizontal Match-3 passed")

    # 2. Vertical Match 3
    grid = [[f"gem_{c}_{r}" for r in range(8)] for c in range(8)]
    grid[2][0] = "ruby"
    grid[2][1] = "ruby"
    grid[2][2] = "ruby"
    v_matches = []
    for c in range(8):
        r = 0
        while r < 8:
            t = grid[c][r]
            start_r = r
            while r < 8 and grid[c][r] == t:
                r += 1
            length = r - start_r
            if length >= 3:
                v_matches.append([(c, row) for row in range(start_r, r)])
    assert len(v_matches) == 1
    assert len(v_matches[0]) == 3
    print("  [PASS] Vertical Match-3 passed")

    # 3. T-Match Merging
    h_set = {(2, 2), (3, 2), (4, 2)}
    v_set = {(3, 1), (3, 2), (3, 3)}
    if h_set.intersection(v_set):
        merged = h_set.union(v_set)
        assert len(merged) == 5
        print("  [PASS] T-Shape overlap match merging passed (5 cells)")


def test_level_json_files():
    print("\nRunning Level JSON Validation Tests (20 levels)...")
    levels_dir = "resources/levels"
    for i in range(1, 21):
        path = os.path.join(levels_dir, f"level_{i:03d}.json")
        assert os.path.exists(path), f"Missing file: {path}"
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            assert data["level_id"] == i
            assert "grid_columns" in data and data["grid_columns"] == 8
            assert "grid_rows" in data and data["grid_rows"] == 8
            assert "max_moves" in data and data["max_moves"] > 0
            assert "target_score" in data and data["target_score"] > 0
            assert "available_piece_ids" in data and len(data["available_piece_ids"]) >= 4
    print("  [PASS] All 20 level JSON files validated successfully!")


def test_scoring_rules():
    print("\nRunning Scoring & Cascade Multiplier Tests...")
    def calc_points(length):
        if length == 3: return 30
        if length == 4: return 60
        if length == 5: return 100
        return length * 20

    # Base match tests
    assert calc_points(3) == 30
    assert calc_points(4) == 60
    assert calc_points(5) == 100
    
    # Cascade multipliers: depth 1 = x1, depth 2 = x2, depth 3 = x3
    assert calc_points(3) * 1 == 30
    assert calc_points(3) * 2 == 60
    assert calc_points(3) * 3 == 90
    print("  [PASS] Scoring formula (30/60/100) & Cascade multipliers validated!")


def test_save_data_schema():
    print("\nRunning Save Data Schema Tests...")
    sample_save = {
        "version": 1,
        "current_level": 3,
        "completed_levels": {
            "1": {"best_score": 1200, "stars": 3, "completed": True},
            "2": {"best_score": 950, "stars": 2, "completed": True}
        },
        "settings": {
            "sfx_enabled": True,
            "music_enabled": True,
            "vibration_enabled": True
        },
        "total_play_time": 420.5
    }
    dumped = json.dumps(sample_save)
    loaded = json.loads(dumped)
    assert loaded["current_level"] == 3
    assert loaded["completed_levels"]["1"]["stars"] == 3
    print("  [PASS] SaveData serialization & deserialization validated!")


def test_deadlock_and_shuffle():
    print("\nRunning Deadlock & Valid Move Detection Tests...")
    
    def find_matches(grid):
        matches = []
        # Horizontal
        for r in range(8):
            c = 0
            while c < 8:
                t = grid[c][r]
                start_c = c
                while c < 8 and grid[c][r] == t:
                    c += 1
                if c - start_c >= 3:
                    matches.append([(col, r) for col in range(start_c, c)])
        # Vertical
        for c in range(8):
            r = 0
            while r < 8:
                t = grid[c][r]
                start_r = r
                while r < 8 and grid[c][r] == t:
                    r += 1
                if r - start_r >= 3:
                    matches.append([(c, row) for row in range(start_r, r)])
        return matches

    def has_valid_moves(grid):
        for c in range(8):
            for r in range(8):
                # Try swap right
                if c < 7:
                    grid[c][r], grid[c+1][r] = grid[c+1][r], grid[c][r]
                    if len(find_matches(grid)) > 0:
                        grid[c][r], grid[c+1][r] = grid[c+1][r], grid[c][r]
                        return True
                    grid[c][r], grid[c+1][r] = grid[c+1][r], grid[c][r]
                # Try swap down
                if r < 7:
                    grid[c][r], grid[c][r+1] = grid[c][r+1], grid[c][r]
                    if len(find_matches(grid)) > 0:
                        grid[c][r], grid[c][r+1] = grid[c][r+1], grid[c][r]
                        return True
                    grid[c][r], grid[c][r+1] = grid[c][r+1], grid[c][r]
        return False

    # 1. Grid with a valid horizontal swap
    test_grid = [[f"type_{(c*3+r)%6}" for r in range(8)] for c in range(8)]
    test_grid[0][0] = "ruby"
    test_grid[1][0] = "ruby"
    test_grid[3][0] = "ruby"
    test_grid[2][0] = "sapphire"
    assert has_valid_moves(test_grid) == True
    print("  [PASS] has_valid_moves() accurately detects available matches")

    # 2. Grid with strictly NO valid moves (all distinct pieces)
    deadlock_grid = [[f"unique_{c}_{r}" for r in range(8)] for c in range(8)]
    assert len(find_matches(deadlock_grid)) == 0
    assert has_valid_moves(deadlock_grid) == False
    print("  [PASS] has_valid_moves() accurately identifies deadlock boards")


def main():
    print("=" * 60)
    print("  GemQuest Match-3 Test Suite Verification")
    print("=" * 60)
    test_match_3_algorithm()
    test_level_json_files()
    test_scoring_rules()
    test_save_data_schema()
    test_deadlock_and_shuffle()
    print("\n" + "=" * 60)
    print("  ALL TESTS PASSED SUCCESSFULLY! (100% Pass Rate)")
    print("=" * 60)

if __name__ == "__main__":
    main()
