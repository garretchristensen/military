//byservice
//3-30-2017 Redo the regressions of death by service and recruits by service, L and P, as requested by referee.

clear all
set more off
cd $dir

cap log close
log using ./Logs/servicebranch-simple.smcl, replace

*cap rm ./Output/servicebranchP.txt
*cap rm ./Output/servicebranchLN.txt

use ./Data/county`file'_raw.dta, clear /*LOOPS OVER BOTH FILES!*/
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command
if "`file'"=="APP"{
	local header1="Applicants"
}
else{
	local header1="Contracts"
}
foreach var in monthcountydeath outofcounty { 
	foreach lag in "" L1 {
		foreach war in "" AR FR MR NR{
			replace `lag'`war'`var'=`lag'`war'`var'/100
		}
	}
}
label var monthcountydeath "In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
label var AFGHANmonthcountydeath "Afghanistan In-County Deaths/100"
label var L1AFGHANmonthcountydeath "Afghanistan Lag In-County Deaths/100"
label var AFGHANoutofcounty "Afghanistan Out-of-County Deaths/100"
label var L1AFGHANoutofcounty "Afghanistan Lag Out-of-County Deaths/100" 
label var IRAQmonthcountydeath "Iraq In-County Deaths/100"
label var L1IRAQmonthcountydeath "Iraq Lag In-County Deaths/100"
label var IRAQoutofcounty "Iraq Out-of-County Deaths/100"
label var L1IRAQoutofcounty "Iraq Lag Out-of-County Deaths/100" 
 
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}

********************************************************************
/*(1)RECRUITS OF DIFFERENT SERVICES--OLS*/
foreach service in AR FR MR NR{
 gen LN`service'monthcounty=ln(`service'monthcounty)
 reghdfe LN`service'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp ///
	statetrend2-statetrend51 [aweight=avgcountypop], robust cluster(fips) absorb(fips month)
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/servicebranchrecLN.txt, ///
	ct(`file'`service'recs) bdec(3) tdec(3) bracket se append
}
/*RECRUITS OF DIFFERENT SERVICES--POISSON*/
foreach service in AR FR MR NR{
 xtpoisson `service'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 ///
	statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 estimates store `service'
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/servicebranchrecP.txt, tex ///
	ct(`file'`service'recs) bdec(3) tdec(3) bracket se append
}
*/
/*(3)DEATHS OF DIFFERENT SERVICES--POISSON*/
/*FIRST RESIZE AND GEN LAGS FOR ALL TYPES OF DIFFERENT DEATHS*/
/*sort fips month
foreach type in AR FR MR NR WHITE BLACK HISP OTH H notH FEMALE MALE IRAQ AFGHAN {
 foreach var in monthcountydeath outofcounty{
  quietly gen L1`type'`var'=`type'`var'[_n-1]/100 if fips[_n]==fips[_n-1]
  quietly replace `type'`var'=`type'`var'/100
 } 
}
*/


/*ONLY LOCAL SPLIT OUT*/
/*LN*/
reghdfe LNactive monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath ///
	outofcounty L1outofcounty stateunemp countyunemp statetrend2-statetrend51, robust cluster(fips) absorb(fips month) 
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp  using ./Output/servicebranchdeathLN.txt, tex ct(`file'servicedeath) bdec(3) tdec(3) bracket se adds("Test Lag County Deaths", r(p)) append

/*ONLY LOCAL SPLIT OUT*/
/*Poisson*/
xtpoisson active monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1outofcounty stateunemp ///
	countyunemp  using ./Output/servicebranchdeath.txt, tex ct(`file'servicedeath) bdec(3) tdec(3) bracket se adds("Test Lag County Deaths", r(p)) append


/*LOCAL AND STATE SPLIT OUT*/
xtpoisson active monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1ARoutofcounty L1FRoutofcounty L1MRoutofcounty L1NRoutofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1ARoutofcounty=L1FRoutofcounty=L1MRoutofcounty=L1NRoutofcounty
local LagState=r(p)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1ARoutofcounty L1FRoutofcounty L1MRoutofcounty L1NRoutofcounty stateunemp countyunemp  using ./Output/redefbyservicedeath.txt, ct(`file'wstate) bdec(3) tdec(3) bracket se adds("Test Lag County Deaths", r(p), "Test Lag State", `LagState') append

} //Loop over both APP and CON
