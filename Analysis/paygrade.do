/*PER REF REQUEST, AND TO ACCOUNT FOR DEATHS OF PEOPLE IN SERVICE LONG ENOUGH TO HAVE CHANGED THEIR 
HOME OF RECORD STATE--NO STATE INCOME TAX!--LOOK ONLY AT DEATHS OF LOW-PAYGRADE SOLDIERS*/
clear all
set more off
cd $dir

cap log close
log using ./Logs/paygrade.smcl, replace

/*HAVE TO KEEP FILE MANAGEMENT STUFF UP HERE, OUTSIDE APP/CON LOOP*/

cap rm ./Output/paygrade.txt
cap rm ./Output/paygrade.tex
*cap rm ./Output/officer.txt
*cap rm ./Output/officer.tex


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
		foreach war in ""  E4 E4P E5 E5P ENLISTED OFFICER{
			replace `lag'`war'`var'=`lag'`war'`var'/100
		}
	}
}
label var monthcountydeath "In-County Deaths/100"
label var L1monthcountydeath "Lag In-County Deaths/100"
label var outofcounty "Out-of-County Deaths/100"
label var L1outofcounty "Lag Out-of-County Deaths/100"
forvalues X=3/5{
	label var E`X'monthcountydeath "Paygrade E`X' In-County Deaths/100"
	label var L1E`X'monthcountydeath "Lag Paygrade E`X' In-County Deaths/100"
	label var E`X'outofcounty "Paygrade E`X' Out-Of-County Deaths/100"
	label var L1E`X'outofcounty "Lag Paygrade E`X' Out-Of-County Deaths/100"
}
forvalues X=3/5{
	label var E`X'Pmonthcountydeath "Paygrade E`X'-plus In-County Deaths/100"
	label var L1E`X'Pmonthcountydeath "Lag Paygrade E`X'-plus  In-County Deaths/100"
	label var E`X'Poutofcounty "Paygrade E`X'-plus Out-Of-County Deaths/100"
	label var L1E`X'Poutofcounty "Lag Paygrade E`X'-plus Out-Of-County Deaths/100"
}
 
summ monthcountydeath //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
summ L1E4outofcounty //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
summ L1OFFICERoutofcounty //Make sure this is between 0 and .08 not 0 to 8.
if r(max)<.01|r(max)>1 {
	display "you divided deaths by 100 too little/much"
	throw a hissy fit
}
*********************************************************************************************
*********************************************************************************************
*COMPARE UNDER AND OVER
*LOOP OVER DIVIDING AT E5/E5
forvalues X=4/5{
if `X'==4{
	local header2="E4"
}
else{
	local header2="E5"
}

	*PUT BOTH e3 and e4 into the same temp var for a nicer table
	gen youngcounty=L1E`X'monthcountydeath
	gen oldcounty=L1E`X'Pmonthcountydeath
	gen youngstate=L1E`X'outofcounty
	gen oldstate=L1E`X'Poutofcounty
	*Give the temp the label
	label var youngcounty "Lag Low Enlisted In-County Deaths/100"
	label var oldcounty "Lag High Enlisted In-county Deaths/100"
	label var youngstate "Lag Low Enlisted Out-of-County Deaths/100"
	label var oldstate "Lag High Enlisted Out-of-County Deaths/100"
	label var L1OFFICERmonthcountydeath "Lag Officer In-county Deaths/100"
	label var L1OFFICERoutofcounty "Lag Officer Out-of-County Deaths/100"
	/*LINEAR*/
	/*IN-COUNTY*/
	reghdfe LNactive monthcountydeath youngcounty oldcounty L1OFFICERmonthcountydeath outofcounty ///
		L1outofcounty stateunemp countyunemp, ///
		absorb(fips month stateyear) vce(cluster fips)
	test youngcounty=oldcounty=L1OFFICERmonthcountydeath
	outreg2  using ./Output/paygrade.txt, lab tex ct(`header', `header2') bdec(3) tdec(3) bracket se append ///
		ti(Recruits vs Deaths by Paygrade and Unemployment) ///
		addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on ", ///
		" deaths by enlisted paygrade--E4/E5 and below compared to above, and separately for (warrant) officers.", ///
		"Fixed effects are included separately by county and month as indiciated,", ///
		"The first four columns show applicants and the last four show contracts.", Filename:paygrade.tex) ///
		addstat("Test In-County", r(p)) addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)
	
	/*BOTH*/
	reghdfe LNactive monthcountydeath youngcounty oldcounty L1OFFICERmonthcountydeath ///
		outofcounty youngstate oldstate L1OFFICERoutofcounty ///
		stateunemp countyunemp , absorb(fips month stateyear) vce(cluster fips)
	test youngcounty=oldcounty=L1OFFICERmonthcountydeath
	local incounty=r(p)
	test youngstate=oldstate=L1OFFICERoutofcounty
	outreg2 using ./Output/paygrade.txt, lab tex ct(`header', `header2') bdec(3) tdec(3) bracket se append ///
		addstat("Test In-County", `incounty', "Test Out-of-County", r(p)) ///
		addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)


	drop youngcounty oldcounty youngstate oldstate
} //END LOOP OVER e4/5

**************************************************************************
/*INTEAD OF SEPARATE OFFICER VS. ENLISTED, SEPARATE YOUNG/OLD ENLISTED, OFFICER
	*PUT BOTH e4 and e5 into the same temp var for a nicer table
	gen youngcounty=L1ENLISTEDmonthcountydeath
	gen oldcounty=L1OFFICERmonthcountydeath
	gen youngstate=L1ENLISTEDoutofcounty
	gen oldstate=L1OFFICERoutofcounty
	*Give the temp the label
	label var youngcounty "Lag Enlisted In-County Deaths/100"
	label var oldcounty "Lag Officer In-county Deaths/100"
	label var youngstate "Lag Enlisted Out-of-County Deaths/100"
	label var oldstate "Lag Officer Out-of-County Deaths/100"
	
	
	/*LINEAR*/
	/*IN-COUNTY*/
	reghdfe LNactive monthcountydeath youngcounty oldcounty outofcounty L1outofcounty stateunemp countyunemp, ///
		absorb(fips month stateyear) vce(cluster fips)
	test youngcounty=oldcounty
	outreg2  using ./Output/officer.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
		ti(Recruits vs Deaths by Enlisted-Officer and Unemployment) ///
		addnote("Notes: Table shows linear regression estimates of log (national active duty recruits +1) on ", ///
		"lagged deaths by officer/enlisted status.", ///
		"Fixed effects are included separately by county and month as indiciated,", ///
		"The first four columns show applicants and the last four show contracts.", Filename:officer.tex) ///
		addstat("Test In-County", r(p)) addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)
	
	/*BOTH*/
	reghdfe LNactive monthcountydeath youngcounty oldcounty outofcounty youngstate oldstate ///
		stateunemp countyunemp , absorb(fips month stateyear) vce(cluster fips)
	test youngcounty=oldcounty
	local incounty=r(p)
	test youngstate=oldstate
	outreg2 using ./Output/officer.txt, lab tex ct(`header') bdec(3) tdec(3) bracket se append ///
		addstat("Test In-County", `incounty', "Test Out-of-County", r(p)) ///
		addtext(County FE, YES, Month FE, YES, Stateyear FE, YES)
*/
	 
} //END BIG APP/CON LOOP	

