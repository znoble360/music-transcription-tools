import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:just_audio/just_audio.dart';

// Try to load audio from a source and catch any errors.
void selectFileForPlayer(AudioPlayer player, Directory appDocDir,
    StreamController<String> waveformFileController) async {
  try {
    // Call to open file manager on android and iOS. Choose only one file for now.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result == null) {
      // User did not select a file, don't do anything.
      return;
    }

    PlatformFile file = result.files.first;

    String md5Hash = _generateMD5Hash(file);
    final Directory newDirectory = Directory('${appDocDir.path}/$md5Hash');
    if (await newDirectory.exists()) {
      // Directory already exists, meaning that we already dealt with this song before.
      // TODO: Check that the files we expect to have exist.
      String audioMP3Path = '${newDirectory.path}/audio.mp3';

      print("We've already seen this file, look at cached files");

      // Set the audio source given file input path
      await player.setAudioSource(AudioSource.uri(Uri.file(audioMP3Path)),
          initialPosition: Duration.zero, preload: true);

      return;
    }

    // Create directory since it doesn't exist yet.
    final Directory finalDirectory = await newDirectory.create(recursive: true);
    final String dirPath = finalDirectory.path;

    String audioMP3Path = '$dirPath/audio.mp3';
    String audioWAVpath = '$dirPath/songWAV.wav'; // path to song's wav
    String bookmarksPath = '$dirPath/bookmarks.json'; // path to bookmarks file
    String waveformBinPath = '$dirPath/waveform.bin';
    String infoJSONPath = '$dirPath/info.json';

    // Run FFmpeg on this single file and store it in app data folder
    String convertToMp3Command = '-i ${file.path} $audioMP3Path';
    FFmpegKit.executeAsync(convertToMp3Command, (session) async {
      await session.getReturnCode();

      // Set the audio source given file input path
      await player.setAudioSource(AudioSource.uri(Uri.file(audioMP3Path)),
          initialPosition: Duration.zero, preload: true);
    });

    // Generate waveform binary data.
    String generateWaveformBinDataCmd =
        '-i ${file.path} -v quiet -ac 1 -filter:a aresample=200 -map 0:a -c:a pcm_s16le -f data $waveformBinPath';

    FFmpegKit.executeAsync(generateWaveformBinDataCmd, (session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        waveformFileController.add(waveformBinPath);
      } else {
        print("Error");
      }
    });

    // Convert to WAV
    String convertToWavCommand = '-i ${file.path} $audioWAVpath';
    FFmpegKit.executeAsync(convertToWavCommand, (session) async {
      await session.getReturnCode();
    });

    /* Here is where we would do the processing */
    /* how to write and write/to JSON file: https://www.youtube.com/watch?v=oZNvRd96iIs&ab_channel=TheFlutterFactory */
    // Store the song name in an info.json file with the path above.
    String ext = file.name.substring(file.name.lastIndexOf('.'));
    String songName = file.name.replaceAll(ext, "");
    Song song = Song(songName); // create new song to be serialized
    String songJSON = jsonEncode(song);
    print('making the JSON, should show file name: ');
    print(songJSON);
    File songInfo = File('$infoJSONPath');
    await songInfo.writeAsString(songJSON);
    if (await songInfo.exists()) {
      print("say that the songInfo file exists");
      String fileContent = await songInfo.readAsString();
      print("file content: " + fileContent);
    } else {
      print("error");
    }

    print("mp3 command: " + convertToMp3Command);
  } catch (e) {
    print("Error loading audio source: $e");
  }
}

String _generateMD5Hash(PlatformFile file) {
  if (file.bytes == null) {
    return "";
  }

  return md5.convert(file.bytes!).toString();
}

class Song {
  String name;

  Song(this.name);

  Map toJson() => {
        'name': name,
      };
}
