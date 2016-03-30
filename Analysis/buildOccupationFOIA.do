// This file builds the military occupation code data from the raw FOIA data.
//Raw FOIA data was received the first week of January, 2016.
//Data was discovered to be faulty, so I requested the FOIA be reopened
//New data was received end of March, 2016

clear all

forvalues X=1/9{
	insheet using .\FOIA\MilitaryOccupations\raw\v2\15F0425_DRS85998_200`X'.txt, clear delimiter("|")
	save .\FOIA\MilitaryOccupations\Occupations_200`X'.dta, replace
}
insheet using .\FOIA\MilitaryOccupations\raw\v2\15F0425_DRS85998_2010.txt, clear delimiter("|")
	save .\FOIA\MilitaryOccupations\Occupations_2010.dta, replace

use .\FOIA\MilitaryOccupations\Occupations_2001.dta
append using .\FOIA\MilitaryOccupations\Occupations_2002.dta
append using .\FOIA\MilitaryOccupations\Occupations_2003.dta
append using .\FOIA\MilitaryOccupations\Occupations_2004.dta
append using .\FOIA\MilitaryOccupations\Occupations_2005.dta
append using .\FOIA\MilitaryOccupations\Occupations_2006.dta
append using .\FOIA\MilitaryOccupations\Occupations_2007.dta
append using .\FOIA\MilitaryOccupations\Occupations_2008.dta
append using .\FOIA\MilitaryOccupations\Occupations_2009.dta
append using .\FOIA\MilitaryOccupations\Occupations_2010.dta

rename v1 grade	
rename v2 service
rename v3 HORstate
rename v4 HORcounty
rename v5 MOS
rename v6 yearmonth
rename v7 manpower

