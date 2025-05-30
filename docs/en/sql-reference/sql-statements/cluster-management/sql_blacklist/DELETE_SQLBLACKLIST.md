---
displayed_sidebar: docs
---

# DELETE SQLBLACKLIST

DELETE SQLBLACKLIST deletes an SQL regular expression from the SQL blacklist.

For more about SQL Blacklist, see [Manage SQL Blacklist](../../../../administration/management/resource_management/Blacklist.md).

:::tip

This operation requires the SYSTEM-level BLACKLIST privilege. You can follow the instructions in [GRANT](../../account-management/GRANT.md) to grant this privilege.

:::

## Syntax

```SQL
DELETE SQLBLACKLIST <sql_index_number>
```

## Parameter

`sql_index_number`: the index number of the SQL regular expression in the blacklist. Separate multiple index numbers with a comma (,) and a space. You can obtain the index number using [SHOW SQLBLACKLIST](SHOW_SQLBLACKLIST.md).

## Examples

```Plain
mysql> DELETE SQLBLACKLIST 3, 4;

mysql> SHOW SQLBLACKLIST;
+-------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Index | Forbidden SQL                                                                                                                                                                                                                                                                                          |
+-------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| 1     | select count\(\*\) from .+                                                                                                                                                                                                                                                                             |
| 2     | select id_int \* 4, id_tinyint, id_varchar from test_all_type_nullable except select id_int, id_tinyint, id_varchar from test_basic except select \(id_int \* 9 \- 8\) \/ 2, id_tinyint, id_varchar from test_all_type_nullable2 except select id_int, id_tinyint, id_varchar from test_basic_nullable |
+-------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
