/*
Three-Preset playable Synthesizer. Requires MIDI-input device.
Authors: Linus Karlsson, Ruben Bromée, Max Benecke
Version: 1.0
Date: 2020-10-08
*/

(
//MIDI Functionality//
MIDIClient.init;
MIDIIn.connectAll;

//Array for all possible notes on keyboard
~notes = Array.newClear(128);


MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;

	//Array for multiple notes
	~notes[nn] = Synth.new(
		"Pluck", //CHANGE THIS LINE TO THE TITLE OF THE INSTRUMENT YOU WISH TO USE "Pluck", "Organ" or "Pad"
	[
		"freq", nn.midicps,
		"mul", vel.linexp(1,127,0.05,1),
		"gate", 1,
	]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;

	//Remove synth when not playing a note
	~notes[nn].set("gate", 0);
	~notes[nn] = nil;
});
)

//SYNTH DEFINITIONS//

//*Saw Pad*//
(
SynthDef.new("Pad", {
	arg freq = 110, mul = 0.5, gate = 0;
	var fundSignal, overSignal, overSignal2, overSignal3, underSignal, underSignal2, underSignal3, outSignal, combinedSignal, filterEnv, volumeEnv,
	filtered, env, finalOut;
	fundSignal = Saw.ar(freq, mul);

	//Unison
	overSignal = Saw.ar(freq*1.013, mul*0.3);
	overSignal2 = Saw.ar(freq*1.005, mul*0.3);
	overSignal3 = Saw.ar(freq*1.001, mul*0.3);
	underSignal = Saw.ar(freq*0.999, mul*0.3);
	underSignal2 = Saw.ar(freq*0.995, mul*0.3);
	underSignal3 = Saw.ar(freq*0.987, mul*0.3);

	//Panning Unison
	fundSignal = Pan2.ar(fundSignal, 0);
	overSignal = Pan2.ar(overSignal, 0.7);
	overSignal2 = Pan2.ar(overSignal2, 0.7);
	overSignal3 = Pan2.ar(overSignal3, 0);
	underSignal = Pan2.ar(underSignal, 0.75);
	underSignal2 = Pan2.ar(underSignal2, -0.75);
	underSignal3 = Pan2.ar(underSignal3, 0);

	//Combine signals
	combinedSignal = fundSignal + overSignal + overSignal2 + overSignal3 + underSignal +
	underSignal2 + underSignal3;

	//Filter envelope
	filterEnv = Env([200, 1000], 3,'lin');
	filtered = LPF.ar(combinedSignal, EnvGen.kr(filterEnv));

	//Volume envelope
	volumeEnv = EnvGen.kr(Env([0, 1], 0.5, 'lin'));
	filtered = filtered * volumeEnv;

	//Volume Gate envelope
	env = EnvGen.kr(Env.adsr, gate, doneAction:2);

	//Output
	finalOut = filtered * env;
	Out.ar(0, finalOut);
}).add;
)

//*Sub Bass*//
(
SynthDef.new("Sub", {
	arg freq, mul, gate = 0;
	var signal, env;

	env = EnvGen.kr(Env.adsr(0.01, 0, 1, 0.01, 1), gate, doneAction:2);
	signal = SinOsc.ar(freq, 0, mul) * env;

	Out.ar(0, signal);
	Out.ar(1, signal);
}).add;
)

//*Organ*//
(
SynthDef.new(
	"Organ", {
		arg freq = 220, phase = 0, mult = 0.3, add = 0, gate = 0;
		var mod, osc, env, osc_left, osc_right, osc_l_1, osc_l_2, osc_l_3, osc_h_1, osc_h_2, osc_h_3, osc_l_4, osc_l_5, osc_l_6, envGate;
		mod = SinOsc.kr(5, 1.5pi, 0.05, 0.25); // Amplitude oscillation
		env = Env.new([0, 1, 1, 1], [0.5, 0.5, 5], [-5, 0, 5]); // Envelope
		osc = SinOsc.ar(freq, 0, mod); // Fundamental frequency

		osc_l_1 = Formant.ar(freq,0.5*freq, 1*freq, mod*0.5);
		osc_l_2 = Formant.ar(freq,0.25*freq, 0.5*freq, mod*0.25);
		osc_l_3 = Formant.ar(freq,0.125*freq, 0.25*freq, mod*0.125);
		osc_l_4 = LFTri.ar(0.125*freq, 0, mod*0.05);
		osc_l_5 = LFTri.ar(0.25*freq, 0, mod*0.125);
		osc_l_6 = LFTri.ar(0.5*freq, 0, mod*0.25);
		osc_h_1 = SinOsc.ar(2*freq, 0, mod*0.5);
		osc_h_2 = SinOsc.ar(4*freq, 0, mod*0.25);
		osc_h_3 = SinOsc.ar(8*freq, 0, mod*0.125);

		osc = osc_l_1 + osc_l_2 + osc_l_3 + osc_l_4 + osc_l_5 + osc_l_6 + osc_h_1 + osc_h_2 + osc_h_3;

		// Effects
		osc = FreeVerb.ar(osc, 0.33, 1, 0.2, 1); // Reverb
		// Flanger
		osc = FreqShift.ar(osc, SinOsc.kr(5, 0, Rand(1,2)*5, 0), 0, 1, 0);
		osc = FreqShift.ar(osc, SinOsc.kr(1, 0, Rand(1,2), 0), 0, 1, 0);
		osc = BPeakEQ.ar(osc, 1200, 1, -10, 1, 0); // EQ
		osc = LPF.ar(osc, 5000, 1, 0); // Low pass filter
		osc = osc * EnvGen.kr(env, Done.freeSelf);
		osc_left = Pan2.ar(osc, -0.5, 0.4);
		osc_right = Pan2.ar(osc, 0.5, 0.4);
		osc = [osc_left, osc_right];

		envGate = EnvGen.kr(Env.adsr(0.01, 0, 1, 0.01, 1), gate, doneAction:2);
		osc = osc * envGate * 0.5;

		// Sending oscillator to both audio channels
		Out.ar(0,osc);
	}
).add;
)

//Pluck//
(
SynthDef.new("Pluck", {
	arg freq = 440, mul = 0.8, gate = 0;
	var env, envGate, mainfreq, overfreq1, overfreq2, octaveUp, octaveDown, underfreq1, underfreq2, combined;

	env = Line.kr(1, 0, 0.4);
	envGate = EnvGen.kr(Env.adsr(0, 0, 1, 1), gate, doneAction:2);

	//signals
	mainfreq = LFTri.ar(freq, 0, 0.2);
	octaveUp = LFTri.ar(freq*2, 0, 0.2);
	octaveDown = LFTri.ar(freq/2, 0, 0.2);
	overfreq1= LFSaw.ar(freq*1.005, 0 , 0.2);
	overfreq2= LFSaw.ar(freq*1.013, 0 , 0.2);
	underfreq1= LFSaw.ar(freq*0.995, 0 , 0.2);
	underfreq2= LFSaw.ar(freq*0.987, 0 , 0.2);

	combined = mainfreq + octaveUp + octaveDown + overfreq1 + overfreq2 + underfreq1 + underfreq2;

	combined = FreeVerb.ar(
		Pan2.ar(
			Decay.ar(
				Compander.ar(combined, combined, 0.5, 3, 1.8, 0.002,0.1, 1), 0.1, 0.05)));
	combined = combined*env*envGate;
	Out.ar(0,combined*mul);
}
).add;
)