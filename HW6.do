**************************************************************
* Nutr 307: Regression for Nutrition Policy
* STATA Hw6
* 4.4.23
* Chad Fisher

* Created to answer questions about childhood malnutrition using IFPRI data
**************************************************************

**************************************************************
* Getting Started
**************************************************************

clear all //  clears anything in the existing memory 
set more off // don't display the 'more' message 
cap log close // closes any existing logs

cap cd "C:\Users\chadl\OneDrive\Desktop\NUTR 307\HW6" // Change working directory

* Open log
log using hw6.log, replace // Create log 

**************************************************************
* Importing Data and Extracting quarter 2
**************************************************************

use fmli132 if interi==2 //quarter 2
keep cuid newid interi finlwt21 wtrep01-wtrep44 psu region jfs_amt bls_urbn fam_size fam_type perslt18 persot64 region respstat inclass ref_race sex_ref hisp_ref high_edu fincatax totexppq totexpcq foodpq foodcq fdhomepq fdhomecq fdawaypq fdawaycq 

generate yessnap = (jfs_amt>0) //creating new variable about SNAP participation

* Rename regions*
replace region="Northeast" if region=="1"
replace region="Midwest" if region=="2"
replace region="South" if region=="3"
replace region="West" if region=="4"

**************************************************************
* Q11
**************************************************************

count if psu!="" //counting PSUs that are not blank/anonymized

**************************************************************
* Q12
**************************************************************

tab psu if region=="Midwest" //seeing how many PSUs are in Midwest

**************************************************************
* Q13 & Q14
**************************************************************

gen income = fincatax/12 //converting annual income to income per month
gen foodaway=fdawaypq/3 //quarterly food expenditure away from home to monthly
regress foodaway income //regress food away from home on income

**************************************************************
* Q15
**************************************************************

svyset [pweight=finlwt21], brrweight(wtrep01-wtrep44) vce(brr) //setting up complex survey data
svy: regress foodaway income //survey corrected regression

**************************************************************
* Q16
**************************************************************

estat effects, deff

**************************************************************
* Closing steps
**************************************************************

log close
clear all
browse
exit