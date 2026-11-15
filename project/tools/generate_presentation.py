import math
import random
import struct
import wave
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PALETTE = {
    ".": (0, 0, 0, 0),
    "d": (15, 23, 39, 255),
    "i": (101, 230, 245, 255),
    "w": (229, 255, 252, 255),
    "g": (255, 189, 91, 255),
    "o": (208, 111, 51, 255),
    "p": (196, 153, 255, 255),
    "s": (65, 101, 145, 255),
    "m": (37, 52, 81, 255),
    "b": (57, 124, 158, 255),
    "r": (204, 82, 84, 255),
    "l": (248, 150, 144, 255),
    "h": (131, 51, 73, 255),
}


def icon(name, rows, folder="ui"):
    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload +
                struct.pack(">I", zlib.crc32(tag + payload)))

    size = len(rows[0]), len(rows)
    assert all(len(row) == size[0] for row in rows)
    header = struct.pack(">IIBBBBB", *size, 8, 6, 0, 0, 0)
    data = b"".join(b"\0" + bytes(c for token in row for c in PALETTE[token]) for row in rows)
    (ROOT / f"art/{folder}/{name}.png").write_bytes(
        b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) +
        chunk(b"IDAT", zlib.compress(data)) + chunk(b"IEND", b"")
    )


def icons():
    icon("crosshair", [
        "....ddd....", "....did....", "....did....",
        ".....d.....", "ddd.....ddd", "dii..w..iid",
        "ddd.....ddd", ".....d.....", "....did....",
        "....did....", "....ddd....",
    ])
    icon("coin", [
        "..dddd..", ".dgggod.", "dgwwggod", "dgwoggod",
        "dgogggod", "dggggood", ".doood..", "..ddd...",
    ])
    icon("extra_ball", [
        "..ddd...", ".diiid..", "diwwwdd.", "diwidppd",
        "diidpppd", ".dddpwpd", "...dppd.", "....dd..",
    ])
    icon("power", [
        "....dd..", "...dwd..", "..dggd..", ".dggdddd",
        "dggggod.", "dddgod..", "..dod...", "..dd....",
    ])
    icon("boost", [
        ".....ddd", "....dppd", "...dpppd", "..dpdpdd",
        ".dpddd..", "dpd.d...", "dddpd...", ".ddd....",
    ])


def core_sprites():
    icon("ball", [
        "....dddd....",
        "...dbbbbd...",
        "..dbiwwbbd..",
        ".dbiiwibbbd.",
        "dbiibbibbbbd",
        "dbiibbibbbbd",
        "dbbibibbbbbd",
        "dbbbbbbbbbbd",
        ".dbbbbbbbbd.",
        "..dbbbbbbd..",
        "...dddddd...",
        "............",
    ])
    icon("heart", [
        "............",
        "..ddd.ddd...",
        ".dllldrrrd..",
        "dlrrrrrrrrd.",
        "dlrrrrrrrhd.",
        "drrrrrrrhhd.",
        ".drrrrrhhd..",
        "..drrrhhd...",
        "...drrhd....",
        "....dhd.....",
        ".....d......",
        "............",
    ])


def launcher():
    silhouette = [
        "....................",
        "....................",
        ".........ddd........",
        "......ddddwdddddd...",
        "...dddsiisiissgmd...",
        "...dmmiidsssssgmd...",
        "....ddddgdddddddd...",
        ".......dgod.........",
        ".......dod..........",
        "........d...........",
        "....................",
        "....................",
    ]
    frame_states = {
        "idle": [(0, False)] * 4,
        "fire": [(-1, True), (-1, True), (-1, False), (0, False)],
        "recover": [(0, False)] * 4,
    }
    for action, states in frame_states.items():
        for frame, (shift, charged) in enumerate(states, 1):
            rows = [list(row) for row in silhouette]
            for y in range(2, 7):
                if shift:
                    rows[y] = rows[y][1:] + ["."]
                if charged and y in (4, 5):
                    rows[y][13:16] = list("iww")
            icon(f"{action}_{frame:02d}", ["".join(row) for row in rows], "launcher")


RATE = 22050
EFFECT_NOTES = {
    "shot": [(400, 135, .085)], "bounce": [(640, 420, .09)],
    "split": [(640, 900, .11), (980, 1400, .10)], "hit": [(280, 130, .09)],
    "death": [(280, 80, .18)], "coin": [(1000, 1400, .075)],
    "return": [(560, 740, .10), (860, 1100, .10)], "hurt": [(220, 76, .24)],
    "buy": [(523, 660, .09), (784, 920, .105)],
    "clear": [(392, 410, .13), (523, 560, .13), (659, 730, .19)],
    "over": [(392, 350, .2), (294, 240, .2), (196, 140, .33)],
    "knight_swing": [(830, 320, .072), (188, 72, .14)],
}


def write_wav(name, signal):
    samples = [int(max(-1, min(1, value)) * 32767) for value in signal]
    with wave.open(str(ROOT / f"art/audio/{name}.wav"), "wb") as audio:
        audio.setparams((1, 2, RATE, len(samples), "NONE", "not compressed"))
        audio.writeframes(struct.pack(f"<{len(samples)}h", *samples))


def sound_effects():
    for name, notes in EFFECT_NOTES.items():
        signal = []
        for start, end, duration in notes:
            phase = 0.0
            for i in range(int(RATE * duration)):
                progress = i / (RATE * duration)
                phase += math.tau * (start + (end - start) * progress) / RATE
                envelope = min(1, i / 100) * (1 - progress) ** 2
                harmonics = math.sin(phase) + .24 * math.sin(2 * phase) + .10 * math.sin(3 * phase)
                signal.append(.2594 * envelope * harmonics)
        write_wav(name, signal)


def music():
    beat = .52
    chords = [(45, 57, 60, 64), (41, 53, 57, 60), (48, 55, 60, 64), (43, 55, 59, 62)]
    phrases = [
        [76, None, 72, 69, 72, None, 74, 76],
        [77, None, 76, 72, 69, None, 72, None],
        [76, None, 79, 76, 74, None, 72, 74],
        [71, None, 74, 76, 74, None, 71, None],
        [76, 79, 81, None, 79, 76, 74, 72],
        [77, None, 81, 79, 76, None, 72, 69],
        [76, 79, 84, None, 83, 79, 76, 74],
        [74, None, 71, 74, 76, 74, 71, None],
    ]
    signal = [0.0] * round(32 * beat * RATE)
    rand = random.Random(820)

    def add(start, length, voice, note, level):
        freq = 440 * 2 ** ((note - 69) / 12)
        offset = round(start * RATE)
        for i in range(round(length * RATE)):
            time = i / RATE
            phase = time * freq % 1
            if voice == "bass":
                value = 4 * abs(phase - .5) - 1
            elif voice == "lead":
                value = (.7 if phase < .31 else -.36) + .26 * math.sin(math.tau * phase)
            elif voice == "kick":
                value = math.sin(math.tau * (53 * time + 3.6 * (1 - math.exp(-30 * time))))
            elif voice == "hat":
                value = rand.uniform(-1, 1) * math.exp(-52 * time)
            else:
                value = math.sin(math.tau * phase) + .25 * math.sin(2 * math.tau * phase)
            edge = min(1, time / .009, (length - time) / .027)
            signal[(offset + i) % len(signal)] += value * level * edge * (1 - .65 * time / length)

    for bar in range(8):
        base, *arp = chords[bar % 4]
        start = bar * 4 * beat
        for step, note in enumerate(phrases[bar]):
            at = start + step * beat / 2
            add(at, .15, "pluck", arp[(step + bar) % 3] + 12, .07)
            if note is not None:
                add(at, .27 if step in (0, 4) else .17, "lead", note, .125)
            if step % 2 == 0:
                add(at, .29, "bass", base + (12 if step == 6 else 0), .16)
            add(at, .095, "kick" if step in (0, 4) else "hat", 45, .13 if step in (0, 4) else .12)
    write_wav("arena_loop", signal)


if __name__ == "__main__":
    icons()
    core_sprites()
    launcher()
    sound_effects()
    music()
