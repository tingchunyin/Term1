# Term1
>Please load data from [f1_dataset.sql](https://github.com/tingchunyin/Term1/blob/main/f1_database.sql) after creating and. using schema term_1

## Analytics Questions
1. We would like to know who has the most race wins or points
 
2. If there is a difference while comparing modern points system with the past
 
3. We would like to know the number of wins of specific constructors (by creating procedure)
 
4. We would like to know the number of wins of specific drivers
 
5. Creating a trigger which will log the future updates to the table to prevent data inaccuracy
 
6. Getting insights on how to tune the car according to the race track's average racing speed
 
7. See if modern race cars or race cars in the past are faster in general


## Create Schema
```sql
DROP SCHEMA IF EXISTS term_1;

create schema term_1;
use term_1;
```


## LOAD DATA FROM [f1_dataset.sql](https://github.com/tingchunyin/Term1/blob/main/f1_database.sql) (PLAN B)
>!!!Please download the file from the link above and run the whole sql script before going to the next step!!!

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

Check if there are missing years from 1950-2022
```sql
drop view if exists distinct_years;

create view distinct_years as
select distinct year from races
order by year desc;

select * from distinct_years;
```
We can see that the database contains ALL the race data since 1950 and until 2022


## Data Marts
Lets have a look at the top 10 drivers who have the most points since 1950
```sql
drop view if exists top_ten_most_points;

create view top_ten_most_points as
select d.driver_id, d.driver_code, d.driver_forename, d.driver_surname, round(sum(ds.driver_points),0) as Total_points
from drivers_standings ds
INNER JOIN drivers d
ON ds.driver_id = d.driver_id
group by driver_id
order by Total_points desc
Limit 10;

select * from top_ten_most_points;
```

We can see that Lewis Hamilton is the highest scoring driver since 1950, however we can see Michael Schumacher is only on the 8th place

It is a bit strange as he is one of the greatest f1 driver ever.


Lets see how many wins did Michael Schumacher and Lewis Hamilton had comparing to other drivers.
```sql
drop view if exists top_ten_most_wins;

create view top_ten_most_wins as
select d.driver_id, d. driver_code, d.driver_forename, d.driver_surname, sum(r.race_position = 1) as wins
from race_results r
INNER JOIN drivers d
ON r.driver_id = d.driver_id
group by driver_id
order by wins desc
limit 10;

select * from top_ten_most_wins;
```

From the results we can see that Michael Schumacher has the 2nd most wins since 1950, and racers like Alain Prost and Ayrton Senna is not even on the top 10 in terms of scores.

So we assume that the Points System in Michael Schumacher's era is different from Lewis Hamiltons.


Lets find out from a random race in 2001 and 2020! (MSC's Prime is in 2001, while HAM's Prime is in 2020)

Points system in 2001
```sql
drop view if exists 2001_points_system;

create view 2001_points_system as
select r.year, rr.race_position,round(rr.race_points,0) as race_points
from race_results rr
left join races r
using (race_id)
where r.race_id = 141;

select * from 2001_points_system;
```

Points system in 2001
```sql
drop view if exists 2020_points_system;

create view 2020_points_system as
select r.year, rr.race_position,round(rr.race_points,0) as race_points
from race_results rr
left join races r
using (race_id)
where r.race_id = 1031;

select * from 2020_points_system;
```
From the views we can see that winning a race in 2001 only counted for 10 points, and only the top 6 finishers got points. 

While in 2020, top 10 finishers get points and the winner get 25 points.

So we can say our assumption about the difference in points system is true, and that is the reason why Schumacher has the 2nd most wins, but only on the 8th place in terms of points.


## Creating procedures
Let's see how many races had a specific constructor won since 1950 by using stored procedure after left joining 2 tables
```sql
DROP PROCEDURE IF EXISTS GetNumOfWins_constructors;

DELIMITER //

CREATE PROCEDURE GetNumOfWins_constructors(
	IN constructorName VARCHAR(100)
)
BEGIN
select sum(rr.race_position = 1) as wins
from constructors c
left join race_results rr
ON rr.constructor_id = c.constructor_id
where c.constructor_name = constructorName;
END //
DELIMITER ;
```


## Testing
Race Wins of Mercedes since 1950
```sql
call GetNumOfWins_constructors('Mercedes');
```

Race Wins of Ferrari since 1950
```sql
call GetNumOfWins_constructors('Ferrari');
```

Race Wins of Red Bull since 1950
```sql
call GetNumOfWins_constructors('Red Bull');
```

Create Procedure for getting dirvers number of wins since 1950
```sql
DROP PROCEDURE IF EXISTS GetNumOfWins_driver;

DELIMITER //

CREATE PROCEDURE GetNumOfWins_driver(
	IN driverName VARCHAR(100)
)
BEGIN
select sum(rr.race_position = 1) as wins
from drivers d
left join race_results rr
ON rr.driver_id = d.driver_id
where d.driver_surname = driverName;
END //
DELIMITER ;
```

TESTING PROCEDURE: Race Wins of Hamilton since 1950
```sql
call GetNumOfWins_driver('Hamilton');
```

TESTING PROCEDURE: Race Wins of Verstappen (2022 world champion) since 1950
```sql
call GetNumOfWins_driver('Verstappen');
```


## Creating Triggers
Let's see how many race wins of Albon has since 1950
```sql
call GetNumOfWins_driver('Albon');
```

We can see that Albon has 0 wins in his career yet, but lets assume he got a win in a random race. 

Lets create a trigger when a new race win is added for Albon.


Now we create empty table for trigger log.
```sql
drop table if exists race_results_add;

CREATE TABLE race_results_add (
    add_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    new_wins INT NOT NULL,
    changedate date,
    action VARCHAR(50) DEFAULT NULL
);
```

Creating the trigger
```sql
drop trigger if exists after_race_result_update ;

CREATE TRIGGER after_race_result_update 
    AFTER UPDATE ON race_results
    FOR EACH ROW 
 INSERT INTO race_results_add
 SET action = 'update',
     driver_id = OLD.driver_id,
     new_wins = NEW.race_position,
     changedate = NOW();
```
   
See if the trigger is sucessfully stored    
```sql
show triggers;
```

Get driver_id of Albon
```sql
select driver_id from drivers where driver_surname = 'Albon';
```

Get a random race_id to update where Albon had raced in
```sql
select race_id from race_results where driver_id = 848;
```

Turn off safe mode to be able to update table value manually
```sql
SET SQL_SAFE_UPDATES = 0;
```

Adding a win for Albon (driver_id : 848), in race_id 1086
```sql
UPDATE race_results
SET 
    race_position = 1
WHERE
    driver_id = 848 and 
    race_id = 1086;
```
    
TESTING THE TRIGGER: Lets also add another race win for Albon in Race 1085
```sql
UPDATE race_results
SET 
    race_position = 1
WHERE
    driver_id = 848 and 
    race_id = 1085;
```  

Lets look at the log of the update trigger (should contain 2 records)
```sql
select * from race_results_add;
```

Lets see how many wins does Albon now have (should have 2 wins)
```sql
call GetNumOfWins_driver('Albon');
```

After updating, we can see Albon now has 2 wins in total and the update is being recorded in the table race_results_add by a trigger.


## More Data Marts regarding specific racetracks
After looking at the performance of specific drivers and constructors, we would also like to know which circuits have the highest average speed in 2021, so wee can tune the cars accordingly (using 2021 racecar specs).
```sql
drop view if exists fastest_track_2021;

create view fastest_track_2021 as
select r.race_id, r.year, r.circuit_id, r.circuit_name, round(avg(rr.race_fastest_lap_speed),2)as speed
from race_results rr
INNER JOIN races r
ON rr.race_id = r.race_id
where r.year = 2021 and rr.race_fastest_lap_speed is not null
group by r.race_id
order by speed desc;

select * from fastest_track_2021;
```

We can see that in 2021, the Italian Grand Prix has the highest average race speed, but we would also like to see if the speed of racecars has increase since 1950.


Lets investigate on the change of average speed of racecars in the Italian Grand Prix since the earliest available record on the dataset

We assume that with technological improvement and fuel efficiency, modern F1 cars are faster than the cars in the past.
```sql
drop view if exists avg_car_speed;

create view avg_car_speed as
select r.year, r.circuit_name, round(avg(rr.race_fastest_lap_speed),2)as speed
from race_results rr
INNER JOIN races r
ON rr.race_id = r.race_id
where r.circuit_name = "Italian Grand Prix"  and rr.race_fastest_lap_speed is not null
group by r.race_id
order by speed desc;

select * from avg_car_speed;
```

Seems that our assumption is wrong, as results show that cars from the 2000s are generally faster than the cars in the 2010s.

So I did some research online, and the reason of a slower speed in modern cars is due to the safety regulations, heavier cars, hybrid engines and using biofuels, which can sufficiently explain why modern f1 cars are generally slower than cars in the past.


# Brief Summary
From the above codes, we can answer our analytics questions, by creating views, stored procedures, triggers and testing the functionality of each of the codes.

