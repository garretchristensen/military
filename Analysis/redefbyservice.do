clear all
set more off
set mem 3g
set maxvar 32767
set matsize 11000
cd /Users/gchrist1/Documents/Research/Military
cap log close
log using ./Logs/byservice.smcl, replace

/*
foreach file in county countyCON{ /*BEGIN HUGE DATA-MAKING LOOP OVER BOTH FILES*/
use ./Data/`file'.dta, clear
drop *G*
drop *V*
foreach var in A F N M{
 gen `var'Routofcounty=`var'Rmonthstatedeath-`var'Rmonthcountydeath
 gen `var'Routofstate=`var'Rmonthtotaldeath-`var'Rmonthstatedeath
}

gen recruits=ARmonthcounty
gen sdeath=ARmonthcountydeath
gen ssdeath=ARoutofcounty
gen tsdeath=ARoutofstate
gen xdeath=NRmonthcountydeath+FRmonthcountydeath+MRmonthcountydeath
gen sxdeath=NRoutofcounty+FRoutofcounty+MRoutofcounty
gen txdeath=NRoutofstate+FRoutofstate+MRoutofstate
gen unit="A"
gen AR=1
save temp_army, replace
drop AR

replace recruits=NRmonthcounty
replace sdeath=NRmonthcountydeath
replace ssdeath=NRoutofcounty
replace tsdeath=NRoutofstate
replace xdeath=ARmonthcountydeath+FRmonthcountydeath+MRmonthcountydeath
replace sxdeath=ARoutofcounty+FRoutofcounty+MRoutofcounty
replace txdeath=ARoutofstate+FRoutofstate+MRoutofstate
replace unit="N"
gen NR=1
save temp_navy, replace
drop NR

replace recruits=FRmonthcounty
replace sdeath=FRmonthcountydeath
replace ssdeath=FRoutofcounty
replace tsdeath=FRoutofstate
replace xdeath=ARmonthcountydeath+NRmonthcountydeath+MRmonthcountydeath
replace sxdeath=ARoutofcounty+NRoutofcounty+MRoutofcounty
replace txdeath=ARoutofstate+NRoutofstate+MRoutofstate
replace unit="F"
gen FR=1
save temp_airforce, replace
drop FR

replace recruits=MRmonthcounty
replace sdeath=MRmonthcountydeath
replace ssdeath=MRoutofcounty
replace tsdeath=MRoutofstate
replace xdeath=ARmonthcountydeath+NRmonthcountydeath+FRmonthcountydeath
replace sxdeath=ARoutofcounty+NRoutofcounty+FRoutofstate
replace txdeath=ARoutofstate+NRoutofstate+FRoutofstate
replace unit="M"
gen MR=1
save temp_marines, replace

append using temp_airforce temp_navy temp_army
foreach var in MR FR NR AR{
 replace `var'=0 if `var'==.
}
sort unit fips month
foreach var in sdeath xdeath ssdeath sxdeath tsdeath txdeath{
 foreach X of numlist 1/2 {
  quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
  quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
 } 
}
save ./Data/`file'by4.dta, replace
} /*END HUGE LOOP OVER BOTH FILES*/
*/

cap rm ./Output/redefbyservice.txt
cap rm ./Output/redefbyserviceP.txt
foreach file in county countyCON { /*BEGIN SMALL REG-RUNNING LOOP OVER BOTH FILES*/
use ./Data/`file'by4.dta, clear
replace unit="1" if unit=="A"
replace unit="2" if unit=="F"
replace unit="3" if unit=="M"
replace unit="4" if unit=="N"
gen fipsunit=string(fips)+unit
destring fipsunit, replace
foreach var in sdeath xdeath L1ssdeath L1sxdeath ssdeath sxdeath L1sdeath L1xdeath{
 replace `var'=`var'/100
}
tsset fipsunit fancymonth
/*
areg recruits  sdeath xdeath L1ssdeath L1sxdeath ssdeath sxdeath L1sdeath L1xdeath  stateunemp countyunemp monthfe3-monthfe58 [aweight=avgcountypop], absorb(fipsunit) cluster(fips) robust
test L1ssdeath=L1sxdeath
test L1sdeath=L1xdeath
outreg2 sdeath xdeath L1ssdeath L1sxdeath ssdeath sxdeath L1sdeath L1xdeath using ./Output/redefbyservice.txt, ct(fips) bdec(3) tdec(3) bracket se append
areg recruits sdeath xdeath L1ssdeath L1sxdeath ssdeath sxdeath L1sdeath L1xdeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51 [aweight=avgcountypop], absorb(fipsunit) cluster(fips) robust
test L1ssdeath=L1sxdeath
test L1sdeath=L1xdeath
outreg2 sdeath xdeath L1ssdeath L1sxdeath ssdeath sxdeath L1sdeath L1xdeath using ./Output/redefbyservice.txt, ct(statetrend) bdec(3) tdec(3) bracket se append
*/
xtpoisson recruits sdeath xdeath L1sdeath L1xdeath ssdeath sxdeath L1ssdeath L1sxdeath stateunemp countyunemp monthfe3-monthfe58, fe exposure(avgcountypop) vce(robust)
test ssdeath=sxdeath
local StateTest=r(p)
test L1ssdeath=L1sxdeath
local StateLagTest=r(p)
test sdeath=xdeath
local LocalTest=r(p)
test L1sdeath=L1xdeath
outreg2  sdeath xdeath L1sdeath L1xdeath ssdeath sxdeath L1ssdeath L1sxdeath using ./Output/redefbyserviceP.txt, ct(`file'fips) bdec(3) tdec(3) bracket se append addstat("Likelihood", e(ll), "State Test", `StateTest', "State Lag Test", `StateLagTest', "Local Test", `LocalTest', "Local Lag Test", r(p))

xtpoisson recruits sdeath xdeath L1sdeath L1xdeath ssdeath sxdeath L1ssdeath L1sxdeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
test ssdeath=sxdeath
local StateTest=r(p)
test L1ssdeath=L1sxdeath
local StateLagTest=r(p)
test sdeath=xdeath
local LocalTest=r(p)
test L1sdeath=L1xdeath
outreg2 sdeath xdeath L1sdeath L1xdeath ssdeath sxdeath L1ssdeath L1sxdeath using ./Output/redefbyserviceP.txt, ct(`file'fips+trend) bdec(3) tdec(3) bracket se addstat("Likelihood", e(ll), "State Test", `StateTest', "State Lag Test", `StateLagTest', "Local Test", `LocalTest', "Local Lag Test", r(p)) append 
} /*END REG-RUNNING LOOP*/

