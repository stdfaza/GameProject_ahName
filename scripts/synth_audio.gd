class_name SynthAudio
extends RefCounted

static func make_sfx(kind: String) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data: PackedByteArray = PackedByteArray()
	var duration: float = 0.2
	
	match kind:
		"shoot":
			duration = 0.15
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = (1.0 - t) * (1.0 - t)
				var freq: float = 300.0 * (1.0 - t * 0.8)
				var noise: float = (randf() * 2.0 - 1.0) * 0.7
				var sine: float = sin(float(i) * freq * TAU / sample_rate) * 0.3
				var s: float = (noise + sine) * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"shotgun":
			duration = 0.25
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = pow(1.0 - t, 1.5)
				var noise: float = (randf() * 2.0 - 1.0) * 0.9
				var s: float = noise * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"knife":
			duration = 0.12
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = sin(t * PI)
				var freq: float = 800.0 + (1.0 - t) * 600.0
				var noise: float = (randf() * 2.0 - 1.0) * 0.5
				var tone: float = sin(float(i) * freq * TAU / sample_rate) * 0.5
				var s: float = (tone + noise) * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"push":
			duration = 0.22
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = (1.0 - t)
				var freq: float = 180.0 * (1.0 - t * 0.5)
				var tone: float = sin(float(i) * freq * TAU / sample_rate)
				var s: float = tone * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"parry":
			duration = 0.35
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = (1.0 - t)
				var tone1: float = sin(float(i) * 880.0 * TAU / sample_rate) * 0.5
				var tone2: float = sin(float(i) * 1760.0 * TAU / sample_rate) * 0.5
				var s: float = (tone1 + tone2) * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"explode":
			duration = 0.4
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = pow(1.0 - t, 2.0)
				var noise: float = (randf() * 2.0 - 1.0)
				var s: float = noise * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"dash":
			duration = 0.15
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = (1.0 - t)
				var freq: float = 400.0 * (1.0 + t)
				var tone: float = (randf() * 0.5 + sin(float(i) * freq * TAU / sample_rate) * 0.5)
				var s: float = tone * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"heal":
			duration = 0.2
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = (1.0 - t)
				var freq: float = 440.0 + t * 440.0
				var tone: float = sin(float(i) * freq * TAU / sample_rate)
				var s: float = tone * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		"pickup":
			duration = 0.25
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				var t: float = float(i) / count
				var env: float = (1.0 - t)
				var freq: float = 523.25 + t * 523.25
				var tone: float = sin(float(i) * freq * TAU / sample_rate)
				var s: float = tone * env
				data[i] = int(clamp((s * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		_:
			duration = 0.1
			var count: int = int(sample_rate * duration)
			data.resize(count)
			for i in range(count):
				data[i] = 128

	wav.data = data
	return wav
