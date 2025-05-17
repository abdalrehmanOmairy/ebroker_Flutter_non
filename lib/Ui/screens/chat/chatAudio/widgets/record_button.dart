import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../utils/Extensions/extensions.dart';
import '../../../../../utils/ui_utils.dart';

import '../audio_state.dart';
import '../globals.dart';
import 'flow_shader.dart';
import 'lottie_animation.dart';

class RecordButton extends StatefulWidget {
  const RecordButton(
      {Key? key,
      required this.controller,
      required this.callback,
      required this.isSending})
      : super(key: key);

  final AnimationController controller;
  final Function(dynamic path)? callback;
  final bool isSending;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  static const double size = 43;

  final double lockerHeight = 200;
  double timerWidth = 0;

  late Animation<double> buttonScaleAnimation;
  late Animation<double> timerAnimation;
  late Animation<double> lockerAnimation;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  AudioRecorder? audioRecorder;
  String? currentFilePath;

  bool isLocked = false;
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });
    audioRecorder = AudioRecorder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        MediaQuery.of(context).size.width - 2 * ChatGlobals.defaultPadding - 4;
    timerAnimation =
        Tween<double>(begin: timerWidth + ChatGlobals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: lockerHeight + ChatGlobals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    audioRecorder?.dispose();
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        (timer?.isActive ?? false) ? lockSlider() : const SizedBox.shrink(),
        (timer?.isActive ?? false) ? cancelSlider() : const SizedBox.shrink(),
        audioButton(),
        if (isLocked) timerLocked(),
      ],
    );
  }

  Widget lockSlider() {
    return Positioned(
      bottom: -lockerAnimation.value,
      child: Container(
        height: lockerHeight,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
          color: context.color.secondaryColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.lock, size: 20),
            const SizedBox(height: 8),
            FlowShader(
              direction: Axis.vertical,
              child: Column(
                children: const [
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cancelSlider() {
    return Positioned(
      right: -timerAnimation.value,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
          color: context.color.primaryColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              showLottie ? const LottieAnimation() : Text(recordDuration),
              FlowShader(
                duration: const Duration(seconds: 3),
                flowColors: [
                  context.color.teritoryColor,
                  const Color(0xFF9E9E9E)
                ],
                child: Row(
                  children: [
                    const Icon(Icons.keyboard_arrow_left),
                    Text(UiUtils.getTranslatedLabel(context, "slidetocancel")),
                    const SizedBox(
                      width: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: size),
            ],
          ),
        ),
      ),
    );
  }

  Widget timerLocked() {
    return Positioned(
      right: 0,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
          color: context.color.secondaryColor,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 25),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await saveFile();
              setState(() {
                isLocked = false;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(recordDuration),
                const SizedBox(
                  width: 5,
                ),
                FlowShader(
                  duration: const Duration(seconds: 3),
                  flowColors: [context.color.teritoryColor, Colors.grey],
                  child: Text(
                      UiUtils.getTranslatedLabel(context, "taploacktostop")),
                ),
                const Center(
                  child: Icon(
                    Icons.lock,
                    size: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      child: Transform.scale(
        scale: buttonScaleAnimation.value,
        child: Container(
          height: size,
          width: size,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.color.teritoryColor,
          ),
          child: widget.isSending
              ? const CircularProgressIndicator()
              : const Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
        ),
      ),
      onLongPressDown: (_) {
        if (widget.isSending) return;
        debugPrint("onLongPressDown");
        widget.controller.forward();
      },
      onLongPressEnd: (details) async {
        if (widget.isSending) return;
        debugPrint("onLongPressEnd");

        if (isCancelled(details.localPosition, context)) {
          if (await Vibration.hasVibrator() ?? false)
            Vibration.vibrate(duration: 100);

          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = "00:00";

          setState(() {
            showLottie = true;
          });

          Timer(const Duration(milliseconds: 1440), () async {
            widget.controller.reverse();
            debugPrint("Cancelled recording");
            await audioRecorder?.cancel();
            if (currentFilePath != null &&
                File(currentFilePath!).existsSync()) {
              File(currentFilePath!).deleteSync();
              debugPrint("Deleted $currentFilePath");
            }
            showLottie = false;
          });
        } else if (checkIsLocked(details.localPosition)) {
          widget.controller.reverse();

          if (await Vibration.hasVibrator() ?? false)
            Vibration.vibrate(duration: 100);
          debugPrint("Locked recording");
          debugPrint(details.localPosition.dy.toString());
          setState(() {
            isLocked = true;
          });
        } else {
          widget.controller.reverse();
          await saveFile();
        }
      },
      onLongPressCancel: () {
        if (widget.isSending) return;
        debugPrint("onLongPressCancel");
        widget.controller.reverse();
      },
      onLongPress: () async {
        if (widget.isSending) return;
        debugPrint("onLongPress");
        if (await Vibration.hasVibrator() ?? false)
          Vibration.vibrate(duration: 50);
        if (await _checkAndRequestPermission()) {
          audioRecorder ??= AudioRecorder();
          currentFilePath = await _generateFilePath();
          await audioRecorder!.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: currentFilePath ?? "",
          );
          startTime = DateTime.now();
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final minDur = DateTime.now().difference(startTime!).inMinutes;
            final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
            String min = minDur < 10 ? "0$minDur" : minDur.toString();
            String sec = secDur < 10 ? "0$secDur" : secDur.toString();
            setState(() {
              recordDuration = "$min:$sec";
            });
          });
        }
      },
    );
  }

  Future<void> saveFile() async {
    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 50);
    timer?.cancel();
    timer = null;
    startTime = null;
    recordDuration = "00:00";

    String? filePath = await audioRecorder?.stop();
    if (filePath != null) {
      AudioState.files.add(filePath);
      if (ChatGlobals.audioListKey.currentState != null) {
        ChatGlobals.audioListKey.currentState!
            .insertItem(AudioState.files.length - 1);
      }
      debugPrint(filePath);
      if (widget.callback != null) {
        widget.callback!(filePath);
      }
    }
  }

  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }

  Future<bool> _checkAndRequestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<String> _generateFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return "${dir.path}/audio_${timestamp}_$random.m4a";
  }
}
