--Select * 
--From PortfolioProject.. covid_deaths_fixed
--Order By 'location', 'date';

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.. covid_deaths_fixed
ORDER BY 'Location', 'date';

--Here we will be looking at total cases vs total deaths

 SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases*100) as death_percent
FROM PortfolioProject.. covid_deaths_fixed
WHERE location like '%states%'
ORDER BY 'Location', 'date'; 

--Changed like to "=" in order to only see States of the United States. % % included Virgin Islands

 SELECT Location, date, total_cases, population, (total_cases/population*100) as infection_rate
FROM PortfolioProject.. covid_deaths_fixed
WHERE location = 'United States'
ORDER BY 'Location', 'date'; 

--Now will look at countries with highest infection rate

 SELECT Location, population, Max(total_cases) as highest_infection_count, Max((total_cases/population)*100) Percent_population_infected
FROM PortfolioProject.. covid_deaths_fixed
GROUP BY location, population
ORDER BY Percent_population_infected desc;

--Checking out countries with highest death to population ratio

 SELECT Location, Max(total_deaths) as total_death_count
FROM PortfolioProject.. covid_deaths_fixed
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count desc; 

--Can also check out by continent

 SELECT location, Max(total_deaths) as total_death_count
FROM PortfolioProject.. covid_deaths_fixed
WHERE continent is null
GROUP BY location
ORDER BY total_death_count desc; 

--Global numbers examined, first by day/date

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as new_deaths_per_day, SUM(new_deaths)/SUM(nullif(new_cases, 0))*100 as death_percentage
FROM PortfolioProject.. covid_deaths_fixed
GROUP BY date
ORDER BY date, total_cases;

--Can then check out the total cases across the globe

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as new_deaths_per_day, SUM(new_deaths)/SUM(nullif(new_cases, 0))*100 as death_percentage
FROM PortfolioProject.. covid_deaths_fixed
--GROUP BY date
ORDER BY total_cases;

--Taking a look at the covid vaccinations table
SELECT*
FROM PortfolioProject.. covid_vaccinations_fixed

--Now we will be joinin the covid deaths table and the covid vaccinations table

SELECT*
FROM PortfolioProject.. covid_vaccinations_fixed as vac
JOIN PortfolioProject.. covid_deaths_fixed  as dea
	ON dea.location = vac.location
	and dea.date = vac.date

--Now can look at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject.. covid_vaccinations_fixed vac
JOIN PortfolioProject.. covid_deaths_fixed	dea
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 'location', 'date';

--Looking at specific countries. 


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject.. covid_vaccinations_fixed vac
JOIN PortfolioProject.. covid_deaths_fixed	dea
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null AND dea.location = 'Canada'
ORDER BY 'location', 'date';

--Can now calculate the total number of vaccinations by each location by partitioning by country.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as rolling_vaccination_count
FROM PortfolioProject.. covid_vaccinations_fixed vac
JOIN PortfolioProject.. covid_deaths_fixed	dea
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 'location', 'date';

--Can now use this information to get a percentage of the population who is vaccinated at each 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as rolling_vaccination_count
FROM PortfolioProject.. covid_vaccinations_fixed vac
JOIN PortfolioProject.. covid_deaths_fixed	dea
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 'location', 'date';

--Will now use a Common Table Expression (CTE) to delve further into the investigation

With Pop_vs_vacc(continent, location, date, population, new_vaccinations, rolling_vaccination_count)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as rolling_vaccination_count
FROM PortfolioProject.. covid_vaccinations_fixed vac
JOIN PortfolioProject.. covid_deaths_fixed	dea
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 'location', 'date';
)
SELECT *, (rolling_vaccination_count/population)*100
FROM Pop_vs_vacc

--Another option is to use a temp table to perform some of these calculations.
DROP TABLE if exists #Percent_population_vaccinated
--Keep to drop table in for maintenance
CREATE TABLE #Percent_population_vaccinated
	(
	continent nvarchar(255), 
	location nvarchar(255), 
	date datetime,
	population numeric,
	new_vaccinations numeric, 
	rolling_vaccination_count numeric)

INSERT INTO #Percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as rolling_vaccination_count
FROM PortfolioProject.. covid_vaccinations_fixed vac
JOIN PortfolioProject.. covid_deaths_fixed	dea
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 'location', 'date';

SELECT *, (rolling_vaccination_count/population)*100
FROM #Percent_population_vaccinated

--Can create a view to store the data for later visualizations

Create View Percent_People_Vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as rolling_vaccination_count
FROM PortfolioProject.. covid_vaccinations_fixed vac
JOIN PortfolioProject.. covid_deaths_fixed	dea
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 'location', 'date';


