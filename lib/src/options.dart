library template_cache.transformer.options;

import 'package:barback/barback.dart';


/// Options used by [TemplateCacheTransformer].
class TransformOptions {
  /// Path to an HTML file that will be used as an entry point for the
  /// application. Must be specified in [AssetId] format. Example:
  ///
  ///   my_app_package_name|web/index.html
  ///
  /// If specified, [TemplateCacheWriter] writes generated template cache right
  /// before closing `</head>` tag. Otherwise, [TemplateCacheWriter] is not
  /// executed at all and user is responsible for loading generated template
  /// cahce file into the application.
  final String entryPoint;

  /// Path to the Dart SDK directory, for resolving Dart libraries.
  final String sdkDirectory;

  TransformOptions({this.entryPoint, this.sdkDirectory}) {
    if (entryPoint != null) {
      try {
        new AssetId.parse(entryPoint);
      } on FormatException catch (e) {
        throw new ArgumentError('entryPoint format is invalid: ${e.message}.'
          'Example value: "my_app_package_name|web/index.html"');
      }
    }

    if (sdkDirectory == null) {
      throw new ArgumentError('sdkDirectory must be provided.');
    }
  }
}
