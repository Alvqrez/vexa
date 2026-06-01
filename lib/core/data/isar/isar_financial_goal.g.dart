// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_financial_goal.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarFinancialGoalCollection on Isar {
  IsarCollection<IsarFinancialGoal> get isarFinancialGoals => this.collection();
}

const IsarFinancialGoalSchema = CollectionSchema(
  name: r'IsarFinancialGoal',
  id: -3973751247765045455,
  properties: {
    r'colorValue': PropertySchema(
      id: 0,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'completed': PropertySchema(
      id: 1,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'current': PropertySchema(
      id: 2,
      name: r'current',
      type: IsarType.double,
    ),
    r'deadline': PropertySchema(
      id: 3,
      name: r'deadline',
      type: IsarType.dateTime,
    ),
    r'goalId': PropertySchema(
      id: 4,
      name: r'goalId',
      type: IsarType.string,
    ),
    r'iconCodePoint': PropertySchema(
      id: 5,
      name: r'iconCodePoint',
      type: IsarType.long,
    ),
    r'target': PropertySchema(
      id: 6,
      name: r'target',
      type: IsarType.double,
    ),
    r'title': PropertySchema(
      id: 7,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _isarFinancialGoalEstimateSize,
  serialize: _isarFinancialGoalSerialize,
  deserialize: _isarFinancialGoalDeserialize,
  deserializeProp: _isarFinancialGoalDeserializeProp,
  idName: r'id',
  indexes: {
    r'goalId': IndexSchema(
      id: 2738626632585230611,
      name: r'goalId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'goalId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarFinancialGoalGetId,
  getLinks: _isarFinancialGoalGetLinks,
  attach: _isarFinancialGoalAttach,
  version: '3.1.0+1',
);

int _isarFinancialGoalEstimateSize(
  IsarFinancialGoal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.goalId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarFinancialGoalSerialize(
  IsarFinancialGoal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.colorValue);
  writer.writeBool(offsets[1], object.completed);
  writer.writeDouble(offsets[2], object.current);
  writer.writeDateTime(offsets[3], object.deadline);
  writer.writeString(offsets[4], object.goalId);
  writer.writeLong(offsets[5], object.iconCodePoint);
  writer.writeDouble(offsets[6], object.target);
  writer.writeString(offsets[7], object.title);
}

IsarFinancialGoal _isarFinancialGoalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarFinancialGoal();
  object.colorValue = reader.readLong(offsets[0]);
  object.completed = reader.readBool(offsets[1]);
  object.current = reader.readDouble(offsets[2]);
  object.deadline = reader.readDateTime(offsets[3]);
  object.goalId = reader.readString(offsets[4]);
  object.iconCodePoint = reader.readLong(offsets[5]);
  object.id = id;
  object.target = reader.readDouble(offsets[6]);
  object.title = reader.readString(offsets[7]);
  return object;
}

P _isarFinancialGoalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarFinancialGoalGetId(IsarFinancialGoal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarFinancialGoalGetLinks(
    IsarFinancialGoal object) {
  return [];
}

void _isarFinancialGoalAttach(
    IsarCollection<dynamic> col, Id id, IsarFinancialGoal object) {
  object.id = id;
}

extension IsarFinancialGoalByIndex on IsarCollection<IsarFinancialGoal> {
  Future<IsarFinancialGoal?> getByGoalId(String goalId) {
    return getByIndex(r'goalId', [goalId]);
  }

  IsarFinancialGoal? getByGoalIdSync(String goalId) {
    return getByIndexSync(r'goalId', [goalId]);
  }

  Future<bool> deleteByGoalId(String goalId) {
    return deleteByIndex(r'goalId', [goalId]);
  }

  bool deleteByGoalIdSync(String goalId) {
    return deleteByIndexSync(r'goalId', [goalId]);
  }

  Future<List<IsarFinancialGoal?>> getAllByGoalId(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'goalId', values);
  }

  List<IsarFinancialGoal?> getAllByGoalIdSync(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'goalId', values);
  }

  Future<int> deleteAllByGoalId(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'goalId', values);
  }

  int deleteAllByGoalIdSync(List<String> goalIdValues) {
    final values = goalIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'goalId', values);
  }

  Future<Id> putByGoalId(IsarFinancialGoal object) {
    return putByIndex(r'goalId', object);
  }

  Id putByGoalIdSync(IsarFinancialGoal object, {bool saveLinks = true}) {
    return putByIndexSync(r'goalId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByGoalId(List<IsarFinancialGoal> objects) {
    return putAllByIndex(r'goalId', objects);
  }

  List<Id> putAllByGoalIdSync(List<IsarFinancialGoal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'goalId', objects, saveLinks: saveLinks);
  }
}

extension IsarFinancialGoalQueryWhereSort
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QWhere> {
  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarFinancialGoalQueryWhere
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QWhereClause> {
  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhereClause>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhereClause>
      goalIdEqualTo(String goalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'goalId',
        value: [goalId],
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterWhereClause>
      goalIdNotEqualTo(String goalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [],
              upper: [goalId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [goalId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [goalId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'goalId',
              lower: [],
              upper: [goalId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IsarFinancialGoalQueryFilter
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QFilterCondition> {
  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      completedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completed',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      currentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'current',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      currentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'current',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      currentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'current',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      currentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'current',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      deadlineEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deadline',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      deadlineGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deadline',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      deadlineLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deadline',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      deadlineBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deadline',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'goalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'goalId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      goalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'goalId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      iconCodePointEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iconCodePoint',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
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

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      targetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'target',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      targetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'target',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      targetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'target',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      targetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'target',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension IsarFinancialGoalQueryObject
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QFilterCondition> {}

extension IsarFinancialGoalQueryLinks
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QFilterCondition> {}

extension IsarFinancialGoalQuerySortBy
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QSortBy> {
  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'current', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'current', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByDeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByDeadlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByIconCodePointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension IsarFinancialGoalQuerySortThenBy
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QSortThenBy> {
  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'current', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByCurrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'current', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByDeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByDeadlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deadline', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByIconCodePointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconCodePoint', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension IsarFinancialGoalQueryWhereDistinct
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct> {
  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct>
      distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct>
      distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct>
      distinctByCurrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'current');
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct>
      distinctByDeadline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deadline');
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct>
      distinctByGoalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct>
      distinctByIconCodePoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconCodePoint');
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct>
      distinctByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'target');
    });
  }

  QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension IsarFinancialGoalQueryProperty
    on QueryBuilder<IsarFinancialGoal, IsarFinancialGoal, QQueryProperty> {
  QueryBuilder<IsarFinancialGoal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarFinancialGoal, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<IsarFinancialGoal, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<IsarFinancialGoal, double, QQueryOperations> currentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'current');
    });
  }

  QueryBuilder<IsarFinancialGoal, DateTime, QQueryOperations>
      deadlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deadline');
    });
  }

  QueryBuilder<IsarFinancialGoal, String, QQueryOperations> goalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalId');
    });
  }

  QueryBuilder<IsarFinancialGoal, int, QQueryOperations>
      iconCodePointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconCodePoint');
    });
  }

  QueryBuilder<IsarFinancialGoal, double, QQueryOperations> targetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'target');
    });
  }

  QueryBuilder<IsarFinancialGoal, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
