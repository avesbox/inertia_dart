import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:serinus/serinus.dart';

class AssetController extends Controller {
  AssetController() : super('/assets') {
    on(Route.get('/**'), _serveAsset);
    on(Route(path: '/**', method: HttpMethod.head), _serveAsset);
  }

  Future<Uint8List> _serveAsset(RequestContext context) async {
    final relativePath = context.params['**']?.toString() ?? '';
    if (relativePath.isEmpty || _containsUnsafeSegments(relativePath)) {
      throw NotFoundException('Asset not found');
    }

    final assetFile = File('client/dist/assets/$relativePath');
    if (!assetFile.existsSync() ||
        assetFile.statSync().type != FileSystemEntityType.file) {
      throw NotFoundException('Asset not found');
    }

    context.res.contentType = ContentType.parse(
      lookupMimeType(assetFile.path) ?? 'application/octet-stream',
    );
    context.res.contentLength = assetFile.lengthSync();
    context.res.headers[HttpHeaders.cacheControlHeader] =
        'public, max-age=31536000, immutable';

    if (context.request.method == HttpMethod.head) {
      return Uint8List(0);
    }

    return assetFile.readAsBytes();
  }

  bool _containsUnsafeSegments(String path) {
    return path.split('/').any((segment) => segment == '..' || segment == '.');
  }
}
