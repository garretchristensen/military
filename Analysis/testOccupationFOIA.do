//Garret Christensen
//Started January 24, 2016
//This file takes the compiled Occupation code data and tests whether people from different
//states go into different occupations in different percentages.

//The idea is that if people from different states are equally likely to go into the risky occupations
//then the hyper rational person wouldn't care where somebody who got killed is from.

//If, on the other hand, people from Tennessee are become infantry, and someone from Tennessee dies,
//then a potential enlistee from Tennessee might be rational to care more that someone from Tennessee died
//compared to when someone from California died.

//One can test this with the Pearson Chi-Square Test

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

*Re-Load MOS Data
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
*tested this with 200309 as well--you get similar results
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
foreach x in a f m n{
	local `x'r=``x'T'/`tT'
}	
display "ARMY:(`ar')"
display "AIR FORCE: (`fr')"
display "MARINES: (`mr')"
display "NAVY: (`nr')"

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
save ./Data/tempMOSchi2.dta, replace


use ./Data/tempMOSchi2.dta, clear
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
gen chi2p=chi2tail(3,chi2stat)
summ chi2p, detail
*HOW MANY COUNTIES HAVE DIFFERENT DISTRIBUTIONS?
count if chi2p<.05
count if chi2p<(.05/3125)

***********************************************************************
*ADJUST THE P-VALUES USING ANDERSON'S CODE TO DO BENJAMINI HOCHBERG FDR
***********************************************************************
gen pval=chi2p
quietly sum pval
local totalpvals = r(N)

* Sort the p-values in ascending order and generate a variable that codes each p-value's rank
quietly gen int original_sorting_order = _n
quietly sort pval
quietly gen int rank = _n if pval~=.

* Set the initial counter to 1 
local qval = 1

* Generate the variable that will contain the BH (1995) q-values
gen bh95_qval = 1 if pval~=.

* Set up a loop that begins by checking which hypotheses are rejected at q = 1.000, 
*then checks which hypotheses are rejected at q = 0.999, then checks which hypotheses 
*are rejected at q = 0.998, etc.  The loop ends by checking which hypotheses are rejected at q = 0.001.
while `qval' > 0 {
	* Generate value qr/M
	quietly gen fdr_temp = `qval'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= qr/M
	quietly gen reject_temp = (fdr_temp>=pval) if fdr_temp~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	quietly gen reject_rank = reject_temp*rank
	* Record the rank of the largest p-value that meets above condition
	quietly egen total_rejected = max(reject_rank)
	* A p-value has been rejected at level q if its rank is less than or equal to the rank of the max p-value that meets the above condition
	quietly replace bh95_qval = `qval' if rank <= total_rejected & rank~=.
	* Reduce q by 0.001 and repeat loop
	quietly drop fdr_temp reject_temp reject_rank total_rejected
	local qval = `qval' - .001
}
	
quietly sort original_sorting_order

display "Code has completed."
display "Benjamini Hochberg (1995) q-vals are in variable 'bh95_qval'"
display	"Sorting order is the same as the original vector of p-values"

summ bh95_qval, detail
count if bh95_qval<.05
**************************************************************
* ADJUST THE P-VALUES USING ANDERSON'S CODE TO DO BKY(2006) FDR
**************************************************************
*drop the vars created by the BH method
drop original_sorting_order rank

quietly sum pval
local totalpvals = r(N)

* Sort the p-values in ascending order and generate a variable that codes each p-value's rank
quietly gen int original_sorting_order = _n
quietly sort pval
quietly gen int rank = _n if pval~=.

* Set the initial counter to 1 
local qval = 1

* Generate the variable that will contain the BKY (2006) sharpened q-values
gen bky06_qval = 1 if pval~=.

*Set up a loop that begins by checking which hypotheses are rejected at q = 1.000, 
*then checks which hypotheses are rejected at q = 0.999, then checks which hypotheses are rejected at q = 0.998, etc.  
*The loop ends by checking which hypotheses are rejected at q = 0.001.
while `qval' > 0 {
	* First Stage
	* Generate the adjusted first stage q level we are testing: q' = q/1+q
	local qval_adj = `qval'/(1+`qval')
	* Generate value q'*r/M
	quietly gen fdr_temp1 = `qval_adj'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q'*r/M
	quietly gen reject_temp1 = (fdr_temp1>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	quietly gen reject_rank1 = reject_temp1*rank
	* Record the rank of the largest p-value that meets above condition
	quietly egen total_rejected1 = max(reject_rank1)

	* Second Stage
	* Generate the second stage q level that accounts for hypotheses rejected in first stage: q_2st = q'*(M/m0)
	local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-total_rejected1[1]))
	* Generate value q_2st*r/M
	quietly gen fdr_temp2 = `qval_2st'*rank/`totalpvals'
	* Generate binary variable checking condition p(r) <= q_2st*r/M
	quietly gen reject_temp2 = (fdr_temp2>=pval) if pval~=.
	* Generate variable containing p-value ranks for all p-values that meet above condition
	quietly gen reject_rank2 = reject_temp2*rank
	* Record the rank of the largest p-value that meets above condition
	quietly egen total_rejected2 = max(reject_rank2)

	* A p-value has been rejected at level q if its rank is less than or equal to the rank of the max p-value that meets the above condition
	quietly replace bky06_qval = `qval' if rank <= total_rejected2 & rank~=.
	* Reduce q by 0.001 and repeat loop
	drop fdr_temp* reject_temp* reject_rank* total_rejected*
	local qval = `qval' - .001
}
	

quietly sort original_sorting_order

display "Code has completed."
display "Benjamini Krieger Yekutieli (2006) sharpened q-vals are in variable 'bky06_qval'"
display	"Sorting order is the same as the original vector of p-values"
summ bky06_qval, detail
count if bky06_qval<.05



exit
/*OLD GARBAGE NOT TO  BE EXECUTED AFTER JULY 16 
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
*/
