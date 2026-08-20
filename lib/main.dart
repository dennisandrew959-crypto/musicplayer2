import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// --- 1. MODEL ---
class Song {
  final String id;
  final String title;
  final String artist;
  final String assetPath;
  final String imagePath;
  final String thumbnailPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.assetPath,
    required this.imagePath,
    required this.thumbnailPath,
  });
}

// --- 2. LOCAL ASSETS SONGS ---
final sampleSongs = [
  // Joji
  Song(
    id: '1',
    title: 'Glimpse Of Us',
    artist: 'Joji',
    assetPath: 'assets/Joji - Glimpse Of Us.mp3',
    imagePath: 'assets/Joji.jpg',
    thumbnailPath: 'assets/glimpse of us image.jpg',
  ),
  Song(
    id: '2',
    title: 'Die For You',
    artist: 'Joji',
    assetPath: 'assets/Joji - Die For You.mp3',
    imagePath: 'assets/Joji.jpg',
    thumbnailPath: 'assets/die for you image.jpg',
  ),
  Song(
    id: '3',
    title: 'Sanctuary',
    artist: 'Joji',
    assetPath: 'assets/Joji - Sanctuary.mp3',
    imagePath: 'assets/Joji.jpg',
    thumbnailPath: 'assets/santuary image.jpg',
  ),
  Song(
    id: '4',
    title: "Past Won't Leave My Bed",
    artist: 'Joji',
    assetPath: "assets/Joji - Past Won't Leave My Bed.mp3",
    imagePath: 'assets/Joji.jpg',
    thumbnailPath: 'assets/past wont leave my bed image.jpg',
  ),

  // Michael Jackson
  Song(
    id: '5',
    title: 'Beat It',
    artist: 'Michael Jackson',
    assetPath: 'assets/Michael Jackson - Beat It (Official 4K Video).mp3',
    imagePath: 'assets/Michael Jackson.jpg',
    thumbnailPath: 'assets/beat it image.jpg',
  ),
  Song(
    id: '6',
    title: 'Billie Jean',
    artist: 'Michael Jackson',
    assetPath: 'assets/Michael Jackson - Billie Jean (Official Video).mp3',
    imagePath: 'assets/Michael Jackson.jpg',
    thumbnailPath: 'assets/billie jean image.jpg',
  ),
  Song(
    id: '7',
    title: 'Chicago',
    artist: 'Michael Jackson',
    assetPath: 'assets/Michael Jackson - Chicago (Official Audio).mp3',
    imagePath: 'assets/Michael Jackson.jpg',
    thumbnailPath: 'assets/chicago image.jpg',
  ),
  Song(
    id: '8',
    title: 'Thriller',
    artist: 'Michael Jackson',
    assetPath: 'assets/Michael Jackson - Thriller (Official 4K Video).mp3',
    imagePath: 'assets/Michael Jackson.jpg',
    thumbnailPath: 'assets/thriller image.jpg',
  ),
  Song(
    id: '9',
    title: 'Bad',
    artist: 'Michael Jackson',
    assetPath: 'assets/Bad (2012 Remaster).mp3',
    imagePath: 'assets/Michael Jackson.jpg',
    thumbnailPath: 'assets/bad image.jpg',
  ),
  // Post Malone
  Song(
    id: '10',
    title: 'Sunflower',
    artist: 'Post Malone, Swae Lee',
    assetPath:
        'assets/Post Malone, Swae Lee - Sunflower (Spider-Man_ Into the Spider-Verse).mp3',
    imagePath: 'assets/Post Malone.jpg',
    thumbnailPath: 'assets/sunflower image.jpg',
  ),
  Song(
    id: '11',
    title: 'Psycho',
    artist: 'Post Malone',
    assetPath:
        'assets/Post Malone - Psycho (Official Music Video) ft. Ty Dolla \$ign.mp3',
    imagePath: 'assets/Post Malone.jpg',
    thumbnailPath: 'assets/psycho image.jpg',
  ),
  Song(
    id: '12',
    title: 'Goodbyes',
    artist: 'Post Malone',
    assetPath: 'assets/Post Malone - Goodbyes (Lyrics) ft. Young Thug.mp3',
    imagePath: 'assets/Post Malone.jpg',
    thumbnailPath: 'assets/goodbye image.jpg',
  ),
  Song(
    id: '13',
    title: 'Circles',
    artist: 'Post Malone',
    assetPath: 'assets/Post Malone - Circles (Lyrics).mp3',
    imagePath: 'assets/Post Malone.jpg',
    thumbnailPath: 'assets/circles image.png',
  ),
  // Ne-Yo
  Song(
    id: '14',
    title: 'Because Of You',
    artist: 'Ne-Yo',
    assetPath: 'assets/Ne-Yo - Because Of You (Official Music Video).mp3',
    imagePath: 'assets/ne-yo.jpg',
    thumbnailPath: 'assets/because of you image.jpg',
  ),
  Song(
    id: '15',
    title: 'Closer',
    artist: 'Ne-Yo',
    assetPath: 'assets/Ne-Yo - Closer [Official Video].mp3',
    imagePath: 'assets/ne-yo.jpg',
    thumbnailPath: 'assets/closer image.jpg',
  ),
];

// --- 3. AUDIO HANDLER (audio_service + just_audio) ---
// This is the canonical pattern for background audio playback.
class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Stream of durations for the currently loaded track.
  final _durationController = StreamController<Duration>.broadcast();
  Stream<Duration> get durationStream => _durationController.stream;

  AudioPlayerHandler() {
    // Propagate playback state to audio_service.
    _player.playbackEventStream.map(_transformEvent).listen(playbackState.add);

    // Keep the media item in sync with the current track.
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Propagate position updates.
    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });

    // Propagate duration updates.
    _player.durationStream.listen((dur) {
      if (dur != null && dur > Duration.zero) {
        _durationController.add(dur);
      }
    });
  }

  // Convert just_audio's PlaybackEvent into audio_service's PlaybackState.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[event.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // Play a single song by its asset path.
  Future<void> playSong(Song song) async {
    final mediaItem = MediaItem(
      id: song.id,
      album: 'Local Player',
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse('asset:///${song.imagePath}'),
    );

    // Set the queue to just this song and play it.
    await _player.setAudioSource(
      AudioSource.asset(song.assetPath, tag: mediaItem),
    );
    queue.add([mediaItem]);
    this.mediaItem.add(mediaItem);
    _player.play();
  }

  // Play a song within the full library queue so next/previous work.
  Future<void> playFromQueue(List<Song> songs, int index) async {
    final items = songs
        .map(
          (s) => MediaItem(
            id: s.id,
            album: 'Local Player',
            title: s.title,
            artist: s.artist,
            artUri: Uri.parse('asset:///${s.imagePath}'),
          ),
        )
        .toList();

    // Set the full library as the playback queue.
    await _player.setAudioSources([
      for (final s in songs)
        AudioSource.asset(
          s.assetPath,
          tag: MediaItem(
            id: s.id,
            album: 'Local Player',
            title: s.title,
            artist: s.artist,
            artUri: Uri.parse('asset:///${s.imagePath}'),
          ),
        ),
    ], initialIndex: index);
    queue.add(items);
    mediaItem.add(items[index]);
    _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
}

// --- 4. STATE & AUDIO PROVIDER ---
class AudioPlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String searchQuery;
  final Map<String, Duration> songDurations;
  final Set<String> favoriteSongIds;
  final List<String> playlistNames;
  final Map<String, List<String>> playlistSongs;
  final String themeMode;
  final String? profileName;
  final bool isGridView;

  AudioPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.searchQuery = '',
    this.songDurations = const {},
    this.favoriteSongIds = const {},
    this.playlistNames = const [],
    this.playlistSongs = const {},
    this.themeMode = 'dark',
    this.profileName,
    this.isGridView = false,
  });

  AudioPlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? searchQuery,
    Map<String, Duration>? songDurations,
    Set<String>? favoriteSongIds,
    List<String>? playlistNames,
    Map<String, List<String>>? playlistSongs,
    String? themeMode,
    String? profileName,
    bool? isGridView,
  }) {
    return AudioPlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      searchQuery: searchQuery ?? this.searchQuery,
      songDurations: songDurations ?? this.songDurations,
      favoriteSongIds: favoriteSongIds ?? this.favoriteSongIds,
      playlistNames: playlistNames ?? this.playlistNames,
      playlistSongs: playlistSongs ?? this.playlistSongs,
      themeMode: themeMode ?? this.themeMode,
      profileName: profileName ?? this.profileName,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayerHandler _handler;

  AudioPlayerNotifier(this._handler) : super(AudioPlayerState()) {
    _initStreams();
  }

  void _initStreams() {
    _handler.playbackState.listen((playbackState) {
      state = state.copyWith(
        isPlaying: playbackState.playing,
        position: playbackState.updatePosition,
      );
    });

    _handler.mediaItem.listen((item) {
      if (item != null) {
        final song = sampleSongs.firstWhere(
          (s) => s.id == item.id,
          orElse: () => sampleSongs.first,
        );
        state = state.copyWith(currentSong: song);
      }
    });

    // Track the duration of the currently loaded song.
    _handler.durationStream.listen((dur) {
      final current = state.currentSong;
      if (current != null && dur > Duration.zero) {
        final updated = Map<String, Duration>.from(state.songDurations);
        updated[current.id] = dur;
        state = state.copyWith(duration: dur, songDurations: updated);
      }
    });
  }

  Future<void> playSong(Song song) async {
    final index = sampleSongs.indexWhere((s) => s.id == song.id);
    state = state.copyWith(
      currentSong: song,
      position: Duration.zero,
      duration: state.songDurations[song.id] ?? Duration.zero,
    );

    // Use the full queue so next/previous work in the background.
    // If the song isn't found in the full list, play it standalone.
    if (index >= 0) {
      await _handler.playFromQueue(sampleSongs, index);
    } else {
      await _handler.playSong(song);
    }
  }

  Future<void> playPlaylist(String playlistName, {int index = 0}) async {
    final playlistSongs = getPlaylistSongs(playlistName);
    if (playlistSongs.isEmpty) return;

    state = state.copyWith(
      currentSong: playlistSongs[index],
      position: Duration.zero,
      duration: state.songDurations[playlistSongs[index].id] ?? Duration.zero,
    );

    await _handler.playFromQueue(playlistSongs, index);
  }

  void togglePlayPause() {
    if (state.currentSong == null && sampleSongs.isNotEmpty) {
      playSong(sampleSongs.first);
      return;
    }

    if (state.isPlaying) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  void next() {
    _handler.skipToNext();
  }

  void previous() {
    _handler.skipToPrevious();
  }

  void seek(Duration position) {
    _handler.seek(position);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFavorite(String songId) {
    final updated = Set<String>.from(state.favoriteSongIds);
    if (updated.contains(songId)) {
      updated.remove(songId);
    } else {
      updated.add(songId);
    }
    state = state.copyWith(favoriteSongIds: updated);
  }

  bool isFavorite(String songId) => state.favoriteSongIds.contains(songId);

  List<Song> get favorites {
    return sampleSongs
        .where((song) => state.favoriteSongIds.contains(song.id))
        .toList();
  }

  void createPlaylist(String name) {
    if (name.isEmpty || state.playlistNames.contains(name)) return;
    final updatedNames = List<String>.from(state.playlistNames)..add(name);
    final updatedSongs = Map<String, List<String>>.from(state.playlistSongs);
    updatedSongs[name] = [];
    state = state.copyWith(
      playlistNames: updatedNames,
      playlistSongs: updatedSongs,
    );
  }

  void removePlaylist(String name) {
    final updatedNames = List<String>.from(state.playlistNames)..remove(name);
    final updatedSongs = Map<String, List<String>>.from(state.playlistSongs);
    updatedSongs.remove(name);
    state = state.copyWith(
      playlistNames: updatedNames,
      playlistSongs: updatedSongs,
    );
  }

  void addToPlaylist(String playlistName, String songId) {
    if (!state.playlistNames.contains(playlistName)) return;
    final updatedSongs = Map<String, List<String>>.from(state.playlistSongs);
    final list = List<String>.from(updatedSongs[playlistName] ?? []);
    if (!list.contains(songId)) {
      list.add(songId);
      updatedSongs[playlistName] = list;
      state = state.copyWith(playlistSongs: updatedSongs);
    }
  }

  void removeFromPlaylist(String playlistName, String songId) {
    if (!state.playlistNames.contains(playlistName)) return;
    final updatedSongs = Map<String, List<String>>.from(state.playlistSongs);
    final list = List<String>.from(updatedSongs[playlistName] ?? []);
    list.remove(songId);
    updatedSongs[playlistName] = list;
    state = state.copyWith(playlistSongs: updatedSongs);
  }

  List<Song> getPlaylistSongs(String playlistName) {
    final ids = state.playlistSongs[playlistName] ?? [];
    return sampleSongs.where((song) => ids.contains(song.id)).toList();
  }

  void setTheme(String themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }

  void setProfileName(String? name) {
    state = state.copyWith(profileName: name);
  }

  void toggleGridView() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  List<Song> get filteredSongs {
    final query = state.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return sampleSongs;

    return sampleSongs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final handler = ref.watch(audioHandlerProvider);
      return AudioPlayerNotifier(handler);
    });

// Provider for the shared AudioPlayerHandler instance.
// Falls back to a plain handler if audio_service isn't available.
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  return AudioPlayerHandler();
});

// --- 5. MAIN ENTRY POINT ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure the audio session for iOS/macOS so audio plays:
  // - With the silent/mute switch on (playback category)
  // - In the background
  // - With the screen locked (control center / lock screen controls)
  try {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
      ),
    );
  } catch (e) {
    debugPrint("AudioSession configure failed: $e");
  }

  AudioPlayerHandler? handler;
  try {
    // Initialize audio_service with our handler for background playback.
    // Use a timeout so the app always starts even if the service hangs.
    handler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.app.channel.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint("AudioService init failed, using local handler: $e");
  }

  try {
    await LiquidGlassWidgets.initialize().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint("LiquidGlassWidgets init failed: $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        if (handler != null) audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const MyAppWrapper(),
    ),
  );
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWidgets.wrap(child: const Myapp());
  }
}

// --- 6. SHARED MENU HELPERS ---
void _showMenu(BuildContext context) {
  final outerContext = context;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: const Text('Menu'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(sheetContext).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(
                outerContext,
              ).push(CupertinoPageRoute(builder: (_) => const PlaylistsPage()));
            });
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.music_note_list,
                color: CupertinoColors.systemBlue,
              ),
              SizedBox(width: 8),
              Text('Playlists'),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(sheetContext).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showInfo(outerContext, 'Settings', 'Settings coming soon.');
            });
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.settings, color: CupertinoColors.systemGrey),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

void _showInfo(BuildContext context, String title, String message) {
  showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

void _showProfileDialog(BuildContext context) {
  final audioNotifier = ProviderScope.containerOf(
    context,
  ).read(audioPlayerProvider.notifier);
  final currentProfileName = ProviderScope.containerOf(
    context,
  ).read(audioPlayerProvider).profileName;
  final nameController = TextEditingController(text: currentProfileName ?? '');

  showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Name:'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CupertinoTextField(
          controller: nameController,
          placeholder: 'Enter your name',
          autofocus: true,
          style: const TextStyle(color: CupertinoColors.white),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.22),
            ),
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        CupertinoDialogAction(
          child: const Text('Save'),
          onPressed: () {
            audioNotifier.setProfileName(nameController.text.trim());
            Navigator.of(dialogContext).pop();
          },
        ),
      ],
    ),
  );
}

// --- Playlist helper dialogs ---
void _showCreatePlaylistDialog(BuildContext context) {
  final audioNotifier = ProviderScope.containerOf(
    context,
  ).read(audioPlayerProvider.notifier);
  final nameController = TextEditingController();

  showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('New Playlist'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CupertinoTextField(
          controller: nameController,
          placeholder: 'Playlist name',
          autofocus: true,
          style: const TextStyle(color: CupertinoColors.white),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.22),
            ),
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        CupertinoDialogAction(
          child: const Text('Create'),
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              audioNotifier.createPlaylist(name);
            }
            Navigator.of(dialogContext).pop();
          },
        ),
      ],
    ),
  );
}

void _showSongMenu(BuildContext context, Song song) {
  final audioNotifier = ProviderScope.containerOf(
    context,
  ).read(audioPlayerProvider.notifier);
  final playlistNames = ProviderScope.containerOf(
    context,
  ).read(audioPlayerProvider).playlistNames;
  final outerContext = context;

  showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text(song.title),
      message: Text(song.artist),
      actions: [
        // Add to playlist action (if playlists exist)
        if (playlistNames.isNotEmpty)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAddToPlaylistDialog(outerContext, song);
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.add_circled,
                  color: CupertinoColors.systemBlue,
                ),
                SizedBox(width: 8),
                Text('Add to Playlist'),
              ],
            ),
          )
        else
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showCreatePlaylistDialog(outerContext);
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.add_circled,
                  color: CupertinoColors.systemBlue,
                ),
                SizedBox(width: 8),
                Text('Create Playlist'),
              ],
            ),
          ),
        // Favorite toggle
        CupertinoActionSheetAction(
          onPressed: () {
            audioNotifier.toggleFavorite(song.id);
            Navigator.of(sheetContext).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                audioNotifier.isFavorite(song.id)
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                color: CupertinoColors.systemPink,
              ),
              const SizedBox(width: 8),
              Text(
                audioNotifier.isFavorite(song.id)
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
              ),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

void _showAddToPlaylistDialog(BuildContext context, Song song) {
  final audioNotifier = ProviderScope.containerOf(
    context,
  ).read(audioPlayerProvider.notifier);
  final playlistNames = ProviderScope.containerOf(
    context,
  ).read(audioPlayerProvider).playlistNames;

  showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text('Add "${song.title}" to...'),
      actions: [
        for (final name in playlistNames)
          CupertinoActionSheetAction(
            onPressed: () {
              audioNotifier.addToPlaylist(name, song.id);
              Navigator.of(sheetContext).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.music_note_list,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

// --- 6. LIBRARY PAGE WIDGET ---
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final audioState = ref.watch(audioPlayerProvider);
    final songs = audioNotifier.filteredSongs;
    final favorites = audioNotifier.favorites;

    return _PurpleBackground(
      child: CustomScrollView(
        slivers: [
          // Top bar: hamburger menu + profile icon
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: CupertinoIcons.bars,
                    onPressed: () => _showMenu(context),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: CupertinoIcons.person_fill,
                    onPressed: () => _showProfileDialog(context),
                  ),
                ],
              ),
            ),
          ),

          // Large "Library" title with "+" icon
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Library',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                  _RoundIconButton(
                    icon: CupertinoIcons.add,
                    onPressed: () => _showCreatePlaylistDialog(context),
                  ),
                ],
              ),
            ),
          ),

          // Section 1: Favorites
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _LibrarySectionHeader(title: 'Favorites'),
            ),
          ),
          if (favorites.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'No favorites yet.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _GlassPanel(
                  child: Column(
                    children: favorites.asMap().entries.map((entry) {
                      final index = entry.key;
                      final song = entry.value;
                      final isSelected = audioState.currentSong?.id == song.id;
                      final duration =
                          audioState.songDurations[song.id] ?? Duration.zero;

                      return _LibrarySongRow(
                        song: song,
                        duration: _formatDuration(duration),
                        isSelected: isSelected,
                        isPlaying: isSelected && audioState.isPlaying,
                        showDivider: index < favorites.length - 1,
                        onPlay: () {
                          if (isSelected) {
                            audioNotifier.togglePlayPause();
                          } else {
                            audioNotifier.playSong(song);
                          }
                        },
                        onMenu: () => _showSongMenu(context, song),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Section 2: Your Playlists
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _LibrarySectionHeader(
                title: 'Your Playlists',
                onAdd: () => _showCreatePlaylistDialog(context),
              ),
            ),
          ),
          if (audioState.playlistNames.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'No playlists yet. Tap + to create one.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _GlassPanel(
                  child: Column(
                    children: audioState.playlistNames.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final name = entry.value;
                      final playlistSongs = audioNotifier.getPlaylistSongs(
                        name,
                      );
                      final isLast =
                          index < audioState.playlistNames.length - 1;

                      return Container(
                        decoration: BoxDecoration(
                          border: isLast
                              ? Border(
                                  bottom: BorderSide(
                                    color: CupertinoColors.white.withValues(
                                      alpha: 0.10,
                                    ),
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) =>
                                    PlaylistDetailPage(playlistName: name),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: CupertinoColors.systemPink.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                child: const Icon(
                                  CupertinoIcons.music_note_list,
                                  color: CupertinoColors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      playlistSongs.isEmpty
                                          ? 'No songs yet'
                                          : '${playlistSongs.length} songs',
                                      style: const TextStyle(
                                        color: CupertinoColors.systemGrey,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: CupertinoColors.systemGrey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Section 3: All Songs
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All Songs',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _RoundIconButton(
                    icon: audioState.isGridView
                        ? CupertinoIcons.list_bullet
                        : CupertinoIcons.square_grid_2x2,
                    size: 42,
                    onPressed: () => audioNotifier.toggleGridView(),
                  ),
                ],
              ),
            ),
          ),

          // All songs: list view (default) or grid view
          if (audioState.isGridView)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
              sliver: SliverToBoxAdapter(
                child: songs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'No songs found',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: songs.map((song) {
                          final isSelected =
                              audioState.currentSong?.id == song.id;
                          return _LibrarySongCard(
                            song: song,
                            isSelected: isSelected,
                            isPlaying: isSelected && audioState.isPlaying,
                            onPlay: () {
                              if (isSelected) {
                                audioNotifier.togglePlayPause();
                              } else {
                                audioNotifier.playSong(song);
                              }
                            },
                            onMenu: () => _showSongMenu(context, song),
                          );
                        }).toList(),
                      ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
              sliver: SliverToBoxAdapter(
                child: _GlassPanel(
                  child: Column(
                    children: [
                      if (songs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'No songs found',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        ...songs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final song = entry.value;
                          final isSelected =
                              audioState.currentSong?.id == song.id;
                          final duration =
                              audioState.songDurations[song.id] ??
                              Duration.zero;

                          return _LibrarySongRow(
                            song: song,
                            duration: _formatDuration(duration),
                            isSelected: isSelected,
                            isPlaying: isSelected && audioState.isPlaying,
                            showDivider: index < songs.length - 1,
                            onPlay: () {
                              if (isSelected) {
                                audioNotifier.togglePlayPause();
                              } else {
                                audioNotifier.playSong(song);
                              }
                            },
                            onMenu: () => _showSongMenu(context, song),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Shared visual components ---
class _PurpleBackground extends StatelessWidget {
  final Widget child;

  const _PurpleBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF650C43), Color(0xFF3B153E), Color(0xFF160D18)],
          stops: [0.0, 0.46, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  const _RoundIconButton({required this.icon, this.onPressed, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed ?? () {},
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.white.withValues(alpha: 0.045),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: CupertinoColors.white, size: size * 0.48),
      ),
      minimumSize: Size(0, 0),
    );
  }
}

class _LibrarySectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;

  const _LibrarySectionHeader({required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onAdd != null)
          _RoundIconButton(
            icon: CupertinoIcons.add,
            size: 36,
            onPressed: onAdd,
          ),
      ],
    );
  }
}

class _LibrarySongRow extends StatelessWidget {
  final Song song;
  final String duration;
  final bool isSelected;
  final bool isPlaying;
  final bool showDivider;
  final VoidCallback onPlay;
  final VoidCallback onMenu;

  const _LibrarySongRow({
    required this.song,
    required this.duration,
    required this.isSelected,
    required this.isPlaying,
    required this.showDivider,
    required this.onPlay,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? CupertinoColors.systemPink.withValues(alpha: 0.12)
            : CupertinoColors.transparent,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: CupertinoColors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
              )
            : null,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        onPressed: onPlay,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                song.thumbnailPath,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 62,
                  height: 62,
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.25),
                  child: const Icon(
                    CupertinoIcons.music_note,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 19,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onMenu,
              child: const Icon(
                CupertinoIcons.line_horizontal_3,
                color: CupertinoColors.white,
                size: 25,
              ),
              minimumSize: Size(34, 34),
            ),
          ],
        ),
      ),
    );
  }
}

// Grid tile card for the grid view layout
class _LibrarySongCard extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onMenu;

  const _LibrarySongCard({
    required this.song,
    required this.isSelected,
    required this.isPlaying,
    required this.onPlay,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    // Compute a fixed tile width so two tiles fit side-by-side.
    final tileWidth = (MediaQuery.of(context).size.width - 40 - 12) / 2;

    return Container(
      width: tileWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isSelected
            ? CupertinoColors.systemPink.withValues(alpha: 0.18)
            : CupertinoColors.white.withValues(alpha: 0.075),
        border: Border.all(
          color: isSelected
              ? CupertinoColors.systemPink.withValues(alpha: 0.6)
              : CupertinoColors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art (tappable to play)
          GestureDetector(
            onTap: onPlay,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      song.thumbnailPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: CupertinoColors.systemGrey.withValues(
                          alpha: 0.25,
                        ),
                        child: const Icon(
                          CupertinoIcons.music_note,
                          color: CupertinoColors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    // Play/pause overlay indicator
                    if (isSelected)
                      Container(
                        color: CupertinoColors.black.withValues(alpha: 0.35),
                        child: Center(
                          child: Icon(
                            isPlaying
                                ? CupertinoIcons.pause_circle_fill
                                : CupertinoIcons.play_circle_fill,
                            color: CupertinoColors.white,
                            size: 44,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Track title + artist + menu
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onMenu,
                  child: const Icon(
                    CupertinoIcons.line_horizontal_3,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  minimumSize: Size(28, 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 6.5 PLAYLIST PAGES ---
class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final audioState = ref.watch(audioPlayerProvider);

    return _PurpleBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: CupertinoIcons.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: CupertinoIcons.add,
                    onPressed: () => _showCreatePlaylistDialog(context),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Playlists',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  if (audioState.playlistNames.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'No playlists yet.\nTap + to create one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    )
                  else
                    _GlassPanel(
                      child: Column(
                        children: audioState.playlistNames.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final name = entry.value;
                          final songs = audioNotifier.getPlaylistSongs(name);
                          final isLast =
                              index < audioState.playlistNames.length - 1;

                          return Container(
                            decoration: BoxDecoration(
                              border: isLast
                                  ? Border(
                                      bottom: BorderSide(
                                        color: CupertinoColors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                            ),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (_) =>
                                        PlaylistDetailPage(playlistName: name),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: CupertinoColors.systemPink
                                          .withValues(alpha: 0.35),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.music_note_list,
                                      color: CupertinoColors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          songs.isEmpty
                                              ? 'No songs yet'
                                              : '${songs.length} songs',
                                          style: const TextStyle(
                                            color: CupertinoColors.systemGrey,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_right,
                                    color: CupertinoColors.systemGrey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistDetailPage extends ConsumerWidget {
  final String playlistName;

  const PlaylistDetailPage({super.key, required this.playlistName});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final audioState = ref.watch(audioPlayerProvider);
    final playlistSongs = audioNotifier.getPlaylistSongs(playlistName);

    return _PurpleBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: CupertinoIcons.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: CupertinoColors.systemPink.withValues(alpha: 0.35),
                    ),
                    child: const Icon(
                      CupertinoIcons.music_note_list,
                      color: CupertinoColors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlistName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlistSongs.isEmpty
                              ? 'No songs yet'
                              : '${playlistSongs.length} songs',
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: playlistSongs.isEmpty
                        ? null
                        : () => audioNotifier.playPlaylist(playlistName),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CupertinoColors.systemPink.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  if (playlistSongs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'No songs in this playlist yet.\nTap the ⋯ menu on a song\nand choose "Add to Playlist".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    )
                  else
                    _GlassPanel(
                      child: Column(
                        children: playlistSongs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final song = entry.value;
                          final isSelected =
                              audioState.currentSong?.id == song.id;
                          final duration =
                              audioState.songDurations[song.id] ??
                              Duration.zero;

                          return _LibrarySongRow(
                            song: song,
                            duration: _formatDuration(duration),
                            isSelected: isSelected,
                            isPlaying: isSelected && audioState.isPlaying,
                            showDivider: index < playlistSongs.length - 1,
                            onPlay: () {
                              if (isSelected) {
                                audioNotifier.togglePlayPause();
                              } else {
                                audioNotifier.playPlaylist(
                                  playlistName,
                                  index: index,
                                );
                              }
                            },
                            onMenu: () => _showSongMenu(context, song),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 7. HOME PAGE WIDGET (glassmorphism design matching Library) ---
class HomePage extends ConsumerWidget {
  final ScrollController? scrollController;

  const HomePage({super.key, this.scrollController});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioNotifier = ref.read(audioPlayerProvider.notifier);
    final audioState = ref.watch(audioPlayerProvider);
    final songs = audioNotifier.filteredSongs;

    // Group songs by artist, preserving first-seen order.
    final artistOrder = <String>[];
    final songsByArtist = <String, List<Song>>{};
    for (final song in songs) {
      if (!songsByArtist.containsKey(song.artist)) {
        artistOrder.add(song.artist);
        songsByArtist[song.artist] = [];
      }
      songsByArtist[song.artist]!.add(song);
    }

    return _PurpleBackground(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Top bar: hamburger menu + profile icon
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: CupertinoIcons.bars,
                    onPressed: () => _showMenu(context),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: CupertinoIcons.person_fill,
                    onPressed: () => _showProfileDialog(context),
                  ),
                ],
              ),
            ),
          ),

          // Large "Music" title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Music',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.music_note_2,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Compact promo/header card, styled like the reference.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _GlassPanel(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: CupertinoColors.systemPink.withValues(
                            alpha: 0.65,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.waveform,
                          color: CupertinoColors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your music',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Listen to your local collection',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Artists',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          if (songs.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.only(top: 40),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'No songs found',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          // Artist sections with glass panels
          for (final artist in artistOrder) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        songsByArtist[artist]!.first.imagePath,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 54,
                          height: 54,
                          color: CupertinoColors.systemGrey.withValues(
                            alpha: 0.3,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        artist,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${songsByArtist[artist]!.length} songs',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _GlassPanel(
                  child: Column(
                    children: songsByArtist[artist]!.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final song = entry.value;
                      final selected = audioState.currentSong?.id == song.id;

                      return _HomeSongRow(
                        song: song,
                        duration: _formatDuration(
                          audioState.songDurations[song.id] ?? Duration.zero,
                        ),
                        selected: selected,
                        playing: selected && audioState.isPlaying,
                        showDivider: index < songsByArtist[artist]!.length - 1,
                        onPlay: () {
                          if (selected) {
                            audioNotifier.togglePlayPause();
                          } else {
                            audioNotifier.playSong(song);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],

          const SliverPadding(
            padding: EdgeInsets.only(bottom: 150),
            sliver: SliverToBoxAdapter(child: SizedBox()),
          ),
        ],
      ),
    );
  }
}

class _HomeSongRow extends StatelessWidget {
  final Song song;
  final String duration;
  final bool selected;
  final bool playing;
  final bool showDivider;
  final VoidCallback onPlay;

  const _HomeSongRow({
    required this.song,
    required this.duration,
    required this.selected,
    required this.playing,
    required this.showDivider,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? CupertinoColors.systemPink.withValues(alpha: 0.12)
            : CupertinoColors.transparent,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: CupertinoColors.white.withValues(alpha: 0.09),
                  width: 1,
                ),
              )
            : null,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        onPressed: onPlay,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                song.thumbnailPath,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 48,
                  height: 48,
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.3),
                  child: const Icon(
                    CupertinoIcons.music_note,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Text(
              duration,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 9),
            Icon(
              playing
                  ? CupertinoIcons.pause_circle_fill
                  : CupertinoIcons.play_circle_fill,
              color: CupertinoColors.activeBlue,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

// --- 8. MAIN APP WIDGET ---
class Myapp extends ConsumerStatefulWidget {
  const Myapp({super.key});

  @override
  ConsumerState<Myapp> createState() => _MyappState();
}

class _MyappState extends ConsumerState<Myapp> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  double bottomPill = 120;
  double leftRightPill = 20;

  int selectedIndex = 0;
  bool isSearchActive = false;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(isScroll);
    _searchController.addListener(() {
      ref
          .read(audioPlayerProvider.notifier)
          .updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void isScroll() {
    if (_scrollController.offset > 10) {
      setState(() {
        isSearchActive = true;
        if (!isExpanded) {
          bottomPill = 42;
          leftRightPill = 80;
        }
      });
    } else {
      setState(() {
        isSearchActive = false;
        bottomPill = 120;
        leftRightPill = 20;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);
    final audioNotifier = ref.read(audioPlayerProvider.notifier);

    final List<Widget> pages = [
      HomePage(scrollController: _scrollController),
      const LibraryPage(),
    ];

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CupertinoColors.black,
        primaryColor: CupertinoColors.label,
      ),
      home: GlassScaffold(
        bodyOverlays: [
          AnimatedPositioned(
            bottom: bottomPill,
            left: leftRightPill,
            right: leftRightPill,
            duration: const Duration(milliseconds: 300),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.075),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => audioNotifier.togglePlayPause(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      audioState.currentSong?.title ??
                                          'No Music Selected',
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDuration(audioState.position),
                                      style: const TextStyle(
                                        color: CupertinoColors.systemGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (audioState.currentSong != null) {
                                  audioNotifier.toggleFavorite(
                                    audioState.currentSong!.id,
                                  );
                                }
                              },
                              child: Icon(
                                audioState.currentSong != null &&
                                        audioNotifier.isFavorite(
                                          audioState.currentSong!.id,
                                        )
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                color: CupertinoColors.systemPink,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 4),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => audioNotifier.previous(),
                              child: const Icon(
                                CupertinoIcons.backward_fill,
                                color: CupertinoColors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 4),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => audioNotifier.togglePlayPause(),
                              child: Icon(
                                audioState.isPlaying
                                    ? CupertinoIcons.pause_circle_fill
                                    : CupertinoIcons.play_circle_fill,
                                color: CupertinoColors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 4),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => audioNotifier.next(),
                              child: const Icon(
                                CupertinoIcons.forward_fill,
                                color: CupertinoColors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        // SeekBar - compact progress bar with dark theme styling
                        if (audioState.duration > Duration.zero) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoSlider(
                                  value: audioState.position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                        0.0,
                                        audioState.duration.inMilliseconds
                                            .toDouble(),
                                      ),
                                  min: 0,
                                  max: audioState.duration.inMilliseconds
                                      .toDouble(),
                                  activeColor: CupertinoColors.white,
                                  onChanged: (value) {
                                    audioNotifier.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(audioState.duration),
                                style: const TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottomBar: GlassTabBar.searchable(
          settings: LiquidGlassSettings(blur: 0.5),
          isSearchActive: isSearchActive,
          tabs: [
            GlassTab(icon: const Icon(CupertinoIcons.home)),
            GlassTab(icon: const Icon(CupertinoIcons.music_albums)),
          ],
          selectedIndex: selectedIndex,
          onTabSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          searchConfig: GlassSearchBarConfig(
            expandWhenActive: isExpanded,
            controller: _searchController,
            onSearchToggle: (active) {
              setState(() {
                isSearchActive = active;
                isExpanded = active;
                if (!active) {
                  _searchController.clear();
                  audioNotifier.updateSearchQuery('');
                }
                if (bottomPill == 42) {
                  bottomPill = 120;
                  leftRightPill = 20;
                }
              });
            },
          ),
        ),
        body: SafeArea(child: pages[selectedIndex]),
      ),
    );
  }
}
