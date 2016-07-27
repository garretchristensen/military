//Garret Christensen
//Started January 24, 2016
//This file takes the compiled Occupation code data and tests whether people from different
//states go into different occupations in different percentages.

//The idea is that if people from different states are equally likely to go into the risky occupations
//then the hyper rational person wouldn't care where somebody who got killed is from.

//If, on the other hand, people from Tennessee are become infantry, and someone from Tennessee dies,
//then a potential enlistee from Tennessee might be rational to care more that someone from Tennessee died
//compared to when someone from California died.

//One could test this with the Pearson Chi-Square Test

/***************************************************
*PREP THE MASTER COUNTY LIST TO DROP MOS OBSERVATIONS FROM NON-EXISTENT COUNTIES
*****************************************************/
insheet using .\FOIA\MilitaryOccupations\raw\CensusCountyList.txt, clear
rename v1 state
rename v2 statenum
rename v3 county
rename v4 countyname
rename v5 fipsclasscode
keep state county
save .\FOIA\MilitaryOccupations\CensusCountyList.dta, replace

*Load MOS Data
clear all
use .\FOIA\MilitaryOccupations\Occupations.dta, replace

*count
*count if state=="ZZ"
*count if county=="ZZZ"
*count if state=="ZZ"|county=="ZZZ"
//No one with missing state has non-missing county
drop if state=="ZZ"
drop if state==""
drop if state=="PR"|state=="AS"|state=="GU"|state=="FM"|state=="MH"|state=="MP"|state=="PW"|state=="VI" //Puerto Rico's not in all the data sets.
drop if county==""
drop if county=="ZZZ"
drop if county=="RP8" //many county codes are nonsense
destring county, replace

//Keeps only the MOS observations that link to valid County IDs
merge m:1 state county using .\FOIA\MilitaryOccupations\CensusCountyList.dta, nogen keep(match)

/*CODEBOOK FOR MOS
-----------------------------------------------------------------------------------------------------------------------------------------------------------
MOS                                                                                                                         Military occupational specialty
-----------------------------------------------------------------------------------------------------------------------------------------------------------

                  type:  string (str5)

         unique values:  2391                     missing "":  7836/59806295

              examples:  "1C35"
                         "31S"
                         "63D"
                         "AM"
*/


*for starters just look at how many go into each branch in one month.
keep if yearmonth==200403 //use the middle month in the data in the main paper
	//have 58 months, div 2=29. starts in 200110, +29=200403
count

//Total in each service branch for whole country			
total(manpower)
local tT=_b[manpower]
total(manpower) if service=="A"
local aT=_b[manpower]
total(manpower) if service=="F"
local fT=_b[manpower]
total(manpower) if service=="M"
local mT=_b[manpower]
total(manpower) if service=="N"
local nT=_b[manpower]
			
//Fractions is each service branch for the whole country
display "ARMY:(`aT' /`tT')"
display "AIR FORCE: (`fT' /`tT')"
display "MARINES: (`mT' /`tT')"
display "NAVY: (`nT' /`tT')"

//count those in each service by state and county	
egen totalmp=total(manpower), by(state county)
foreach sb in A F M N {
	egen `sb'x=total(manpower) if service=="`sb'", by(state county)
	bysort state county: egen `sb'mp=max(`sb'x)
	replace `sb'mp=0 if `sb'mp==.
	drop `sb'x
	label var `sb'mp "Manpower in service branch `sb' in given county"
}

duplicates drop state county, force
drop manpower grade service MOS 

//the expected # in each county for each branch

gen ae=totalmp*(`aT' /`tT')
gen fe=totalmp*(`fT' /`tT')
gen me=totalmp*(`mT' /`tT')
gen ne=totalmp*(`nT' /`tT')

//square the difference and divide by the expected
gen ad=((Amp-ae)^2)/ae
gen fd=((Fmp-fe)^2)/fe
gen md=((Mmp-me)^2)/me
gen nd=((Nmp-ne)^2)/ne
gen chi2stat=ad+fd+md+nd //compares this to chi-2 w/ 3 dof.

stop


total(manpower) if MOS=="11B"
local b11=_b[manpower]
total(manpower)
local b11frac=`b11'/_b[manpower]
disp "the fraction of 

egen totbycounty=total(manpower), by(county)

egen X=total(manpower) if MOS=="11B", by(county)
bysort county: egen tot11Bbycounty=max(X)
drop X
label var tot11Bbycounty "total Army 11B by state"

gen frac11B=tot11Bbystate/totbycounty
label var frac11B "fraction Army 11B/total military by state"


*************
egen totbystate=total(manpower), by(state)
label var totbystate "total military by state"

egen X=total(manpower) if MOS=="11B", by(state)
bysort state: egen tot11Bbystate=max(X)
drop X
label var tot11Bbystate "total Army 11B by state"

gen frac11B=tot11Bbystate/totbystate
label var frac11B "fraction Army 11B/total military by state"

egen X=total(manpower) if service=="A", by(state)
bysort state: egen totArmybystate=max(X)
drop X

egen X=total(manpower) if service=="N", by(state)
bysort state: egen totNavybystate=max(X)
drop X

egen X=total(manpower) if service=="M", by(state)
bysort state: egen totMarinebystate=max(X)
drop X

egen X=total(manpower) if service=="F", by(state)
bysort state: egen totAFbystate=max(X)
drop X

foreach service in Army Navy Marine AF{
 label var tot`service'bystate "Total manpower in service branch(`service') by state"
 gen frac`service'bystate=tot`service'bystate/totbystate
 label var frac`service'bystate "Fraction in service branch(`service') by state"
}

gen fracArmy11Bbystate=tot11Bbystate/totArmybystate
label var fracArmy11Bbystate "fraction Army 11B/Army by state"

*Let's just run a test*
*Just the Army, Just one month*
keep if service=="A" & yearmonth==200312
count
egen stateArmyMOSmp=total(manpower), by(MOS state)
duplicates drop MOS state, force
drop county grade //because we've already limited to army and one month, and summed across county and grade
sort stateArmyMOSmp
br

*Let's do two tests. Are the fractions that go to each of the four service branches the same?
*(Across states? Or maybe also over time?)
*Are the fractions of the top 10 Army MOS the same across states?
* 11B, 91W, 92Y, 31B, 92A, 13B, 19K, 92Y, 92F, 21B
