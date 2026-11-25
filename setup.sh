#!/usr/bin/env bash
# One-shot setup for a fresh cloud session. Run from the repo root: bash setup.sh
set -e
cd "$(dirname "$0")"
(cd remotion && npm install --no-audit --no-fund)
pip install -q kokoro-onnx soundfile scipy
mkdir -p voice/models
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  [ -s voice/models/$f ] || curl -sSL -o voice/models/$f https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/$f
done
# voice/*.py expect the models here
mkdir -p /home/claude/tts
ln -sf "$PWD/voice/models/kokoro-v1.0.onnx" /home/claude/tts/kokoro.onnx
ln -sf "$PWD/voice/models/voices-v1.0.bin" /home/claude/tts/voices.bin
echo "setup done"
