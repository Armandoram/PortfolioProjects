Select * 
from [Portfolio Project]..CovidDeaths
where continent is not null
order by 3,4



select Location, date, total_cases, new_cases, total_deaths, population
from [Portfolio Project]..CovidDeaths
order by 1,2

-- looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you get Covid in your country
select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from [Portfolio Project]..CovidDeaths
where location like '%states%'
order by 1,2 DESC

--Total Cases vs Population
-- Shows percent of population got covid
select Location, date, total_cases, population, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
from [Portfolio Project]..CovidDeaths
where location like '%states%'
order by 1,2 DESC

-- Countries with Highest Infection percentage compared to Population
select Location,population, MAX(total_cases) as HighestInfectionsCount, MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100) AS PercentPopulationInfected
from [Portfolio Project]..CovidDeaths
--where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected Desc

--Show countries with Highest Death Count per Population

select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
--where location like '%states%'
where continent is not null
Group by Location
order by TotalDeathCount Desc

-- Showing the continents with highest death count
select continent,  MAX(cast(Total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount Desc

-- GLOBAL NUMBERS
SELECT 
    SUM(CAST(new_cases AS int)) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    SUM(CAST(new_deaths AS int)) * 100.0 
        / NULLIF(SUM(CAST(new_cases AS int)), 0) AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL;

-- Total Population vs Vaccinations


WITH PopvsVac AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        TRY_CONVERT(bigint, dea.population) AS Population,
        vac.new_vaccinations,
        SUM(TRY_CONVERT(bigint, vac.new_vaccinations))
            OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
            AS RollingPeopleVaccinated
    FROM [Portfolio Project]..CovidDeaths dea
    JOIN [Portfolio Project]..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       CASE 
           WHEN Population IS NULL OR Population = 0 THEN NULL
           ELSE (RollingPeopleVaccinated * 1.0 / Population) * 100
       END AS PercentVaccinated
FROM PopvsVac;

-- Using Temp Table to perform calculation on Partition By

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric(18,0),
    New_vaccinations numeric(18,0),
    RollingPeopleVaccinated numeric(18,0)
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    TRY_CONVERT(numeric(18,0), dea.population) AS Population,
    TRY_CONVERT(numeric(18,0), vac.new_vaccinations) AS New_vaccinations,
    SUM(TRY_CONVERT(bigint, vac.new_vaccinations))
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
        AS RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
       CASE
           WHEN Population IS NULL OR Population = 0 THEN NULL
           ELSE (RollingPeopleVaccinated * 1.0 / Population) * 100
       END AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;


-- Create view for later visualizations
Create View PercentPopulationVaccinated as
  SELECT
        dea.continent,
        dea.location,
        dea.date,
        TRY_CONVERT(bigint, dea.population) AS Population,
        vac.new_vaccinations,
        SUM(TRY_CONVERT(bigint, vac.new_vaccinations))
            OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
            AS RollingPeopleVaccinated
    FROM [Portfolio Project]..CovidDeaths dea
    JOIN [Portfolio Project]..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL

Select * 
from PercentPopulationVaccinated