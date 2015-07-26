*2014.11.27
*This file takes the 1990-2010 Death data from my FOIA that has already been collapsed by date, using death_build90.do
*and summarizes it by year, for the data summary table (Likely called Table 1)
*Originally I constructed the top half of Table 1 with the public data, but since I use the FOIA data for regressions
*I might as well make the table from FOIA data as well.

cd $dir
set more off
clear all
cap log close
log using .\Logs\DataSummaryTable.smcl, replace

use .\Deaths\deathsbydate90.dta 
gen year=floor(date/10000)
label var year "Year of Death"

bysort year: egen dbyy=total(totaldeaths)
label var dbyy "total deaths by year"

bysort year: egen hdbyy=total(totalHdeaths)
label var hdbyy "total Hostile deaths by year"

sort year
duplicates drop year, force
