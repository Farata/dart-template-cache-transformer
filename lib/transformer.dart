library template_cache.transformer;

import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:template_cache_transformer/src/generator.dart';
import 'package:template_cache_transformer/src/options.dart';
import 'package:template_cache_transformer/src/writer.dart';


/// The template cahce trasnformer that internally runs several phases:
///
/// 1. Extracts all URIs referenced by AngularDart @Component annotation's
///    templateUrl and cssUrl properites. Reads the content of all referenced
///    files, creates a template cache entry for each of them, concatenates
///    template cache entries, writes the result into an HTML file.
///
/// 2. If an entry point is specified (usually `web/index.html`), writes all the
///    template cache entries into that file, right before closing `</head>`
///    tag.
class TemplateCacheTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  TemplateCacheTransformerGroup(TransformOptions options)
      : phases = _createPhases(options);

  TemplateCacheTransformerGroup.asPlugin(BarbackSettings settings)
      : this(_parseSettings(settings.configuration));
}

/// Parses and validates configured transformer's settings, provides default
/// values for [TransformOptions].
TransformOptions _parseSettings(Map args) {
  return new TransformOptions(
    entryPoint: _readStringValue(args, 'entry_point'),
    sdkDirectory: _readStringValue(args, 'dart_sdk', dartSdkDirectory));
}

String _readStringValue(Map args, String name, [String defaultValue]) {
  var value = args[name];
  if (value == null) return defaultValue;
  if (value is! String) {
    print('TemplateCache transformer parameter "$name" value must be a string');
    return defaultValue;
  }
  return value;
}

/// Dynamically creates phases for the main transformer based on the configured
/// settings in pubspec.yaml.
List<List<Transformer>> _createPhases(TransformOptions options) {
  var phases = [
    [new TemplateCacheGenerator(new Resolvers(options.sdkDirectory))]
  ];

  // Add [TemplateCacheWriter] only if an entry point is specified in
  // pubspec.yaml. Otherwise user is responsible for loading generated template
  // cache into the application.
  if (options.entryPoint != null) {
    phases.add([new TemplateCacheWriter(options.entryPoint)]);
  }

  return phases;
}
