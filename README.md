# Term1
>Please load data from [f1_dataset.sql](https://github.com/tingchunyin/Term1/blob/main/f1_database.sql) after creating and. using schema term_1


## Create Schema
```sql
DROP SCHEMA IF EXISTS term_1;

create schema term_1;
use term_1;
```

## LOAD DATA FROM [f1_dataset.sql](https://github.com/tingchunyin/Term1/blob/main/f1_database.sql) (PLAN B)

Lets have a look what we have got in the data base
```sql
show tables;
```

We can see that there are 6 tables, which are constructors, drivers, drivers_standings, qualifying, race_results and races.

Lets look at the range of time of races recorded in this database
```sql
drop view if exists range_of_time;

create view range_of_time as
select min(year) as Earliest_race, max(year) as Latest_race
from races;

select * from range_of_time;
```
