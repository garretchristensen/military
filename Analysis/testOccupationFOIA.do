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

*Rename to Simplify
destring NUMBER_OF_MEMBERS, replace
rename NUMBER_OF_MEMBERS number
label var number "Number of members of occupation code by home state, month"

rename HOME_OF_RECORD_STATE state
label var state "Home of Record State, 2 Letter Abbrev"

*1/25/16 There's no Air Force data! Everyone is from state "ZZ"!
drop if SERVICE=="AIR FORCE"
drop if state=="ZZ"
count

*for starters just look at how many go into 11B from each state.
egen totbystate=total(number), by(state)
label var totbystate "total military by state"

egen X=total(number) if OCCUPATION_CODE=="11B", by(state)
bysort state: egen tot11Bbystate=max(X)
drop X
label var tot11Bbystate "total Army 11B by state"

gen frac11B=tot11Bbystate/totbystate
label var frac11B "fraction Army 11B/total military by state"

egen X=total(number) if SERVICE=="ARMY", by(state)
bysort state: egen totArmybystate=max(X)
drop X

egen X=total(number) if SERVICE=="NAVY", by(state)
bysort state: egen totNavybystate=max(X)
drop X

egen X=total(number) if SERVICE=="MARINE CORPS", by(state)
bysort state: egen totMarinebystate=max(X)
drop X

*egen X=total(number) if SERVICE=="AIR FORCE", by(state)
*bysort state: egen totAFbystate=max(X)
*drop X

foreach service in Army Navy Marine /*AF*/{
 label var tot`service'bystate "Total number in service branch(`service') by state"
 gen frac`service'bystate=tot`service'bystate/totbystate
 label var frac`service'bystate "Fraction in service branch(`service') by state"
}

gen fracArmy11Bbystate=tot11Bbystate/totArmybystate
label var fracArmy11Bbystate "fraction Army 11B/Army by state"

*Let's just run a test*
*Just the Army, Just one month*
keep if SERVICE=="ARMY" & DATE=="200312"
