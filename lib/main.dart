import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kWood = Color(0xFF9B6B47);
const Color kInk = Color(0xFF45333F);
const Color kPaper = Color(0xFFFFFAF0);
const Color kGlow = Color(0xFFFFD98A);
const Color kBg = Color(0xFFEFE6F5);

void main() => runApp(const KamarkuApp());

class KamarkuApp extends StatelessWidget {
  const KamarkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kamarku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE58F7A),
      ),
      home: const DoorScreen(),
    );
  }
}

// ---------------------------------------------------------------- PINTU

class DoorScreen extends StatefulWidget {
  const DoorScreen({super.key});

  @override
  State<DoorScreen> createState() => _DoorScreenState();
}

class _DoorScreenState extends State<DoorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _opening = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    await _c.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const RoomScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kamarku',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _open,
                child: SizedBox(
                  width: 220,
                  height: 330,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: kWood,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(color: kGlow),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedBuilder(
                          animation: _c,
                          builder: (_, __) => Transform(
                            alignment: Alignment.centerLeft,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY(-_c.value * 1.35),
                            child: Container(
                              color: const Color(0xFFE7A98F),
                              child: Align(
                                alignment: const Alignment(0.75, 0.1),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: kGlow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ketuk pintunya untuk masuk.',
                style: TextStyle(color: kInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- KAMAR

class _Phase {
  final Color top, bottom, wall;
  final bool night;
  const _Phase(this.top, this.bottom, this.wall, this.night);
}

_Phase _phaseFor(int h) {
  if (h >= 5 && h < 10) {
    return const _Phase(
        Color(0xFFFFD6A5), Color(0xFFBFE3F2), Color(0xFFD8CDEA), false);
  }
  if (h >= 10 && h < 16) {
    return const _Phase(
        Color(0xFF8FD3F4), Color(0xFFD6F0FA), Color(0xFFDCD2EE), false);
  }
  if (h >= 16 && h < 19) {
    return const _Phase(
        Color(0xFFFF9E80), Color(0xFFFFD6A5), Color(0xFFD3C3DD), false);
  }
  return const _Phase(
      Color(0xFF1B2250), Color(0xFF3A3F7A), Color(0xFF6B5C8F), true);
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  bool _tidy = false;
  int _hour = DateTime.now().hour;
  Timer? _timer;

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _hour = DateTime.now().hour);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounce.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _tidy = p.getString('kasur_rapi') == _today);
  }

  Future<void> _setTidy(bool v) async {
    final p = await SharedPreferences.getInstance();
    if (v) {
      await p.setString('kasur_rapi', _today);
    } else {
      await p.remove('kasur_rapi');
    }
    if (!mounted) return;
    setState(() => _tidy = v);
    _bounce.forward(from: 0);
  }

  void _bedTap() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kasur', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_tidy
                ? 'Harimu sudah dimulai. Ketuk tombol di bawah kalau mau mengakhiri hari.'
                : 'Selamat datang. Rapikan dulu kasur yang asli, lalu ketuk tombol di bawah.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _setTidy(!_tidy);
              },
              child: Text(_tidy ? 'Akhiri hariku' : 'Kasur sudah rapi, mulai hariku'),
            ),
          ],
        ),
      ),
    );
  }

  void _todoTap() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const TodoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ph = _phaseFor(_hour);
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kamarku',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 400 / 460,
                      child: LayoutBuilder(
                        builder: (ctx, box) =>
                            _room(box.maxWidth, box.maxHeight, ph),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Ketuk kasur untuk memulai atau mengakhiri hari, dan buku di meja untuk tugasmu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kInk),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _room(double w, double h, _Phase ph) {
    const d800 = Duration(milliseconds: 800);
    final bedW = w * .48;
    final bedH = h * .25;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(duration: d800, color: ph.wall),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: h * .67,
          bottom: 0,
          child: AnimatedContainer(
            duration: d800,
            color: ph.night ? const Color(0xFF6B4A35) : const Color(0xFFCFA57C),
          ),
        ),
        // lampu hias
        Positioned(
          left: 0,
          right: 0,
          top: h * .025,
          height: h * .05,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final a = (120 +
                        135 * ((math.sin(_glow.value * math.pi * 2 + i) + 1) / 2))
                    .round();
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kGlow.withAlpha(a),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ),
        // jendela
        Positioned(
          left: w * .08,
          top: h * .15,
          width: w * .28,
          height: h * .28,
          child: _window(w, ph),
        ),
        // karpet
        Positioned(
          left: w * .2,
          right: w * .2,
          top: h * .86,
          height: h * .1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8C4CF),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        // cahaya lampu tidur
        Positioned(
          left: w * .5,
          top: h * .56,
          width: w * .2,
          height: w * .2,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGlow.withAlpha((50 + 40 * _glow.value).round()),
              ),
            ),
          ),
        ),
        // nakas dan lampu
        Positioned(
          left: w * .52,
          top: h * .74,
          width: w * .12,
          height: h * .14,
          child: Container(
            decoration: BoxDecoration(
              color: kWood,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Positioned(
          left: w * .545,
          top: h * .64,
          width: w * .07,
          height: h * .08,
          child: Container(
            decoration: const BoxDecoration(
              color: kPaper,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(10),
                bottom: Radius.circular(3),
              ),
            ),
          ),
        ),
        // kasur
        Positioned(
          left: w * .02,
          top: h * .55,
          width: bedW,
          height: bedH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _bedTap,
            child: AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) => Transform.scale(
                scale: 1 + .06 * math.sin(_bounce.value * math.pi),
                alignment: Alignment.bottomCenter,
                child: child,
              ),
              child: _bed(bedW, bedH),
            ),
          ),
        ),
        // meja
        Positioned(
          left: w * .66,
          top: h * .73,
          width: w * .32,
          height: h * .03,
          child: Container(
            decoration: BoxDecoration(
              color: kWood,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          left: w * .68,
          top: h * .76,
          width: w * .02,
          height: h * .12,
          child: Container(color: kWood),
        ),
        Positioned(
          left: w * .94,
          top: h * .76,
          width: w * .02,
          height: h * .12,
          child: Container(color: kWood),
        ),
        // buku tugas
        Positioned(
          left: w * .72,
          top: h * .655,
          width: w * .2,
          height: h * .075,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _todoTap,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kPaper,
                      border: Border.all(color: kInk.withAlpha(70)),
                      borderRadius:
                          const BorderRadius.only(topLeft: Radius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kPaper,
                      border: Border.all(color: kInk.withAlpha(70)),
                      borderRadius:
                          const BorderRadius.only(topRight: Radius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _window(double w, _Phase ph) {
    return Container(
      padding: EdgeInsets.all(w * .012),
      decoration: BoxDecoration(
        color: kWood,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ph.top, ph.bottom],
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 800),
                alignment: Alignment(0.3, ph.night ? -0.5 : -0.2),
                child: Icon(
                  ph.night ? Icons.nightlight_round : Icons.wb_sunny,
                  color: ph.night
                      ? const Color(0xFFF4EFD0)
                      : const Color(0xFFFFD36E),
                  size: w * .07,
                ),
              ),
              Center(child: Container(width: 3, color: kWood)),
              Center(child: Container(height: 3, color: kWood)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bed(double bw, double bh) {
    const dur = Duration(milliseconds: 600);
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: bw * .06,
          child: Container(
            decoration: BoxDecoration(
              color: kWood,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Positioned(
          left: bw * .04,
          right: 0,
          top: bh * .35,
          bottom: bh * .08,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2B5A3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Positioned(
          left: bw * .04,
          right: 0,
          top: bh * .22,
          height: bh * .4,
          child: AnimatedContainer(
            duration: dur,
            curve: Curves.easeOutBack,
            transformAlignment: Alignment.center,
            transform: Matrix4.rotationZ(_tidy ? 0 : -0.06),
            decoration: BoxDecoration(
              color: _tidy ? const Color(0xFFFFF1DF) : const Color(0xFFE59A87),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Positioned(
          left: bw * .1,
          top: bh * .1,
          width: bw * .28,
          height: bh * .26,
          child: AnimatedContainer(
            duration: dur,
            curve: Curves.easeOutBack,
            transformAlignment: Alignment.center,
            transform: Matrix4.rotationZ(_tidy ? 0 : 0.35),
            decoration: BoxDecoration(
              color: kPaper,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- TUGAS

class TodoSheet extends StatefulWidget {
  const TodoSheet({super.key});

  @override
  State<TodoSheet> createState() => _TodoSheetState();
}

class _TodoSheetState extends State<TodoSheet> {
  final TextEditingController _ctl = TextEditingController();
  List<String> _items = [];
  SharedPreferences? _p;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _items = List<String>.from(_p!.getStringList('todo') ?? []));
  }

  void _save() {
    _p?.setStringList('todo', _items);
  }

  void _add() {
    final t = _ctl.text.trim();
    if (t.isEmpty) return;
    setState(() => _items.add('0|$t'));
    _ctl.clear();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jadwal tugas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctl,
                  onSubmitted: (_) => _add(),
                  decoration: const InputDecoration(
                    hintText: 'Tulis tugas kuliah…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: const Text('Tambah')),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var i = 0; i < _items.length; i++) _row(i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(int i) {
    final done = _items[i].startsWith('1|');
    final text = _items[i].substring(2);
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: done,
      onChanged: (v) {
        setState(() {
          _items[i] = '${v == true ? '1' : '0'}|$text';
        });
        _save();
      },
      title: Text(
        text,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      secondary: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _items.removeAt(i);
          });
          _save();
        },
      ),
    );
  }
}
