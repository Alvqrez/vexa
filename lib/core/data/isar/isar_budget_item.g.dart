// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_budget_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarBudgetItemCollection on Isar {
  IsarCollection<IsarBudgetItem> get isarBudgetItems => this.collection();
}

const IsarBudgetItemSchema = CollectionSchema(
  name: r'IsarBudgetItem',
  id: -2259659219011360659,
  properties: {
    r'budgetId': PropertySchema(
      id: 0,
      name: r'budgetId',
      type: IsarType.string,
    ),
    r'categoryStr': PropertySchema(
      id: 1,
      name: r'categoryStr',
      type: IsarType.string,
    ),
    r'colorValue': PropertySchema(
      id: 2,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'iconCodePoint': PropertySchema(
      id: 3,
      name: r'iconCodePoint',
      type: IsarType.long,
    ),
    r'limit': PropertySchema(
      id: 4,
      name: r'limit',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _isarBudgetItemEstimateSize,
  serialize: _isarBudgetItemSerialize,
  deserialize: _isarBudgetItemDeserialize,
  deserializeProp: _isarBudgetItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'budgetId': IndexSchema(
      id: 1954233043883219522,
      name: r'budgetId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'budgetId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarBudgetItemGetId,
  getLinks: _isarBudgetItemGetLinks,
  attach: _isarBudgetItemAttach,
  version: '3.1.0+1',
);

int _isarBudgetItemEstimateSize(
  IsarBudgetItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.budgetId.length * 3;
  {
    final value = object.categoryStr;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _isarBudgetItemSerialize(
  IsarBudgetItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.budgetId);
  writer.writeString(offsets[1], object.categoryStr);
  writer.writeLong(offsets[2], object.colorValue);
  writer.writeLong(offsets[3], object.iconCodePoint);
  writer.writeDouble(offsets[4], object.limit);
  writer.writeString(offsets[5], object.name);
}

IsarBudgetItem _isarBudgetItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarBudgetItem();
  object.budgetId = reader.readString(offsets[0]);
  object.categoryStr = reader.readStringOrNull(offsets[1]);
  object.colorValue = reader.readLong(offsets[2]);
  object.iconCodePoint = reader.readLong(offsets[3]);
  object.id = id;
  object.limit = reader.readDouble(offsets[4]);
  object.name = reader.readString(offsets[5]);
  return object;
}

P _isarBudgetItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarBudgetItemGetId(IsarBudgetItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarBudgetItemGetLinks(IsarBudgetItem object) {
  return [];
}

void _isarBudgetItemAttach(
    IsarCollection<dynamic> col, Id id, IsarBudgetItem object) {
  object.id = id;
}

extension IsarBudgetItemByIndex on IsarCollection<IsarBudgetItem> {
  Future<IsarBudgetItem?> getByBudgetId(String budgetId) {
    return getByIndex(r'budgetId', [budgetId]);
  }

  IsarBudgetItem? getByBudgetIdSync(String budgetId) {
    return getByIndexSync(r'budgetId', [budgetId]);
  }

  Future<bool> deleteByBudgetId(String budgetId) {
    return deleteByIndex(r'budgetId', [budgetId]);
  }

  bool deleteByBudgetIdSync(String budgetId) {
    return deleteByIndexSync(r'budgetId', [budgetId]);
  }

  Future<List<IsarBudgetItem?>> getAllByBudgetId(List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'budgetId', values);
  }

  List<IsarBudgetItem?> getAllByBudgetIdSync(List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'budgetId', values);
  }

  Future<int> deleteAllByBudgetId(List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'budgetId', values);
  }

  int deleteAllByBudgetIdSync(List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'budgetId', values);
  }

  Future<Id> putByBudgetId(IsarBudgetItem object) {
    return putByIndex(r'budgetId', object);
  }

  Id putByBudgetIdSync(IsarBudgetItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'budgetId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBudgetId(List<IsarBudgetItem> objects) {
    return putAllByIndex(r'budgetId', objects);
  }

  List<Id> putAllByBudgetIdSync(List<IsarBudgetItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'budgetId', objects, saveLinks: saveLinks);
  }
}

extension IsarBudgetItemQueryWhereSort
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QWhere> {
  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarBudgetItemQueryWhere
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QWhereClause> {
  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhereClause>
      budgetIdEqualTo(String budgetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'budgetId',
        value: [budgetId],
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterWhereClause>
      budgetIdNotEqualTo(String budgetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [],
              upper: [budgetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [budgetId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [budgetId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [],
              upper: [budgetId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarBudgetItemQueryFilter
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QFilterCondition> {
  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'budgetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'budgetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budgetId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      budgetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'budgetId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoryStr',
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoryStr',
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoryStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoryStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoryStr',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoryStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoryStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryStr',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryStr',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      categoryStrIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryStr',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      colorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      colorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      colorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      iconCodePointEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconCodePoint',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      iconCodePointGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iconCodePoint',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      iconCodePointLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iconCodePoint',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      iconCodePointBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iconCodePoint',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      limitEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'limit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      limitGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'limit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      limitLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'limit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      limitBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'limit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension IsarBudgetItemQueryObject
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QFilterCondition> {}

extension IsarBudgetItemQueryLinks
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QFilterCondition> {}

extension IsarBudgetItemQuerySortBy
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QSortBy> {
  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> sortByBudgetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      sortByBudgetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      sortByCategoryStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      sortByCategoryStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      sortByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      sortByIconCodePointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> sortByLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> sortByLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension IsarBudgetItemQuerySortThenBy
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QSortThenBy> {
  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> thenByBudgetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      thenByBudgetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      thenByCategoryStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      thenByCategoryStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      thenByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy>
      thenByIconCodePointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> thenByLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> thenByLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.desc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension IsarBudgetItemQueryWhereDistinct
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QDistinct> {
  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QDistinct> distinctByBudgetId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'budgetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QDistinct> distinctByCategoryStr(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryStr', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QDistinct>
      distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QDistinct>
      distinctByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconCodePoint');
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QDistinct> distinctByLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'limit');
    });
  }

  QueryBuilder<IsarBudgetItem, IsarBudgetItem, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension IsarBudgetItemQueryProperty
    on QueryBuilder<IsarBudgetItem, IsarBudgetItem, QQueryProperty> {
  QueryBuilder<IsarBudgetItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarBudgetItem, String, QQueryOperations> budgetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'budgetId');
    });
  }

  QueryBuilder<IsarBudgetItem, String?, QQueryOperations>
      categoryStrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryStr');
    });
  }

  QueryBuilder<IsarBudgetItem, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<IsarBudgetItem, int, QQueryOperations> iconCodePointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconCodePoint');
    });
  }

  QueryBuilder<IsarBudgetItem, double, QQueryOperations> limitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'limit');
    });
  }

  QueryBuilder<IsarBudgetItem, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}
