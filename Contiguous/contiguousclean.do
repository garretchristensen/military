clear
insheet using contiguous.csv
rename v1 statefips1
rename v2 countyfips1
rename v3 samecounty
rename v4 statefips2
rename v5 countyfips2
rename v6 connectiontype
rename v7 name
replace name=name+" "+v8+" "+v9+" "+v10
replace name=rtrim(name)
drop v8 v9 v10
replace name=connectiontype if samecounty==1
replace connectiontype="" if samecounty==1
save contiguous, replace
