import 'dart:async';

import 'package:collection/collection.dart';
import 'package:macros/macros.dart';

final _dartCore = Uri.parse('dart:core');

/// A macro for data classes.
///
/// Generates equals, hashCode and copyWith methods.
macro class Data implements ClassDeclarationsMacro, ClassDefinitionMacro {
  /// The default constructor for [Data] macro;
  const Data();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final fields = await builder.fieldsOf(clazz);

    if (fields.isEmpty) {
      return builder.reportError(
        'The target class should have at least one field',
        clazz.asDiagnosticTarget,
      );
    }

    final constructors = await builder.constructorsOf(clazz);

    final constructor = constructors.first;

    if (constructor.identifier.name != '') {
      return builder.reportError(
        'Data classes should contain exactly one default constructor',
        constructor.asDiagnosticTarget,
      );
    }

    await [
      _declareCopyWith(builder, clazz, fields),
      _declareEquals(builder),
      _declareHashCode(builder),
    ].wait;
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder typeBuilder,
  ) async {
    final methods = await typeBuilder.methodsOf(clazz);
    final copyWith = methods.firstWhereOrNull(
      (method) => method.identifier.name == 'copyWith',
    );
    final equals = methods.firstWhereOrNull(
      (method) => method.identifier.name == '==',
    );
    final hashCode = methods.firstWhereOrNull(
      (method) => method.identifier.name == 'hashCode',
    );

    if (copyWith == null || equals == null || hashCode == null) {
      return;
    }

    final fields = await typeBuilder.fieldsOf(clazz);

    await [
      _buildCopyWith(typeBuilder, copyWith, clazz, fields),
      _buildEquals(typeBuilder, equals, clazz, fields),
      _buildHashCode(typeBuilder, hashCode, clazz, fields),
    ].wait;
  }

  Future<void> _buildCopyWith(
    TypeDefinitionBuilder typeBuilder,
    MethodDeclaration copyWith,
    ClassDeclaration clazz,
    List<FieldDeclaration> fields,
  ) async {
    final (builder, objectType) = await (
      typeBuilder.buildMethod(copyWith.identifier),
      // ignore: deprecated_member_use
      typeBuilder.resolveIdentifier(_dartCore, 'Object'),
    ).wait;

    builder.augment(
      FunctionBodyCode.fromParts(
        [
          '=> ',
          '({',
          for (final field in fields) ...[
            objectType,
            if (field.type.isNullable) '?',
            ' ${field.identifier.name} = _undefined,',
          ],
          '}) =>',
          '${clazz.identifier.name}(',
          for (final field in fields) ..._buildCopyWithField(field),
          ');',
        ],
      ),
      docComments: CommentCode.fromParts(
        [
          '/// Creates a copy of [${clazz.identifier.name}] with replaced values.',
        ],
      ),
    );
  }

  String _buildFieldComparator(FieldDeclaration field) {
    final name = field.identifier.name;

    return ' && other.$name == $name';
  }

  Future<void> _buildEquals(
    TypeDefinitionBuilder typeBuilder,
    MethodDeclaration equals,
    ClassDeclaration clazz,
    List<FieldDeclaration> fields,
  ) async {
    final builder = await typeBuilder.buildMethod(equals.identifier);

    builder.augment(
      FunctionBodyCode.fromParts(
        [
          '=> ',
          'other is ${clazz.identifier.name} ',
          for (final field in fields) _buildFieldComparator(field),
          ';',
        ],
      ),
    );
  }

  Future<void> _buildHashCode(
    TypeDefinitionBuilder typeBuilder,
    MethodDeclaration hashCode,
    ClassDeclaration clazz,
    List<FieldDeclaration> fields,
  ) async {
    final (builder, objectType) = await (
      typeBuilder.buildMethod(hashCode.identifier),
      // ignore: deprecated_member_use
      typeBuilder.resolveIdentifier(_dartCore, 'Object'),
    ).wait;

    builder.augment(
      FunctionBodyCode.fromParts(
        [
          '=> ',
          objectType,
          '.hashAll([',
          for (final field in fields) ' ${field.identifier.name},',
          ']);',
        ],
      ),
    );
  }

  Future<void> _declareCopyWith(
    MemberDeclarationBuilder builder,
    ClassDeclaration clazz,
    List<FieldDeclaration> fields,
  ) async {
    // ignore: deprecated_member_use
    final objectType = await builder.resolveIdentifier(_dartCore, 'Object');
    builder
      ..declareInLibrary(
        DeclarationCode.fromParts(
          ['const _undefined = ', objectType, '();'],
        ),
      )
      ..declareInType(
        DeclarationCode.fromParts(
          [
            'external ${clazz.identifier.name} Function({',
            for (final field in fields) ..._buildCopyWithFieldArgument(field),
            '}) get copyWith;',
          ],
        ),
      );
  }

  Future<void> _declareEquals(
    MemberDeclarationBuilder builder,
  ) async {
    final (boolType, objectType) = await (
      // TODO: replace this with its substitute
      // ignore: deprecated_member_use
      builder.resolveIdentifier(_dartCore, 'bool'),
      // ignore: deprecated_member_use
      builder.resolveIdentifier(_dartCore, 'Object'),
    ).wait;

    builder.declareInType(
      DeclarationCode.fromParts([
        'external ',
        boolType,
        ' operator ==(',
        objectType,
        ' other);',
      ]),
    );
  }

  Future<void> _declareHashCode(
    MemberDeclarationBuilder builder,
  ) async {
    // TODO: replace this with its substitute
    // ignore: deprecated_member_use
    final intType = await builder.resolveIdentifier(_dartCore, 'int');

    builder.declareInType(
      DeclarationCode.fromParts([
        'external ',
        intType,
        ' get hashCode;',
      ]),
    );
  }
}

List<Object> _buildTypeDeclaration(NamedTypeAnnotation type) {
  final typeArguments = type.typeArguments;

  return [
    type.identifier,
    if (type.isNullable) '?',
    if (typeArguments.isNotEmpty) ...[
      '<',
      for (final argument in typeArguments)
        ..._buildTypeDeclaration(argument as NamedTypeAnnotation),
      '>',
    ],
  ];
}

List<Object> _buildCopyWithFieldArgument(FieldDeclaration field) {
  final type = field.type as NamedTypeAnnotation;

  return [..._buildTypeDeclaration(type), ' ${field.identifier.name},'];
}

List<Object> _buildCopyWithField(FieldDeclaration field) {
  final name = field.identifier.name;
  final type = _buildTypeDeclaration(field.type as NamedTypeAnnotation);

  return ['$name: $name == _undefined ? this.$name : $name as ', ...type, ','];
}

extension on MemberDeclarationBuilder {
  void reportError(String message, DeclarationDiagnosticTarget target) {
    report(
      Diagnostic(
        DiagnosticMessage(
          message,
          target: target,
        ),
        Severity.error,
      ),
    );
  }
}
