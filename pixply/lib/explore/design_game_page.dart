import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pixply/explore/instructions.dart';
import 'package:provider/provider.dart';
import 'package:pixply/explore/game_creation_store.dart';

// ---------------- settings --------------------------------
enum _Tool { brush, eraser, zoom }

// ignore: unused_element
late LedBluetooth _bluetooth;
// ignore: unused_element
bool _isConnected = false;
int ledWidth = 56;
int ledHeight = 56;

class DesignGamePage extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const DesignGamePage({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

  @override
  State<DesignGamePage> createState() => _DesignGamePageState();
}

class _DesignGamePageState extends State<DesignGamePage> {
  static const int gridSize = 56;
  late List<Color> pixelColors;
  Color selectedColor = Colors.white;
  bool isEraser = false;
  final GlobalKey repaintKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();
  int? _hoverCell;
  int _activePointers = 0;
  bool _lockScroll = false; // when zooming, disable scroll
  bool _isInteracting = false; // when zooming, we are interacting
  final Map<int, Offset> _lastPointerScene = {}; // last known scene position

  // active tool
  // _Tool? _activeTool ; // null = no tool active
  _Tool _activeTool = _Tool.zoom; 

  final List<int> _brushSizes = [1, 2, 4]; // 1x1, 2x2 (4px), 4x4 (16px)
  int _brushSizeIndex = 0; // 0 => 1px, 1 => 4px, 2 => 16px
  final LayerLink _toolsLink = LayerLink();
  OverlayEntry? _sizeOverlay;
 final List<Color> _primarySwatches = const [
  Colors.black, Colors.white, Colors.red, Colors.green, Colors.blue,
  Colors.purple, Colors.yellow, Colors.orange,
];
final List<Color> _savedColors = [];
final TextEditingController _hexCtrl = TextEditingController();


  @override
  void initState() {
    super.initState();
    pixelColors = List.generate(gridSize * gridSize, (_) => Colors.black);
    _bluetooth = widget.bluetooth;
    _isConnected = widget.isConnected;
  }

  @override
  void dispose() {
    _closeSizePopup();
    _transformationController.dispose();
    super.dispose();
  }
void _rebuildSizeOverlay() => _sizeOverlay?.markNeedsBuild();

  void _openSizePopup() {
    if (_sizeOverlay != null || !mounted) return;

    _sizeOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeSizePopup,
            ),
          ),
          // popup
          CompositedTransformFollower(
            link: _toolsLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 6), //
            child: Material(
              color: Colors.transparent,
              child: _BrushPopup(
                selectedIndex: _brushSizeIndex,
                onSelect: (i) {
                  _brushSizeIndex = i; 
                  _rebuildSizeOverlay(); 
                  setState(() {});   
                  // _closeSizePopup(); // ✅
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_sizeOverlay!);
  }

  void _closeSizePopup() {
    _sizeOverlay?.remove();
    _sizeOverlay = null;
  }

  // ---------- set tool ----------
  void _setTool(_Tool t) {
    setState(() {
      if (_activeTool == t) {
        _activeTool = _Tool.zoom;
        _isInteracting = false;
        _lastPointerScene.clear();

        _closeSizePopup();
      } else {
        _activeTool = t;

        if (t == _Tool.brush || t == _Tool.eraser) {
          // open size popup
          _openSizePopup();
        } else {
          _closeSizePopup();
        }
      }
    });
  }
String _toHex(Color c) => c.value.toRadixString(16).padLeft(8,'0').substring(2).toUpperCase();
Color? _fromHex(String s){
  final v=s.replaceAll('#','').trim();
  if(v.length!=6) return null;
  final n=int.tryParse(v,radix:16); if(n==null) return null;
  return Color(0xFF000000|n);
}

void _pickColor() {
  _closeSizePopup();
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      Color temp = selectedColor;
      _hexCtrl.text = _toHex(temp);

      Widget swatch(Color c) => InkWell(
        onTap: () => ( // انتخاب preset با هایلایت و آپدیت HEX
          () {
            // با setState محلی برای نمایش استروک انتخاب
            (ctx as Element).markNeedsBuild();
          }(),
          temp = c,
          _hexCtrl.text = _toHex(temp)
        ),
        child: Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: (temp.value == c.value) ? Colors.white : Colors.white24,
              width: (temp.value == c.value) ? 3 : 1,
            ),
          ),
        ),
      );

      return StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Choose a color',
            style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600,
              fontSize: 20, fontFamily: 'Poppins'
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Presets (بالا)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _primarySwatches.map((c) => InkWell(
                      onTap: () {
                        setLocal(() {
                          final h = HSVColor.fromColor(c);
                          // Top-right of HSV square: full saturation and value
                          temp = HSVColor.fromAHSV(1.0, h.hue, 1.0, 1.0).toColor();
                          _hexCtrl.text = _toHex(temp);
                        });
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (temp.value == c.value) ? Colors.white : Colors.white24,
                            width: (temp.value == c.value) ? 3 : 1,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // HSV ColorPicker
                ColorPicker(
                  pickerColor: temp,
                  onColorChanged: (c) {
                    setLocal(() {
                      // Ensure maximum brightness (V=1.0); keep user saturation and hue
                      final h = HSVColor.fromColor(c);
                      temp = HSVColor.fromAHSV(1.0, h.hue, h.saturation, 1.0).toColor();
                      _hexCtrl.text = _toHex(temp);
                    });
                  },
                  enableAlpha: false,
                  labelTypes: const [],
                  portraitOnly: true,
                ),
                const SizedBox(height: 8),

                // HEX input
                Row(
                  children: [
                    const Text('#', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _hexCtrl,
                        maxLength: 6,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFF2B2B2B),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          hintText: 'A816A8',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        onSubmitted: (txt) {
                          final c = _fromHex(txt);
                          if (c != null) setLocal(() => temp = c);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final c = _fromHex(_hexCtrl.text);
                        if (c != null) setLocal(() => temp = c);
                      },
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 🔵 پیش‌نمایش دایره‌ای پایین (زنده)
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: temp,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Saved (پایین)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!_savedColors.contains(temp)) {
                          setLocal(() => _savedColors.add(temp));
                        }
                      },
                      child: Container(
                        width: 26, height: 26, margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white38, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 18, color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Wrap(
                        children: [
                          for (int i = 0; i < _savedColors.length; i++)
                            GestureDetector(
                              onTap: () => setLocal(() => temp = _savedColors[i]),
                              onLongPress: () => setLocal(() => _savedColors.removeAt(i)),
                              child: Container(
                                width: 26, height: 26, margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _savedColors[i],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (temp.value == _savedColors[i].value)
                                        ? Colors.white
                                        : Colors.white24,
                                    width: (temp.value == _savedColors[i].value) ? 2.5 : 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: ui.Color.fromRGBO(255, 141, 131, 1),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => selectedColor = temp);
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      );
    },
  );
}




  void _selectBrush() => _setTool(_Tool.brush);
  void _selectEraser() => _setTool(_Tool.eraser);
  void _selectZoom() => _setTool(_Tool.zoom);

  void _clearDesign() {
    setState(() {
      pixelColors = List.generate(gridSize * gridSize, (_) => Colors.black);
    });
  }

  // ---------- set cell ----------
  int _cellFromOffset(Offset p, double side) {
    final cell = side / gridSize;
    final x = ((p.dx / cell).floor()).clamp(0, gridSize - 1).toInt();
    final y = ((p.dy / cell).floor()).clamp(0, gridSize - 1).toInt();
    return y * gridSize + x;
  }

  Offset _toScene(Offset local, double canvasSide) {
    final Matrix4 m = _transformationController.value.clone();
    final double det = m.determinant();
    if (det.abs() < 1e-9) return local;
    m.invert();
    final Offset scene = MatrixUtils.transformPoint(m, local);
    return scene;
  }

  // ---------- paint (1x1, 2x2, 4x4) ----------
  void _paintBlockAtIndex(int idx,
      {required int blockSize, required bool erase}) {
    final int cx = idx % gridSize;
    final int cy = idx ~/ gridSize;

    final int half = blockSize ~/ 2;
    final int startX = cx - half;
    final int startY = cy - half;

    for (int by = 0; by < blockSize; by++) {
      for (int bx = 0; bx < blockSize; bx++) {
        final int nx = startX + bx;
        final int ny = startY + by;
        if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
          final int nidx = ny * gridSize + nx;
          pixelColors[nidx] = erase ? Colors.black : selectedColor;
        }
      }
    }
  }

  void _paintAt(Offset p, double side,
      {required int blockSize, required bool erase}) {
    if (p.dx < 0 || p.dy < 0 || p.dx >= side || p.dy >= side) return;
    final idx = _cellFromOffset(p, side);
    setState(() {
      _paintBlockAtIndex(idx, blockSize: blockSize, erase: erase);
    });
  }

  // The device expects RGB byte order. Using BGR would swap red/blue on panel.
  Uint8List _imageToRawRGB(img.Image src) {
    final w = src.width, h = src.height;
    final out = List<int>.filled(w * h * 3, 0, growable: false);
    int k = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y); // RGBA
        out[k++] = p.r.toInt(); // R
        out[k++] = p.g.toInt(); // G
        out[k++] = p.b.toInt(); // B
      }
    }
    return Uint8List.fromList(out);
  }

  // ---------- send design to board ----------
  Future<void> _sendDesignToBoard() async {
    const int n = gridSize; // 56

    final img.Image canvas56 = img.Image(width: n, height: n);
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final c = pixelColors[y * n + x].withAlpha(0xFF);

        canvas56.setPixelRgb(x, y, c.red, c.green, c.blue);
      }
    }

    final Uint8List rawRgb = _imageToRawRGB(canvas56);
    //  ColorConfig
    // final Uint8List rawBgr = _bwToColoredRawBGR(canvas56, ColorConfig.selectedDisplayColor);

    final program = Program.bmp(
      partitionX: 0,
      partitionY: 0,
      partitionWidth: n,
      partitionHeight: n,
      bmpData: rawRgb,
      specialEffect: SpecialEffect.fixed,
      speed: 0,
      stayTime: 30,
      circularBorder: 0,
      brightness: 100,
    );

    if (_bluetooth.isConnected) {
      await _bluetooth.switchLedScreen(true);
      await _bluetooth.setBrightness(Brightness.high);
      await _bluetooth.updatePlaylistComplete();
      await widget.bluetooth.deleteAllPrograms();
      await _bluetooth.updatePlaylistComplete();
      await Future.delayed(const Duration(milliseconds: 200));
      final ok = await _bluetooth.sendTemporaryProgram(program, circularBorder: 0);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                ok ? "Design sent to LED board" : "Failed to send design")),
      );
      if (ok) {
        // Mark that this design has been tested on the board
        setState(() {
          _testedOnBoard = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not connected to LED board")),
      );
    }
  }

  void _showHowTo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How To Do",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600 , fontFamily: 'Poppins')),
            SizedBox(height: 8),
            Text(
              "• Select a color and drag it onto the grid.\n"
              "• See the design on the board with Test on the board.\n"
              "• Save the design with Next Step.",
              style: TextStyle(color: Colors.white70 , fontSize: 14, fontWeight: FontWeight.w400, fontFamily: 'Poppins'),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _testedOnBoard = false;

  void _onNextStep() {
    final pixelsArgb = pixelColors.map((c) => c.value).toList(growable: false);
    final store = context.read<GameCreationStore>();
    store.setDesign(gridSize: gridSize, pixelsArgb: pixelsArgb);

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => GameInstructionPage(
        bluetooth: widget.bluetooth,
        isConnected: widget.isConnected,
        gridSize: gridSize,
        pixelsArgb: pixelsArgb,
        testedOnBoard: _testedOnBoard,
      ),
    ));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double canvasSide =
                (constraints.maxWidth - 60).clamp(160.0, 391.0);
            final double previewSide = (canvasSide * 0.69).clamp(140.0, 270.0);
            final double buttonWidth =
                (constraints.maxWidth - 60).clamp(200.0, 336.0);
            const double buttonHeight = 82.0;

            return Column(
              children: [
                // --- Header ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SizedBox(
                    height: 71,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double leftButtonWidth = 71;
                        final double minGap = 12;
                        final double rightBalanceWidth = 71;
                        final double computed = constraints.maxWidth -
                            leftButtonWidth -
                            minGap -
                            rightBalanceWidth;
                        final double maxTextWidth =
                            computed.clamp(0.0, constraints.maxWidth);

                        return Stack(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _CircleSvgButton(
                                asset: 'assets/back.svg',
                                onTap: () => Navigator.of(context).maybePop(),
                                size: leftButtonWidth,
                                iconSize: 36,
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: maxTextWidth),
                                child: Center(
                                  child: Text(
                                    "Game Layout Design",
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(width: rightBalanceWidth),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    physics: _lockScroll
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 80,
                            child: CompositedTransformTarget(
                              link: _toolsLink,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 6),
                                    _HoverToolIcon(
                                      asset: 'assets/displaycolor.svg',
                                      active:
                                          false, // tool does not have active state
                                      onTap: _pickColor,
                                      tooltip: 'Color Picker',
                                      keepOriginalColor: true,
                                      size: 71,
                                      iconSize: 36,
                                      ignoreHover: false,
                                      onMouseExit: () {},
                                    ),
                                    const SizedBox(width: 6),
                                    _HoverToolIcon(
                                      asset: 'assets/brush.svg',
                                      active: _activeTool == _Tool.brush,
                                      onTap: _selectBrush,
                                      tooltip: 'Brush',
                                    ),
                                    const SizedBox(width: 6),
                                    _HoverToolIcon(
                                      asset: 'assets/zoom.svg',
                                      active: _activeTool == _Tool.zoom,
                                      onTap: _selectZoom,
                                      tooltip: 'Zoom',
                                    ),
                                    const SizedBox(width: 6),
                                    _HoverToolIcon(
                                      asset:
                                          'assets/pen.svg', // icon for eraser
                                      active: _activeTool == _Tool.eraser,
                                      onTap: _selectEraser,
                                      tooltip: 'Eraser',
                                    ),
                                    const SizedBox(width: 6),
                                    _HoverToolIcon(
                                      asset: 'assets/garbag.svg',
                                      active:
                                          false, // tool does not have active state
                                      onTap: _clearDesign,
                                      tooltip: 'Clear All',
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // if (_showBrushSizes)
                          //   Padding(
                          //     padding: const EdgeInsets.only(top: 8.0),
                          //     child: Center(
                          //       child: _BrushPopup(
                          //         selectedIndex: _brushSizeIndex,
                          //         onSelect: (i) => setState(() => _brushSizeIndex = i),
                          //       ),
                          //     ),
                          //   ),

                          const SizedBox(height: 12),

                          // --- Canvas  ---
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 4),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: RepaintBoundary(
                                key: repaintKey,
                                child: SizedBox(
                                  width: canvasSide,
                                  height: canvasSide,
                                  child: InteractiveViewer(
                                    transformationController:
                                        _transformationController,
                                    panEnabled: _activeTool == _Tool.zoom,
                                    scaleEnabled: _activeTool == _Tool.zoom,
                                    maxScale: 8,
                                    minScale: 1,
                                    boundaryMargin: const EdgeInsets.all(80),
                                    onInteractionStart: (_) {
                                      if (_activeTool == _Tool.zoom) {
                                        setState(() {
                                          _isInteracting = true;
                                          _lockScroll = true;
                                        });
                                      }
                                    },
                                    onInteractionEnd: (_) {
                                      if (_activeTool == _Tool.zoom) {
                                        setState(() {
                                          _isInteracting = false;
                                          _lockScroll = false;
                                          _lastPointerScene.clear();
                                        });
                                      }
                                    },
                                    child: MouseRegion(
                                      onHover: (e) {
                                        if (!kIsWeb) return;
                                        final sceneP = _toScene(
                                            e.localPosition, canvasSide);
                                        setState(() => _hoverCell =
                                            (sceneP.dx >= 0 &&
                                                    sceneP.dy >= 0 &&
                                                    sceneP.dx < canvasSide &&
                                                    sceneP.dy < canvasSide)
                                                ? _cellFromOffset(
                                                    sceneP, canvasSide)
                                                : null);
                                      },
                                      onExit: (_) {
                                        if (!kIsWeb) return;
                                        setState(() => _hoverCell = null);
                                      },
                                      child: Listener(
                                        behavior: HitTestBehavior.opaque,
                                        onPointerDown: (PointerDownEvent e) {
                                          setState(() {
                                            _activePointers++;
                                            _lockScroll = true;
                                          });

                                          // Only for brush or eraser with single touch and not interacting (zooming)
                                          if ((_activeTool == _Tool.brush ||
                                                  _activeTool ==
                                                      _Tool.eraser) &&
                                              _activePointers == 1 &&
                                              !_isInteracting) {
                                            final box = repaintKey
                                                    .currentContext
                                                    ?.findRenderObject()
                                                as RenderBox?;
                                            if (box == null) return;

                                            final local =
                                                box.globalToLocal(e.position);
                                            final sceneP =
                                                _toScene(local, canvasSide);
                                            final bs =
                                                _brushSizes[_brushSizeIndex];

                                            // ✅when inside canvas
                                            final inside = sceneP.dx >= 0 &&
                                                sceneP.dy >= 0 &&
                                                sceneP.dx < canvasSide &&
                                                sceneP.dy < canvasSide;
                                            if (inside) {
                                              _paintAt(sceneP, canvasSide,
                                                  blockSize: bs,
                                                  erase: _activeTool ==
                                                      _Tool.eraser);
                                              _lastPointerScene[e.pointer] =
                                                  sceneP;
                                            } else {
                                              //  if outside, do not paint and do not set last
                                              _lastPointerScene
                                                  .remove(e.pointer);
                                            }
                                          }
                                        },
                                        onPointerMove: (PointerMoveEvent e) {
                                          if (!(_activeTool == _Tool.brush ||
                                              _activeTool == _Tool.eraser))
                                            return;
                                          if (_activePointers != 1 ||
                                              _isInteracting) return;

                                          final box = repaintKey.currentContext
                                                  ?.findRenderObject()
                                              as RenderBox?;
                                          if (box == null) return;

                                          final local =
                                              box.globalToLocal(e.position);
                                          final sceneP =
                                              _toScene(local, canvasSide);
                                          final prev =
                                              _lastPointerScene[e.pointer];
                                          final bs =
                                              _brushSizes[_brushSizeIndex];

                                          //
                                          final inside = sceneP.dx >= 0 &&
                                              sceneP.dy >= 0 &&
                                              sceneP.dx < canvasSide &&
                                              sceneP.dy < canvasSide;
                                          if (!inside) {
                                            _lastPointerScene.remove(e.pointer);
                                            return;
                                          }

                                          if (prev == null) {
                                            _paintAt(sceneP, canvasSide,
                                                blockSize: bs,
                                                erase: _activeTool ==
                                                    _Tool.eraser);
                                            _lastPointerScene[e.pointer] =
                                                sceneP;
                                            return;
                                          }

                                          //  just in canvas prev و sceneP
                                          final cellSize =
                                              canvasSide / gridSize;
                                          final distance =
                                              (sceneP - prev).distance;
                                          final steps =
                                              (distance / (cellSize * 0.5))
                                                  .ceil()
                                                  .clamp(1, 1000);
                                          for (int i = 1; i <= steps; i++) {
                                            final t = i / steps;
                                            final interp =
                                                Offset.lerp(prev, sceneP, t)!;
                                            final ok = interp.dx >= 0 &&
                                                interp.dy >= 0 &&
                                                interp.dx < canvasSide &&
                                                interp.dy < canvasSide;
                                            if (ok) {
                                              _paintAt(interp, canvasSide,
                                                  blockSize: bs,
                                                  erase: _activeTool ==
                                                      _Tool.eraser);
                                            } else {
                                              // if outside, do not paint
                                              break;
                                            }
                                          }
                                          _lastPointerScene[e.pointer] = sceneP;
                                        },
                                        onPointerUp: (PointerUpEvent e) =>
                                            setState(() {
                                          _activePointers =
                                              ((_activePointers - 1)
                                                      .clamp(0, 10))
                                                  .toInt();
                                          _lastPointerScene.remove(e.pointer);
                                          if (_activePointers == 0 &&
                                              !_isInteracting)
                                            _lockScroll = false;
                                        }),
                                        onPointerCancel:
                                            (PointerCancelEvent e) =>
                                                setState(() {
                                          _activePointers =
                                              ((_activePointers - 1)
                                                      .clamp(0, 10))
                                                  .toInt();
                                          _lastPointerScene.remove(e.pointer);
                                          if (_activePointers == 0 &&
                                              !_isInteracting)
                                            _lockScroll = false;
                                        }),
                                        child: CustomPaint(
                                          painter: _PixelsPainter(
                                              pixelColors, gridSize),
                                          foregroundPainter:
                                              _GridAndHoverPainter(
                                            gridSize,
                                            gridColor: const Color(0xFF707070),
                                            gridOpacity: 0.55,
                                            hoverIndex: _hoverCell,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // --- Preview ---
                          Center(
                            child: Container(
                              width: previewSide,
                              height: previewSide,
                              decoration: BoxDecoration(
                                color:
                                    const ui.Color.fromRGBO(104, 104, 104, 1),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.white38, width: 4),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: _MiniPreview(
                                  gridSize: gridSize, pixels: pixelColors),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // --- Buttons ---
                          Center(
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: _BigPillSvgButton(
                                asset: 'assets/tested.svg',
                                label: "Test on the board",
                                onPressed: _sendDesignToBoard,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: _BigPillSvgButton(
                                asset: 'assets/info.svg',
                                label: "How To Do",
                                onPressed: _showHowTo,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: _BigPillButton(
                                label: "Next Step",
                                onPressed: _onNextStep,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ================= Helper Widgets =================
class _CircleSvgButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  const _CircleSvgButton({
    required this.asset,
    required this.onTap,
    this.size = 36,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: ui.Color.fromRGBO(51, 51, 51, 1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: iconSize,
            height: iconSize,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

// hover icon
class _HoverToolIcon extends StatefulWidget {
  final String asset;
  final VoidCallback onTap;
  final bool active;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool keepOriginalColor;
  final bool ignoreHover;
  final VoidCallback? onMouseExit;

  const _HoverToolIcon({
    required this.asset,
    required this.onTap,
    required this.active,
    this.tooltip,
    this.size = 71,
    this.iconSize = 36,
    this.keepOriginalColor = false,
    this.ignoreHover = false,
    this.onMouseExit,
  });

  @override
  State<_HoverToolIcon> createState() => _HoverToolIconState();
}

class _HoverToolIconState extends State<_HoverToolIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlight = widget.active || (_hovered && !widget.ignoreHover);
    final bg = highlight ? Colors.white : const Color(0xFF5A5A5A);
    final iconColor = highlight ? Colors.black : Colors.white;

    final body = InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            widget.asset,
            width: widget.iconSize,
            height: widget.iconSize,
            colorFilter: widget.keepOriginalColor
                ? null
                : ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );

    final wrapped = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onMouseExit?.call();
      },
      child: body,
    );

    return widget.tooltip == null
        ? wrapped
        : Tooltip(message: widget.tooltip!, child: wrapped);
  }
}

// popup
class _BrushPopup extends StatelessWidget {
  final int selectedIndex; // 0,1,2
  final ValueChanged<int> onSelect;
  const _BrushPopup({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget item(int i, int px) {
      final sel = i == selectedIndex;
      return GestureDetector(
        onTap: () => onSelect(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24 + i * 10.0,
              height: 24 + i * 10.0,
              decoration: BoxDecoration(
                color: const Color(0xFF2B2B2B),
                borderRadius: BorderRadius.circular(12),
                border:
                    sel ? Border.all(color: Colors.white70, width: 2) : null,
              ),
              child: Center(
                child: Container(
                  width: [8.0, 14.0, 20.0][i],
                  height: [8.0, 14.0, 20.0][i],
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('$px pixel',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(0, 1),
          const SizedBox(width: 18),
          item(1, 4),
          const SizedBox(width: 18),
          item(2, 16),
        ],
      ),
    );
  }
}

class _BigPillSvgButton extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onPressed;
  const _BigPillSvgButton({
    required this.asset,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2B2B2B),
        foregroundColor: const ui.Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(41)),
        elevation: 0,
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 20, fontFamily: 'Poppins'),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            asset,
            width: 36,
            height: 36,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, textAlign: TextAlign.center)),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

// ===== Painters =====
class _MiniPreview extends StatelessWidget {
  final int gridSize;
  final List<Color> pixels;
  const _MiniPreview({required this.gridSize, required this.pixels});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MiniPreviewPainter(gridSize, pixels));
  }
}

class _MiniPreviewPainter extends CustomPainter {
  final int n;
  final List<Color> pixels;
  _MiniPreviewPainter(this.n, this.pixels);

  static const Color _bg = ui.Color.fromRGBO(104, 104, 104, 1);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    paint.color = _bg;
    canvas.drawRect(Offset.zero & size, paint);
    final cellW = size.width / n;
    final cellH = size.height / n;

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        final c = pixels[y * n + x];
        if (c == Colors.black) continue;
        paint.color = c;
        canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPreviewPainter old) => true;
}

class _PixelsPainter extends CustomPainter {
  final List<Color> pixels;
  final int n;
  _PixelsPainter(this.pixels, this.n);

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / n;
    final cellH = size.height / n;
    final paint = Paint()..isAntiAlias = false;
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        paint.color = pixels[y * n + x];
        canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelsPainter old) => true;
}

class _GridAndHoverPainter extends CustomPainter {
  final int n;
  final Color gridColor;
  final double gridOpacity;
  final int? hoverIndex;
  _GridAndHoverPainter(this.n,
      {required this.gridColor, required this.gridOpacity, this.hoverIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final dpr =
        ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;
    final cellW = size.width / n;
    final cellH = size.height / n;

    final p = Paint()
      ..color = gridColor.withValues(alpha: gridOpacity)
      ..strokeWidth = 1 / dpr
      ..isAntiAlias = false;

    for (int i = 1; i < n; i++) {
      final x = (i * cellW * dpr).round() / dpr;
      final y = (i * cellH * dpr).round() / dpr;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }

    if (hoverIndex != null) {
      final hx = hoverIndex! % n;
      final hy = hoverIndex! ~/ n;
      final r = Rect.fromLTWH(hx * cellW, hy * cellH, cellW, cellH);
      final hp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.6);
      canvas.drawRect(r.deflate(0.25), hp);
    }
  }

  @override
  bool shouldRepaint(covariant _GridAndHoverPainter old) =>
      old.hoverIndex != hoverIndex ||
      old.gridOpacity != gridOpacity ||
      old.gridColor != gridColor;
}

class _BigPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _BigPillButton({required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B2B2B),
          foregroundColor: const ui.Color.fromARGB(255, 255, 255, 255),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(41)),
          elevation: 0,
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 20),
        ),
        child: Text(label, textAlign: TextAlign.center),
      );
}
