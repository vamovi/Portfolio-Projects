CREATE TABLE CovidVaccinations (
    Iso_code VARCHAR(50),
    Continent VARCHAR(50),
    Location VARCHAR(50),
    Date DATE,
    Total_tests	INT,
    New_tests	INT,
    Total_tests_per_thousand INT,
    New_tests_per_thousand	INT,
    New_tests_smoothed INT,
    New_tests_smoothed_per_thousand	INT,
    Positive_rate INT,
    Tests_per_case	INT,
    Tests_units	VARCHAR(50),
    Total_vaccinations	INT,
    People_vaccinated INT,
    People_fully_vaccinated	INT,
    Total_boosters	INT,
    New_vaccinations INT,
    New_vaccinations_smoothed	INT,
    Total_vaccinations_per_hundred	INT,
    People_vaccinated_per_hundred INT,
    People_fully_vaccinated_per_hundred	INT,
    Total_boosters_per_hundred	INT,
    New_vaccinations_smoothed_per_million	INT,
    New_people_vaccinated_smoothed	INT,
    New_people_vaccinated_smoothed_per_hundred	INT,
    Stringency_index INT,
    Population_density INT,	
    Median_age	INT,
    Aged_65_older	INT,
    Aged_70_older	INT,
    Gdp_per_capita	INT,
    Extreme_poverty	INT,
    Cardiovasc_death_rate INT,	
    Diabetes_prevalence	INT,
    Female_smokers	INT,
    Male_smokers	INT,
    Handwashing_facilities INT,
    Hospital_beds_per_thousand	INT,
    Life_expectancy	INT,
    Human_development_index	INT,
    Excess_mortality_cumulative_absolute	INT,
    Excess_mortality_cumulative	INT,
    Excess_mortality	INT,
    Excess_mortality_cumulative_per_million INT
) 


BULK insert dbo.CovidVaccinations
FROM '/CovidVaccinations.csv'

With
(
    FORMAT = 'CSV',
    FIRSTROW = 2
)
GO

CREATE TABLE NamesVal 
(
    Names VARCHAR(30),
    Age int
)

select *
from NamesVal

BULK insert dbo.CovidVaccinations
FROM '/NamesVal.csv'
With
(
    FORMAT = 'CSV',
    FIRSTROW = 2
)
GO
DROP TABLE IF EXISTS CovidVaccinations

Select top 3 *
FROM CovidVaccinations;

Select * 
From CovidDeaths 
order by 3, 4;

-- Select data that we are going to be using 

Select Location, date, total_cases, new_cases, total_deaths, population 
From CovidDeaths;

Select * 
From CovidVaccinations
order by 1, 2;

-- looking at total cases vs total deaths 

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where location like '%states%'
order by 1, 2

-- looking at total cases vs population 
Select Location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
From CovidDeaths
Where location like '%colombia%'
order by 1, 2


--Looking at countries with highest infection rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as 
PercentPopulationInfected
from CovidDeaths
Group by Location, population
order by PercentPopulationInfected desc

-- showing countries with highest Death Count per population

Select Location, MAX(cast(Total_Deaths as int)) as TotalDeathCount
from CovidDeaths
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- Let's break things down by continent

Select location, MAX(cast(Total_Deaths as int)) as TotalDeathCount
from CovidDeaths
Where continent is null
Group by location
order by TotalDeathCount desc

-- Global numbers

Select SUM(new_cases) as total_cases, SUM(cast (new_deaths as int)) as total_deaths, SUM(cast (new_deaths as int))/ SUM(new_cases)*100 as DeathPercentage 
From CovidDeaths
Where continent is not null and new_cases !=  '0'
--Group by date
order by 1, 2   

Select MIN(new_cases)
From CovidDeaths
Where continent is not NULL 

-- looking at total population vs vaccinations 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) over (PARTITION by dea.location order by dea.location, 
dea.date)
From CovidDeaths as dea 
Join CovidVaccinations as vac   
    On dea.location = vac.location 
    and dea.date = vac.date
Where dea.continent is not NULL    
order by  2, 3

-- CTE

with PopvsVac(Continent, location, date, population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) over (PARTITION by dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
From CovidDeaths as dea 
Join CovidVaccinations as vac   
    On dea.location = vac.location 
    and dea.date = vac.date
Where dea.continent is not NULL    
)

Select *, (RollingPeopleVaccinated/Population)*100 
From PopvsVac

-- Creating View to store data for later visualization

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) over (PARTITION by dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
From CovidDeaths as dea 
Join CovidVaccinations as vac   
    On dea.location = vac.location 
    and dea.date = vac.date
Where dea.continent is not NULL   

Select *
from PercentPopulationVaccinated