//Garret Christensen
//Started January 24, 2016
//This file takes the compiled Occupation code data and tests whether people from different
//states go into different occupations in different percentages.

//The idea is that if people from different states are equally likely to go into the risky occupations
//then the hyper rational person wouldn't care where somebody who got killed is from.

//If, on the other hand, people from Tennessee are become infantry, and someone from Tennessee dies,
//then a potential enlistee from Tennessee might be rational to care more that someone from Tennessee died
//compared to when someone from California died.

*Load Data
clear all
use .\FOIA\MilitaryOccupations\Occupations.dta, replace

count
count if state=="ZZ"
count if county=="ZZZ"
count if state=="ZZ"|county=="ZZZ"
//No one with missing state has non-missing county
drop if state=="ZZ"

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


*for starters just look at how many go into 11B from each state.
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
