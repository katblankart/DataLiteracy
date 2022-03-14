
* 	Table 1:
****************

/* Comment:
Information was obtained from the footnote of Table 1, p. 115 of the original study.
The text stats that only uses data without missing values.
This applies to all tables and figures and was done in the initial data preparation.

The footnote defines the dummy variable "specialist":
whether a physician is not a general practice, family practice, or basic pediatrics.
The dummy medicare takes the value of 1 if medicare was the only source of payment.

Observations of patient visits in which the patient was not charged were excluded.
*/
  
  
use "$d\namcs91.dta", clear

qui eststo table1: estpost summarize age female nonwhite hispanic selfpay medicare medicaid ///
private_ins other_gov_ins  hmo_pre_paid specialist northeast midwest south west

esttab table1 using "$tab\Table_1.rtf", replace  ///
title("Summary Statistics for Overall NAMCS Patient Sample") ///
cells ("mean(fmt(%12.2f)) sd(fmt(%12.2f))") nonumber noobs ///
coeflabels(age "Age" female "Female" nonwhite "Nonwhite" hispanic "Hispanic" ///
selfpay "Self-pay" medicare "Medicare" medicaid "Medicaid" private_ins "Private/commercial" ///
other_gov_ins "Other government insurance" hmo_pre_paid "HMO/prepaid plan" ///
  specialist "Specialist" ///
northeast "Northeast" midwest "Midwest" south "South" west "West" ) ///
addnote("Notes: Sample size is 32,407. For further notes see table 1 notes in Hellerstein (1998); ///
        Sample size differs as data from different years is used" "Data source: NAMSC91")




* 	Table 2:
****************

/* Comment:
Variables and data preparing processes equivalent to Table 1.

Create a matrix resembling the table and store each value in its respective cell.
*/
use "$d\namcs91d.dta", clear


* 1) Saving all values in locals:
**********************************
* For all rows besides the last one
foreach x in age female nonwhite hispanic selfpay medicare medicaid  private_ins hmo_pre_paid specialist northeast midwest south west {
	
	* Computing mean and sd
	qui: sum `x'
	local `x'_m = r(mean)
	local `x'_std = r(sd)
	
	* Computing the share of generics for all rows exept for the row age
	if "`x'" != "age"{
		qui: sum  generic_status if `x' == 1
		local `x'_share = r(mean)
	}
	}
	
* Last row (Share of generics in the full sample)
qui: sum generic_status
local fullsample_share = r(mean)
	

* 2) Filling a matrix with the locals:
***************************************
mat input table2 = ( /// 
`age_m', `age_std' , . \ ///
`female_m', `female_std', `female_share' \ ///
`nonwhite_m', `nonwhite_std', `nonwhite_share' \ ///
`hispanic_m', `hispanic_std', `hispanic_share' \ ///
`selfpay_m', `selfpay_std', `selfpay_share' \ ///
`medicare_m', `medicare_std', `medicare_share' \ ///
`medicaid_m', `medicaid_std', `medicaid_share' \ ///
`private_ins_m', `private_ins_std', `private_ins_share' \ ///
`hmo_pre_paid_m', `hmo_pre_paid_std', `hmo_pre_paid_share' \ ///
`specialist_m', `specialist_std', `specialist_share' \ ///
`northeast_m', `northeast_std', `northeast_share' \ ///
`midwest_m', `midwest_std', `midwest_share' \ ///
`south_m', `south_std', `south_share' \ ///
`west_m', `west_std', `west_share' \ ///
. , . , `fullsample_share' ///
 )

 
* 3) Labelling and exporting:
**************************************
matrix rownames table2 = ///
"Age" "Female" "Nonwhite" "Hispanic" "Self-Pay" "Medicare" "Medicaid" "Private/Commercial" ///
"HMO/prepaid plan" ///
"Specialist" "Northeast" "Midwest" "South" "West" "Full sample"

matrix colnames table2 = "Mean" "Standard Deviation" "Proportion Generic"

putexcel set "$tab\Table_2.xlsx", replace
putexcel A1 = matrix(table2 ), names


* 	Table 3:
****************
use "$d\namcs91d.dta", clear
return clear
ereturn clear

* Turn decimal numbers into percentage
gen All_drugs = generic_status * 100

* generic share for all drugs
eststo t10: quietly estpost tabstat All_drugs, ///
statistics(mean N) columns(statistics) listwise

* generic share by drug class
eststo t20: quietly estpost tabstat All_drugs, by(drug_class) ///
statistics(mean N) columns(statistics) listwise notot

esttab t10 t20 using "$tab\Table_3.rtf", replace ///
cells("count(fmt(%12.0f)) mean(fmt(%12.2f))") ///
title("Table 3 - Frequency of Generic Prescription by Drug Class") ///
collabels("Observations" "% Generics") noobs nonumber gaps refcat(3 "By drug class" , nolabel) ///
coeflabels(generic "All drugs" 3 "Antimicrobials" 5 "Cardiovascular-renals" ///
 6 "Central Nervous System" 10 "Hormones/Hormonal mechanisms" ///
 12 "Skin/Mucous membrane" 15 "Ophthalmics" 17 "Pain relief" 19 "Resperatory tract") 




* 	Figure 1:
*****************
/* Comment:
Visualizations of kernel densities vary depending on the specifications. 
Two parameters define the density function: Bandwidth and whether/how to round the data.
Hellerstein does not provide information about the density function.
We  visually rule out that she rounds to the first decimal place.
There are fluctuations between the first decimal places.
Rounding to the third or higher decimal places produces much noisier curves.
Hence, we assume that she rounded to the second decimal place.
For the bandwidth and density function, there are no obvious clues.
That the reproduction relies on visual approximation of the original figure.
*/


* 1) Estimate the mean share of prescribed generics per physician
bys physician_id: egen temp2 = mean(generic_status)
gen generic_share = round(temp2, .01) 


* 2) Collapse the data so that one observation per physician remains
duplicates drop physician_id, force


* 3) Recreate Figure 1
set scheme  s1manual
twoway kdensity generic_share, range(0 1) bw( 0.02) kernel(bi)  ///
xtitle("Physician generic prescription rates") ytitle("Percent of physicians") ///
xlabel(0 (0.1) 1) lc(black)

graph export "$fig\Figure_1.png", replace



* 	Figure 2:
*****************
use "$d\namcs91d.dta", clear

/* Comment:
The figure uses observations of drugs with > 6 prescriptions by a single physician. 
158 unique physicians remain in Hellerstein (1998).
We are left with 122 physicians (see p. 116 first paragraph).
*/


* 1) Apply dropping conditions
bys physician_id ingredient : gen temp = _N
drop if temp < 6
* Check the number of remaining physicians. 158 in Hellerstein
qui: tab physician_id
di r(r)


* 2) Create the categories for the bars
** 2.1) Avg generic prescription rate for each per physician
bys physician_id ingredients: egen temp2 = mean(generic_status) 

 * 2.2) Use the share to set up the groups
gen counter = .
replace counter = 0 if temp2 == 0 /* Never generic */
replace counter = 1 if temp2 > 0 & temp2 < 1 /* Sometimes */
replace counter = 2 if temp2 == 1 /* Always */

label define l 0 "Only trade names" 1 "Both versions" 2 "Only generics"
label values counter l


* 3) Collapse the data so that one observation per physician remains
duplicates drop physician_id, force


* 4) Recreating the figure
set scheme  s1manual
graph bar (count), over(counter) ///
ytitle("") intensity(60) lintensity(100) bar(1, color("black") fcolor("gs5")) ylab(, nogrid)

graph export "$fig\Figure_2.png", replace
