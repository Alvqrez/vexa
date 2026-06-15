// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_subscription.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSubscriptionCollection on Isar {
  IsarCollection<IsarSubscription> get isarSubscriptions => this.collection();
}

const IsarSubscriptionSchema = CollectionSchema(
  name: r'IsarSubscription',
  id: -1005276068565913477,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.string,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.double,
    ),
    r'categoryStr': PropertySchema(
      id: 2,
      name: r'categoryStr',
      type: IsarType.string,
    ),
    r'colorValue': PropertySchema(
      id: 3,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'frequencyStr': PropertySchema(
      id: 4,
      name: r'frequencyStr',
      type: IsarType.string,
    ),
    r'iconCodePoint': PropertySchema(
      id: 5,
      name: r'iconCodePoint',
      type: IsarType.long,
    ),
    r'isActive': PropertySchema(
      id: 6,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 7,
      name: r'name',
      type: IsarType.string,
    ),
    r'nextBillingDate': PropertySchema(
      id: 8,
      name: r'nextBillingDate',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(
      id: 9,
      name: r'note',
      type: IsarType.string,
    ),
    r'subscriptionId': PropertySchema(
      id: 10,
      name: r'subscriptionId',
      type: IsarType.string,
    )
  },
  estimateSize: _isarSubscriptionEstimateSize,
  serialize: _isarSubscriptionSerialize,
  deserialize: _isarSubscriptionDeserialize,
  deserializeProp: _isarSubscriptionDeserializeProp,
  idName: r'id',
  indexes: {
    r'subscriptionId': IndexSchema(
      id: -2440251475652077983,
      name: r'subscriptionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'subscriptionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarSubscriptionGetId,
  getLinks: _isarSubscriptionGetLinks,
  attach: _isarSubscriptionAttach,
  version: '3.1.0+1',
);

int _isarSubscriptionEstimateSize(
  IsarSubscription object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accountId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.categoryStr.length * 3;
  bytesCount += 3 + object.frequencyStr.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.subscriptionId.length * 3;
  return bytesCount;
}

void _isarSubscriptionSerialize(
  IsarSubscription object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountId);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeString(offsets[2], object.categoryStr);
  writer.writeLong(offsets[3], object.colorValue);
  writer.writeString(offsets[4], object.frequencyStr);
  writer.writeLong(offsets[5], object.iconCodePoint);
  writer.writeBool(offsets[6], object.isActive);
  writer.writeString(offsets[7], object.name);
  writer.writeDateTime(offsets[8], object.nextBillingDate);
  writer.writeString(offsets[9], object.note);
  writer.writeString(offsets[10], object.subscriptionId);
}

IsarSubscription _isarSubscriptionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSubscription();
  object.accountId = reader.readStringOrNull(offsets[0]);
  object.amount = reader.readDouble(offsets[1]);
  object.categoryStr = reader.readString(offsets[2]);
  object.colorValue = reader.readLong(offsets[3]);
  object.frequencyStr = reader.readString(offsets[4]);
  object.iconCodePoint = reader.readLong(offsets[5]);
  object.id = id;
  object.isActive = reader.readBool(offsets[6]);
  object.name = reader.readString(offsets[7]);
  object.nextBillingDate = reader.readDateTime(offsets[8]);
  object.note = reader.readStringOrNull(offsets[9]);
  object.subscriptionId = reader.readString(offsets[10]);
  return object;
}

P _isarSubscriptionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSubscriptionGetId(IsarSubscription object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarSubscriptionGetLinks(IsarSubscription object) {
  return [];
}

void _isarSubscriptionAttach(
    IsarCollection<dynamic> col, Id id, IsarSubscription object) {
  object.id = id;
}

extension IsarSubscriptionByIndex on IsarCollection<IsarSubscription> {
  Future<IsarSubscription?> getBySubscriptionId(String subscriptionId) {
    return getByIndex(r'subscriptionId', [subscriptionId]);
  }

  IsarSubscription? getBySubscriptionIdSync(String subscriptionId) {
    return getByIndexSync(r'subscriptionId', [subscriptionId]);
  }

  Future<bool> deleteBySubscriptionId(String subscriptionId) {
    return deleteByIndex(r'subscriptionId', [subscriptionId]);
  }

  bool deleteBySubscriptionIdSync(String subscriptionId) {
    return deleteByIndexSync(r'subscriptionId', [subscriptionId]);
  }

  Future<List<IsarSubscription?>> getAllBySubscriptionId(
      List<String> subscriptionIdValues) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'subscriptionId', values);
  }

  List<IsarSubscription?> getAllBySubscriptionIdSync(
      List<String> subscriptionIdValues) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'subscriptionId', values);
  }

  Future<int> deleteAllBySubscriptionId(List<String> subscriptionIdValues) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'subscriptionId', values);
  }

  int deleteAllBySubscriptionIdSync(List<String> subscriptionIdValues) {
    final values = subscriptionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'subscriptionId', values);
  }

  Future<Id> putBySubscriptionId(IsarSubscription object) {
    return putByIndex(r'subscriptionId', object);
  }

  Id putBySubscriptionIdSync(IsarSubscription object, {bool saveLinks = true}) {
    return putByIndexSync(r'subscriptionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySubscriptionId(List<IsarSubscription> objects) {
    return putAllByIndex(r'subscriptionId', objects);
  }

  List<Id> putAllBySubscriptionIdSync(List<IsarSubscription> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'subscriptionId', objects, saveLinks: saveLinks);
  }
}

extension IsarSubscriptionQueryWhereSort
    on QueryBuilder<IsarSubscription, IsarSubscription, QWhere> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSubscriptionQueryWhere
    on QueryBuilder<IsarSubscription, IsarSubscription, QWhereClause> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      subscriptionIdEqualTo(String subscriptionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'subscriptionId',
        value: [subscriptionId],
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterWhereClause>
      subscriptionIdNotEqualTo(String subscriptionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subscriptionId',
              lower: [],
              upper: [subscriptionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subscriptionId',
              lower: [subscriptionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subscriptionId',
              lower: [subscriptionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subscriptionId',
              lower: [],
              upper: [subscriptionId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarSubscriptionQueryFilter
    on QueryBuilder<IsarSubscription, IsarSubscription, QFilterCondition> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountId',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accountId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accountId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      accountIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accountId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrEqualTo(
    String value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrGreaterThan(
    String value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrLessThan(
    String value, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoryStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoryStr',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoryStr',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      categoryStrIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoryStr',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequencyStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequencyStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequencyStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequencyStr',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'frequencyStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'frequencyStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'frequencyStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'frequencyStr',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequencyStr',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      frequencyStrIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'frequencyStr',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      iconCodePointEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconCodePoint',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
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

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      nextBillingDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextBillingDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subscriptionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterFilterCondition>
      subscriptionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subscriptionId',
        value: '',
      ));
    });
  }
}

extension IsarSubscriptionQueryObject
    on QueryBuilder<IsarSubscription, IsarSubscription, QFilterCondition> {}

extension IsarSubscriptionQueryLinks
    on QueryBuilder<IsarSubscription, IsarSubscription, QFilterCondition> {}

extension IsarSubscriptionQuerySortBy
    on QueryBuilder<IsarSubscription, IsarSubscription, QSortBy> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByCategoryStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByCategoryStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByFrequencyStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyStr', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByFrequencyStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyStr', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIconCodePointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNextBillingDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortBySubscriptionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      sortBySubscriptionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.desc);
    });
  }
}

extension IsarSubscriptionQuerySortThenBy
    on QueryBuilder<IsarSubscription, IsarSubscription, QSortThenBy> {
  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByCategoryStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByCategoryStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoryStr', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByFrequencyStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyStr', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByFrequencyStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequencyStr', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIconCodePointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNextBillingDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenBySubscriptionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.asc);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QAfterSortBy>
      thenBySubscriptionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionId', Sort.desc);
    });
  }
}

extension IsarSubscriptionQueryWhereDistinct
    on QueryBuilder<IsarSubscription, IsarSubscription, QDistinct> {
  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByAccountId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByCategoryStr({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoryStr', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByFrequencyStr({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequencyStr', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconCodePoint');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextBillingDate');
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSubscription, IsarSubscription, QDistinct>
      distinctBySubscriptionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionId',
          caseSensitive: caseSensitive);
    });
  }
}

extension IsarSubscriptionQueryProperty
    on QueryBuilder<IsarSubscription, IsarSubscription, QQueryProperty> {
  QueryBuilder<IsarSubscription, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSubscription, String?, QQueryOperations>
      accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<IsarSubscription, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations>
      categoryStrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoryStr');
    });
  }

  QueryBuilder<IsarSubscription, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations>
      frequencyStrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequencyStr');
    });
  }

  QueryBuilder<IsarSubscription, int, QQueryOperations>
      iconCodePointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconCodePoint');
    });
  }

  QueryBuilder<IsarSubscription, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<IsarSubscription, DateTime, QQueryOperations>
      nextBillingDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextBillingDate');
    });
  }

  QueryBuilder<IsarSubscription, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<IsarSubscription, String, QQueryOperations>
      subscriptionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionId');
    });
  }
}
