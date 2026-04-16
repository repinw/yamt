import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_image_tile.dart';

const _imageUrl = 'https://images.example.com/item.png';
const _fallbackEmoji = '🍽️';

final Uint8List _transparentPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8'
  '/w8AAgMBgJGDnzsAAAAASUVORK5CYII=',
);

class _MockImageCacheManager extends Mock implements ImageCacheManager {}

Widget _buildHarness(Widget child, {double devicePixelRatio = 1}) {
  return MediaQuery(
    data: MediaQueryData(devicePixelRatio: devicePixelRatio),
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Stream<FileResponse> _imageResponseStream(String url, List<int> bytes) async* {
  final file = MemoryFileSystem().systemTempDirectory.childFile('test.png');
  await file.writeAsBytes(bytes);
  yield FileInfo(
    file,
    FileSource.Online,
    DateTime.now().add(const Duration(days: 1)),
    url,
  );
}

void _stubImageSuccess(_MockImageCacheManager cacheManager, String url) {
  when(
    () => cacheManager.getImageFile(
      url,
      key: any(named: 'key'),
      headers: any(named: 'headers'),
      withProgress: any(named: 'withProgress'),
      maxHeight: any(named: 'maxHeight'),
      maxWidth: any(named: 'maxWidth'),
    ),
  ).thenAnswer((_) => _imageResponseStream(url, _transparentPngBytes));
}

void _stubImageFailure(_MockImageCacheManager cacheManager, String url) {
  when(
    () => cacheManager.getImageFile(
      url,
      key: any(named: 'key'),
      headers: any(named: 'headers'),
      withProgress: any(named: 'withProgress'),
      maxHeight: any(named: 'maxHeight'),
      maxWidth: any(named: 'maxWidth'),
    ),
  ).thenAnswer((_) => Stream<FileResponse>.error(Exception('network failed')));
}

void main() {
  testWidgets(
    'renders AppCachedNetworkImage and resolves cache dimensions from dpr',
    (tester) async {
      final cacheManager = _MockImageCacheManager();
      CachedNetworkImageProvider.defaultCacheManager = cacheManager;
      _stubImageSuccess(cacheManager, _imageUrl);

      await tester.pumpWidget(
        _buildHarness(
          const InventoryItemImageTile(imageUrl: _imageUrl),
          devicePixelRatio: 2.5,
        ),
      );

      final imageFinder = find.byType(AppCachedNetworkImage);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<AppCachedNetworkImage>(imageFinder);
      expect(imageWidget.imageUrl, _imageUrl);
      expect(imageWidget.cacheWidth, 140);
      expect(imageWidget.cacheHeight, 140);
    },
  );

  testWidgets('renders fallback emoji when imageUrl is null', (tester) async {
    await tester.pumpWidget(_buildHarness(const InventoryItemImageTile()));

    expect(find.byType(AppCachedNetworkImage), findsNothing);
    expect(find.text(_fallbackEmoji), findsOneWidget);
  });

  testWidgets('renders fallback emoji when image loading fails', (
    tester,
  ) async {
    final cacheManager = _MockImageCacheManager();
    CachedNetworkImageProvider.defaultCacheManager = cacheManager;
    _stubImageFailure(cacheManager, _imageUrl);

    await tester.pumpWidget(
      _buildHarness(const InventoryItemImageTile(imageUrl: _imageUrl)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_fallbackEmoji), findsOneWidget);
  });
}
