import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

typedef HotelSelected = void Function(String hotelName);

class HotelSearchField extends StatefulWidget {
  const HotelSearchField({
    super.key,
    required this.allHotels,
    required this.onSearch,
    this.searching = false,
  });

  final List<String> allHotels;
  final HotelSelected onSearch;
  final bool searching;

  @override
  State<HotelSearchField> createState() => _HotelSearchFieldState();
}

class _HotelSearchFieldState extends State<HotelSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _hideDropdown();
      });
    } else {
      _updateSuggestions(_controller.text);
    }
  }

  void _onTextChanged() => _updateSuggestions(_controller.text);

  void _updateSuggestions(String text) {
    final q = text.trim().toLowerCase();
    final matches = q.isEmpty
        ? widget.allHotels
        : widget.allHotels.where((n) => n.toLowerCase().contains(q)).toList();
    setState(() => _suggestions = matches.take(8).toList());
    if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
      _showDropdownOverlay();
    } else {
      _hideDropdown();
    }
  }

  void _showDropdownOverlay() {
    _removeOverlay();
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showDropdown = true);
  }

  void _hideDropdown() {
    _removeOverlay();
    if (mounted) setState(() => _showDropdown = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectHotel(String name) {
    _controller.text = name;
    _hideDropdown();
    _focusNode.unfocus();
    widget.onSearch(name);
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 400;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 12,
            color: AppColors.surface,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(AppDecor.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final name = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.chipBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hotel, size: 18, color: AppColors.accent),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onTap: () => _selectHotel(name),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search Disneyland-area hotels…',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showDropdown && _suggestions.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, color: AppColors.textSecondary),
                  onPressed: _hideDropdown,
                ),
              if (widget.searching)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) widget.onSearch(text);
                    },
                  ),
                ),
            ],
          ),
        ),
        onSubmitted: widget.onSearch,
        onTap: () => _updateSuggestions(_controller.text),
      ),
    );
  }
}
