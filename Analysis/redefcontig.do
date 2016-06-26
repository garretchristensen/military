cd $dir
cap log close
log using ./Logs/redefcontig.log, replace
cap rm ./Output/redefcontigP.txt
cap rm ./Output/redefcontigLN.txt

set more off


foreach file in APP CON{   /*BEGIN CONSTRUCTION LOOP OVER BOTH FILES*/
 use ./Data/county`file'_raw.dta, clear
 sort statefips countyfips t
 keep statefips countyfips t monthcountydeath active
 save temp_contig`file'.dta, replace
 use ./Contiguous/contiguous.dta, clear
 rename name contiguousname
 gen new=_n
 expand 58
 bys new: egen new2=rank(_n)
 gen t=-1+new2 
 sort statefips2 countyfips2 t
 rename statefips2 statefips
 rename countyfips2 countyfips
 merge statefips countyfips t using temp_contig`file'.dta
 rename _merge mergecontig1
 /*GENERATE NEIGHBORING VARS*/
 bysort statefips1 countyfips1 t: egen neighbordeath=sum(monthcountydeath)
 bysort statefips1 countyfips1 t: egen neighborsamestatedeath=sum(monthcountydeath) if statefips==statefips1
 bysort statefips1 countyfips1 t: egen neighborrecruit=sum(active)
 bysort statefips1 countyfips1 t: egen neighborsamestaterecruit=sum(active) if statefips==statefips1
 bysort statefips1 countyfips1 t: egen neighborcount=count(statefips)
 bysort statefips1 countyfips1 t: egen neighborsamestatecount=count(statefips) if statefips==statefips1
 replace neighborcount=neighborcount-1
 replace neighborsamestatecount=neighborsamestatecount-1
 replace neighbordeath=neighbordeath-monthcountydeath
 replace neighborsamestatedeath=neighborsamestatedeath-monthcountydeath
 replace neighborrecruit=neighborrecruit-active
 replace neighborsamestaterecruit=neighborsamestaterecruit-active
 keep if samecounty==1
 keep neighbor* statefips1 countyfips1 t
 rename statefips1 statefips
 rename countyfips1 countyfips
 save temp_contig`file', replace
 use ./Data/`file'.dta, clear
 sort statefips countyfips t
 merge 1:1 statefips countyfips t using temp_contig`file'
 rename _merge mergecontig2
 merge m:1 fips using ./Media/dma_counties_new.dta
 bysort dma00_1 month: egen mediadeath=total(monthcountydeath)
 *bysort dma00_1 month: egen mediasamestatedeath=total(monthcountydeath) if 
 /*HOW CAN I GET THIS TO WORK? THERE IS NO "HOME STATE" BASE OBSERVATION*/
 replace mediadeath=mediadeath-monthcountydeath
 tab monthcountydeath
 tab mediadeath
 *gen outofcountyX=outofcounty-neighborsamestatedeath
 /*HOW CAN I GET OUT OF COUNTY DEATHS TO NOT INCLUDE MEDIA, SINCE I DON'T KNOW IF MEDIA ARE FROM SAME STATE?*/
 
 save ./Data/`file'contig.dta, replace  
} /*END CONSTRUCTION LOOP OVER BOTH FILES*/ 

 
foreach file in county countyCON { /*REG LOOP OVER BOTH FILES*/
 use ./Data/`file'contig.dta, replace
 sort fips month
 foreach var in neighbordeath mediadeath{
  foreach X of numlist 1/2 {
   quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
   quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
  } 
 }
 corr monthcountydeath L1monthcountydeath
 corr L1monthcountydeath L1neighbordeath
 corr L1monthcountydeath L1mediadeath
 corr L1mediadeath L1neighbordeath
 
 /*POISSON*/
  *xtpoisson active monthcountydeath L1monthcountydeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
  *xtpoisson active outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
  
  /*NEIGHBOR ONLY*/
  xtpoisson active neighbordeath L1neighbordeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
   outreg2 neighbordeath L1neighbordeath stateunemp countyunemp  using ./Output/redefcontigP.txt, ct(`file'justneighbor) ti(Poisson Regression of Media and Contiguous Deaths) addnote(redefcontigP.txt EML) bdec(3) tdec(3) bracket se append
  /*IN-COUNTY, NEIGHBOR*/
  xtpoisson active monthcountydeath L1monthcountydeath neighbordeath L1neighbordeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
   outreg2 monthcountydeath L1monthcountydeath neighbordeath L1neighbordeath stateunemp countyunemp  using ./Output/redefcontigP.txt, ct(`file'neighbor) bdec(3) tdec(3) bracket se append
  /*MEDIA ONLY*/
  xtpoisson active mediadeath L1mediadeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
   outreg2 mediadeath L1mediadeath stateunemp countyunemp  using ./Output/redefcontigP.txt, ct(`file'justmedia) bdec(3) tdec(3) bracket se append
  /*IN-COUNTY, MEDIA*/
  xtpoisson active monthcountydeath L1monthcountydeath mediadeath L1mediadeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
   outreg2 monthcountydeath L1monthcountydeath mediadeath L1mediadeath stateunemp countyunemp  using ./Output/redefcontigP.txt, ct(`file'media) bdec(3) tdec(3) bracket se append
  /*IN-COUNTY, NEIGHBOR, MEDIA*/
  xtpoisson active monthcountydeath L1monthcountydeath mediadeath L1mediadeath neighbordeath L1neighbordeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
   outreg2 monthcountydeath L1monthcountydeath mediadeath L1mediadeath neighbordeath L1neighbordeath stateunemp countyunemp  using ./Output/redefcontigP.txt, ct(`file'all) bdec(3) tdec(3) bracket se append
 /*
 /*LINEAR LN*/
  areg LNactive neighbordeath L1neighbordeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51[aweight=avgcountypop], absorb(fips) cluster(fips) robust 
   outreg2 neighbordeath L1neighbordeath stateunemp countyunemp  using ./Output/redefcontigLN.txt, ct(`file'justneighbor) ti(Regression of Nat'l Log Media and Contiguous Deaths) addnote(redefcontigLN.txt EML) bdec(3) tdec(3) bracket se append
  areg LNactive monthcountydeath L1monthcountydeath neighbordeath L1neighbordeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51 [aweight=avgcountypop], absorb(fips) cluster(fips) robust
   outreg2 monthcountydeath L1monthcountydeath neighbordeath L1neighbordeath stateunemp countyunemp  using ./Output/redefcontigLN.txt, ct(`file'neighbor) bdec(3) tdec(3) bracket se append
  areg LNactive mediadeath L1mediadeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51 [aweight=avgcountypop], absorb(fips) cluster(fips) robust
   outreg2 mediadeath L1mediadeath stateunemp countyunemp  using ./Output/redefcontigLN.txt, ct(`file'justmedia) bdec(3) tdec(3) bracket se append
  areg LNactive monthcountydeath L1monthcountydeath mediadeath L1mediadeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51 [aweight=avgcountypop], absorb(fips) cluster(fips) robust
   outreg2 monthcountydeath L1monthcountydeath mediadeath L1mediadeath stateunemp countyunemp  using ./Output/redefcontigLN.txt, ct(`file'media) bdec(3) tdec(3) bracket se append
  areg LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty mediadeath L1mediadeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51[aweight=avgcountypop], absorb(fips) cluster(fips) robust
   outreg2 monthcountydeath L1monthcountydeath outofcounty L1outofcounty mediadeath L1mediadeath stateunemp countyunemp  using ./Output/redefcontigLN.txt, ct(`file'all) bdec(3) tdec(3) bracket se append
 */
 
} /*END REG LOOP OVER BOTH FILES*/
