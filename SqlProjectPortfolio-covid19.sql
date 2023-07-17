select*
from CovidVaccinations

Select*
from CovidDeaths

-- To see the data (rows) same for both with 

select*
from CovidVaccinations
order by 3,4

Select*
from CovidDeaths
order by 3,4

-- Select Data that we are going to be using
select location, date, total_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total cases vs total Deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)
from PortfolioProject..CovidDeaths
order by 1,2


--Change column type total_cases and total_deaths from nvarchar to int,as out these column are in varchar so showing error in dividing

Alter table CovidDeaths
Alter column total_cases float

Alter table CovidDeaths
Alter column total_Deaths float

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
order by 1,2

--Shows likelihood of dying if you contract covid in yourv country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%Asia%'
order by 1,2

--Looking total case v s Polulation
--Shos what percentage of population got covid
select location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
from PortfolioProject..CovidDeaths
where location like '%Asia%'
order by 1,2

--For finding Death percentange
select location, date, population, total_deaths, (total_deaths/population)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%Asia%'
order by 1,2

--Looking at Countries with Highest Infection rate comared to population

select location, population, max(total_cases) as HighestInfectionCont, max((total_cases/population))*100 CasePercentage
from PortfolioProject..CovidDeaths
Group by location, population
order by CasePercentage desc

--Showing countries with highest Death count per population
--
select location, max(total_deaths) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
Group by location
order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT

SELECT continent, max(total_deaths) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc


-- Now lets see globally total cases and deaths on date basis
select date, sum(new_cases) as total_cases , sum(new_deaths) as total_deaths , sum(new_deaths) / sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null and new_cases > 0 
group by date
order by 1,2 

--If we need to see total overall
select sum(new_cases) as total_cases , sum(new_deaths) as total_deaths , sum(new_deaths) / sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null and new_cases > 0 
order by 1,2 


--Now lets work with our another table "CovidVaccinations"
Select* from CovidVaccinations
order by 3 

--Lets join both the table for working
select*
from PortfolioProject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date

--Looking at total population vs vaccination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Lets look for 'INDIA'
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
and dea.location = 'india'
order by 2,3


--Now we need to create one more column which rolling counts new vaccination as the days passes and also have to remember it sums seperatey for new location(i.e partition by)
-- also new_vaccination was in nvarchar so istead of using alter to chnge it into int/float we can use cast/convert function in query itself to convert column from varchar to int
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as rollingpplvacc
from PortfolioProject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Now from rollingpplvacc we have to take highest number of vacc of that country and divide it by population to get the % of ppl got vaccinated in that country
-- but as we cannot use created column in query for further cal so we need to convert that into temp table or cte

--USING CTE (number of column in with popvsvacc should be same as in select one)


With PopvsVac (continent, location, date, population, new_vaccinations, rollingpplvacc)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as rollingpplvacc
-- ,(rollingpplvacc/population)*100
from PortfolioProject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select * , (rollingpplvacc/population)*100
from PopvsVac


--USING TEMP table 

Drop table if exists #PercentagePopulationVaccinated
create table #PercentagePopulationVaccinated
(continent nvarchar(255), 
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpplvacc numeric)


insert into #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as rollingpplvacc
-- ,(rollingpplvacc/population)*100
from PortfolioProject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select * , (rollingpplvacc/population)*100
from #PercentagePopulationVaccinated

--We also used drop table command in above query because we ran query just before this with somthing missing that we added again but it does'nt ran as temp table once created.

--Now we will create view (table)for later viaualizaion in tableau

Create view PercentagePopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as rollingpplvacc
-- ,(rollingpplvacc/population)*100
from PortfolioProject..CovidDeaths as dea
join PortfolioProject..CovidVaccinations as vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select*
from PercentagePopulationVaccinated