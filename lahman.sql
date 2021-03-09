--Question 1: What range of years for baseball games played does the provided database cover?
SELECT yearID as year, G as games_played
FROM teams
WHERE G IS NOT NULL
ORDER BY yearID;
-- 1871 through 2016

--Question 1 (alternative approach)
SELECT MIN(yearid), MAX(yearid)
FROM appearances;
---- 1871 through 2016

/*Question 2: Find the name and height of the shortest player in the database. 
How many games did he play in? What is the name of the team for which he played?*/
SELECT DISTINCT ppl.namefirst, ppl.namelast, height, app.g_all AS games, t.name AS team
FROM people AS ppl
LEFT JOIN appearances AS app
ON ppl.playerid = app.playerid
RIGHT JOIN teams AS t
ON app.teamid = t.teamid
WHERE ppl.height = (SELECT MIN(height) 
					FROM people);

/*Question 3: Find all players in the database who played at Vanderbilt University. 
Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors? */

WITH income_per_player AS
						(SELECT playerid, SUM(salary) AS income_per_player
						FROM salaries
						GROUP BY playerid)
SELECT DISTINCT ppl.playerid, sch.schoolname, ppl.namefirst, ppl.namelast, ipp.income_per_player::numeric::money
FROM people as ppl
	 INNER JOIN salaries as s
	 ON ppl.playerid = s.playerid
	 INNER JOIN collegeplaying as cp
	 ON ppl.playerid = cp.playerid
	 INNER JOIN schools as sch
	 ON cp.schoolid = sch.schoolid
	 INNER JOIN income_per_player AS ipp
	 ON ipp.playerid = ppl.playerid
WHERE sch.schoolname = 'Vanderbilt University'
ORDER BY ipp.income_per_player::numeric::money DESC;

-- alternative approach to Question 3:
SELECT DISTINCT concat(p.namefirst, ' ', p.namelast) AS name, sc.schoolname,
  SUM(sa.salary) OVER (PARTITION BY concat(p.namefirst, ' ', p.namelast))::numeric::money AS total_salary
  FROM people AS p INNER JOIN collegeplaying AS cp ON p.playerid = cp.playerid
  INNER JOIN schools AS sc ON cp.schoolid = sc.schoolid
  INNER JOIN salaries AS sa ON p.playerid = sa.playerid
  WHERE cp.schoolid = 'vandy'
  GROUP BY name, schoolname, sa.salary, sa.yearid
  ORDER BY total_salary DESC


/*Question 4: Using the fielding table, group players into three groups based on their position: 
label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/
WITH calculation AS (
		SELECT playerid, pos,
				CASE WHEN pos = 'OF' THEN 'Outfield'
					WHEN pos = 'SS' OR pos ='1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
					ELSE 'Battery' END AS position,
			po AS PutOut,
			yearid
		FROM fielding
		WHERE yearid = '2016')
SELECT position, SUM(putout) AS number_putouts
FROM calculation
GROUP BY position;

--alternative approach to Question 4 (sometimes the GROUP BY will be able to see something in a SELECT clause)
SELECT SUM(po) AS putouts,
		CASE 
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
		WHEN pos = 'P' OR pos ='C' THEN 'Battery' END as pos_category
FROM fielding
WHERE yearID = '2016'
GROUP BY pos_category;

/*Question 5: Find the average number of strikeouts per game by decade since 1920. 
Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?*/
--strikeouts
SELECT teams.yearid /10*10 as decade, sum(so) AS total_strike_out,
	   Sum(g) as total_games,
	   round(sum(so)::decimal / sum(g),2)::decimal as average_strike_out
	   FROM teams
	   WHERE yearid >= '1920'
	   GROUP BY yearid/10*10
	   ORDER BY decade DESC
	   
-- Home Runs
SELECT teams.yearid /10*10 as decade, 
		SUM(hr) AS homerun,
	   Sum(g) as total_games,
	   round(sum(hr)::decimal / sum(g),2)::decimal as average_homerun
	   FROM teams
	   WHERE yearid >= '1920'
	   GROUP BY yearid/10*10
	   ORDER BY decade DESC
--alternative approach:

SELECT yearid/10*10 as decade,
	   ROUND(AVG(HR/g), 2) as avg_HR_per_game,
	   ROUND(AVG(so/g), 2) as avg_so_per_game
FROM teams
WHERE yearid>=1920
GROUP BY decade
ORDER BY decade

/*Question 6: Find the player who had the most success stealing bases in 2016, where success is measured 
as the percentage of stolen base attempts which are successful. (A stolen base attempt results either 
in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.*/

select  distinct(p.playerid),
		p.namefirst, p.namelast,
		a.yearid, b.sb,
		cast(b.sb as numeric) + cast(b.cs as numeric) as total_attempts,
		round(cast(b.sb as numeric) /(cast(b.sb as numeric) + cast(b.cs as numeric)),2) as percentage_stole
from people as p left join appearances as a
	on p.playerid = a.playerid 
	left join batting as b
	on p.playerid = b.playerid
where	a.yearid = 2016
		and b.yearid =2016
		and cast(b.sb as numeric) + cast(b.cs as numeric) >= 20
order by percentage_stole desc;




/*Question 7: From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? Doing this will probably result 
in an unusually small number of wins for a world series champion – determine why this is the case. Then redo 
your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most 
wins also won the world series? What percentage of the time?*/


---mahesh approach--
WITH most_no_win AS (SELECT name, w, wswin, yearid
					 FROM teams
					 WHERE yearid BETWEEN 1970 AND 2016
					 	   AND wswin = 'N'
					 	   AND yearid <> 1981
					 ORDER BY w DESC
					 LIMIT 1),
	 least_win AS (SELECT name, w, wswin, yearid
				   FROM teams
				   WHERE yearid BETWEEN 1970 AND 2016
				   	   	 AND wswin = 'Y'
					 	 AND yearid <> 1981
				   ORDER BY w
				   LIMIT 1)
SELECT *
FROM most_no_win
UNION ALL
SELECT *
FROM least_win;

--next part of Question 7:
WITH ws_wins AS (SELECT name, w, wswin, yearid
					 FROM teams
					 WHERE yearid BETWEEN 1970 AND 2016
					 	   AND wswin = 'Y'
					 ORDER BY w DESC),
	 most_wins AS (SELECT MAX(w) AS w, yearid
				   FROM teams
				   WHERE yearid BETWEEN 1970 AND 2016
				   GROUP BY yearid)
SELECT 2016-1970 AS total_seasons, COUNT(*) AS most_win_ws, (COUNT(*)::float/(2016-1970)::float)*100 AS pct_ws_most
FROM most_wins INNER JOIN ws_wins USING(yearid)
WHERE most_wins.w = ws_wins.w;


/*Question 8 (part 1): Using the attendance figures from the homegames table, find the teams and parks 
which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance 
divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, 
team name, and average attendance. Repeat for the lowest 5 average attendance.*/

SELECT team, park, (attendance/games) as avg_attendance
FROM homegames
WHERE year='2016'
AND games > 10
ORDER BY avg_attendance DESC
LIMIT 5;

--Question 8(part 2): Lowest avg attendance per game
SELECT team, park, (attendance/games) as avg_attendance
FROM homegames
WHERE year='2016'
AND games > 10
ORDER BY avg_attendance
LIMIT 5;

--Mahesh aproach to question 8
WITH avg_attend AS (SELECT park, team, attendance/games AS avg_attendance
					FROM homegames
					WHERE year = 2016
						  AND games >= 10),
	 avg_attend_full AS (SELECT park_name, name as team_name, avg_attendance
						 FROM avg_attend INNER JOIN teams ON avg_attend.team = teams.teamid
						 	  INNER JOIN parks ON avg_attend.park = parks.park
						 WHERE teams.yearid = 2016
						 GROUP BY park_name, avg_attendance, name),
	 top_5 AS (SELECT *, 'top_5' AS category
			   FROM avg_attend_full
			   ORDER BY avg_attendance DESC
			   LIMIT 5),
	 bottom_5 AS (SELECT *, 'bottom_5' AS category
			      FROM avg_attend_full
			      ORDER BY avg_attendance
			      LIMIT 5)
SELECT *
FROM top_5
UNION ALL
SELECT *
FROM bottom_5;

--alternative approach
SELECT p.park_name, hg.park, team, sum(attendance)/games as avg_attendance
FROM homegames as hg
LEFT JOIN parks AS p ON hg.park =p.park
Where games >= 10
and year = 2016
group by park_name, team, attendance, games, year, hg.park
order by avg_attendance desc
Limit 5;

/*Question 9: Which managers have won the TSN Manager of the Year award in both the National League (NL) 
and the American League (AL)? Give their full name and the teams that they were managing when they won the award.*/

WITH all_MOTY_awards AS
		 (SELECT playerid, awardid,
		 		COUNT(CASE WHEN lgid = 'NL' THEN 'national league' END) as nl_awards,
	  			COUNT(CASE WHEN lgid = 'AL' THEN 'american league' END) as al_awards
		FROM awardsmanagers
		WHERE awardid ILIKE 'TSN Manager of the Year'
		GROUP BY playerid, awardid
		ORDER BY nl_awards DESC, al_awards DESC),
		 
	 /*nl_awards DESC, al_awards DESC),*/
	filtered_awards AS (SELECT *
					FROM all_MOTY_awards
					WHERE nl_awards > 0
					AND al_awards>0)
SELECT namefirst, namelast, name as team, nl_awards, al_awards, teams.lgid
FROM filtered_awards
	INNER JOIN awardsmanagers USING(playerid, awardid)
	INNER JOIN people ON filtered_awards.playerid=people.playerid
	INNER JOIN managers ON filtered_awards.playerid=managers.playerid AND awardsmanagers.yearid=managers.yearid AND awardsmanagers.lgid=managers.lgid 
	INNER JOIN teams ON managers.teamid=teams.teamid AND managers.yearid=teams.yearid AND managers.lgid=teams.lgid
GROUP BY namefirst, namelast, name, nl_awards, al_awards, teams.lgid
		 
--mahesh approach
WITH mngr_list AS (SELECT playerid, awardid, COUNT(DISTINCT lgid) AS lg_count
				   FROM awardsmanagers
				   WHERE awardid = 'TSN Manager of the Year'
				   		 AND lgid IN ('NL', 'AL')
				   GROUP BY playerid, awardid
				   HAVING COUNT(DISTINCT lgid) = 2),
	 mngr_full AS (SELECT playerid, awardid, lg_count, yearid, lgid
				   FROM mngr_list INNER JOIN awardsmanagers USING(playerid, awardid))
SELECT DISTINCT namegiven, namelast, name AS team_name, mngr_full.lgid, mngr_full.yearid
FROM mngr_full INNER JOIN people USING(playerid)
	 INNER JOIN managers USING(playerid, yearid, lgid)
	 INNER JOIN teams ON mngr_full.yearid = teams.yearid AND mngr_full.lgid = teams.lgid AND managers.teamid = teams.teamid;

--Jen approach
WITH am AS (SELECT playerid, 
				yearid, 
				lgid,
				CONCAT(playerid, yearid) AS manid
			FROM awardsmanagers 
			WHERE awardid ilike '%tsn%'),
mid AS (SELECT CONCAT(playerid, yearid) AS manid,
			playerid,
			yearid,
			teamid,
			lgid
		FROM managers),
winner AS (SELECT DISTINCT am.playerid as playerid,
				CONCAT(people.namefirst, ' ', people.namelast) as name,
				am.yearid as yearid,
				am.lgid as league,
				am.manid as manid,
				mid.teamid as teamid,
				teams.name as team
			FROM am INNER JOIN mid ON am.manid = mid.manid
				INNER JOIN teams ON mid.teamid = teams.teamid
				INNER JOIN people ON am.playerid = people.playerid
			WHERE teams.yearid > 1980)
SELECT DISTINCT w1.name as name,
	w1.yearid as year1,
	w1.league as league1,
	w1.team as team1,
	w2.yearid as year2,
	w2.league as league2,
	w2.team as team2
FROM winner as w1 INNER JOIN winner as w2 ON w1.playerid = w2.playerid
WHERE w1.league = 'NL'
AND w2.league = 'AL'
ORDER BY year1;

/*Question 10:Analyze all the colleges in the state of Tennessee. 
Which college has had the most success in the major leagues. 
Use whatever metric for success you like - number of players, number of games, salaries, world series wins, etc.*/
WITH tn_schools AS (SELECT schoolname, schoolid
					FROM schools
					WHERE schoolstate = 'TN'
					GROUP BY schoolname, schoolid)
SELECT schoolname, COUNT(DISTINCT playerid) AS player_count, SUM(salary)::text::money AS total_salary, (SUM(salary)/COUNT(DISTINCT playerid))::text::money AS money_per_player
FROM tn_schools INNER JOIN collegeplaying USING(schoolid)
	 INNER JOIN people USING(playerid)
	 INNER JOIN salaries USING(playerid)
GROUP BY schoolname
ORDER BY money_per_player DESC;


/*Question 11 - Is there any correlation between number of wins and team salary? 
Use data from 2000 and later to answer this question. As you do this analysis, 
keep in mind that salaries across the whole league tend to increase together, 
so you may want to look on a year-by-year basis.*/

----no correlation betweens wins and salary increases
		  
SELECT DISTINCT teams.yearid, teams.teamid, teams.w as wins, teams.g as games_played,
		 SUM(salary::numeric::money) as salary, CEILING(((w/g::FLOAT)*100.00)) AS percent_wins
			 --OVER(PARTITION BY teams.name, teams.yearid) as team_salary 
		 	FROM teams
		 			INNER JOIN salaries ON teams.yearid=salaries.yearid 
		  								AND teams.teamid=salaries.teamid 
		  								AND teams.lgid=salaries.lgid
		WHERE teams.yearid >= '2000'
		GROUP BY teams.yearid, teams.teamid, teams.w, teams.g
		ORDER BY teams.teamid, teams.yearid; 
		
		
--alternative approach (if a correlation is closer to 0, then there is very little correlation)
WITH team_year_sal_w AS (SELECT teamid, yearid, SUM(salary) AS total_team_sal, AVG(w)::integer AS w
						 FROM salaries INNER JOIN teams USING(yearid, teamid)
						 WHERE yearid >= 2000
						 GROUP BY yearid, teamid)
SELECT yearid, CORR(total_team_sal, w) AS sal_win_corr
FROM team_year_sal_w
GROUP BY yearid
ORDER BY yearid;

/*Question 12: In this question, you will explore the connection between number of wins and attendance.
part 1--Does there appear to be any correlation between attendance at home games and number of wins?
part 2--Do teams that win the world series see a boost in attendance the following year? 
part 3--What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.*/

SELECT CORR(homegames.attendance, w) AS corr_attend_w
FROM teams INNER JOIN homegames ON teamid = team AND yearid = year
WHERE homegames.attendance IS NOT NULL
---
SELECT AVG(hg_2.attendance - hg_1.attendance) AS avg_attend_increase,
	   stddev_pop(hg_2.attendance - hg_1.attendance) AS stdev_attend_increase,
	   MAX(hg_2.attendance - hg_1.attendance) AS max_attend_increase,
	   MIN(hg_2.attendance - hg_1.attendance) AS min_attend_increase
FROM teams INNER JOIN homegames AS hg_1 ON teams.yearid = hg_1.year AND teams.teamid = hg_1.team
	 	   INNER JOIN homegames AS hg_2 ON teams.yearid + 1 = hg_2.year AND teams.teamid = hg_2.team
WHERE wswin = 'Y'
	  AND hg_1.attendance > 0
	  AND hg_2.attendance > 0;
---
SELECT AVG(hg_2.attendance - hg_1.attendance) AS avg_attend_increase,
	   stddev_pop(hg_2.attendance - hg_1.attendance) AS stdev_attend_increase,
	   MAX(hg_2.attendance - hg_1.attendance) AS max_attend_increase,
	   MIN(hg_2.attendance - hg_1.attendance) AS min_attend_increase
FROM teams INNER JOIN homegames AS hg_1 ON teams.yearid = hg_1.year AND teams.teamid = hg_1.team
	 INNER JOIN homegames AS hg_2 ON teams.yearid + 1 = hg_2.year AND teams.teamid = hg_2.team
WHERE (divwin = 'Y' OR wcwin = 'Y')
	  AND hg_1.attendance > 0
	  AND hg_2.attendance > 0;

/*Question 13: It is thought that since left-handed pitchers are more rare, 
causing batters to face them less often, that they are more effective. Investigate this claim 
and present evidence to either support or dispute this claim. First, determine just how rare 
left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely 
to win the Cy Young Award? Are they more likely to make it into the hall of fame?*/
git aWITH pitchers AS (SELECT *
				  FROM people INNER JOIN pitching USING(playerid)
				 	   INNER JOIN awardsplayers USING(playerid)
				 	   INNER JOIN halloffame USING(playerid))
SELECT (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float AS pct_left_pitch,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE awardid = 'Cy Young Award')/COUNT(DISTINCT playerid)::float AS pct_pitch_cy_young,
	   ((SELECT COUNT(DISTINCT playerid)::float
		 FROM pitchers WHERE awardid = 'Cy Young Award')/COUNT(DISTINCT playerid)::float) * ((SELECT COUNT(DISTINCT playerid)::float
																							  FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float) AS calc_pct_left_cy_young,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE awardid = 'Cy Young Award' AND throws = 'L')/COUNT(DISTINCT playerid)::float AS actual_pct_left_cy_young,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE inducted = 'Y')/COUNT(DISTINCT playerid)::float AS pct_hof,
	   ((SELECT COUNT(DISTINCT playerid)::float
		 FROM pitchers WHERE inducted = 'Y')/COUNT(DISTINCT playerid)::float) * ((SELECT COUNT(DISTINCT playerid)::float
																				  FROM pitchers WHERE throws = 'L')/COUNT(DISTINCT playerid)::float) AS calc_pct_left_hof,
	   (SELECT COUNT(DISTINCT playerid)::float
		FROM pitchers WHERE inducted = 'Y' AND throws = 'L')/COUNT(DISTINCT playerid)::float AS actual_pct_left_hof
FROM pitchers;
