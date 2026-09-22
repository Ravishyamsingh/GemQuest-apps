import math
import struct
import wave
import os

SAMPLE_RATE = 44100

def create_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        
        # Clip and pack
        packed_data = bytearray()
        for s in samples:
            s_clamped = max(-1.0, min(1.0, s))
            val = int(s_clamped * 32767.0)
            packed_data.extend(struct.pack('<h', val))
            
        wav_file.writeframes(packed_data)
    print(f"Generated: {filename}")

def envelope(t, attack, decay, sustain_level, release, total_dur):
    if t < attack:
        return t / attack
    elif t < attack + decay:
        dt = t - attack
        return 1.0 - (1.0 - sustain_level) * (dt / decay)
    elif t < total_dur - release:
        return sustain_level
    else:
        dt = t - (total_dur - release)
        return max(0.0, sustain_level * (1.0 - dt / release))

# 1. Gem Select (high pleasant ping)
def gen_gem_select():
    dur = 0.12
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    freq = 880.0 # A5
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 30.0)
        # Sine + gentle harmonic
        val = (math.sin(2 * math.pi * freq * t) * 0.7 + 
               math.sin(2 * math.pi * freq * 2.0 * t) * 0.3) * env * 0.5
        samples.append(val)
    return samples

# 2. Gem Swap (smooth whoosh / swish)
def gen_gem_swap():
    dur = 0.18
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / dur))
        # frequency sweep from 350 up to 600 then down
        freq = 350.0 + 250.0 * math.sin(math.pi * (t / dur))
        val = math.sin(2 * math.pi * freq * t) * env * 0.4
        samples.append(val)
    return samples

# 3. Gem Invalid Swap (soft low double bounce)
def gen_gem_invalid():
    dur = 0.22
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Two fast decaying low pulses
        p1 = math.exp(-t * 25.0) * math.sin(2 * math.pi * 180.0 * t)
        t2 = max(0.0, t - 0.08)
        p2 = math.exp(-t2 * 25.0) * math.sin(2 * math.pi * 140.0 * t2) if t >= 0.08 else 0.0
        val = (p1 + p2) * 0.4
        samples.append(val)
    return samples

# 4. Gem Match (bright crystalline chime chord: C6, E6, G6)
def gen_gem_match():
    dur = 0.35
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    chords = [1046.50, 1318.51, 1567.98] # C6, E6, G6
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 9.0)
        val = 0.0
        for f in chords:
            val += math.sin(2 * math.pi * f * t) * 0.25
            val += math.sin(2 * math.pi * f * 2.0 * t) * 0.08
        samples.append(val * env * 0.7)
    return samples

# 5. Gem Combo Match (sparkly ascending arpeggio)
def gen_gem_combo():
    dur = 0.45
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    notes = [1046.50, 1318.51, 1567.98, 2093.00]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        note_idx = min(int(t / 0.08), len(notes) - 1)
        freq = notes[note_idx]
        local_t = t - note_idx * 0.08
        env = math.exp(-local_t * 12.0)
        val = (math.sin(2 * math.pi * freq * t) * 0.6 + 
               math.sin(2 * math.pi * freq * 2.0 * t) * 0.2) * env * 0.5
        samples.append(val)
    return samples

# 6. Button Click (clean tactile pop)
def gen_button_click():
    dur = 0.06
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 70.0)
        val = math.sin(2 * math.pi * (600.0 - 300.0 * (t/dur)) * t) * env * 0.5
        samples.append(val)
    return samples

# 7. Star Award (magical shimmer ding)
def gen_star_award():
    dur = 0.5
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    freq = 1760.0 # A6
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 6.0)
        shimmer = 1.0 + 0.1 * math.sin(2 * math.pi * 30.0 * t)
        val = (math.sin(2 * math.pi * freq * t) * 0.5 + 
               math.sin(2 * math.pi * freq * 1.5 * t) * 0.25) * shimmer * env * 0.5
        samples.append(val)
    return samples

# 8. Level Win (triumphant brass-like chord fanfare)
def gen_level_win():
    dur = 1.4
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    # Arpeggio up to chord: G4 -> C5 -> E5 -> G5 (sustained)
    seq = [
        (0.0, 0.2, 392.00),   # G4
        (0.2, 0.4, 523.25),   # C5
        (0.4, 0.6, 659.25),   # E5
        (0.6, 1.4, 783.99),   # G5
        (0.6, 1.4, 1046.50),  # C6
        (0.6, 1.4, 1318.51),  # E6
    ]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for start_t, end_t, freq in seq:
            if start_t <= t < end_t:
                local_t = t - start_t
                note_dur = end_t - start_t
                env = math.sin(math.pi * min(1.0, local_t / 0.05)) * math.exp(-local_t / (note_dur * 0.9))
                # Warm square/sine blend
                tone = math.sin(2 * math.pi * freq * t) * 0.4 + math.sin(2 * math.pi * freq * 2.0 * t) * 0.15
                val += tone * env
        samples.append(val * 0.5)
    return samples

# 9. Level Lose (gentle melancholy descending tones)
def gen_level_lose():
    dur = 1.0
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    seq = [
        (0.0, 0.3, 523.25),  # C5
        (0.3, 0.6, 466.16),  # Bb4
        (0.6, 1.0, 392.00)   # G4
    ]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for start_t, end_t, freq in seq:
            if start_t <= t < end_t:
                local_t = t - start_t
                env = math.exp(-local_t * 4.0)
                tone = math.sin(2 * math.pi * freq * t) * 0.5
                val += tone * env
        samples.append(val * 0.4)
    return samples

# 10. Background Music (calm ambient looped track ~ 8 seconds)
def gen_bgm_ambient():
    dur = 8.0
    num_samples = int(SAMPLE_RATE * dur)
    samples = []
    # Chord progression: Cmaj7 -> Am7 -> Fmaj7 -> G7 (2s each)
    chords = [
        [261.63, 329.63, 392.00, 493.88], # Cmaj7 (C4, E4, G4, B4)
        [220.00, 261.63, 329.63, 392.00], # Am7 (A3, C4, E4, G4)
        [174.61, 220.00, 261.63, 329.63], # Fmaj7 (F3, A3, C4, E4)
        [196.00, 246.94, 293.66, 349.23], # G7 (G3, B3, D4, F4)
    ]
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        chord_idx = int(t / 2.0) % 4
        chord_t = t % 2.0
        current_chord = chords[chord_idx]
        
        val = 0.0
        # Warm pad envelope
        pad_env = math.sin(math.pi * (chord_t / 2.0))
        for f in current_chord:
            # Low pad
            val += math.sin(2 * math.pi * f * t) * 0.07
            # Subtle octave harmonic
            val += math.sin(2 * math.pi * f * 2.0 * t) * 0.02
        
        # Pluck melody on top
        melody_step = int(chord_t / 0.5) # 4 notes per chord
        melody_notes = [current_chord[melody_step % len(current_chord)] * 2.0]
        pluck_t = chord_t % 0.5
        pluck_env = math.exp(-pluck_t * 8.0)
        for mf in melody_notes:
            val += math.sin(2 * math.pi * mf * t) * 0.12 * pluck_env

        samples.append(val * pad_env * 0.6)
    return samples

def main():
    base_sfx = "assets/audio/sfx"
    base_music = "assets/audio/music"
    
    create_wav(f"{base_sfx}/gem_select.wav", gen_gem_select())
    create_wav(f"{base_sfx}/gem_swap.wav", gen_gem_swap())
    create_wav(f"{base_sfx}/gem_invalid.wav", gen_gem_invalid())
    create_wav(f"{base_sfx}/gem_match.wav", gen_gem_match())
    create_wav(f"{base_sfx}/gem_combo.wav", gen_gem_combo())
    create_wav(f"{base_sfx}/button_click.wav", gen_button_click())
    create_wav(f"{base_sfx}/star_award.wav", gen_star_award())
    create_wav(f"{base_sfx}/level_win.wav", gen_level_win())
    create_wav(f"{base_sfx}/level_lose.wav", gen_level_lose())
    
    create_wav(f"{base_music}/bgm_gameplay.wav", gen_bgm_ambient())
    print("All audio files synthesized successfully!")

if __name__ == "__main__":
    main()
