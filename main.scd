//MIDI Functionality//
MIDIClient.init;
MIDIIn.connectAll;

//Array for all possible notes on keyboard
~notes = Array.newClear(128);

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;

	//Array for multiple notes
	~notes[nn] = Synth.new(
	"Pad",
	[
		"freq", nn.midicps,
		"mul", vel.linexp(1,127,0.05,1),
		"gate", 1,
	]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	[vel, nn].postln;

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
	var fundSignal, overSignal, overSignal2, overSignal3, underSignal, underSignal2, underSignal3, outSignal, combinedSignal, filterEnv, volumeEnv, filtered, env, finalOut;
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

