import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar_state.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_controller.dart';

export 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_controller.dart';

/// Shared search field with an optional built-in voice search button.
class TextVoiceSearchBar extends StatefulWidget {
  /// Creates shared text search bar with optional voice search.
  const new({
    required this.controller,
    required this.label,
    required this.fieldKey,
    super.key,
    this.voiceButtonKey,
    this.clearButtonKey,
    this.focusNode,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.isSearching = false,
    this.startVoiceSearchOnMount = false,
    this.onTap,
    this.onChanged,
    this.voiceSearchService,
    this.voiceSearchController,
    this.onVoiceSearchPressed,
    this.onClearPressed,
    this.trailingActions = const <Widget>[],
    this.hintText,
    this.clearTooltip,
    this.prefixIcon,
    this.useCompactSurface = false,
  });

  /// Controller that holds current search text.
  final TextEditingController controller;

  /// Localized field label.
  final String label;

  /// Widget key for the text field.
  final Key fieldKey;

  /// Optional key for the voice button.
  final Key? voiceButtonKey;

  /// Optional key for the clear button.
  final Key? clearButtonKey;

  /// Optional focus node for the text field.
  final FocusNode? focusNode;

  /// Whether text field should be read-only.
  final bool readOnly;

  /// Whether text field should autofocus.
  final bool autofocus;

  /// Whether all controls are enabled.
  final bool enabled;

  /// Whether a search request is currently in progress.
  final bool isSearching;

  /// Whether voice search should auto-start after first frame.
  final bool startVoiceSearchOnMount;

  /// Optional tap callback for the text field.
  final VoidCallback? onTap;

  /// Optional change callback for the text field.
  final ValueChanged<String>? onChanged;

  /// Optional internal voice search service implementation.
  final VoiceSearchService? voiceSearchService;

  /// Optional controller for external coordination.
  final TextVoiceSearchController? voiceSearchController;

  /// Optional external voice button handler.
  final VoidCallback? onVoiceSearchPressed;

  /// Optional custom clear handler.
  final VoidCallback? onClearPressed;

  /// Extra trailing actions rendered after the voice button.
  final List<Widget> trailingActions;

  /// Optional hint text shown inside the field instead of a floating label.
  final String? hintText;

  /// Optional clear button tooltip.
  final String? clearTooltip;

  /// Optional custom prefix icon for field.
  final Widget? prefixIcon;

  /// Whether to render the compact filled search style.
  final bool useCompactSurface;

  @override
  State<TextVoiceSearchBar> createState() => TextVoiceSearchBarState();
}
