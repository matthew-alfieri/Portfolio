--Total Population vs Total Cases
--Ordered by positive rate to show date with the highest positive rate (add TOP 1 in select to refine)
select location, date, population, total_cases, 
		round((total_cases/population)*100, 2) as positive_rate
from projectcovid..deaths
where total_cases != 0
and location like 'Japan'
order by 1, 5 desc


--Total Cases vs Total Deaths
--Rolling average of the death rate of covid, in this case Italy
select location, date, population, total_cases, total_deaths,
		round((total_deaths/total_cases)*100,2) as Death_Rate
from projectcovid..deaths
where total_cases != 0
and location like 'Italy'
order by 1


--New Deaths
--Finds the date where each continent had their highest recorded new deaths
with cte as (
	select location, date,
		new_deaths,
		ROW_NUMBER() over (partition by location order by new_deaths desc) as ranking
	from projectcovid..deaths
	where total_cases != 0
	and location in ('Asia','North America','South America','Europe','Africa','Oceania','World')
)
select location, date, new_deaths
from cte
where ranking = 1
order by location asc;


--Compare countries with highest total infected versus their population
select location, population, MAX(total_cases) as Highest_Infected_Count, 
		round(MAX((total_cases/population))*100, 2) as positive_rate
from projectcovid..deaths
where population != 0
and continent != ''
group by location, population
order by positive_rate desc


--Countries with the highest death count versus their population
SELECT location, population, MAX(total_deaths) as Total_Death_Count
FROM projectcovid..deaths
WHERE population != 0
AND continent != ''
GROUP BY location, population
ORDER BY Total_Death_Count desc


--Continent based statistics on total cases and deaths
SELECT continent, MAX(total_cases) as tot_cases, MAX(total_deaths) as tot_deaths
FROM projectcovid..deaths
WHERE continent != ''
GROUP BY continent
ORDER BY continent


--HDI vs Covid cases and deaths by country
SELECT v.location, MAX(d.total_cases) as Cases,
		MAX(d.total_deaths) as Deaths, v.human_development_index as HDI
FROM projectcovid..deaths d
JOIN projectcovid..vaccinations v
ON d.iso_code = v.iso_code AND d.date = v.date
WHERE v.continent != ''
GROUP BY v.location, v.human_development_index
HAVING MAX(d.total_cases) != 0
ORDER BY HDI desc


--Look at the countries with above average new cases per day in the year 2020 only
--Shows how fast covid spread, which can be compared to the actions taken by each country for effectivness
WITH avg_new_cases as (
	SELECT location, round(avg(new_cases),2) as Avg_Cases
	FROM projectcovid..deaths d
	WHERE new_cases != ''
		and continent != ''
		and YEAR(date) = 2020
	GROUP BY location
)
SELECT location, Avg_Cases
FROM avg_new_cases
WHERE Avg_Cases > (SELECT AVG(Avg_Cases)
					FROM avg_new_cases)
ORDER BY Avg_Cases DESC


--Look at the rolling sums of testing and then vaccinations in a country
SELECT d.location, d.date, 
		v.new_tests, SUM(cast(v.new_tests as int)) OVER (partition by d.Location ORDER BY d.location, d.date) as Rolling_Tests,
		v.new_vaccinations, SUM(cast(v.new_vaccinations as int)) OVER (partition by d.Location ORDER BY d.location, d.date) as Rolling_Vacs
FROM projectcovid..deaths d
JOIN projectcovid..vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent != ''
and d.location = 'Japan'
order by d.location, d.date


--Calculate percent of each country hospitalized using temp table(possible using existing table)
DROP TABLE if exists #PercentHospitalized
CREATE TABLE #PercentHospitalized
(
	Continent nvarchar(25),
	Location nvarchar(50),
	Population bigint,
	Hosp_patients int
)
INSERT INTO #PercentHospitalized (continent, location, population, Hosp_patients)
	SELECT continent, location, population, Hosp_patients
	FROM projectcovid..deaths d

SELECT location, ROUND((cast(hosp_patients as float)/population) * 100, 3) as hospitalization_percent
from #PercentHospitalized
where population != 0 and continent != ''
order by hospitalization_percent desc


--Create view for later use
CREATE VIEW HighestRecordedDeath as 
	with cte as (
	select location, date,
		new_deaths,
		ROW_NUMBER() over (partition by location order by new_deaths desc) as ranking
	from projectcovid..deaths
	where total_cases != 0
	and location in ('Asia','North America','South America','Europe','Africa','Oceania','World')
	)
	select location, date, new_deaths
	from cte
	where ranking = 1
	





















