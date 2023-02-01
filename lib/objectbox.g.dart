// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again:
// With a Flutter package, run `flutter pub run build_runner build`.
// With a Dart package, run `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart';
import 'package:objectbox_flutter_libs/objectbox_flutter_libs.dart';

import 'productObject.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <ModelEntity>[
  ModelEntity(
      id: const IdUid(1, 5008384711528315705),
      name: 'productObject',
      lastPropertyId: const IdUid(3, 3276619982039123702),
      flags: 0,
      properties: <ModelProperty>[
        ModelProperty(
            id: const IdUid(1, 1365682112609899515),
            name: 'id',
            type: 6,
            flags: 1),
        ModelProperty(
            id: const IdUid(2, 5354522813894601113),
            name: 'name',
            type: 9,
            flags: 0),
        ModelProperty(
            id: const IdUid(3, 3276619982039123702),
            name: 'ingredients',
            type: 9,
            flags: 0)
      ],
      relations: <ModelRelation>[],
      backlinks: <ModelBacklink>[])
];

/// Open an ObjectBox store with the model declared in this file.
Future<Store> openStore(
        {String? directory,
        int? maxDBSizeInKB,
        int? fileMode,
        int? maxReaders,
        bool queriesCaseSensitiveDefault = true,
        String? macosApplicationGroup}) async =>
    Store(getObjectBoxModel(),
        directory: directory ?? (await defaultStoreDirectory()).path,
        maxDBSizeInKB: maxDBSizeInKB,
        fileMode: fileMode,
        maxReaders: maxReaders,
        queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
        macosApplicationGroup: macosApplicationGroup);

/// ObjectBox model definition, pass it to [Store] - Store(getObjectBoxModel())
ModelDefinition getObjectBoxModel() {
  final model = ModelInfo(
      entities: _entities,
      lastEntityId: const IdUid(1, 5008384711528315705),
      lastIndexId: const IdUid(0, 0),
      lastRelationId: const IdUid(0, 0),
      lastSequenceId: const IdUid(0, 0),
      retiredEntityUids: const [],
      retiredIndexUids: const [],
      retiredPropertyUids: const [],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, EntityDefinition>{
    productObject: EntityDefinition<productObject>(
        model: _entities[0],
        toOneRelations: (productObject object) => [],
        toManyRelations: (productObject object) => {},
        getId: (productObject object) => object.id,
        setId: (productObject object, int id) {
          object.id = id;
        },
        objectToFB: (productObject object, fb.Builder fbb) {
          final nameOffset =
              object.name == null ? null : fbb.writeString(object.name!);
          final ingredientsOffset = object.ingredients == null
              ? null
              : fbb.writeString(object.ingredients!);
          fbb.startTable(4);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, nameOffset);
          fbb.addOffset(2, ingredientsOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = productObject()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..name = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 6)
            ..ingredients = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 8);

          return object;
        })
  };

  return ModelDefinition(model, bindings);
}

/// [productObject] entity fields to define ObjectBox queries.
class productObject_ {
  /// see [productObject.id]
  static final id =
      QueryIntegerProperty<productObject>(_entities[0].properties[0]);

  /// see [productObject.name]
  static final name =
      QueryStringProperty<productObject>(_entities[0].properties[1]);

  /// see [productObject.ingredients]
  static final ingredients =
      QueryStringProperty<productObject>(_entities[0].properties[2]);
}
