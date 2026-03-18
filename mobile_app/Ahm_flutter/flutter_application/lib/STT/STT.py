import json
import os
import shutil
import subprocess
from pathlib import Path

import whisper

# =========================
# 0) CONFIG
# =========================
BASE_DIR = Path(__file__).resolve().parent
INPUT_AUDIO = BASE_DIR / "sample.m4a"

# ถ้ายังเพี้ยน: เปลี่ยนเป็น "medium" หรือ "large"
MODEL_SIZE = "large"  # small / medium / large

FFMPEG_BIN = r"C:\Users\Yossawat\Documents\ffmpeg\ffmpeg\bin"  # โฟลเดอร์ที่มี ffmpeg.exe

PROMPT_SHORT = "Medical wound check."

# =========================
# 1) Ensure ffmpeg visible
# =========================
ffmpeg_path = shutil.which("ffmpeg")
print("[debug] which ffmpeg (before):", ffmpeg_path)

if not ffmpeg_path:
    if not Path(FFMPEG_BIN).exists():
        raise FileNotFoundError(f"FFmpeg bin directory not found: {FFMPEG_BIN}")
    os.environ["PATH"] = FFMPEG_BIN + ";" + os.environ.get("PATH", "")
    ffmpeg_path = shutil.which("ffmpeg")
    print("[debug] which ffmpeg (after):", ffmpeg_path)

if not ffmpeg_path:
    raise RuntimeError("ffmpeg not found for Python subprocess. Check FFMPEG_BIN/PATH.")

# =========================
# 2) Validate input audio
# =========================
if not INPUT_AUDIO.exists():
    raise FileNotFoundError(f"Audio not found: {INPUT_AUDIO}")

print("[info] input audio:", INPUT_AUDIO.name)

# =========================
# 3) Preprocess: trim silence + normalize + wav 16k mono
# =========================
WAV_AUDIO = INPUT_AUDIO.with_name(INPUT_AUDIO.stem + "_prep16k.wav")

# silenceremove ตัดช่วงเงียบหัวท้าย + loudnorm เพิ่มความดังให้คงที่
af = "silenceremove=start_periods=1:start_duration=0.25:start_threshold=-40dB:stop_periods=1:stop_duration=0.25:stop_threshold=-40dB,loudnorm"

cmd = [
    "ffmpeg", "-y",
    "-i", str(INPUT_AUDIO),
    "-ac", "1",
    "-ar", "16000",
    "-af", af,
    str(WAV_AUDIO)
]
print("[info] preprocessing ->", WAV_AUDIO.name)
subprocess.run(cmd, check=True, capture_output=True)

# =========================
# 4) Load model
# =========================
print("[info] loading Whisper model:", MODEL_SIZE)
model = whisper.load_model(MODEL_SIZE)

# shared knobs to reduce guessing
common_kwargs = dict(
    initial_prompt=PROMPT_SHORT,
    condition_on_previous_text=False,
    temperature=0.0,
    no_speech_threshold=0.7,
    logprob_threshold=-0.8,
    compression_ratio_threshold=2.4,
    fp16=False,
)

# =========================
# 5A) Burmese Transcribe
# =========================
print("\n[run] Burmese TRANSCRIBE ...")
res_my = model.transcribe(
    str(WAV_AUDIO),
    task="transcribe",
    language="my",   # บังคับพม่า
    **common_kwargs
)

text_my = (res_my.get("text") or "").strip()
print("Detected language:", res_my.get("language"))
print("Transcript (MY):")
print(text_my)

# Save
out_my_txt = WAV_AUDIO.with_name(WAV_AUDIO.stem + "_my.txt")
out_my_json = WAV_AUDIO.with_name(WAV_AUDIO.stem + "_my.json")
out_my_txt.write_text(text_my, encoding="utf-8")
out_my_json.write_text(json.dumps(res_my, ensure_ascii=False, indent=2), encoding="utf-8")
print("[saved]", out_my_txt.name, "|", out_my_json.name)

# =========================
# 5B) English Translate
# =========================
print("\n[run] TRANSLATE to ENGLISH ...")
res_en = model.transcribe(
    str(WAV_AUDIO),
    task="translate",  # 👈 แปลเป็นอังกฤษ
    language="my",     # บอกว่าอินพุตเป็นพม่า
    **common_kwargs
)

text_en = (res_en.get("text") or "").strip()
print("Detected language:", res_en.get("language"))
print("Translation (EN):")
print(text_en)

# Save
out_en_txt = WAV_AUDIO.with_name(WAV_AUDIO.stem + "_en.txt")
out_en_json = WAV_AUDIO.with_name(WAV_AUDIO.stem + "_en.json")
out_en_txt.write_text(text_en, encoding="utf-8")
out_en_json.write_text(json.dumps(res_en, ensure_ascii=False, indent=2), encoding="utf-8")
print("[saved]", out_en_txt.name, "|", out_en_json.name)

print("\n[done] Completed both transcribe(my) and translate(en).")

