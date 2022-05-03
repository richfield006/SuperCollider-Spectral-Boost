//SuperCollider

s.boot; //Boot the server

ServerOptions.devices; //Choose to view your I/O options

//Modify I/O to your preference and reboot the server
(
s.options.inDevice = "MacBook Pro Microphone";
s.options.outDevice = "External Headphones";
s.reboot;
)

Buffer.freeAll;

//Loading audio
~music = Buffer.read(s, "LOAD A AUDIO FILE FROM DIRECTORY"); //MONO
~noise = Buffer.read(s, "LOAD A AUDIO FILE FROM DIRECTORY"); //MONO

//Processing in MONO
(
SynthDef(\DSBMONO, {
	arg loop=1, da=1;
	var sig, sig1, sig2, chain1, chain2, size=1024;
	sig1 = SoundIn.ar(0, 1);                                                     //Mic - Noise (Mono)
	//sig1 = PlayBuf.ar(1, ~noise.bufnum, BufRateScale.ir(~noise.bufnum), loop: 1); //If a audio file is used as noise, comment (//) the above line and run this line
	sig2 = PlayBuf.ar(1, \buf.kr(0), BufRateScale.ir(\buf.kr(0)), loop: loop, doneAction: da); //Music(Mono)
	chain1 = FFT(LocalBuf(size), sig1, hop: 0.25, wintype: 1);
	chain2 = FFT(LocalBuf(size), sig2, hop: 0.25, wintype: 1);
	chain2= chain2.pvcalc2(chain1, size, {
		arg mag1, phs1, mag2, phs2;
		var energy, mag1Energy, mag2Energy, energyRatio, amplitudeRatio;
		mag1Energy = mag1**2;                                                    //Music spectrogram to Energy
		mag2Energy = mag2**2;                                                    //Noise spectrogram to Energy
		mag1 = (mag1Energy * mag1)*2/3;                                      //Multipy the amplitude ratio with Music spectogram. Since each segments overlaps more than once resulting in processed signal being 1.5x louder, multipled by 2/3 right before IFFT
		[mag1, phs1];
	}, 0, 350, 0);                                                               //Processing FFT bins from 0 to 350
	sig = IFFT(chain2, 1) * 1!2;                                                 //Duplicating to make it play on L and R
	//sig = Limiter.ar(sig, 1);                                                    //A limiter - Just to be safe
	Out.ar(0, sig);
}).add;
)

Synth(\DSBMONO, [\buf, ~music]);


//TO RECORD

(
s.recSampleFormat = "int16"; //Specifing to record the audio file in 16bit
s.recHeaderFormat = "wav"; //Specifing to record the audio file in wav format
)

(
Routine({
	s.prepareForRecord(numChannels: 1); //numChannels set to 1 to get mono
	s.sync;
	s.record(duration:64); //Specified in seconds
	x = Synth(\DSBMONO, [\buf, ~music]);
}).play;
)

s.stopRecording; //To force stop the recording

Platform.recordingsDir;//To check where the recorded file saves on the directory
