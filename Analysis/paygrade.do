/*PER REF REQUEST, AND TO ACCOUNT FOR DEATHS OF PEOPLE IN SERVICE LONG ENOUGH TO HAVE CHANGED THEIR 
HOME OF RECORD STATE--NO STATE INCOME TAX!--LOOK ONLY AT DEATHS OF LOW-PAYGRADE SOLDIERS*/
clear all
set more off
cd $dir

cap log close
log using ./Logs/paygrade.smcl, replace

/*HAVE TO KEEP FILE MANAGEMENT STUFF UP HERE, OUTSIDE APP/CON LOOP*/

cap rm ./Output/paygradeE3LN.txt
cap rm ./Output/paygradeE4LN.txt
cap rm ./Output/paygradeE3LN.tex
cap rm ./Output/paygradeE4LN.tex


foreach file in APP CON {
/******************************************************************************/
use ./Data/county`file'_raw.dta, clear /*LOOPS OVER BOTH FILES!*/
destring month, replace //necessary for reghdfe command
destring stateyear, replace //necessary for reghdfe command
if "`file'"=="APP"{
	local header="Applicants"
}
else{
	local header="Contracts"
}
foreach var in monthcountydeath outofcounty { 
	foreach lag in "" L1 {
		foreach war in "" E3 E4{
			replace `lag'`war'`var'=`lag'`war'`var'/100
		}
	}
}
label var monthcountydeath "In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
forvalues X=3/4{
	label var E`X'monthcountydeath "Paygrade E`X' In-County Deaths/100"
	label var L1E`X'monthcountydeath "Lag Paygrade E`X' In-County Deaths/100"
	label var E`X'outofocounty "Paygrade E`X' Out-Of-County Deaths/100"
	label var L1E`X'outofcounty "Lag Paygrade E`X' Out-Of-County Deaths/100"
}
 
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
summ L1E3outofcounty //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
*********************************************************************************************
*********************************************************************************************
*SIMPLE JUST USE ONLY e3 or e4
reghdfe LNactive E3monthcountydeath L1E3monthcountydeath E3outofcounty L1E3outofcounty stateunemp countyunemp ///
	, absorb(fips month stateyear) vce(cluster fips)
outreg2  using ./Output/paygrade.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on cumulative ", ///
	"lagged deaths for only soldiers paygrade E3 or lower. Fixed effects are included separately by county and month as indiciated,", ///
	"The first four columns show applicants and the last four show contracts.", Filename:paygrade.tex) ///
	 addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)

reghdfe LNactive E4monthcountydeath L1E4monthcountydeath E4outofcounty L1E4outofcounty stateunemp countyunemp ///
	, absorb(fips month stateyear) vce(cluster fips)
outreg2  using ./Output/paygrade.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
	addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on cumulative ", ///
	"lagged deaths for only soldiers paygrade E3 or lower. Fixed effects are included separately by county and month as indiciated,", ///
	"The first four columns show applicants and the last four show contracts.", Filename:paygrade.tex) ///
	 addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)

*BETTER-COMPARE UNDER AND OVER
*LOOP OVER DIVIDING AT E3/E4
forvalues X=3/4{
	/*LINEAR*/
	/*IN-COUNTY*/
	reghdfe LNactive monthcountydeath L1E`X'monthcountydeath L1E`X'Pmonthcountydeath outofcounty L1outofcounty stateunemp countyunemp ///
		, absorb(fips month stateyear) vce(cluster fips)
	test L1E`X'monthcountydeath=L1E`X'Pmonthcountydeath
	outreg2  using ./Output/paygrade`X'.txt, lab tex ct(`header1') bdec(3) tdec(3) bracket se append ///
		addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on cumulative ", ///
		"lagged deaths by paygrade. Fixed effects are included separately by county and month as indiciated,", ///
		"The first four columns show applicants and the last four show contracts.", Filename:paygrade`X'.tex) ///
		addstat("Test In-County", r(p)) addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)
	
	/*BOTH*/
	reghdfe LNactive monthcountydeath L1E`X'monthcountydeath L1E`X'Pmonthcountydeath outofcounty L1E`X'outofcounty L1E`X'Poutofcounty ///
		stateunemp countyunemp , absorb(fips month stateyear) vce(cluster fips)
	test L1E`X'monthcountydeath=L1E`X'Pmonthcountydeath
	local incounty=r(p)
	test L1E`X'outofcount=L1E`X'Poutofcounty
	outreg2 using ./Output/paygrade`X'.txt, lab tex ct(`header1') bdec(3) tdec(3) bracket se append ///
		addstat("Test In-County", `incounty', "Test Out-of-County", r(p)) ///
		addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)
} //END LOOP OVER e3/4
	 
} //END BIG APP/CON LOOP	

