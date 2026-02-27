// lib/features/browser/music_browser_view.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/audio/deck.dart';
import '../../core/audio/audio_engine.dart';

class Track {
  final String path;
  final String title;
  final String artist;
  final String duration;
  final bool isLocal;

  const Track({
    required this.path,
    required this.title,
    required this.artist,
    required this.duration,
    required this.isLocal,
  });
}

class MusicBrowserView extends StatefulWidget {
  final DeckId targetDeck;
  final VoidCallback onClose;

  const MusicBrowserView({
    super.key,
    required this.targetDeck,
    required this.onClose,
  });

  @override
  State<MusicBrowserView> createState() => _MusicBrowserViewState();
}

class _MusicBrowserViewState extends State<MusicBrowserView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final List<Track> _localTracks = [];
  DeckId _targetDeck;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _targetDeck = widget.targetDeck;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null) return;

    setState(() {
      for (final file in result.files) {
        if (file.path != null) {
          _localTracks.add(Track(
            path: file.path!,
            title: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
            artist: 'Unknown',
            duration: '--:--',
            isLocal: true,
          ));
        }
      }
    });
  }

  Future<void> _loadTrack(Track track) async {
    final engine = context.read<AudioEngine>();
    await engine.loadTrackToDeck(
      _targetDeck,
      track.path,
      title: track.title,
      artist: track.artist,
    );
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.library_music, color: Color(0xFF00D4FF), size: 18),
                const SizedBox(width: 8),
                const Text('Music Browser',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Spacer(),
                // Target deck selector
                Row(
                  children: [
                    const Text('Load to: ',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                    _DeckToggle(
                      value: _targetDeck,
                      onChanged: (d) => setState(() => _targetDeck = d),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white38,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Local Files'),
              Tab(text: 'SoundCloud'),
            ],
            labelColor: const Color(0xFF00D4FF),
            unselectedLabelColor: Colors.white38,
            indicatorColor: const Color(0xFF00D4FF),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Local Files tab
                _LocalFilesTab(
                  tracks: _localTracks,
                  onPickFiles: _pickFiles,
                  onLoadTrack: _loadTrack,
                ),
                // SoundCloud tab
                const _SoundCloudTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckToggle extends StatelessWidget {
  final DeckId value;
  final ValueChanged<DeckId> onChanged;
  const _DeckToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [DeckId.a, DeckId.b].map((id) {
        final isSelected = value == id;
        final color = id == DeckId.a
            ? const Color(0xFF00D4FF)
            : const Color(0xFFFF6B35);
        return GestureDetector(
          onTap: () => onChanged(id),
          child: Container(
            width: 32,
            height: 22,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : Colors.white24,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                id == DeckId.a ? 'A' : 'B',
                style: TextStyle(
                  color: isSelected ? color : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LocalFilesTab extends StatelessWidget {
  final List<Track> tracks;
  final VoidCallback onPickFiles;
  final Future<void> Function(Track) onLoadTrack;

  const _LocalFilesTab({
    required this.tracks,
    required this.onPickFiles,
    required this.onLoadTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Import button
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Import Audio Files'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00D4FF),
                side: const BorderSide(color: Color(0xFF00D4FF)),
              ),
              onPressed: onPickFiles,
            ),
          ),
        ),

        if (tracks.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text('No tracks imported yet',
                      style: TextStyle(color: Colors.white38)),
                  Text('Tap "Import Audio Files" to add music',
                      style: TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (_, i) => _TrackTile(
                track: tracks[i],
                onLoad: () => onLoadTrack(tracks[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onLoad;
  const _TrackTile({required this.track, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.music_note, color: Color(0xFF00D4FF), size: 18),
      ),
      title: Text(track.title,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      subtitle: Text(track.artist,
          style: const TextStyle(color: Colors.white38, fontSize: 10)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(track.duration,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onLoad,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withOpacity(0.15),
                border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LOAD',
                  style: TextStyle(color: Color(0xFF00D4FF), fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundCloudTab extends StatelessWidget {
  const _SoundCloudTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud, color: Colors.orange, size: 48),
          SizedBox(height: 12),
          Text('SoundCloud Integration',
              style: TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Add your SoundCloud API key in\nlib/core/soundcloud_service.dart',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
