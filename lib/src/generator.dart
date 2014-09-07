library template_cache.transformer.generator;

import 'dart:async';
import 'package:analyzer/src/generated/element.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/assets.dart' show uriToAssetId;
import 'package:code_transformers/resolver.dart';


/// Pub transformer which finds all AngularDart components used within
/// application, reads the content of files referenced by templateUrl and cssUrl
/// properties, creates a template cache entry for each of the files,
/// concatenates them and writes the result into an HTML file.
class TemplateCacheGenerator extends Transformer with ResolverTransformer {
  static const String CACHE_PATH = 'web/template_cache.generated.html';

  TemplateCacheGenerator(Resolvers resolvers) {
    this.resolvers = resolvers;
  }

  @override
  applyResolver(Transform transform, Resolver resolver) {
    // Find all URIs used within the application.
    var uris = resolver.libraries
      .where((lib) => !lib.isInSdk)
      .expand((lib) => lib.units)
      .map(_extractUris)
      .expand((_) => _);

    // For each found URI create a template cache entry, concatenate the result
    // and write it to the [CACHE_PATH].
    return Future.wait(uris.map((uri) => _templateFor(uri, transform)))
        .then((cacheEntries) {
          var id = new AssetId(transform.primaryInput.id.package, CACHE_PATH);
          transform.addOutput(new Asset.fromString(id, cacheEntries.join()));
        });
  }

  /// Creates a template cache entry for the file referenced by [uri].
  Future _templateFor(String uri, Transform transform) {
    final logger = transform.logger;

    // TODO: figure out how to get Span/SourceSpan object for the element.
    var id = uriToAssetId(transform.primaryInput.id, uri, logger, null);
    return transform.hasInput(id).then((hasInput) {
      if (!hasInput) {
        logger.warning("Can't find asset ${id.path}.", asset: id);
        return new Future.value();
      }

      logger.info('Adding asset "$uri" to the template cache.', asset: id);
      return transform.readInputAsString(id).then((content) =>
        '<template id="$uri" type="text/ng-template">$content</template>');
    });
  }

  /// Runs [_AngularComponentsVisitor] through the compilation [unit].
  List<String> _extractUris(CompilationUnitElement unit) {
    var visitor = new _AngularComponentsVisitor();
    unit.visitChildren(visitor);
    return visitor.assetUris;
  }
}

/// Visits all Angular components and collects all URIs referenced by @Component
/// annotation's templateUrl and cssUrl properties.
class _AngularComponentsVisitor extends RecursiveElementVisitor {
  final List<String> assetUris = [];

  @override
  void visitAngularComponentElement(AngularComponentElement element) {
    if (element.styleUri != null) assetUris.add(element.styleUri);
    if (element.templateUri != null) assetUris.add(element.templateUri);
  }
}
