//This file builds county, state, and national unemployment data.
//It starts with countyunemployment.txt (which I downloaded from BLS) and turns it into countyunemployment.dta
//It also turns statewidesa.dta into state-monthly data (stateunemp.dta)
//nationalunemp was easy enough that I didn't have to do anything to it. (I'm also not sure I ever use it.)

****************COUNTY*******************************
/*GOAL IS TO TURN UNEMPLOYMENT DATA INTO SOMETHING WITH EVERY COUNTY-MONTH AS AN OBSERVATION WITH FIPS
AND UNEMPLOYMENT AS VARS*/
clear all
set more off
set mem 500m
cd $dir
insheet using ./Unemployment/raw/countyunemployment.txt, names
replace seriesid=substr(seriesid, 4, 8)
sort seriesid
merge 1:1 seriesid using ./Unemployment/raw/countycrosswalk.dta
sort _merge statefips name
drop if _merge!=3 /*SOME (5) COUNTIES CHANGED BOUNDARIES*/
drop _merge
drop annual* /*JUST WANT MONTHLY FIGURES*/
/*GET RID OF LETTERS AFTER NUMBERS*/
foreach var of varlist jan1990-dec2010{
 replace `var'=subinstr(`var',"(E)","",.)
 replace `var'=subinstr(`var',"(P)","",.)
 replace `var'=subinstr(`var',"(D)","",.)
 replace `var'=subinstr(`var',"(Y)","",.)
 replace `var'=subinstr(`var',"-(N)","",.)
 destring `var', replace
}
forvalues year=1990/2010 {
 rename jan`year' unemp`year'01
 rename feb`year' unemp`year'02
 rename mar`year' unemp`year'03
 rename apr`year' unemp`year'04
 rename may`year' unemp`year'05
 rename jun`year' unemp`year'06
 rename jul`year' unemp`year'07
 rename aug`year' unemp`year'08
 rename sep`year' unemp`year'09
 rename oct`year' unemp`year'10
 rename nov`year' unemp`year'11
 rename dec`year' unemp`year'12
}
reshape long unemp, i(fips)
rename _j month
rename unemp countyunemp
tostring fips, replace
replace fips=statefips+countyfips
sort fips
compress
save ./Unemployment/countyunemployment.dta, replace

***************************STATE************************
clear all
set more off
use ./Unemployment/raw/statewidesa.dta, clear
forvalues year=1990/2006 {
 rename jan`year' unemp`year'01
 rename feb`year' unemp`year'02
 rename mar`year' unemp`year'03
 rename apr`year' unemp`year'04
 rename may`year' unemp`year'05
 rename jun`year' unemp`year'06
 rename jul`year' unemp`year'07
 rename aug`year' unemp`year'08
 rename sep`year' unemp`year'09
 rename oct`year' unemp`year'10
 rename nov`year' unemp`year'11
 rename dec`year' unemp`year'12
}

reshape long unemp, i(state)
rename _j month
rename unemp stateunemp
destring state, replace
rename state statefips
tostring month, replace
sort month statefips
save ./Unemployment/stateunemp.dta, replace
