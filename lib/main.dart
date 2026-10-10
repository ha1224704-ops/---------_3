import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:just_audio/just_audio.dart';

void main() { runApp(QuranApp()); }

class QuranApp extends StatefulWidget { @override State<QuranApp> createState() => QuranAppState(); }

class QuranAppState extends State<QuranApp> {
  bool loading = true;
  double prog = 0;
  @override void initState() { super.initState(); startApp(); }
  startApp() async {
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 15));
      setState(() { prog = i / 100; });
    }
    setState(() { loading = false; });
  }
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: Color(0xFF0A0A0A)),
      home: loading? Splash(prog: prog) : HomeMain(),
    );
  }
}

class Splash extends StatelessWidget {
  final double prog;
  Splash({required this.prog});
  @override Widget build(BuildContext context) {
    int p = (prog * 100).toInt();
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.menu_book, size: 80, color: Color(0xFF00FF88)),
          SizedBox(height: 15),
          Text("Noor Al Quloob", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text("Sadaqa for Nasser Aziz", style: TextStyle(color: Colors.white38, fontSize: 12)),
          SizedBox(height: 30),
          Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: LinearProgressIndicator(value: prog, color: Color(0xFF00FF88), backgroundColor: Colors.white10)),
          SizedBox(height: 8),
          Text(p.toString() + " %", style: TextStyle(color: Color(0xFF00FF88), fontSize: 10)),
        ]),
      ),
    );
  }
}

class HomeMain extends StatefulWidget { @override State<HomeMain> createState() => HomeMainState(); }
class HomeMainState extends State<HomeMain> {
  int idx = 0;
  @override Widget build(BuildContext context) {
    List<Widget> pages = [SurahList(), SebhaPage(), SettingsPage()];
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) { setState(() { idx = i; }); },
        selectedItemColor: Color(0xFF00FF88),
        backgroundColor: Color(0xFF111111),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Quran"),
          BottomNavigationBarItem(icon: Icon(Icons.circle), label: "Tasbeeh"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class SurahList extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Al Quran"), centerTitle: true, backgroundColor: Color(0xFF111111)),
      body: ListView.builder(
        itemCount: 114,
        itemBuilder: (c, i) {
          int n = i + 1;
          int cnt = quran.getVerseCount(n);
          String engName = quran.getSurahName(n);
          String arName = quran.getSurahNameArabic(n);
          return Card(
            color: Color(0xFF1C1C1C),
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 45, height: 45,
                decoration: BoxDecoration(color: Color(0xFF00FF88), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(n.toString(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              ),
              title: Text(arName + " - " + engName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(cnt.toString() + " Ayah", style: TextStyle(color: Colors.white38, fontSize: 10)),
              trailing: Icon(Icons.play_circle_fill, color: Color(0xFF00FF88), size: 28),
              onTap: () { Navigator.push(c, MaterialPageRoute(builder: (_) => ReaderPage(surah: n))); },
            ),
          );
        },
      ),
    );
  }
}

class ReaderPage extends StatefulWidget {
  final int surah;
  ReaderPage({required this.surah});
  @override State<ReaderPage> createState() => ReaderPageState();
}

class ReaderPageState extends State<ReaderPage> {
  AudioPlayer player = AudioPlayer();
  bool playing = false;
  bool isLoading = false;

  playFull() async {
    if (playing) {
      await player.pause();
      setState(() { playing = false; });
      return;
    }
    if (player.audioSource!= null) {
      await player.play();
      setState(() { playing = true; });
      return;
    }
    setState(() { isLoading = true; });
    int cnt = quran.getVerseCount(widget.surah);
    List<AudioSource> src = [];
    for (int i = 1; i <= cnt; i++) {
      String sid = widget.surah.toString().padLeft(3, '0');
      String vid = i.toString().padLeft(3, '0');
      String url = "https://everyayah.com/data/Yasser_Ad-Dosari_128kbps/" + sid + vid + ".mp3";
      src.add(AudioSource.uri(Uri.parse(url)));
    }
    await player.setAudioSource(ConcatenatingAudioSource(children: src));
    await player.play();
    setState(() { playing = true; isLoading = false; });
  }

  @override void dispose() { player.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    int cnt = quran.getVerseCount(widget.surah);
    IconData btnIcon;
    if (playing) { btnIcon = Icons.pause_circle_filled; } else { btnIcon = Icons.play_circle_fill; }
    Widget topBtn;
    if (isLoading) {
      topBtn = CircularProgressIndicator(color: Color(0xFF00FF88));
    } else {
      topBtn = IconButton(icon: Icon(btnIcon, size: 50, color: Color(0xFF00FF88)), onPressed: playFull);
    }
    String statusText;
    if (playing) { statusText = "Playing - stays in background"; } else { statusText = "Play full Surah - background"; }

    return Scaffold(
      appBar: AppBar(title: Text(quran.getSurahNameArabic(widget.surah)), backgroundColor: Color(0xFF111111)),
      body: Column(children: [
        Container(
          padding: EdgeInsets.all(10),
          color: Color(0xFF111111),
          child: Row(children: [topBtn, SizedBox(width: 8), Expanded(child: Text(statusText, style: TextStyle(color: Colors.white, fontSize: 11)))]),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: cnt + 1,
            itemBuilder: (c, i) {
              if (i == cnt) {
                return Container(
                  margin: EdgeInsets.only(top: 25, bottom: 30),
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: Color(0xFF00FF88), width: 1.2)),
                  child: Column(children: [
                    Text("Sadaqa Jaria", style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text("Al Fatiha for Nasser Aziz", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Divider(color: Color(0xFF00FF88)),
                  ]),
                );
              }
              String verseText = quran.getVerse(widget.surah, i + 1, verseEndSymbol: false);
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(12)),
                child: Text(verseText, textAlign: TextAlign.right, style: TextStyle(fontSize: 22, height: 1.9, color: Colors.white)),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class SebhaPage extends StatefulWidget { @override State<SebhaPage> createState() => SebhaPageState(); }
class SebhaPageState extends State<SebhaPage> {
  int count = 0;
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasbeeh"), centerTitle: true, backgroundColor: Color(0xFF111111)),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(count.toString(), style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Color(0xFF00FF88))),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () { setState(() { count++; }); },
            child: Container(width: 160, height: 160, decoration: BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle), child: Center(child: Text("Sabeh", style: TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold)))),
          ),
          SizedBox(height: 10),
          TextButton(onPressed: () { setState(() { count = 0; }); }, child: Text("Reset")),
        ]),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings"), centerTitle: true, backgroundColor: Color(0xFF111111)),
      body: ListView(padding: EdgeInsets.all(14), children: [
        Card(color: Color(0xFF1C1C1C), child: ListTile(leading: Icon(Icons.email, color: Color(0xFF00FF88)), title: Text("Contact: noor.app@gmail.com", style: TextStyle(color: Colors.white, fontSize: 12)))),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFF00FF88))),
          child: Column(children: [
            Text("Noor Al Quloob v6", style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("Sadaqa Jaria for Nasser Aziz - No Ads - Background Audio", style: TextStyle(color: Colors.white38, fontSize: 9), textAlign: TextAlign.center),
          ]),
        ),
      ]),
    );
  }
}