
-- Create Schema
DROP SCHEMA IF EXISTS term_1;

create schema term_1;
use term_1;

-- Load data from f1_database.sql

-- Lets have a look what we have got in the data base
show tables;

-- We can see that there are 6 tables, which are constructors, drivers, drivers_standings, qualifying, race_results and races.

-- Lets look at the range of time of races recorded in this database
select min(year) as Earliest_race, max(year) as Latest_race
from races;

-- check if there are missing years from 1950-2022
select distinct year from races
order by year desc;
-- We can see that the database contains ALL the race data since 1950 and until 2022

-- Lets have a look at the top 10 drivers who have the most points since 1950
select d.driver_id, d.driver_code, d.driver_forename, d.driver_surname, round(sum(ds.driver_points),0) as Total_points
from drivers_standings ds
INNER JOIN drivers d
ON ds.driver_id = d.driver_id
group by driver_id
order by Total_points desc
Limit 10;
-- We can see that Lewis Hamilton is the highest scoring driver since 1950, however we can see Michael Schumacher is only on the 8th place
-- It is a bit strange as he is one of the greatest f1 driver ever.

-- Lets see how many wins did Michael Schumacher and Lewis Hamilton had comparing to other drivers.
select d.driver_id, d. driver_code, d.driver_forename, d.driver_surname, sum(r.race_position = 1) as wins
from race_results r
INNER JOIN drivers d
ON r.driver_id = d.driver_id
group by driver_id
order by wins desc
limit 10;
-- From the results we can see that Michael Schumacher has the 2nd most wins since 1950, and racers like Alain Prost and Ayrton Senna is not even on the top 10 in terms of scores.
-- So we assume that the Points System in Michael Schumacher's era is different from Lewis Hamiltons.

-- Lets find out! (MSC's Prime is in 2001, while HAM's Prime is in 2020)
select r.year, rr.race_position,round(rr.race_points,0) as race_points
from race_results rr
left join races r
using (race_id)
where r.race_id = 141 or r.race_id = 1031;
-- From the view we can see that winning a race in 2001 only counted for 10 points, and only the top 6 finishers got points. 
-- While in 2020, top 10 finishers get points and the winner get 25 points.
-- So we can say our assumption about the difference in points system is true, and that is the reason why MSC has the 2nd most wins, but only on the 8th place in terms of points.

-- Let's see how many races has specific constructor won since 1950 by using stored procedure after left joining 2 tables
DROP PROCEDURE IF EXISTS GetNumOfWins;

DELIMITER //

CREATE PROCEDURE GetNumOfWins(
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
call GetNumOfWins('Mercedes');

-- Race Wins of Ferrari since 1950
call GetNumOfWins('Ferrari');

-- Race Wins of Red Bull since 1950
call GetNumOfWins('Red Bull');
