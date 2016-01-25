// This file builds the military occupation code data from the raw FOIA data.
//Raw FOIA data was received the first week of January, 2016.
clear all
set excelxlsxlargefile on

//Could do this as a loop over years, but would append work the first time?

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2001") 
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2002") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2003") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2004") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2005") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2006") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2007") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2008") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2009") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

import excel using .\FOIA\MilitaryOccupations\raw\15F0425_Doc_01_DRS85998.xlsx, sheet("FY 2010") clear
drop if _n<=5
foreach j in A B C D E F G H {
	replace `j'=subinstr(`j'," ","_",.) in 1
	rename `j' `=`j'[1]'
}
drop if _n==1
append using .\FOIA\MilitaryOccupations\Occupations.dta
save .\FOIA\MilitaryOccupations\Occupations.dta, replace

