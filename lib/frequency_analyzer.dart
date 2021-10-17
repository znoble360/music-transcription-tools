// @dart=2.9

import 'dart:io';
import 'dart:math';
import 'package:musictranscriptiontools/wav_parser.dart';
import 'package:fft/fft.dart';

void main (List<String> args) {
  File fp = File(args[0]);

  Frequencies freq = Frequencies(fp);
  //freq.printNotes();

}

class Frequencies {
  List<double> notes = List.filled(88, -1);
  List<int> waveform;
  List<double> pianoNotes;

  Frequencies(File fp){
    waveform = Wav(fp).waveform[0];
    //var temp = Wav(fp);
    //temp.printHeader();
    //print("length of waveform: " + waveform.length.toString());

    //var windowed = Window(new HammingWindowType).apply(waveform);
    //var fft = new FFT().Transform(windowed);

    
    var fft = new FFT().Transform(waveform.sublist(0, 4096));


    num max = 0;
    List res = [];
    for (int i = 0; i < 4096; i++) {
      num mag = sqrt(fft[i].real*fft[i].real + fft[i].imaginary*fft[i].imaginary);
      if (mag > max) {
        max = mag;
      }

      res.add(mag);
    }

    for (int i = 0; i < 4096; i++) {
      print(res[i]/max);
    }

    //for (int i = 0; i < 2048; i++) {
    //  print(i.toString() + ":\t" + fft[i].real.toString());
    //  if (fft[i].real.abs() < 1000) {
    //    print(i.toString() + ":\t" + fft[i].real.toString());
    //  }
    //}
    //print(fft.length);

    //print(fft.toString());

  }
}