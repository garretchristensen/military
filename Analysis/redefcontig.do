cd $dir
cap log close
log using ./Logs/redefcontig.log, replace
cap rm ./Output/redefcontigP.txt
cap rm ./Output/redefcontigP.tex
cap rm ./Output/redefcontigLN.txt
cap rm ./Output/redefcontigLN.tex

set more off



**************************************************
*CONTIGUOUS CONSTRUCTION
**************************************************
foreach file in APP CON{   /*BEGIN CONSTRUCTION LOOP OVER BOTH FILES*/ 
 *generate a file of just deaths and recruits
 use ./Data/county`file'_raw.dta, clear
 sort statefips countyfips t
 keep statefips countyfips t monthcountydeath active
 save temp_contig`file'.dta, replace
 
 *expand neighboring counties for each month
 use ./Contiguous/contiguous.dta, clear
 rename name contiguousname
 gen new=_n
 expand 58 //create one obs for every month
 bys new: egen t=rank(_n)
 sort statefips2 countyfips2 t
 rename statefips2 statefips //fips2 is the center (non-neighbor) county
 rename countyfips2 countyfips
 merge m:1 statefips countyfips t using temp_contig`file'.dta
 tab _merge
 rename _merge mergecontig1
 
 /*GENERATE NEIGHBORING VARS*/
 *fips1 are the neighbor counties
 *deaths are from the center county.
 *so group by fips1s, and summ all the deaths to get deaths in all neighbors
 bysort statefips1 countyfips1 t: egen neighbordeath=sum(monthcountydeath)
 bysort statefips1 countyfips1 t: egen neighborsamestatedeath=sum(monthcountydeath) if statefips==statefips1
 bysort statefips1 countyfips1 t: egen neighborrecruit=sum(active)
 bysort statefips1 countyfips1 t: egen neighborsamestaterecruit=sum(active) if statefips==statefips1
 bysort statefips1 countyfips1 t: egen neighborcount=count(statefips)
 bysort statefips1 countyfips1 t: egen neighborsamestatecount=count(statefips) if statefips==statefips1
 replace neighborcount=neighborcount-1
 replace neighborsamestatecount=neighborsamestatecount-1
 replace neighbordeath=(neighbordeath-monthcountydeath)/100
 label var neighbordeath "Death in Neighbor County"
 replace neighborsamestatedeath=neighborsamestatedeath-monthcountydeath
 replace neighborrecruit=neighborrecruit-active
 replace neighborsamestaterecruit=neighborsamestaterecruit-active
 keep if samecounty==1 //keep just one observation from each county, month
 keep neighbor* statefips1 countyfips1 t
 rename statefips1 statefips
 rename countyfips1 countyfips
 save temp_contig`file', replace
 
 use ./Data/county`file'_raw.dta, clear
 sort statefips countyfips t
 merge 1:1 statefips countyfips t using temp_contig`file'
 rename _merge mergecontig2
 merge m:1 fips using ./Media/dma_counties_new.dta
 bysort dma00_1 month: egen mediadeath=total(monthcountydeath)
 *bysort dma00_1 month: egen mediasamestatedeath=total(monthcountydeath) if 
 /*HOW CAN I GET THIS TO WORK? THERE IS NO "HOME STATE" BASE OBSERVATION*/
 replace mediadeath=(mediadeath-monthcountydeath)/100
 tab monthcountydeath
 summ mediadeath
 if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
 *gen outofcountyX=outofcounty-neighborsamestatedeath
 /*HOW CAN I GET OUT OF COUNTY DEATHS TO NOT INCLUDE MEDIA, SINCE I DON'T KNOW IF MEDIA ARE FROM SAME STATE?*/
 
 save ./Data/`file'contig.dta, replace  
} /*END CONSTRUCTION LOOP OVER BOTH FILES*/ 

 
 ******************************************
 *PREP
 *******************************************
foreach file in APP CON { /*REG LOOP OVER BOTH FILES*/
if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}

 use ./Data/`file'contig.dta, replace
 destring month, replace //necessary for reghdfe command
 destring stateyear, replace //necessary for reghdfe command
 sort fips month
 foreach var in neighbordeath mediadeath{
  foreach X of numlist 1/2 {
   quietly gen L`X'`var'=`var'[_n-`X'] if fips[_n]==fips[_n-`X']
   quietly gen F`X'`var'=`var'[_n+`X'] if fips[_n]==fips[_n+`X']
  } 
 }
label var L1neighbordeath "Lag Death in Neighbor County"
label var L1mediadeath "Lag Death in Media Market County"
 
replace monthcountydeath=monthcountydeath/100
replace L1monthcountydeath=L1monthcountydeath/100
replace outofcounty=outofcounty/100
replace L1outofcounty=L1outofcounty/100
label var monthcountydeath "Current In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Current Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
 corr monthcountydeath L1monthcountydeath
 corr L1monthcountydeath L1neighbordeath
 corr L1monthcountydeath L1mediadeath
 corr L1mediadeath L1neighbordeath
 
 *******************************************
 *REGS
 *******************************************
 /*LINEAR LN*/
 
 reghdfe LNactive neighbordeath L1neighbordeath stateunemp countyunemp [aweight=avgcountypop], ///
	absorb(fips month stateyear) vce(cluster fips)  
 outreg2  using ./Output/redefcontigLN.txt, tex lab ///
	ct(`header') ti(Media and Contiguous Deaths) bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on deaths.", ///
	"Fixed effects are included separately by county and month as indiciated,", ///
	"The first five columns show applicants and the last five show contracts.", Filename:redefcontigLN.tex) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 reghdfe LNactive monthcountydeath L1monthcountydeath neighbordeath L1neighbordeath stateunemp countyunemp ///
	[aweight=avgcountypop], absorb(fips month stateyear) vce(cluster fips) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 outreg2 using ./Output/redefcontigLN.txt, tex lab ct(`header') bdec(3) tdec(3) bracket se append
 reghdfe LNactive mediadeath L1mediadeath stateunemp countyunemp  [aweight=avgcountypop], ///
	absorb(fips month) vce(cluster fips stateyear) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 outreg2 using ./Output/redefcontigLN.txt, tex lab ct(`header') bdec(3) tdec(3) bracket se append
 reghdfe LNactive monthcountydeath L1monthcountydeath mediadeath L1mediadeath stateunemp countyunemp ///
	[aweight=avgcountypop], absorb(fips month stateyear) vce(cluster fips) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 outreg2 using ./Output/redefcontigLN.txt, tex lab ct(`header') bdec(3) tdec(3) bracket se append
 reghdfe LNactive monthcountydeath L1monthcountydeath outofcounty L1outofcounty mediadeath L1mediadeath stateunemp ///
	countyunemp [aweight=avgcountypop], absorb(fips month stateyear) vce(cluster fips) ///
	addtext(County FE, YES, Month FE, YES, Stateyear FE, NO)
 outreg2 using ./Output/redefcontigLN.txt, tex lab ct(`header') bdec(3) tdec(3) bracket se append
 
 /*POISSON TAKES FOREVER*/
 /*POISSON*/
  *xtpoisson active monthcountydeath L1monthcountydeath stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
  *xtpoisson active outofcounty L1outofcounty stateunemp countyunemp monthfe3-monthfe58 statetrend2-statetrend51, fe exposure(avgcountypop) vce(robust)
 
 /*NEIGHBOR ONLY*/
 xtpoisson active neighbordeath L1neighbordeath stateunemp countyunemp monthfe3-monthfe58 /*statetrend2-statetrend51*/, ///
	fe exposure(avgcountypop) vce(robust)
 outreg2 using ./Output/redefcontigP.txt, ///
	ct(`file'justneighbor) ti(Poisson Regression of Media and Contiguous Deaths) addnote(redefcontigP.txt) ///
	lab tex bdec(3) tdec(3) bracket se append keep(neighbordeath L1neighbordeath stateunemp countyunemp) 
	addnote("Notes: Table shows Poisson regression estimates of national active duty recruits on deaths.", ///
	"Fixed effects are included separately by county and month as indiciated,", ///
	"The first five columns show applicants and the last five show contracts.", Filename:redefcontigP.tex) ///
	addtext(County FE, YES, Month FE, YES, State Trend, NO)
  /*IN-COUNTY, NEIGHBOR*/
  xtpoisson active monthcountydeath L1monthcountydeath neighbordeath L1neighbordeath stateunemp countyunemp ///
	monthfe3-monthfe58 /*statetrend2-statetrend51*/, fe exposure(avgcountypop) vce(robust)
  outreg2  using ./Output/redefcontigP.txt, keep(monthcountydeath L1monthcountydeath neighbordeath L1neighbordeath ///
	stateunemp countyunemp) lab tex ct(`file'neighbor) bdec(3) tdec(3) bracket se append ///
	addtext(County FE, YES, Month FE, YES, State Trend, NO)
  /*MEDIA ONLY*/
  xtpoisson active mediadeath L1mediadeath stateunemp countyunemp monthfe3-monthfe58 /*statetrend2-statetrend51*/, ///
	fe exposure(avgcountypop) vce(robust)
  outreg2 using ./Output/redefcontigP.txt, keep(mediadeath L1mediadeath stateunemp countyunemp) ct(`file'justmedia) ///
	bdec(3) tdec(3) bracket se append lab tex ///
	addtext(County FE, YES, Month FE, YES, State Trend, NO)
  /*IN-COUNTY, MEDIA*/
  xtpoisson active monthcountydeath L1monthcountydeath mediadeath L1mediadeath stateunemp countyunemp monthfe3-monthfe58 ///
	/*statetrend2-statetrend51*/, fe exposure(avgcountypop) vce(robust) ///
	addtext(County FE, YES, Month FE, YES, State Trend, NO)
  outreg2 using ./Output/redefcontigP.txt, keep(monthcountydeath L1monthcountydeath mediadeath L1mediadeath stateunemp countyunemp) ///
   ct(`file'media) bdec(3) tdec(3) bracket se append lab tex
  /*IN-COUNTY, NEIGHBOR, MEDIA*/
  xtpoisson active monthcountydeath L1monthcountydeath mediadeath L1mediadeath neighbordeath L1neighbordeath stateunemp ///
	countyunemp monthfe3-monthfe58 /*statetrend2-statetrend51*/, fe exposure(avgcountypop) vce(robust)
  outreg2 using ./Output/redefcontigP.txt, ct(`file'all) bdec(3) tdec(3) bracket se append lab tex ///
	keep(monthcountydeath L1monthcountydeath mediadeath L1mediadeath neighbordeath L1neighbordeath stateunemp countyunemp) ///
	addtext(County FE, YES, Month FE, YES, State Trend, NO)
 
} /*END REG LOOP OVER BOTH FILES*/
