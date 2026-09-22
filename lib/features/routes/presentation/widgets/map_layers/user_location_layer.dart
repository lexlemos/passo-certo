import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/active_navigation_bloc.dart';

/// Camada isolada de alta performance para o marcador do usuário em navegação ativa.
///
/// Escuta estritamente alterações de coordenadas do GPS para evitar rebuilds do [FlutterMap].
class UserLocationLayer extends StatelessWidget {
  const UserLocationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveNavigationBloc, ActiveNavigationState>(
      buildWhen: (prev, curr) {
        final prevPos = prev.lastPosition;
        final currPos = curr.lastPosition;
        if (prev.isActive != curr.isActive) return true;
        if (prevPos == null && currPos == null) return false;
        if (prevPos == null || currPos == null) return true;
        return prevPos.latitude != currPos.latitude ||
            prevPos.longitude != currPos.longitude;
      },
      builder: (context, activeState) {
        if (!activeState.isActive || activeState.lastPosition == null) {
          return const SizedBox.shrink();
        }

        final latLng = LatLng(
          activeState.lastPosition!.latitude,
          activeState.lastPosition!.longitude,
        );

        return MarkerLayer(
          markers: [
            Marker(
              point: latLng,
              width: 44,
              height: 44,
              child: const _PulsingUserLocationMarker(),
            ),
          ],
        );
      },
    );
  }
}

/// Componente de pino pulsante com gerenciamento de ciclo de vida seguro contra vazamentos de memória.
class _PulsingUserLocationMarker extends StatefulWidget {
  const _PulsingUserLocationMarker();

  @override
  State<_PulsingUserLocationMarker> createState() =>
      __PulsingUserLocationMarkerState();
}

class __PulsingUserLocationMarkerState extends State<_PulsingUserLocationMarker>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  bool _isObserving = false;

  @override
  void initState() {
    super.initState();
    try {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
    } catch (_) {}

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (_controller != null) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.6,
      ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOut));
      _fadeAnimation = Tween<double>(
        begin: 0.6,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOut));
      _controller!.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_controller!.isAnimating) {
        _controller!.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_controller!.isAnimating) {
        _controller!.repeat();
      }
    }
  }

  @override
  void dispose() {
    if (_isObserving) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
      _isObserving = false;
    }
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null ||
        _scaleAnimation == null ||
        _fadeAnimation == null) {
      return Icon(
        Icons.navigation,
        color: AppTheme.mintGreen,
        size: 32,
        semanticLabel: 'Sua posição atual na navegação',
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation!.value,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.mintGreen.withValues(
                    alpha: _fadeAnimation!.value.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
            Icon(
              Icons.navigation,
              color: AppTheme.mintGreen,
              size: 32,
              semanticLabel: 'Sua posição atual na navegação',
            ),
          ],
        );
      },
    );
  }
}
