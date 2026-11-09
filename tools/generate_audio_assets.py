import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "audio"
SAMPLE_RATE = 22050


def _write_wav(name, samples, loop=False):
    peak = max((abs(sample) for sample in samples), default=1.0)
    gain = min(0.94 / max(peak, 0.001), 4.0)
    pcm = bytearray()
    for sample in samples:
        value = max(-1.0, min(1.0, sample * gain))
        pcm.extend(struct.pack("<h", round(value * 32767)))
    with wave.open(str(OUTPUT / name), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(SAMPLE_RATE)
        stream.writeframes(pcm)
    return loop


def _envelope(time, duration, attack=0.01, release=0.08):
    attack_gain = min(time / attack, 1.0) if attack else 1.0
    release_gain = min((duration - time) / release, 1.0) if release else 1.0
    return max(0.0, min(attack_gain, release_gain))


def _tone(frequency, time, phase=0.0):
    return math.sin(math.tau * frequency * time + phase)


def build_music():
    duration = 8.0
    chords = (
        (146.83, 174.61, 220.0),
        (116.54, 146.83, 174.61),
        (130.81, 164.81, 196.0),
        (110.0, 130.81, 164.81),
    )
    samples = []
    for frame in range(round(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        chord_index = int(time // 2.0) % len(chords)
        chord_time = time % 2.0
        fade = min(chord_time / 0.28, (2.0 - chord_time) / 0.32, 1.0)
        chord = chords[chord_index]
        pad = sum(
            _tone(frequency, time, index * 0.3)
            + 0.25 * _tone(frequency * 2.0, time, index * 0.17)
            for index, frequency in enumerate(chord)
        ) / 5.0
        note_index = int(time / 0.5) % 4
        note_time = time % 0.5
        bell_frequency = chord[(note_index + chord_index) % 3] * 4.0
        bell = (
            _tone(bell_frequency, time, 0.2)
            + 0.3 * _tone(bell_frequency * 1.5, time, 0.1)
        ) * math.exp(-note_time * 7.0)
        samples.append(0.105 * fade * pad + 0.022 * bell)
    _write_wav("range_theme.wav", samples, loop=True)


def build_shot():
    rng = random.Random(1701)
    duration = 0.2
    samples = []
    for frame in range(round(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        envelope = math.exp(-time * 26.0)
        noise = rng.uniform(-1.0, 1.0)
        body = _tone(105.0 - 30.0 * time, time)
        samples.append(envelope * (0.32 * noise + 0.26 * body))
    _write_wav("shot.wav", samples)


def build_hit():
    duration = 0.28
    samples = []
    for frame in range(round(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        envelope = math.exp(-time * 12.0)
        samples.append(
            0.28
            * envelope
            * (_tone(1046.5, time) + 0.48 * _tone(1568.0, time, 0.15))
        )
    _write_wav("target_hit.wav", samples)


def build_enemy_destroy():
    rng = random.Random(481)
    duration = 0.5
    samples = []
    for frame in range(round(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        envelope = _envelope(time, duration, 0.004, 0.25)
        sweep = 150.0 - 90.0 * time / duration
        noise = rng.uniform(-1.0, 1.0)
        samples.append(envelope * (0.32 * _tone(sweep, time) + 0.12 * noise))
    _write_wav("enemy_destroy.wav", samples)


def build_victory():
    notes = (523.25, 659.25, 783.99, 1046.5)
    duration = 1.1
    samples = []
    for frame in range(round(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        index = min(int(time / 0.24), len(notes) - 1)
        note_time = time - index * 0.24
        envelope = math.exp(-note_time * 3.2) * _envelope(time, duration, 0.01, 0.18)
        samples.append(0.3 * envelope * _tone(notes[index], time))
    _write_wav("victory.wav", samples)


def build_defeat():
    notes = (392.0, 311.13, 261.63, 196.0)
    duration = 1.1
    samples = []
    for frame in range(round(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        index = min(int(time / 0.26), len(notes) - 1)
        note_time = time - index * 0.26
        envelope = math.exp(-note_time * 2.2) * _envelope(time, duration, 0.02, 0.24)
        samples.append(0.27 * envelope * _tone(notes[index], time))
    _write_wav("defeat.wav", samples)


def build_unlock():
    notes = (659.25, 783.99, 987.77, 1318.51)
    duration = 0.8
    samples = []
    for frame in range(round(SAMPLE_RATE * duration)):
        time = frame / SAMPLE_RATE
        index = min(int(time / 0.16), len(notes) - 1)
        note_time = time - index * 0.16
        envelope = math.exp(-note_time * 4.5) * _envelope(time, duration, 0.005, 0.17)
        samples.append(0.28 * envelope * _tone(notes[index], time))
    _write_wav("level_unlock.wav", samples)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    build_music()
    build_shot()
    build_hit()
    build_enemy_destroy()
    build_victory()
    build_defeat()
    build_unlock()
    for asset in sorted(OUTPUT.glob("*.wav")):
        print("%s: %d bytes" % (asset.name, asset.stat().st_size))
