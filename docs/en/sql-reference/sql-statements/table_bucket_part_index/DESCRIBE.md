---
displayed_sidebar: docs
---

# DESC

DESC is used to view table schemas:

- View the schema of a table stored in your StarRocks cluster, along with the type of the [sort key](../../../table_design/indexes/Prefix_index_sort_key.md) and [materialized view](../../../using_starrocks/async_mv/Materialized_view.md) of the table.
- View the schema of a table stored in the following external data sources, such as Apache Hive™. Note that you can perform this operation only in StarRocks 2.4 and later versions.

## Syntax

```SQL
DESC[RIBE] { [[<catalog_name>.]<db_name>.]<table_name> [ALL] | FILES(files_loading_properties) }
```

## Parameters

| **Parameter** | **Required** | **Description**                                              |
| ------------- | ------------ | ------------------------------------------------------------ |
| catalog_name  | No           | The name of the internal catalog or an external catalog. <ul><li>If you set the value of the parameter to the name of the internal catalog, which is `default_catalog`, you can view the schema of the table stored in your StarRocks cluster. </li><li>If you set the value of the parameter to the name of an external catalog, you can view the schema of the table stored in the external data source.</li></ul> |
| db_name       | No           | The database name.                                           |
| table_name    | Yes          | The table name.                                              |
| ALL           | No           | <ul><li>If this keyword is specified, you can view the type of the sort key, materialized view, and schema of a table stored in your StarRocks cluster. If this keyword is not specified, you only view the table schema. </li><li>Do not specify this keyword when you view the schema of a table stored in an external data source.</li></ul> |
| FILES         | No           | The FILES() table function. From v3.3.4 onwards, you can use DESC with FILES() to view the schema information of files stored in remote storage. For detailed information, see [Function reference - FILES()](../../sql-functions/table-functions/files.md). |

## Output

```Plain
+-----------+---------------+-------+------+------+-----+---------+-------+
| IndexName | IndexKeysType | Field | Type | Null | Key | Default | Extra |
+-----------+---------------+-------+------+------+-----+---------+-------+
```

The following table describes the parameters returned by this statement.

| **Parameter** | **Description**                                              |
| ------------- | ------------------------------------------------------------ |
| IndexName     | The table name. If you view the schema of a table stored in an external data source, this parameter is not returned. |
| IndexKeysType | The type of the sort key of the table. If you view the schema of a table stored in an external data source, this parameter is not returned. |
| Field         | The column name.                                             |
| Type          | The data type of the column.                                 |
| Null          | Whether the column values can be NULL. <ul><li>`yes`: indicates the values can be NULL. </li><li>`no`: indicates the values cannot be NULL. </li></ul>|
| Key           | Whether the column is used as the sort key. <ul><li>`true`: indicates the column is used as the sort key. </li><li>`false`: indicates the column is not used as the sort key. </li></ul>|
| Default       | The default value for the data type of the column. If the data type does not have a default value, a NULL is returned. |
| Extra         | <ul><li>If you see the schema of a table stored in your StarRocks cluster, this field displays the following information about the column: <ul><li>The aggregate function used by the column, such as `SUM` and `MIN`. </li><li>Whether a bloom filter index is created on the column. If so, the value of `Extra` is `BLOOM_FILTER`. </li></ul></li><li>If you see the schema of a table stored in external data sources, this field displays whether the column is the partition column. If the column is the partition column, the value of `Extra` is `partition key`. </li></ul>|

> Note: For information about how a materialized view is displayed in the output, see Example 2.

## Examples

Example 1: View the schema of `example_table` stored in your StarRocks cluster.

```SQL
DESC example_table;
```

Or

```SQL
DESC default_catalog.example_db.example_table;
```

The output of the preceding statements is as follows.

```Plain
+-------+---------------+------+-------+---------+-------+
| Field | Type          | Null | Key   | Default | Extra |
+-------+---------------+------+-------+---------+-------+
| k1    | TINYINT       | Yes  | true  | NULL    |       |
| k2    | DECIMAL(10,2) | Yes  | true  | 10.5    |       |
| k3    | CHAR(10)      | Yes  | false | NULL    |       |
| v1    | INT           | Yes  | false | NULL    |       |
+-------+---------------+------+-------+---------+-------+
```

Example 2: View the schema, type of the sort key, and materialized view of `sales_records` stored in your StarRocks cluster. In the following example, one materialized view `store_amt` is created based on `sales_records`.

```Plain
DESC db1.sales_records ALL;

+---------------+---------------+-----------+--------+------+-------+---------+-------+
| IndexName     | IndexKeysType | Field     | Type   | Null | Key   | Default | Extra |
+---------------+---------------+-----------+--------+------+-------+---------+-------+
| sales_records | DUP_KEYS      | record_id | INT    | Yes  | true  | NULL    |       |
|               |               | seller_id | INT    | Yes  | true  | NULL    |       |
|               |               | store_id  | INT    | Yes  | true  | NULL    |       |
|               |               | sale_date | DATE   | Yes  | false | NULL    | NONE  |
|               |               | sale_amt  | BIGINT | Yes  | false | NULL    | NONE  |
|               |               |           |        |      |       |         |       |
| store_amt     | AGG_KEYS      | store_id  | INT    | Yes  | true  | NULL    |       |
|               |               | sale_amt  | BIGINT | Yes  | false | NULL    | SUM   |
+---------------+---------------+-----------+--------+------+-------+---------+-------+
```

Example 3: View the schema of `hive_table` stored in your Hive cluster.

```Plain
DESC hive_catalog.hive_db.hive_table;

+-------+----------------+------+-------+---------+---------------+ 
| Field | Type           | Null | Key   | Default | Extra         | 
+-------+----------------+------+-------+---------+---------------+ 
| id    | INT            | Yes  | false | NULL    |               | 
| name  | VARCHAR(65533) | Yes  | false | NULL    |               | 
| date  | DATE           | Yes  | false | NULL    | partition key | 
+-------+----------------+------+-------+---------+---------------+
```

Example 4: View the schema of parquet file `lineorder` stored in AWS S3.

> **NOTE**
>
> For files stored in remote storage, DESC only returns three fields: `Field`, `Type`, and `Null`.

```Plain
DESC FILES(
    "path" = "s3://inserttest/lineorder.parquet",
    "format" = "parquet",
    "aws.s3.access_key" = "AAAAAAAAAAAAAAAAAAAA",
    "aws.s3.secret_key" = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
    "aws.s3.region" = "us-west-2"
);

+------------------+------------------+------+
| Field            | Type             | Null |
+------------------+------------------+------+
| lo_orderkey      | int              | YES  |
| lo_linenumber    | int              | YES  |
| lo_custkey       | int              | YES  |
| lo_partkey       | int              | YES  |
| lo_suppkey       | int              | YES  |
| lo_orderdate     | int              | YES  |
| lo_orderpriority | varchar(1048576) | YES  |
| lo_shippriority  | int              | YES  |
| lo_quantity      | int              | YES  |
| lo_extendedprice | int              | YES  |
| lo_ordtotalprice | int              | YES  |
| lo_discount      | int              | YES  |
| lo_revenue       | int              | YES  |
| lo_supplycost    | int              | YES  |
| lo_tax           | int              | YES  |
| lo_commitdate    | int              | YES  |
| lo_shipmode      | varchar(1048576) | YES  |
+------------------+------------------+------+
17 rows in set (0.05 sec)
```

## References

- [CREATE DATABASE](../Database/CREATE_DATABASE.md)
- [SHOW CREATE DATABASE](../Database/SHOW_CREATE_DATABASE.md)
- [USE](../Database/USE.md)
- [SHOW DATABASES](../Database/SHOW_DATABASES.md)
- [DROP DATABASE](../Database/DROP_DATABASE.md)
