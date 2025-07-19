-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people p
  WHERE p.weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, p.playerid, yearid
  FROM people p, halloffame ha
  WHERE p.playerid = ha.playerid AND ha.inducted LIKE 'Y'
  ORDER BY yearid DESC, p.playerid
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
 SELECT namefirst, namelast, q2i.playerid, C.schoolid, q2i.yearid
   FROM q2i, collegeplaying C, schools S
   WHERE C.playerid = q2i.playerid AND C.schoolid = S.schoolid AND S.schoolState LIKE 'CA'
   ORDER BY q2i.yearid DESC, C.schoolid, q2i.playerid
;

-- More directly case
-- SELECT namefirst, namelast, p.playerid, pl.schoolid, ha.yearid
--    FROM people p, halloffame ha, collegeplaying pl, schools sc
--    WHERE p.playerid = ha.playerid AND ha.inducted LIKE 'Y' AND p.playerid = pl.playerid
--      AND pl.schoolid = sc.schoolid AND sc.schoolState LIKE 'CA'
--    ORDER BY ha.yearid DESC, pl.schoolid, p.playerid

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT q2i.playerid, namefirst, namelast, schoolid
  FROM q2i
  LEFT OUTER JOIN collegeplaying C ON C.playerid = q2i.playerid
  ORDER BY q2i.playerid DESC, schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
WITH slg_cal AS (
  SELECT playerid, yearid, ((H - H2B - H3B - HR) + 2*H2B + 3*H3B + 4*HR) / CAST(AB AS FLOAT) AS slg
  FROM batting
  WHERE AB > 50
)
  SELECT P.playerid, namefirst, namelast, yearid, slg
  FROM people P, slg_cal S
  WHERE P.playerid = S.playerid
  ORDER BY slg DESC, yearid, P.playerid
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
WITH bat_sum AS (
  SELECT playerid, SUM(H) AS LH, SUM(H2B) AS L2B, SUM(H3B) AS L3B, SUM(HR) AS LHR, SUM(AB) AS LAB
  FROM batting
  GROUP BY playerid
),
  lslg_cal AS (
  SELECT playerid, ((LH - L2B - L3B - LHR) + 2*L2B + 3*L3B + 4*LHR) / CAST(LAB AS FLOAT) AS lslg
  FROM bat_sum
  WHERE LAB > 50
)
  SELECT P.playerid, namefirst, namelast, lslg
  FROM people P, lslg_cal L
  WHERE P.playerid = L.playerid
  ORDER BY lslg DESC, P.playerid
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
WITH bat_sum AS (
  SELECT playerid, SUM(H) AS LH, SUM(H2B) AS L2B, SUM(H3B) AS L3B, SUM(HR) AS LHR, SUM(AB) AS LAB
  FROM batting
  GROUP BY playerid
  HAVING SUM(AB) > 50
),
  lslg_cal AS (
     SELECT playerid, ((LH - L2B - L3B - LHR) + 2*L2B + 3*L3B + 4*LHR) / CAST(LAB AS FLOAT) AS lslg
     FROM bat_sum
),
  goat AS (
    SELECT playerid, lslg
    FROM lslg_cal L
    WHERE L.playerid LIKE 'mayswi01'
  )

  SELECT namefirst, namelast, lslg
  FROM people P, lslg_cal L
  WHERE P.playerid = L.playerid AND L.lslg > (SELECT lslg FROM goat)
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
WITH range AS (
  SELECT binid, (min + binid*(max - min) / 10) AS low, (min + (binid + 1)*(max - min) / 10) AS high
  FROM binids,
       (SELECT MIN(salary) AS min, MAX(salary) AS max
        FROM salaries
        WHERE yearid = 2016
        GROUP BY yearid)
)
  SELECT binid, low, high, COUNT(*)
  FROM salaries S, range R
  WHERE yearid = 2016 AND ((binid < 9 AND salary >= low AND salary < high) OR (binid = 9 AND salary >= low AND salary <= high))
  GROUP BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT Q2.yearid, Q2.min - Q1.min, Q2.max - Q1.max, Q2.avg - Q1.avg
  FROM q4i Q1, q4i Q2
  WHERE Q1.yearid + 1 = Q2.yearid
  ORDER BY Q2.yearid
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT P.playerid, namefirst, namelast, S.salary, S.yearid
  FROM people P, salaries S, q4i Q
  WHERE P.playerid = S.playerid AND S.yearid = Q.yearid AND S.yearid IN (2000, 2001) AND S.salary >= Q.max
;

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT A.teamid, MAX(S.salary) - MIN(S.salary)
  FROM salaries S, allstarfull A
  WHERE S.yearid = 2016 AND S.yearid = A.yearid AND S.playerid = A.playerid
  GROUP BY A.teamid
;

