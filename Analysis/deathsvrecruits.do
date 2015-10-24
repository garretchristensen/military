/*DEATH NUMBERS AND RECRUIT NUMBERS*/
//NATIONAL LEVEL RECRUITS AND DEATHS, simple analysis with 58 observations.

clear all
set more off
set mem 200m
cd $dir
cap rm ./Output/deathsvrecruits.txt
cap rm ./Output/deathsvrecruitsSEMI.txt
cap rm ./Ouput/deathsvrecruitsSEMI.tex
cap rm ./Output/deathsvrecruitsP.txt
cap rm ./Ouput/deathsvrecruitsP.tex


foreach file in APP CON{ /*BEGIN HUGE LOOP OVER BOTH FILES*/

use ./Apps/`file'_bydate2000.dta, clear
sort date
merge 1:1 date using ./Deaths/deathsbydate

/*KEEP ONLY THE DATES FOR WHICH I HAVE RECRUIT NUMBERS*/
drop if date<20011000|date>=20060800
tostring date, gen(month)
replace month=substr(month, 1, 6)
/*COLLAPSE DEATHS BY MONTH*/
bysort month: egen monthdeathUS=total(totalUS)
bysort month: egen monthdeathtotal=total(totaldeaths)
bysort month: egen monthapptotal=total(totapp)
bysort month: egen monthARtotal=total(AR)

label var monthdeathtotal "Current Deaths"
label var monthapptotal "Total Applicants"
label var monthARtotal "Total Active Duty Applicants"
count
duplicates drop month, force
count
/*GRAPH RECRUITS AND DEATHS BY MONTH*/
keep month type month*
sort month
save ./Deaths/deathsbymonth, replace
gen mo=substr(month,5,2)
destring mo, replace
gen year=substr(month,1,4)
destring year, replace
generate fancymonth=ym(year,mo)
destring fancymonth, replace
format fancymonth %tm
tsset fancymonth

/*SIMPLE TIME SERIES REGRESSION*/
gen t=fancymonth-501
label var t "Linear Time Trend"
sort fancymonth
replace monthdeathtotal=.0000001 if month=="200207" /*NO DEATHS THIS MONTH--CHEAP FIX*/
gen lag1monthdeath=monthdeathtotal[_n-1]
label var lag1monthdeath "Lag Deaths"

/*FIX UNITS SO ESTIMATES AREN'T ALL ZEROES*/
replace monthdeathtotal=monthdeathtotal/100
replace lag1monthdeath=lag1monthdeath/100
/*
reg monthapptotal monthdeathtotal
estat bgodfrey, lags (1 2 3 4)
estat dwatson
estat durbinalt
 *outreg2 using ./Output/deathsvrecruits.txt, append ti(Total Apps vs. Total Deaths) addnote(deathsvrecruits.txt) ct (`file'None) bdec(3) tdec(3) bracket se  
newey monthapptotal monthdeathtotal, lag(4)
 *outreg2 using ./Output/deathsvrecruits.txt, ct(Newey4) bdec(3) tdec(3) bracket se  append
newey monthapptotal monthdeathtotal lag1monthdeath, lag(4)
 *outreg2 using ./Output/deathsvrecruits.txt, ct(LagNewey4) bdec(3) tdec(3) bracket se  append
newey monthapptotal monthdeathtotal lag1monthdeath t, lag(4)
 *outreg2 using ./Output/deathsvrecruits.txt, ct(LagNewey4t) bdec(3) tdec(3) bracket se  append 
newey monthapptotal lag1monthdeath, lag(4)
 *outreg2 using ./Output/deathsvrecruits.txt, ct(LagonlyNewey4) bdec(3) tdec(3) bracket se  append
newey monthapptotal lag1monthdeath t, lag(4)
 *outreg2 using ./Output/deathsvrecruits.txt, ct(LagonlyNewey4t) bdec(3) tdec(3) bracket se  append
*/
/*SIMPLE DEATH/APP REGRESSION WITH LOGS*/
gen logmonthapptotal=log(monthapptotal)
label var logmonthapptotal "Log Applicants"
gen logmonthdeathtotal=log(monthdeathtotal)
label var logmonthdeathtotal "Log Monthly Deaths"
gen loglag1monthdeath=log(lag1monthdeath)
label var loglag1monthdeath "Log Lag Monthly Deaths"
/*
reg logmonthapptotal logmonthdeathtotal
estat bgodfrey, lags(1 2 3 4)
estat dwatson
estat durbinalt
 outreg2 using ./Output/deathsvrecruits.txt, ti(Log Total Apps vs. Log Total Deaths: Elasticity) addnote(deathsvrecruits.txt) ct(Log) bdec(3) tdec(3) bracket se append
newey logmonthapptotal logmonthdeathtotal, lag(4)
 outreg2 using ./Output/deathsvrecruits.txt, ct(LogNewey4) bdec(3) tdec(3) bracket se  append
newey logmonthapptotal logmonthdeathtotal loglag1monthdeath, lag(3)
 outreg2 using ./Output/deathsvrecruits.txt, ct(LogLagNewey4) bdec(3) tdec(3) bracket se  append
newey logmonthapptotal logmonthdeathtotal loglag1monthdeath t, lag(3)
 outreg2 using ./Output/deathsvrecruits.txt, ct(LogLagNewey4t) bdec(3) tdec(3) bracket se  append
newey logmonthapptotal loglag1monthdeath, lag(4)
 outreg2 using ./Output/deathsvrecruits.txt, ct(LogLagonlyNewey4) bdec(3) tdec(3) bracket se  append
newey logmonthapptotal loglag1monthdeath t, lag(4)
 outreg2 using ./Output/deathsvrecruits.txt, ct(LogLagonlyNewey4t) bdec(3) tdec(3) bracket se  append
*/

/*DAVID'S SUGGESTION--USE SEMI-ELASTICITY HERE, SINCE I DO THAT EVERYWHERE ELSE*/
reg logmonthapptotal monthdeathtotal
*estat bgodfrey, lags(1 2 3 4)
*estat dwatson
*estat durbinalt
 outreg2 using ./Output/deathsvrecruitsSEMI.txt, tex label ti(Log Total Apps vs. Total Deaths: Semi-Elasticity) ///
 addnote("Notes: Table shows linear regression estimates of log national monthly on recruits on deaths.", ///
 "The first three columns show applicants and the last three show contracts.", Filename:deathsvrecruitsSEMI.tex) ///
 cti(`file') cttop(Applicants,"","",Contracts,"","") bdec(3) tdec(3) bracket se append nocons addtext (Linear Trend, NO)
reg logmonthapptotal monthdeathtotal lag1monthdeath
 outreg2 using ./Output/deathsvrecruitsSEMI.txt, tex label bdec(3) tdec(3) cti(`file') bracket se append nocons addtext (Linear Trend, NO)
reg logmonthapptotal monthdeathtotal lag1monthdeath t
 outreg2 using ./Output/deathsvrecruitsSEMI.txt, drop(t) tex label bdec(3) tdec(3) bracket se cti(`file') append addtext (Linear Trend, YES) nocons cttop(Applicants,"","",Contracts,"","")

 
 *newey logmonthapptotal monthdeathtotal, lag(4)
* outreg2 using ./Output/deathsvrecruitsSEMI.txt, tex label ct(LogNewey4) bdec(3) tdec(3) bracket se  append
*newey logmonthapptotal monthdeathtotal lag1monthdeath, lag(3)
* outreg2 using ./Output/deathsvrecruitsSEMI.txt, tex label ct(LogLagNewey4) bdec(3) tdec(3) bracket se  append
*newey logmonthapptotal monthdeathtotal lag1monthdeath t, lag(3)
* outreg2 using ./Output/deathsvrecruitsSEMI.txt, tex label ct(LogLagNewey4t) bdec(3) tdec(3) bracket se  append
*newey logmonthapptotal lag1monthdeath, lag(4)
* outreg2 using ./Output/deathsvrecruitsSEMI.txt, tex label ct(LogLagonlyNewey4) bdec(3) tdec(3) bracket se  append
*newey logmonthapptotal lag1monthdeath t, lag(4)
* outreg2 using ./Output/deathsvrecruitsSEMI.txt, tex label ct(LogLagonlyNewey4t) bdec(3) tdec(3) bracket se  append

/*SEMI-ELASTICITIES USING POISSON*/
poisson monthapptotal monthdeathtotal
 outreg2 using ./Output/deathsvrecruitsP.txt, tex ti(Poisson Regression: Total Applicants vs. Total Deaths) ///
 addnote("Notes: Table shows Poisson regression estimates of total national monthly deaths on recruits.", ///
 "The first three columns show applicants and the last three show contracts.", Filename:deathsvrecruitsP.tex) ///
 ct(`file') bdec(3) tdec(3) bracket addstat(Likelihood, e(ll)) se append nocons label addtext (Linear Trend, NO)
poisson monthapptotal monthdeathtotal lag1monthdeath
 outreg2 using ./Output/deathsvrecruitsP.txt, tex ct(`file') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) nocons label addtext (Linear Trend, NO)
poisson monthapptotal monthdeathtotal lag1monthdeath t
 outreg2 using ./Output/deathsvrecruitsP.txt, drop(t) tex ct(`file') bdec(3) tdec(3) bracket se append addstat(Likelihood, e(ll)) nocons  label addtext (Linear Trend, YES)
*poisson monthapptotal lag1monthdeath
* outreg2 using ./Output/deathsvrecruitsP.txt, tex ct(LogLagonly) bdec(3) tdec(3) bracket se  append addstat(Likelihood, e(ll)) nocons
*poisson monthapptotal lag1monthdeath t
* outreg2 using ./Output/deathsvrecruitsP.txt, tex ct(LogLagonlyt) bdec(3) tdec(3) bracket se  append addstat(Likelihood, e(ll)) nocons
 

} /*END HUGE LOOP OVER BOTH FILES*/
