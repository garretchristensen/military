//byservice
//3-30-2017 Redo the regressions of death by service and recruits by service, L and P, as requested by referee.

clear all
set more off
cd $dir

cap log close
log using ./Logs/servicebranch-simple.smcl, replace

cap rm ./Output/servicebranchrecP.txt
cap rm ./Output/servicebranchrecLN.txt
cap rm ./Output/servicebranchdeathP.txt
cap rm ./Output/servicebranchdeathLN.txt
cap rm ./Output/servicebranchrecP.tex
cap rm ./Output/servicebranchrecLN.tex
cap rm ./Output/servicebranchdeathP.tex
cap rm ./Output/servicebranchdeathLN.tex

foreach file in APP CON{ /*BEGIN HUGE LOOP OVER BOTH FILES*/
use ./Data/county`file'_raw.dta, clear /*LOOPS OVER BOTH FILES!*/
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command
if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
} 
	foreach lag in "" L1 {
		foreach war in "" AR FR MR NR{
			replace `lag'`war'monthcountydeath=`lag'`war'monthcountydeath/100
			replace `lag'`war'outofcounty=`lag'`war'outofcounty/100
		}
	}
	
replace outofcounty=outofcounty/100
replace L1outofcounty=L1outofcounty/100
label var monthcountydeath "In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
label var L1ARmonthcountydeath "Army Lag In-County Deaths/100"
label var L1MRmonthcountydeath "Marines Lag In-County Deaths/100"
label var L1FRmonthcountydeath "Air Force Lag In-County Deaths/100"
label var L1NRmonthcountydeath "Navy Lag In-County Deaths/100"
label var L1ARoutofcounty "Army Lag Out-of-County Deaths/100"
label var L1FRoutofcounty "Air Force Lag Out-of-County Deaths/100"
label var L1MRoutofcounty "Marines Lag Out-of-County Deaths/100"
label var L1NRoutofcounty "Navy Lag Out-of-County Deaths/100" 
 
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
summ L1ARmonthcountydeath //Make sure this is between 0 and .0X not 0 to X.
if r(max)<.01|r(max)>1 {
	display "you divided Army deaths by 100 too little/much"
	throw a hissy fit
}
summ L1ARoutofcounty //Make sure this is between 0 and .0X not 0 to X.
if r(max)<.01|r(max)>1 {
	display "you divided Army OOC deaths by 100 too little/much"
	throw a hissy fit
}

********************************************************************
/*(1)RECRUITS OF DIFFERENT SERVICES--OLS*/
foreach service in AR FR MR NR{
if "`service'"=="AR"{
	local header2="Army"
}
if "`service'"=="FR"{
	local header2="Air Force"
}
if "`service'"=="MR"{
	local header2="Marines"
}
if "`service'"=="NR"{
	local header2="Navy"
}

 gen LN`service'monthcounty=ln(`service'monthcounty+1)
 reghdfe LN`service'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp ///
	 [aweight=avgcountypop], vce(cluster fips) absorb(fips month stateyear)
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/servicebranchrecLN.txt, ///
	tex label ct(`header', `header2') ti(Recruits by Service Branch vs Deaths and Unemployment) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES) ///
	addnote("Notes: Table shows linear regression estimates of log (service branch active duty recruits +1) on deaths.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indicated,", ///
	"The first four columns show applicants and the last four show contracts.", Filename:servicebranchrecLN.tex) 
/*RECRUITS OF DIFFERENT SERVICES--POISSON*/

 xtpoisson `service'monthcounty monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 ///
	statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 estimates store `service'
 outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty stateunemp countyunemp using ./Output/servicebranchrecP.txt, ///
	tex label ct(`header', `header2') ti(Recruits by Service Branch vs Deaths and Unemployment--Poisson) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, Statetrend, YES) ///
	drop(monthfe3-monthfe58 statetrend2-statetrend51) ///
	addnote("Notes: Table shows Poisson regression estimates of service branch active duty recruits on deaths.", ///
	"Fixed effects are included separately by county and month, and linear trends for each state, as indicated,", ///
	"The first four columns show applicants and the last four show contracts.", Filename:servicebranchrecP.tex) 
}

**********************************************************************************************
*DEATHS OF DIFFERENT SERVICES
/*ONLY LOCAL SPLIT OUT*/
*LN
reghdfe LNactive monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath ///
	outofcounty L1outofcounty stateunemp countyunemp, vce(cluster fips) absorb(fips month stateyear)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 using ./Output/servicebranchdeathLN.txt, tex label ct(`header') bdec(3) tdec(3) bracket se ///
	addstat("Test Lag County Deaths", r(p)) append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES) ///
	ti(Recruits vs Deaths by Service Branch and Unemployment) ///
	addnote("Notes: Table shows linear regression estimates of log (active duty recruits +1) on deaths in a particular service branch.", ///
	"Fixed effects are included separately by county and month, and for each state-year, as indiciated,", ///
	"The first two columns show applicants and the last two show contracts.", Filename:servicebranchdeathLN.tex) 
	
/*LOCAL AND STATE SPLIT OUT*/
*LN
reghdfe LNactive monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath ///
	outofcounty L1ARoutofcounty L1FRoutofcounty L1MRoutofcounty L1NRoutofcounty stateunemp countyunemp, ///
	vce(cluster fips) absorb(fips month stateyear)	
test L1ARoutofcounty=L1FRoutofcounty=L1MRoutofcounty=L1NRoutofcounty
local LagState=r(p)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 using ./Output/servicebranchdeathLN.txt, tex label ct(`header') bdec(3) tdec(3) bracket se ///
	addstat("Test Lag County Deaths", r(p), "Test Lag State", `LagState') append ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, YES) 
	

/*ONLY LOCAL SPLIT OUT*/
/*Poisson*/
xtpoisson active monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath outofcounty L1outofcounty ///
	stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 using ./Output/servicebranchdeathP.txt, tex label ct(`header') bdec(3) tdec(3) bracket se ///
	addstat("Test Lag County Deaths", r(p)) append ///
	addtext(County FE, YES, Month FE, YES, Statetrend, YES) ///
	ti(Recruits vs Deaths by Service Branch and Unemployment--Poisson) ///
	addnote("Notes: Table shows Poisson regression estimates of active duty recruits on deaths in a particular service branch.", ///
	"Fixed effects are included separately by county and month, and linear trends for each state", ///
	"The first two columns show applicants and the last two show contracts.", Filename:servicebranchdeathP.tex) ///
	drop(monthfe3-monthfe58 statetrend2-statetrend51)


/*LOCAL AND STATE SPLIT OUT*/
*POISSON
xtpoisson active monthcountydeath L1ARmonthcountydeath L1FRmonthcountydeath L1MRmonthcountydeath L1NRmonthcountydeath ///
	outofcounty L1ARoutofcounty L1FRoutofcounty L1MRoutofcounty L1NRoutofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
test L1ARoutofcounty=L1FRoutofcounty=L1MRoutofcounty=L1NRoutofcounty
local LagState=r(p)
test L1ARmonthcountydeath=L1FRmonthcountydeath=L1MRmonthcountydeath=L1NRmonthcountydeath
outreg2 using ./Output/servicebranchdeathP.txt, tex label ct(`header') bdec(3) tdec(3) bracket se ///
	addstat("Test Lag County Deaths", r(p), "Test Lag State", `LagState') append ///
	addtext(County FE, YES, Month FE, YES, Statetrend, YES) ///
	drop(monthfe3-monthfe58 statetrend2-statetrend51)

} //Loop over both APP and CON
