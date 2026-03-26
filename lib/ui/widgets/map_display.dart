import 'package:flutter/material.dart';

class MapDisplay extends StatefulWidget {
  final String imageUrl;
  final String? placeholderText;
  final VoidCallback? onReload;
  final double aspectRatio;
  final Widget? overlay;
  const MapDisplay({
    super.key,
    required this.imageUrl,
    this.placeholderText,
    this.onReload,
    required this.aspectRatio,
    this.overlay,
  });

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  late String _currentUrl;
  bool _loading = true;
  bool _error = false;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.imageUrl;
    _precacheImage(_currentUrl);
  }

  @override
  void didUpdateWidget(MapDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _currentUrl = widget.imageUrl;
      _precacheImage(_currentUrl);
    }
  }

  void _precacheImage(String url) {
    setState(() {
      _loading = true;
      _error = false;
    });
    final img = Image.network(url);
    final stream = img.image.resolve(const ImageConfiguration());
    _imageStream = stream;
    stream.addListener(
      ImageStreamListener(
        (info, _) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = false;
              _imageInfo = info;
            });
          }
        },
        onError: (err, stack) {
          if (mounted) {
            setState(() {
              _loading = false;
              _error = true;
              _imageInfo = null;
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _imageStream = null;
    _imageInfo = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error)
            Center(
              child: Text(
                widget.placeholderText ?? 'Waiting for Match...',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          if (!_loading && !_error && _imageInfo != null)
            RawImage(image: _imageInfo!.image, fit: BoxFit.cover),
          if (widget.overlay != null) widget.overlay!,
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Ververs map image',
              onPressed: widget.onReload,
            ),
          ),
        ],
      ),
    );
  }
}
