
-- Create Schema
DROP SCHEMA IF EXISTS term_1;

create schema term_1;
use term_1;

-- Load data from f1_database.sql

-- Lets have a look what we have got in the data base
show tables;

-- We can see that there are 6 tables, which are constructors, drivers, drivers_standings, qualifying, race_results and races.

-- Lets look at the range of time of races recorded in this database
drop view if exists range_of_times;

create view range_of_time as
select min(year) as Earliest_race, max(year) as Latest_race
from races;

select * from range_of_time;
-- check if there are missing years from 1950-2022
drop view if exists distinct_years;

create view distinct_years as
select distinct year from races
order by year desc;

select * from distinct_years;
-- We can see that the database contains ALL the race data since 1950 and until 2022

-- Lets have a look at the top 10 drivers who have the most points since 1950
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
-- We can see that Lewis Hamilton is the highest scoring driver since 1950, however we can see Michael Schumacher is only on the 8th place
-- It is a bit strange as he is one of the greatest f1 driver ever.

-- Lets see how many wins did Michael Schumacher and Lewis Hamilton had comparing to other drivers.
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
-- From the results we can see that Michael Schumacher has the 2nd most wins since 1950, and racers like Alain Prost and Ayrton Senna is not even on the top 10 in terms of scores.
-- So we assume that the Points System in Michael Schumacher's era is different from Lewis Hamiltons.

-- Lets find out! (MSC's Prime is in 2001, while HAM's Prime is in 2020)
drop view if exists 2020_points_system;

create view 2020_points_system as
select r.year, rr.race_position,round(rr.race_points,0) as race_points
from race_results rr
left join races r
using (race_id)
where r.race_id = 1031;

drop view if exists 2001_points_system;

create view 2001_points_system as
select r.year, rr.race_position,round(rr.race_points,0) as race_points
from race_results rr
left join races r
using (race_id)
where r.race_id = 141;

select * from 2001_points_system;
select * from 2020_points_system;
-- From the views we can see that winning a race in 2001 only counted for 10 points, and only the top 6 finishers got points. 
-- While in 2020, top 10 finishers get points and the winner get 25 points.
-- So we can say our assumption about the difference in points system is true, and that is the reason why MSC has the 2nd most wins, but only on the 8th place in terms of points.

-- Let's see how many races had a specific constructor won since 1950 by using stored procedure after left joining 2 tables
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

-- Race Wins of Mercedes since 1950
call GetNumOfWins_constructors('Mercedes');

-- Race Wins of Ferrari since 1950
call GetNumOfWins_constructors('Ferrari');

-- Race Wins of Red Bull since 1950
call GetNumOfWins_constructors('Red Bull');


-- Create Procedure for getting dirvers number of wins since 1950
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

-- Race Wins of Hamilton since 1950
call GetNumOfWins_driver('Hamilton');

-- Race Wins of Albon since 1950
call GetNumOfWins_driver('Albon');


-- We can see that Albon has 0 wins in his career yet, but lets assume he got a win in a random race. Lets create a trigger when a new race win is added for Albon.
-- Create empty table for trigger log.
drop table if exists race_results_add;

CREATE TABLE race_results_add (
    add_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    wins INT NOT NULL,
    changedate date,
    action VARCHAR(50) DEFAULT NULL
);

-- Creating the trigger
drop trigger if exists after_race_result_update ;

CREATE TRIGGER after_race_result_update 
    AFTER UPDATE ON race_results
    FOR EACH ROW 
 INSERT INTO race_results_add
 SET action = 'update',
     driver_id = OLD.driver_id,
     wins = NEW.race_position,
     changedate = NOW();

show triggers;

-- Get driver_id of Albon
select driver_id from drivers where driver_surname = 'Albon';
-- Get a random race_id to update where Albon had raced in
select race_id from race_results where driver_id = 848;

-- Turn off safe mode
SET SQL_SAFE_UPDATES = 0;

-- Adding a win for Albon (driver_id : 848), in race_id 1086
UPDATE race_results
SET 
    race_position = 1
WHERE
    driver_id = 848 and 
    race_id = 1086;
    
-- Lets look at the log of the update trigger
select * from race_results_add;

-- Lets see how many wins does Albon now have
call GetNumOfWins_driver('Albon');

-- After updating, we can see Albon now have 1 win in total and the update is being recorded in the table race_results_add by a trigger.

