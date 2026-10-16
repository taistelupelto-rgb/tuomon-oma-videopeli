"""Kokoro multi-voice dialogue render: lines.tsv -> assets/voices/*.ogg"""
import csv, subprocess, sys, os
from pathlib import Path

VOICES = {"MOTHER": "af_sarah", "HERO": "bf_alice", "WARDEN": "bm_george", "TUHK": "am_adam"}
MODEL = "/tmp/opencode/koko/model/kokoro-v1_0.onnx"
VBYTES = "/tmp/opencode/koko/model/voices.bin"
HERE = Path(__file__).parent
OUT = HERE / "assets" / "voices"
TMP = Path("/tmp/opencode/koko/wav")
TMP.mkdir(parents=True, exist_ok=True)

from kokoro_onnx import Kokoro
import soundfile as sf

kok = Kokoro(MODEL, VBYTES)
rows = list(csv.DictReader(open(HERE / "assets" / "voices" / "lines.tsv"), delimiter="\t"))
print(f"rows={len(rows)}", flush=True)
ok = 0
for r in rows:
    fn = r["file"].strip()
    voice = VOICES[r["speaker"].strip()]
    speed = float(r["speed"])
    text = r["text"].strip()
    wav = TMP / (fn.replace(".ogg", ".wav"))
    ogg = OUT / fn
    if ogg.exists():
        ok += 1
        continue
    samples, sr = kok.create(text, voice=voice, speed=speed, lang="en-us")
    sf.write(str(wav), samples, sr)
    # resample 24000->22050 + loudnorm + vorbis
    cmd = ["ffmpeg", "-y", "-v", "error", "-i", str(wav),
           "-af", "loudnorm=I=-16:TP=-1.5:LRA=11,aresample=22050",
           "-ar", "22050", "-c:a", "libvorbis", "-q:a", "4", str(ogg)]
    subprocess.run(cmd, check=True)
    ok += 1
    if ok % 20 == 0:
        print(f"done {ok}/{len(rows)}", flush=True)
print(f"DONE ok={ok}/{len(rows)}", flush=True)
