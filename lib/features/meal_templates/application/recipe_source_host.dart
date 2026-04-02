String? recipeSourceHost(String? recipeUrl) {
  if (recipeUrl == null || recipeUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(recipeUrl);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  return uri.host.replaceFirst(RegExp(r'^www\.'), '');
}
