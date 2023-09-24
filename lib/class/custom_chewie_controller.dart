import 'dart:async';
import 'dart:math' as math;
import 'package:chewie/src/animated_play_pause.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/cupertino/cupertino_progress_bar.dart';
import 'package:chewie/src/cupertino/widgets/cupertino_options_dialog.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class CustomCupertinoControls extends StatefulWidget {
  const CustomCupertinoControls({
    required this.backgroundColor,
    required this.iconColor,
    this.showPlayButton = true,
    Key? key,
  }) : super(key: key);

  final Color backgroundColor;
  final Color iconColor;
  final bool showPlayButton;

  @override
  State<StatefulWidget> createState() {
    return _CustomCupertinoControlsState();
  }
}

class _CustomCupertinoControlsState extends State<CustomCupertinoControls>
    with SingleTickerProviderStateMixin {
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  Timer? _hideTimer;
  final marginSize = 5.0;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;
  Duration? _subtitlesPosition;
  bool _subtitleOn = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;

  late VideoPlayerController controller;

  ChewieController get chewieController => _chewieController!;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
    Wakelock.enable();
  }

  @override
  void dispose() {
    _dispose();
    
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder!(
        context,
        chewieController.videoPlayerController.value.errorDescription!,
      )
          : const Center(
        child: Icon(
          CupertinoIcons.exclamationmark_circle,
          color: Colors.white,
          size: 42,
        ),
      );
    }

    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;

    return MouseRegion(
      onHover: (_) => _cancelAndRestartTimer(),
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              if (_displayBufferingIndicator)
                const Center(
                  child: CircularProgressIndicator(color: Colors.black54),
                )
              else
                _buildHitArea(),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Spacer(),
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(
                        0.0,
                        notifier.hideStuff ? barHeight * 0.8 : 0.0,
                      ),
                      child: _buildSubtitles(chewieController.subtitle!),
                    ),
                  _buildBottomBar(backgroundColor, iconColor, barHeight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  GestureDetector buildOptionsButton(
      Color iconColor,
      double barHeight,
      ) {
    final options = <OptionItem>[];

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions!(context));
    }

    return GestureDetector(
      onTap: () async {
        _hideTimer?.cancel();

        if (chewieController.optionsBuilder != null) {
          await chewieController.optionsBuilder!(context, options);
        } else {
          await showCupertinoModalPopup<OptionItem>(
            context: context,
            semanticsDismissible: true,
            useRootNavigator: chewieController.useRootNavigator,
            builder: (context) => CupertinoOptionsDialog(
              options: options,
              cancelButtonText:
              chewieController.optionsTranslation?.cancelButtonText,
            ),
          );
          if (_latestValue.isPlaying) {
            _startHideTimer();
          }
        }
      },
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 4.0, right: 8.0),
        margin: const EdgeInsets.only(right: 6.0),
        child: Icon(
          Icons.more_vert,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSubtitles(Subtitles subtitles) {
    if (!_subtitleOn) {
      return const SizedBox();
    }
    if (_subtitlesPosition == null) {
      return const SizedBox();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition!);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }

    if (chewieController.subtitleBuilder != null) {
      return chewieController.subtitleBuilder!(
        context,
        currentSubtitle.first!.text,
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: marginSize, right: marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          currentSubtitle.first!.text.toString(),
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      Color backgroundColor,
      Color iconColor,
      double barHeight,
      ) {
    return SafeArea(
      bottom: chewieController.isFullScreen,
      minimum: chewieController.controlsSafeAreaMinimum,
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.all(marginSize),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: SizedBox(
              height: barHeight,
              child: Row(
                children: [
                  _buildPlayPause(controller, iconColor, barHeight),
                  _buildPosition(iconColor),
                  _buildProgressBar(),
                  _buildSubtitleToggle(iconColor, barHeight),
                  _buildExpandButton(backgroundColor, iconColor, barHeight, 0.5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLive(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        'LIVE',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildExpandButton(
      Color backgroundColor,
      Color iconColor,
      double barHeight,
      double buttonPadding,
      ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: Container(
        height: barHeight,
        padding: EdgeInsets.only(
          left: buttonPadding,
          right: buttonPadding,
        ),
        color: Colors.transparent,
        child: Center(
          child: Icon(
            CupertinoIcons.app,
            color: iconColor,
            size: 17,
          ),
        ),
      ),
    );
  }

  bool _showPlayButton = false;

  void _handleTap() {
    _cancelAndRestartTimer();

    setState(() {
      _showPlayButton = !_showPlayButton;
    });

    // 버튼이 화면에 나타난 상태에서는 일정 시간 후에 자동으로 사라지도록 타이머 시작
    if (_showPlayButton) {
      _startHideTimer();
    }
  }

  void _playPause2() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        _showPlayButton = true;
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            _showPlayButton = false;
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          _showPlayButton = false;
          controller.play();
        }
      }
    });
  }

  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;

    return GestureDetector(
      onTap: _handleTap,
      child: AbsorbPointer(
        absorbing: !_showPlayButton,
        child: Stack(
          children: [
            CenterPlayButton(
              backgroundColor: Colors.black.withOpacity(0.2),
              iconColor: widget.iconColor,
              isFinished: isFinished,
              isPlaying: controller.value.isPlaying,
              show: _showPlayButton,
              onPressed: _playPause2,
            ),
            Container(),
          ],
        ),
      ),
    );
  }


  GestureDetector _buildPlayPause(
      VideoPlayerController controller,
      Color iconColor,
      double barHeight,
      ) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: AnimatedPlayPause(
          color: widget.iconColor,
          playing: controller.value.isPlaying,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Row(
        children: [
          Text(formatDuration(position), style: TextStyle(color: iconColor, fontSize: 12.0)),
          Text(' / ${formatDuration(duration)}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12.0)),
        ],
      ),
    );
  }

  Widget _buildSubtitleToggle(Color iconColor, double barHeight) {
    //if don't have subtitle hiden button
    if (chewieController.subtitle?.isEmpty ?? true) {
      return const SizedBox();
    }
    return GestureDetector(
      onTap: _subtitleToggle,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(right: 10.0),
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          Icons.subtitles,
          color: _subtitleOn ? iconColor : Colors.grey[700],
          size: 16.0,
        ),
      ),
    );
  }

  void _subtitleToggle() {
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
  }

  GestureDetector buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipBack,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0),
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          CupertinoIcons.gobackward_10,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  GestureDetector buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipForward,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: const EdgeInsets.only(
          right: 8.0,
        ),
        child: Icon(
          CupertinoIcons.goforward_10,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  GestureDetector buildSpeedButton(
      VideoPlayerController controller,
      Color iconColor,
      double barHeight,
      ) {
    return GestureDetector(
      onTap: () async {
        _hideTimer?.cancel();

        final chosenSpeed = await showCupertinoModalPopup<double>(
          context: context,
          semanticsDismissible: true,
          useRootNavigator: chewieController.useRootNavigator,
          builder: (context) => _PlaybackSpeedDialog(
            speeds: chewieController.playbackSpeeds,
            selected: _latestValue.playbackSpeed,
          ),
        );

        if (chosenSpeed != null) {
          controller.setPlaybackSpeed(chosenSpeed);
        }

        if (_latestValue.isPlaying) {
          _startHideTimer();
        }
      },
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: const EdgeInsets.only(
          right: 8.0,
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.skewY(0.0)
            ..rotateX(math.pi)
            ..rotateZ(math.pi * 0.8),
          child: Icon(
            Icons.speed,
            color: iconColor,
            size: 18.0,
          ),
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    setState(() {
      notifier.hideStuff = false;

      _startHideTimer();
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      notifier.hideStuff = true;

      chewieController.toggleFullScreen();
      _expandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: CupertinoVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
            });

            _startHideTimer();
          },
          colors: chewieController.cupertinoProgressColors ??
              ChewieProgressColors(
                //진행바 색상
                playedColor: const Color.fromARGB(
                  255,
                  255,
                  0,
                  0,
                ),
                handleColor: const Color.fromARGB(
                  255,
                  255,
                  0,
                  0,
                ),
                //바 버퍼 색상
                bufferedColor: const Color.fromARGB(
                  60,
                  55,
                  55,
                  55,
                ),
                //바 백그라운드 색상
                backgroundColor: const Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
              ),
        ),
      ),
    );
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  // void _skipBack() {
  //   _cancelAndRestartTimer();
  //   final beginning = Duration.zero.inMilliseconds;
  //   final skip =
  //       (_latestValue.position - const Duration(seconds: 10)).inMilliseconds;
  //   controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
  // }
  //
  // void _skipForward() {
  //   _cancelAndRestartTimer();
  //   final end = _latestValue.duration.inMilliseconds;
  //   final skip =
  //       (_latestValue.position + const Duration(seconds: 10)).inMilliseconds;
  //   controller.seekTo(Duration(milliseconds: math.min(skip, end)));
  // }

  void _skipBack() {
    _cancelAndRestartTimer();
    final beginning = Duration.zero.inMilliseconds;
    final skip = (_latestValue.position - const Duration(seconds: 10))
        .inMilliseconds;
    controller.seekTo(Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    _cancelAndRestartTimer();
    final end = _latestValue.duration.inMilliseconds;
    final skip = (_latestValue.position + const Duration(seconds: 10))
        .inMilliseconds;
    controller.seekTo(Duration(milliseconds: math.min(skip, end)));
  }

  void _startHideTimer() {
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative
        ? ChewieController.defaultHideControlsTimer
        : chewieController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      setState(() {
        notifier.hideStuff = true;
        _showPlayButton = false;
      });
    });
  }

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        _displayBufferingIndicator = false;
      }
    } else {
      _displayBufferingIndicator = controller.value.isBuffering;
    }

    setState(() {
      _latestValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }
}

class _PlaybackSpeedDialog extends StatelessWidget {
  const _PlaybackSpeedDialog({
    Key? key,
    required List<double> speeds,
    required double selected,
  })  : _speeds = speeds,
        _selected = selected,
        super(key: key);

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoActionSheet(
      actions: _speeds
          .map(
            (e) => CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop(e);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (e == _selected)
                Icon(Icons.check, size: 20.0, color: selectedColor),
              Text(e.toString()),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}
