[fragment statistics]
PLAN FRAGMENT 0(F10)
Output Exprs:2: S_NAME | 77: count
Input Partition: UNPARTITIONED
RESULT SINK

27:MERGING-EXCHANGE
distribution type: GATHER
limit: 100
cardinality: 100
column statistics:
* S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
* count-->[0.0, 2334116.9317591335, 0.0, 8.0, 40000.0] ESTIMATE

PLAN FRAGMENT 1(F09)

Input Partition: HASH_PARTITIONED: 2: S_NAME
OutPut Partition: UNPARTITIONED
OutPut Exchange Id: 27

26:TOP-N
|  order by: [77, BIGINT, false] DESC, [2, VARCHAR, false] ASC
|  offset: 0
|  limit: 100
|  cardinality: 100
|  column statistics:
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|  * count-->[0.0, 2334116.9317591335, 0.0, 8.0, 40000.0] ESTIMATE
|
25:AGGREGATE (merge finalize)
|  aggregate: count[([77: count, BIGINT, false]); args: ; result: BIGINT; args nullable: true; result nullable: false]
|  group by: [2: S_NAME, VARCHAR, false]
|  cardinality: 40000
|  column statistics:
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|  * count-->[0.0, 2334116.9317591335, 0.0, 8.0, 40000.0] ESTIMATE
|
24:EXCHANGE
distribution type: SHUFFLE
partition exprs: [2: S_NAME, VARCHAR, false]
cardinality: 40000

PLAN FRAGMENT 2(F00)

Input Partition: RANDOM
OutPut Partition: HASH_PARTITIONED: 2: S_NAME
OutPut Exchange Id: 24

23:AGGREGATE (update serialize)
|  STREAMING
|  aggregate: count[(*); args: ; result: BIGINT; args nullable: false; result nullable: false]
|  group by: [2: S_NAME, VARCHAR, false]
|  cardinality: 40000
|  column statistics:
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|  * count-->[0.0, 2334116.9317591335, 0.0, 8.0, 40000.0] ESTIMATE
|
22:Project
|  output columns:
|  2 <-> [2: S_NAME, VARCHAR, false]
|  cardinality: 2334117
|  column statistics:
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|
21:HASH JOIN
|  join op: INNER JOIN (BUCKET_SHUFFLE)
|  equal join conjunct: [26: O_ORDERKEY, INT, false] = [9: L_ORDERKEY, INT, false]
|  build runtime filters:
|  - filter_id = 4, build_expr = (9: L_ORDERKEY), remote = false
|  output columns: 2
|  cardinality: 2334117
|  column statistics:
|  * S_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|
|----20:EXCHANGE
|       distribution type: SHUFFLE
|       partition exprs: [9: L_ORDERKEY, INT, false]
|       cardinality: 4799990
|
1:Project
|  output columns:
|  26 <-> [26: O_ORDERKEY, INT, false]
|  cardinality: 72941300
|  column statistics:
|  * O_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 7.29413E7] ESTIMATE
|
0:OlapScanNode
table: orders, rollup: orders
preAggregation: on
Predicates: [28: O_ORDERSTATUS, CHAR, false] = 'F'
partitionsRatio=1/1, tabletsRatio=10/10
actualRows=0, avgRowSize=9.0
cardinality: 72941300
probe runtime filters:
- filter_id = 4, probe_expr = (26: O_ORDERKEY)
column statistics:
* O_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 7.29413E7] ESTIMATE
* O_ORDERSTATUS-->[-Infinity, Infinity, 0.0, 1.0, 3.0] MCV: [[F:72941300]] ESTIMATE

PLAN FRAGMENT 3(F01)

Input Partition: RANDOM
OutPut Partition: BUCKET_SHUFFLE_HASH_PARTITIONED: 9: L_ORDERKEY
OutPut Exchange Id: 20

19:Project
|  output columns:
|  2 <-> [2: S_NAME, VARCHAR, false]
|  9 <-> [9: L_ORDERKEY, INT, false]
|  cardinality: 4799990
|  column statistics:
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 4799990.4000047995] ESTIMATE
|
18:HASH JOIN
|  join op: RIGHT SEMI JOIN (COLOCATE)
|  colocate: true
|  equal join conjunct: [41: L_ORDERKEY, INT, false] = [9: L_ORDERKEY, INT, false]
|  other join predicates: [43: L_SUPPKEY, INT, false] != [11: L_SUPPKEY, INT, false]
|  build runtime filters:
|  - filter_id = 3, build_expr = (9: L_ORDERKEY), remote = false
|  output columns: 2, 9
|  cardinality: 4799990
|  column statistics:
|  * S_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 4799990.4000047995] ESTIMATE
|  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|
|----17:Project
|    |  output columns:
|    |  2 <-> [2: S_NAME, VARCHAR, false]
|    |  9 <-> [9: L_ORDERKEY, INT, false]
|    |  11 <-> [11: L_SUPPKEY, INT, false]
|    |  cardinality: 4799995
|    |  column statistics:
|    |  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|    |  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 4799995.2] ESTIMATE
|    |  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|    |
|    16:HASH JOIN
|    |  join op: RIGHT ANTI JOIN (COLOCATE)
|    |  colocate: true
|    |  equal join conjunct: [59: L_ORDERKEY, INT, false] = [9: L_ORDERKEY, INT, false]
|    |  other join predicates: [61: L_SUPPKEY, INT, false] != [11: L_SUPPKEY, INT, false]
|    |  build runtime filters:
|    |  - filter_id = 2, build_expr = (9: L_ORDERKEY), remote = false
|    |  output columns: 2, 9, 11
|    |  cardinality: 4799995
|    |  column statistics:
|    |  * S_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|    |  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|    |  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 4799995.2] ESTIMATE
|    |  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|    |
|    |----15:Project
|    |    |  output columns:
|    |    |  2 <-> [2: S_NAME, VARCHAR, false]
|    |    |  9 <-> [9: L_ORDERKEY, INT, false]
|    |    |  11 <-> [11: L_SUPPKEY, INT, false]
|    |    |  cardinality: 12000000
|    |    |  column statistics:
|    |    |  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|    |    |  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 1.2E7] ESTIMATE
|    |    |  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|    |    |
|    |    14:HASH JOIN
|    |    |  join op: INNER JOIN (BROADCAST)
|    |    |  equal join conjunct: [11: L_SUPPKEY, INT, false] = [1: S_SUPPKEY, INT, false]
|    |    |  build runtime filters:
|    |    |  - filter_id = 1, build_expr = (1: S_SUPPKEY), remote = false
|    |    |  output columns: 2, 9, 11
|    |    |  cardinality: 12000000
|    |    |  column statistics:
|    |    |  * S_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|    |    |  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|    |    |  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 1.2E7] ESTIMATE
|    |    |  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|    |    |
|    |    |----13:EXCHANGE
|    |    |       distribution type: BROADCAST
|    |    |       cardinality: 40000
|    |    |
|    |    6:Project
|    |    |  output columns:
|    |    |  9 <-> [9: L_ORDERKEY, INT, false]
|    |    |  11 <-> [11: L_SUPPKEY, INT, false]
|    |    |  cardinality: 300000000
|    |    |  column statistics:
|    |    |  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 1.5E8] ESTIMATE
|    |    |  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 1000000.0] ESTIMATE
|    |    |
|    |    5:OlapScanNode
|    |       table: lineitem, rollup: lineitem
|    |       preAggregation: on
|    |       Predicates: [21: L_RECEIPTDATE, DATE, false] > [20: L_COMMITDATE, DATE, false]
|    |       partitionsRatio=1/1, tabletsRatio=20/20
|    |       actualRows=0, avgRowSize=20.0
|    |       cardinality: 300000000
|    |       probe runtime filters:
|    |       - filter_id = 1, probe_expr = (11: L_SUPPKEY)
|    |       column statistics:
|    |       * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 1.5E8] ESTIMATE
|    |       * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 1000000.0] ESTIMATE
|    |       * L_COMMITDATE-->[6.967872E8, 9.097632E8, 0.0, 4.0, 2466.0] ESTIMATE
|    |       * L_RECEIPTDATE-->[6.94368E8, 9.150336E8, 0.0, 4.0, 2554.0] MCV: [[1995-10-08:269400][1997-08-08:266100][1997-06-05:266000][1998-07-26:265100][1994-12-03:264500]] ESTIMATE
|    |
|    4:Project
|    |  output columns:
|    |  59 <-> [59: L_ORDERKEY, INT, false]
|    |  61 <-> [61: L_SUPPKEY, INT, false]
|    |  cardinality: 300000000
|    |  column statistics:
|    |  * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 1.5E8] ESTIMATE
|    |  * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 1000000.0] ESTIMATE
|    |
|    3:OlapScanNode
|       table: lineitem, rollup: lineitem
|       preAggregation: on
|       Predicates: [71: L_RECEIPTDATE, DATE, false] > [70: L_COMMITDATE, DATE, false]
|       partitionsRatio=1/1, tabletsRatio=20/20
|       actualRows=0, avgRowSize=20.0
|       cardinality: 300000000
|       probe runtime filters:
|       - filter_id = 2, probe_expr = (59: L_ORDERKEY)
|       column statistics:
|       * L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 1.5E8] ESTIMATE
|       * L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 1000000.0] ESTIMATE
|       * L_COMMITDATE-->[6.967872E8, 9.097632E8, 0.0, 4.0, 2466.0] ESTIMATE
|       * L_RECEIPTDATE-->[6.94368E8, 9.150336E8, 0.0, 4.0, 2554.0] MCV: [[1995-10-08:269400][1997-08-08:266100][1997-06-05:266000][1998-07-26:265100][1994-12-03:264500]] ESTIMATE
|
2:OlapScanNode
table: lineitem, rollup: lineitem
preAggregation: on
partitionsRatio=1/1, tabletsRatio=20/20
actualRows=0, avgRowSize=12.0
cardinality: 600000000
probe runtime filters:
- filter_id = 3, probe_expr = (41: L_ORDERKEY)
column statistics:
* L_ORDERKEY-->[1.0, 6.0E8, 0.0, 8.0, 1.5E8] ESTIMATE
* L_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 1000000.0] ESTIMATE

PLAN FRAGMENT 4(F04)

Input Partition: RANDOM
OutPut Partition: UNPARTITIONED
OutPut Exchange Id: 13

12:Project
|  output columns:
|  1 <-> [1: S_SUPPKEY, INT, false]
|  2 <-> [2: S_NAME, CHAR, false]
|  cardinality: 40000
|  column statistics:
|  * S_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|
11:HASH JOIN
|  join op: INNER JOIN (BROADCAST)
|  equal join conjunct: [4: S_NATIONKEY, INT, false] = [36: N_NATIONKEY, INT, false]
|  build runtime filters:
|  - filter_id = 0, build_expr = (36: N_NATIONKEY), remote = false
|  output columns: 1, 2
|  cardinality: 40000
|  column statistics:
|  * S_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 40000.0] ESTIMATE
|  * S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 40000.0] ESTIMATE
|  * S_NATIONKEY-->[0.0, 24.0, 0.0, 4.0, 1.0] ESTIMATE
|  * N_NATIONKEY-->[0.0, 24.0, 0.0, 4.0, 1.0] MCV: [[22:1][23:1][24:1][10:1][11:1]] ESTIMATE
|
|----10:EXCHANGE
|       distribution type: BROADCAST
|       cardinality: 1
|
7:OlapScanNode
table: supplier, rollup: supplier
preAggregation: on
partitionsRatio=1/1, tabletsRatio=1/1
actualRows=0, avgRowSize=33.0
cardinality: 1000000
probe runtime filters:
- filter_id = 0, probe_expr = (4: S_NATIONKEY)
column statistics:
* S_SUPPKEY-->[1.0, 1000000.0, 0.0, 4.0, 1000000.0] ESTIMATE
* S_NAME-->[-Infinity, Infinity, 0.0, 25.0, 1000000.0] ESTIMATE
* S_NATIONKEY-->[0.0, 24.0, 0.0, 4.0, 25.0] ESTIMATE

PLAN FRAGMENT 5(F05)

Input Partition: RANDOM
OutPut Partition: UNPARTITIONED
OutPut Exchange Id: 10

9:Project
|  output columns:
|  36 <-> [36: N_NATIONKEY, INT, false]
|  cardinality: 1
|  column statistics:
|  * N_NATIONKEY-->[0.0, 24.0, 0.0, 4.0, 1.0] MCV: [[22:1][23:1][24:1][10:1][11:1]] ESTIMATE
|
8:OlapScanNode
table: nation, rollup: nation
preAggregation: on
Predicates: [37: N_NAME, CHAR, false] = 'CANADA'
partitionsRatio=1/1, tabletsRatio=1/1
actualRows=0, avgRowSize=29.0
cardinality: 1
column statistics:
* N_NATIONKEY-->[0.0, 24.0, 0.0, 4.0, 1.0] MCV: [[22:1][23:1][24:1][10:1][11:1]] ESTIMATE
* N_NAME-->[-Infinity, Infinity, 0.0, 25.0, 1.0] MCV: [[CANADA:1]] ESTIMATE
[end]

