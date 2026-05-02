import 'package:flutter/material.dart';
import 'package:tvplus/models/lista_de_canales.dart';
import 'package:tvplus/player_status.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tvplus/main.dart';
import 'package:go_router/go_router.dart';
import 'package:tvplus/integrations/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:tvplus/globals/app_state.dart';
import 'package:tvplus/components/hls_video_player.dart';

@NowaGenerated()
class TvPlus extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const TvPlus({super.key});

  @override
  State<TvPlus> createState() {
    return _TvPlusState();
  }
}

@NowaGenerated()
class _TvPlusState extends State<TvPlus> with TickerProviderStateMixin {
  listaDeCanales? selectedChannel;

  Future<List<listaDeCanales>>? _channelsFuture;

  int? _selectedChannelId;

  String playerMessage = 'Iniciando...';

  PlayerStatus playerStatus = PlayerStatus.connecting;

  int _refreshCount = 0;

  late AnimationController _pulseController;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await sharedPrefs.remove('bypass_auth');
    if (mounted) {
      context.go('/login');
    }
  }

  Color _getBadgeColor() {
    switch (playerStatus) {
      case PlayerStatus.connecting:
        return Colors.yellow;
      case PlayerStatus.retrying:
        return Colors.orange;
      case PlayerStatus.webFallback:
        return Colors.blue;
      case PlayerStatus.playing:
        return Colors.red;
      case PlayerStatus.error:
        return Colors.grey;
    }
  }

  void _refreshChannels() {
    setState(() {
      _channelsFuture = SupabaseService().getAllCanales();
      playerMessage = 'Recargando...';
      _refreshCount++;
    });
  }

  void _handleSystemUI(bool isLandscape) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isLandscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    return OrientationBuilder(
      builder: (context, orientation) {
        final bool isLandscape = orientation == Orientation.landscape;
        _handleSystemUI(isLandscape);
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            top: !isLandscape,
            bottom: !isLandscape,
            left: !isLandscape,
            right: !isLandscape,
            child: DataBuilder<List<listaDeCanales>>(
              future: _channelsFuture,
              builder: (context, channels) {
                if (channels == null || channels.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Conectando...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }
                final currentChannel = channels.firstWhere(
                  (c) => c.id == appState.selectedChannelId,
                  orElse: () => channels[0],
                );
                final String? rawUrl = currentChannel.url_stream;
                final String streamUrl = (rawUrl != null && rawUrl!.isNotEmpty)
                    ? rawUrl!
                    : 'https://livetrx01.vodgc.net/eltrecetv/index.m3u8';
                final String? logoUrl =
                    (currentChannel.logo != null &&
                        currentChannel.logo!.isNotEmpty)
                    ? currentChannel.logo
                    : null;
                final playerWidget = AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: isLandscape
                          ? BorderRadius.zero
                          : BorderRadius.circular(16),
                      boxShadow: isLandscape
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: -5,
                                offset: const Offset(0, 0),
                              ),
                            ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: HlsVideoPlayer(
                      key: ValueKey('${streamUrl}_${_refreshCount}'),
                      url: streamUrl,
                      logoUrl: logoUrl,
                      userAgent: currentChannel.userAgent,
                      referer: currentChannel.referer,
                      onStatusChanged: (status, message) {
                        if (mounted) {
                          setState(() {
                            playerStatus = status;
                            playerMessage = message;
                          });
                        }
                      },
                    ),
                  ),
                );
                if (isLandscape) {
                  return Container(
                    color: Colors.black,
                    child: Center(child: playerWidget),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: playerWidget,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentChannel.nombre ?? 'Canal sin nombre',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Señal: ${currentChannel.categoria ?? 'En vivo'}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FadeTransition(
                                      opacity:
                                          playerStatus ==
                                              PlayerStatus.connecting
                                          ? _pulseController
                                          : const AlwaysStoppedAnimation(1),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getBadgeColor().withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: _getBadgeColor().withValues(
                                              alpha: 0.5,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: _getBadgeColor(),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              playerMessage.toUpperCase(),
                                              style: TextStyle(
                                                color: _getBadgeColor(),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _refreshChannels,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white54,
                                ),
                              ),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'GUÍA DE CANALES',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          final isSelected = currentChannel.id == channel.id;
                          final String channelLogo =
                              (channel.logo != null && channel.logo!.isNotEmpty)
                              ? channel.logo!
                              : 'https://images.unsplash.com/photo-1594908900066-3f47337549d8?w=400';
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onChannelSelected(channel),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.white10,
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(channelLogo),
                                    fit: BoxFit.cover,
                                    colorFilter: isSelected
                                        ? null
                                        : ColorFilter.mode(
                                            Colors.black.withValues(alpha: 0.3),
                                            BlendMode.darken,
                                          ),
                                  ),
                                ),
                                child: Container(
                                  alignment: Alignment.bottomCenter,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        isSelected
                                            ? Colors.red.withValues(alpha: 0.7)
                                            : Colors.black87,
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    channel.nombre ?? 'Canal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _channelsFuture = SupabaseService().getAllCanales();
    _loadPreferences();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  Future<void> _loadPreferences() async {
    final lastId = sharedPrefs.getInt('last_channel_id');
    if (lastId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppState.of(context, listen: false).setSelectedChannelId(lastId);
        }
      });
    }
  }

  void _onChannelSelected(listaDeCanales channel) {
    AppState.of(context, listen: false).setSelectedChannel(channel);
    if (mounted) {
      setState(() {
        playerMessage = 'Cargando...';
        playerStatus = PlayerStatus.connecting;
      });
    }
    sharedPrefs.setInt('last_channel_id', channel.id ?? 0);
    SupabaseService().updateLastChannel(channel.id ?? 0);
  }
}
