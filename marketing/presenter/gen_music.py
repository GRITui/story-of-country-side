"""Generate a cheerful, cozy BGM loop for the game-manual video.

Pure NumPy synthesis — no licensed samples, no downloads. A gentle chime/
kalimba melody over soft pads and light percussion in a major pentatonic
tune. Produces marketing/presenter/bgm.wav (mono, 44.1kHz).

The 16-bar phrase is ~24s and is meant to be looped by ffmpeg
(-stream_loop -1) to span whatever the video length turns out to be.
"""
import os
import numpy as np

SR = 44100
BPM = 80
BEAT = 60.0 / BPM
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'bgm.wav')


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def env_tau(n, tau):
    return np.exp(-np.arange(n) / (tau * SR))


def bell(freq, dur, amp):
    """Warm plucked chime: fundamental + soft upper partials, natural decay."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    wav = (np.sin(2 * np.pi * freq * t)
           + 0.35 * np.sin(2 * np.pi * freq * 2.01 * t)
           + 0.12 * np.sin(2 * np.pi * freq * 3.0 * t))
    decay = np.exp(-np.arange(n) / (0.24 * SR))
    return amp * wav * decay


def pad(freq, dur, amp):
    n = int(dur * SR)
    t = np.arange(n) / SR
    wav = np.sin(2 * np.pi * freq * t) + 0.4 * np.sin(2 * np.pi * freq * 2.02 * t)
    atk = np.clip(np.arange(n) / (0.6 * SR), 0, 1)
    rel = np.linspace(1, 0, n) ** 2
    return amp * wav * atk * rel


def bass(freq, dur, amp):
    n = int(dur * SR)
    t = np.arange(n) / SR
    wav = np.sin(2 * np.pi * freq * t) * np.exp(-np.arange(n) / (0.5 * SR))
    return amp * wav


def kick():
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    f = 90 * np.exp(-t * 30) + 40
    ph = 2 * np.pi * np.cumsum(f) / SR
    return 0.5 * np.sin(ph) * np.exp(-t * 40)


def shaker(seed):
    rng = np.random.RandomState(seed)
    n = int(0.08 * SR)
    noise = rng.randn(n) * np.exp(-np.arange(n) / (0.018 * SR))
    # band-pass-ish by differencing
    return 0.18 * np.diff(np.concatenate([[0], noise]))


# --- composition -------------------------------------------------------
# 16 bars, one chord per bar. bar of 2 beats, so a strong leisurely feel.
BAR = 4  # beats per bar
CHORDS = ['C', 'Am', 'F', 'G'] * 4
NOTE = {
    'C': [48, 52, 55], 'G': [43, 47, 50], 'Am': [45, 48, 52],
    'F': [41, 45, 48],
}
# melody: (beat_index within bar, midi) across the 16 bars
MEL = [
    (0, 72), (1, 74), (2, 76), (3, 74),
    (0, 72), (1, 69), (2, 72), (3, 71),
    (0, 64), (1, 69), (2, 71), (3, 69),
    (0, 64), (1, 67), (2, 69), (3, 71),
]
# a second, softer call-and-answer line (pickups)
MEL2 = [
    (0, 60), (1, 64), (2, 67), (3, 69),
    (0, 62), (1, 64), (2, 62), (3, 60),
]

total_beats = 16 * BAR
seconds = total_beats * BEAT
N = int(seconds * SR)
mix = np.zeros(N)


def add_at(idx, sig):
    """Add a signal at a sample offset, clipping if it runs past the end."""
    start = int(idx)
    end = min(N, start + len(sig))
    if end <= start:
        return
    seg = sig[:end - start]
    mix[start:end] += seg


for bi in range(total_beats):
    bar = bi // BAR
    chord = CHORDS[bar]
    t0 = int(bi * BEAT * SR)
    dur = BAR * BEAT
    # pad chord
    for n in NOTE[chord]:
        add_at(t0, pad(midi(n), dur, 0.035))
    # bass on the low root
    root = NOTE[chord][0] - 12
    add_at(t0, bass(midi(root), BEAT, 0.10))

# melody plinks
for line, amp in ((MEL, 0.16), (MEL2, 0.07)):
    for bar in range(16):
        for (b, note) in line:
            beatglobal = bar * BAR + b
            t0 = int(beatglobal * BEAT * SR)
            add_at(t0, bell(midi(note), BEAT * 1.6, amp))

# percussion on every beat
for bi in range(total_beats):
    t0 = int(bi * BEAT * SR)
    if bi % 4 == 0:
        add_at(t0, kick())
    s = shaker(seed=bi)
    t1 = int((bi + 0.5) * BEAT * SR)
    add_at(t1, s)

# master level + gentle bus softness
mix = np.tanh(mix * 1.1)
peak = np.max(np.abs(mix))
if peak > 0.95:
    mix *= 0.95 / peak
arr = (mix * 32000).astype(np.int16)

import wave
with wave.open(OUT, 'wb') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(arr.tobytes())
print('wrote', OUT, f'{len(arr)/SR:.1f}s')