clear all
set more off
cd $dir

set maxvar 32767
set matsize 11000
cap log close
log using ./Logs/table1bycounty.smcl, replace

/*****************************************************/
/* JUST TEST HOW WELL THEY FIT TO A BINOMIAL DISTRIBUTION*/
/****************************************************/
/*ACTIVE DEATHS ACTIVE APPS*/
use ./Data/countyAPP_raw.dta, clear
gen WorstP=.
gen Rmonthcounty=ARmonthcounty+FRmonthcounty+NRmonthcounty+MRmonthcounty
bysort fips: egen countyactiveapps=sum(Rmonthcounty)
drop if countyactiveapps==0
bysort fips: egen activedeaths=sum(Rmonthcountydeath)
bysort fips: egen deaths=sum(monthcountydeath)
duplicates drop fips, force
forvalues X=1/3130{
quietly bitesti countyactiveapps[`X'] activedeaths[`X'] .0027603, detail
quietly replace WorstP=r(p) in `X'
}
summ WorstP
label var WorstP "County P-Value"
histogram WorstP if WorstP!=1, width(.01) frequency ti(Active Duty Deaths and Applicants) //addl
graph save ./Output/hist_binomial.gph, replace

count if WorstP<(.05/3129) //was 8 last time I checked
if r(N)!=8{
 throw a hissy fit
}
disp "this is how many counties couldn't come from the average dist"
***********************************************************************
*ADJUST THE P-VALUES USING ANDERSON'S CODE TO DO BENJAMINI HOCHBERG FDR
gen pval=WorstP
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
*********************************************************/
/** ALL COUNTIES ARE CLEARLY NOT THE SAME. JUST SHOW THE DISPERSION OF THE HAZARD RATE ISN'T CRAZY*/
/* DO FOR ALL RECS & DEATHS AND ACTIVE ONLY*/
/**********************************************************/

/*ACTIVE ACTIVE APPS*/
gen hazard_aaa=activedeaths/countyactiveapps
summ hazard_aaa
disp "Active Deaths/Active Apps " r(sd)/r(mean)
*summ hazard_aaa [aweight=percentpop]
*disp "Active Deaths/Active Apps WEIGHTED " r(sd)/r(mean)
label var hazard_aaa "Active Deaths/Active Applicants"
histogram hazard_aaa, frequency //addl title("Hazard Rate by County")
graph save ./Output/hist_county_aaa.gph, replace
/*TOTAL ACTIVE APPS*/
gen hazard_taa=deaths/countyactiveapps
summ hazard_taa
disp "Total Deaths/Active Apps "r(sd)/r(mean)
*summ hazard_taa [aweight=percentpop]
*disp "Total Deaths/Active Apps WEIGHTED "r(sd)/r(mean)
label var hazard_taa "Total Deaths/Active Applicants"
histogram hazard_taa, frequency //addl title("Hazard Rate by County")
graph save ./Output/hist_county_taa.gph, replace


**************************************************************
*SAME AS ABOVE, NOW WITH CONTRACTS
**************************************************************


/*****************************************************/
/* PAT'S THING. JUST TEST HOW WELL THEY FIT TO A BINOMIAL DISTRIBUTION*/
/****************************************************/
/*ACTIVE DEATHS ACTIVE CONS*/
use ./Data/countyCON_raw.dta, clear
gen WorstP=.
gen Rmonthcounty=ARmonthcounty+FRmonthcounty+NRmonthcounty+MRmonthcounty
bysort fips: egen countyactivecons=sum(Rmonthcounty)
drop if countyactivecons==0
bysort fips: egen deaths=sum(monthcountydeath)
bysort fips: egen activedeaths=sum(Rmonthcountydeath)
duplicates drop fips, force
egen sumactivecons=sum(countyactivecons)
egen sumactivedeaths=sum(activedeaths)
forvalues X=1/3129{
quietly bitesti countyactivecons[`X'] activedeaths[`X'] sumactivedeaths/sumactivecons, detail
quietly replace WorstP=r(p) in `X'
}
summ WorstP
label var WorstP "County P-Value"
histogram WorstP if WorstP!=1, width(.01) frequency ti(Active-Duty Deaths and Contracts) //addl
graph save ./Output/hist_binomialcon.gph, replace

count if WorstP<(.05/3129) //was 0 last time I checked
if r(N)!=0{
 throw a hissy fit
}
disp "this is how many counties couldn't come from the average dist"

***********************************************************************
*ADJUST THE P-VALUES USING ANDERSON'S CODE TO DO BENJAMINI HOCHBERG FDR
gen pval=WorstP
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

******************************************
*COMBINE 2 STATE and 2 COUNTY GRAPHS INTO ONE
graph combine ./Output/hist_state_binomial.gph ./Output/hist_state_binomialcon.gph ///
	./Output/hist_binomial.gph ./Output/hist_binomialcon.gph, ///
	saving(./Output/hist_binomial_combined.gph, replace) title("State and County Binomial Tests of Death Hazard Rates") ///
	note("Graph displays the p-values that the observed state and county death rate could come from the overall" ///
	"average national death rate. The majority (70+%) of county p-values are ~=1 and are excluded from the graph.")
graph export ./Output/hist_binomial_combined.png, replace

*********************************************************/
/** ALL COUNTIES ARE CLEARLY NOT THE SAME. JUST SHOW THE DISPERSION OF THE HAZARD RATE ISN'T CRAZY*/
/* DO FOR ALL RECS & DEATHS AND ACTIVE ONLY*/
/**********************************************************/
/*ACTIVE ACTIVE CON*/
gen hazard_aac=activedeaths/countyactivecons
summ hazard_aac
disp "Active Deaths/Active Cons "r(sd)/r(mean)
*summ hazard_aac [aweight=percentpop]
*disp "Active Deaths/Active Cons WEIGHTED "r(sd)/r(mean)
label var hazard_aac "Active Deaths/Active Contracts"
histogram hazard_aac, frequency //addl
graph save ./Output/hist_county_aac.gph, replace
/*TOTAL ACTIVE CON*/
gen hazard_tac=deaths/countyactivecons
summ hazard_tac
disp "Total Deaths/Active Cons "r(sd)/r(mean)
*summ hazard_tac [aweight=percentpop]
disp "Total Deaths/Active Cons WEIGHTED "r(sd)/r(mean)
label var hazard_tac "Total Deaths/Active Contracts"
histogram hazard_tac, frequency //addl
graph save ./Output/hist_county_tac.gph, replace

**COMBINE ALL FOUR COUNTY GRAPHS
graph combine ./Output/hist_county_aaa.gph ./Output/hist_county_taa.gph ./Output/hist_county_aac.gph ///
	./Output/hist_county_tac.gph, title("Death Hazard Rate by County") saving(./Output/hist_county_combined.gph, replace) 
graph export ./Output/hist_county_combined.png, replace
