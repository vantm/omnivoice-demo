from omnivoice import OmniVoice
import torch
import torchaudio
from datetime import datetime as dt

def read_input():
    with open("input.txt", "r") as f:
        text = f.read().strip()
        return text

model = OmniVoice.from_pretrained(
    "k2-fsa/OmniVoice",
    device_map="cuda",
    dtype=torch.float16
)

input_text = read_input()

audio = model.generate(
    text=input_text,
    ref_audio="ref.mp3",
    language="vi"
)

torchaudio.save(f"voice-{dt.now().strftime("%Y%m%d%H%M%S")}.wav", audio[0], 24000)
