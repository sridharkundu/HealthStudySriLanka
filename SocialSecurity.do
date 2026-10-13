*Inkind transfers, BRIGHT2024-25
clear all
set more off
set scheme s1color
graph set window fontface "Garamond"
	glo macro "D:\macro\WBSrilanka\HumanCap" // <<==Sridhar
	glo do 			"${macro}/Health/do"
	glo hies16 		"${macro}/HIES16/raw"
	glo hies19 		"${macro}/HIES19/raw"
	glo bright2425 		"${macro}/BRIGHT/Survey1"		
	glo output 		"${macro}/output"
	glo input 		"${macro}/input"
	glo temp 		"${macro}/temp"
	glob wbest		"${macro}/WBestimate"
	glo graph 		"${macro}/graph"

**Chronology
*1-Estimate of in-kind transfer beneficiaries
*1a- Graphs
*2-Estimate of Free food transfer beneficiaries
*2a- Graphs\
*2b- Graphs- Free food consumption share
*3- Beneficiaries of counseling and nutrition messaging
*3a- Graphs
*4- Owe money to Food vendors
*4a- Graphs
*5- Estimation of cash transfers beneficiaries
*5a-Graphs
*6- Share of cash transfers in households' welfare
*6a- Graphs
*1-Estimate of in-kind transfer beneficiaries
use "${bright2425}\mod_r2_inkind_long.dta", clear
ren hhcode hhid
keep hhid r2_02 //type of inkind transfer programs
gen program=1
reshape wide program, i( hhid) j(r2_02)
egen tot_beneficiary=rsum( program1- program999)
gen hh_beneficiary= 0
replace hh_beneficiary=1 if tot_beneficiary!=. 
sort hhid
merge hhid using "${output}/health_humancap25_updt1"
drop if _m==1 //households without any basic information such as, sector, provinces, weight etc.
keep hhid sector province quintile hhweight tot_beneficiary hh_beneficiary
replace tot_beneficiary=0 if tot_beneficiary==. //total individual beneficiaries
 replace hh_beneficiary=0 if hh_beneficiary==. // total household beneficiaries
 replace hh_beneficiary= hh_beneficiary*100 // to make the percentage share in graph bars
label define province 1 "WP" 2 "CP" 3 "SP" 4 "NP" 5 "EP" 6 "NWP" 7 "NCP" 8 "UVA" 9 "SAB", modify
label values province province
*1a- Graphs
graph bar hh_beneficiary[fw=hhweight], over(sector) blab(bar, format(%3.2f) gap(0)) ///
title("In-kind transfers household beneficiaries as a share of total households", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar hh_beneficiary[fw=hhweight], over(quintile) blab(bar, format(%3.2f) gap(0)) ///
title("In-kind transfers household beneficiaries as a share of total households", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar hh_beneficiary[fw=hhweight], over(province) blab(bar, format(%3.2f) gap(0)) ///
title("In-kind transfers household beneficiaries as a share of total households", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")

*2-Estimate of Free food transfer beneficiaries
use "${bright2425}\mod_j1_fah_long.dta", clear
ren hhcode hhid
/*
replace j1_06=0 if j1_06==.
tab j1_06  if j1_04_16==0
*/
keep hhid j1_04_16 j1_06 // food through inkind transfers
keep if j1_04_16==1 // households who receive inkind transfers
collapse(mean) j1_04_16 j1_06, by(hhid)
ren (j1_04_16 j1_06) (inkind_received inkind_consumed)
sort hhid
merge hhid using "${output}/health_humancap25_updt1"
drop if _m==1
keep hhid sector province hhweight inkind_received inkind_consumed quintile
replace inkind_received= 0 if inkind_received==.

replace inkind_received=inkind_received*100 // to make percentage share
label define province 1 "WP" 2 "CP" 3 "SP" 4 "NP" 5 "EP" 6 "NWP" 7 "NCP" 8 "UVA" 9 "SAB", modify
label values province province

*2a-Free food graphs
graph bar inkind_received[fw=hhweight], over(sector) blab(bar, format(%3.2f) gap(0)) ///
title("Households received food through in-kind transfers as a share of total households", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar inkind_received[fw=hhweight], over(quintile) blab(bar, format(%3.2f) gap(0)) ///
title("Households received food through in-kind transfers as a share of total households", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar inkind_received[fw=hhweight], over(province) blab(bar, format(%3.2f) gap(0)) ///
title("Households received food through in-kind transfers as a share of total households", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")	
	
*2b- Graphs- Free food consumption share
graph bar inkind_consumed[fw=hhweight], over(sector) blab(bar, format(%3.2f) gap(0)) ///
title("Consumption share of food received through in-kind transfers", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar inkind_consumed[fw=hhweight], over(quintile) blab(bar, format(%3.2f) gap(0)) ///
title("Consumption share of food received through in-kind transfers", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar inkind_consumed[fw=hhweight], over(province) blab(bar, format(%3.2f) gap(0)) ///
title ("Consumption share of food received through in-kind transfers", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
*3- Beneficiaries of counseling and nutrition messaging
use "${bright2425}\mod_s_nutrition_knowledge.dta", clear // data at household level
ren hhcode hhid
keep hhid s1_08a s1_08b s1_09
sort hhid
merge hhid using "${output}/health_humancap25_updt1"	
 drop if _m==1
gen counsel=1 if s1_08a!="1" //1- counsel
replace counsel=0 if counsel==.
gen nutrition_message=1 if s1_09!="1"
replace nutrition_message=0 if nutrition_message==.
keep hhid sector province hhweight quintile counsel nutrition_message
label define province 1 "WP" 2 "CP" 3 "SP" 4 "NP" 5 "EP" 6 "NWP" 7 "NCP" 8 "UVA" 9 "SAB", modify
label values province province
replace counsel=counsel*100 // to make percent share
replace nutrition_message=nutrition_message*100
*3a-Graphs
graph bar (mean) counsel[fw=hhweight], over(sector) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households received counseling on food and nutrition", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/counsel1.png", replace

graph bar (mean) counsel[fw=hhweight], over(quintile) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households received counseling on food and nutrition", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/counsel2.png", replace

graph bar (mean) counsel[fw=hhweight], over(province, sort(counsel)) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households received counseling on food and nutrition", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/counsel3.png", replace
**nutrition
graph bar (mean) nutrition_message[fw=hhweight], over(sector) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households received messages on food and nutrition", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/counsel1.png", replace

graph bar (mean) nutrition_message[fw=hhweight], over(quintile) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households received messages on food and nutrition", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/counsel2.png", replace

graph bar (mean) nutrition_message[fw=hhweight], over(province, sort(nutrition_message)) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households received messages on food and nutrition", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/counsel3.png", replace
 
*4- Owe money to Food vendors
use "${bright2425}\mod_n1_debt.dta", clear
ren hhcode hhid
keep hhid n1_01_2  // owe money to food vendors
sort hhid
merge hhid using "${output}/health_humancap25_updt1"
drop if _m==1
/*
keep hhid sector province hhweight quintile n1_0- n1_01_12
foreach var of varlist n1_0- n1_01_12 {
replace `var'=0 if `var'==.
}
gen hh=1
collapse(sum) n1_0- n1_01_12 hh [fw= hhweight], by( sector province quintile)
foreach var of varlist n1_0- n1_01_12 {
gen `var'_share= (`var'/ hh)*100
}
*/
ren n1_01_2 foodvendors
replace foodvendors=0 if foodvendors==.
replace foodvendors=foodvendors*100 // to make percetage share
keep hhid sector province hhweight quintile foodvendors
label define province 1 "WP" 2 "CP" 3 "SP" 4 "NP" 5 "EP" 6 "NWP" 7 "NCP" 8 "UVA" 9 "SAB", modify
label values province province
*4a- Graphs
graph bar (mean) foodvendors, over(sector) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households owe money to the food vendors", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/freefood6.png", replace

graph bar (mean) foodvendors, over(quintile) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households owe money to the food vendors", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/freefood7.png", replace
	
graph bar (mean) foodvendors, over(province, sort(foodvendors)) blab(bar, format(%3.1f) gap(0)) ///
title("Share of households owe money to the food vendors", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25") 
	graph export "${graph}/Health/freefood8.png", replace
	
*5- Estimation of cash transfers beneficiaries
use "${bright2425}\mod_r1_cash_long.dta", clear
ren hhcode hhid
keep hhid r1_01 //received cash transfers
collapse(mean) r1_01, by(hhid) // in some of the households more than 1 member say yes
sort hhid
merge hhid using "${output}/health_humancap25_updt1"
drop if _m==1
ren r1_01 cash_beneficiary
keep hhid sector province quintile hhweight cash_beneficiary
replace cash_beneficiary=0 if cash_beneficiary==.
replace cash_beneficiary= cash_beneficiary*100  // to make the percentage share in graph bars
label define province 1 "WP" 2 "CP" 3 "SP" 4 "NP" 5 "EP" 6 "NWP" 7 "NCP" 8 "UVA" 9 "SAB", modify
label values province province
*5a- Graphs
graph bar cash_beneficiary[fw=hhweight], over(sector) blab(bar, format(%3.2f) gap(0)) ///
title("Cash transfers household beneficiaries as a share of total households", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar cash_beneficiary[fw=hhweight], over(quintile) blab(bar, format(%3.2f) gap(0)) ///
title("Cash transfers household beneficiaries as a share of total households", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar cash_beneficiary[fw=hhweight], over(province, sort(cash_beneficiary)) blab(bar, format(%3.2f) gap(0)) ///
title("Cash transfers household beneficiaries as a share of total households", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
*6- Share of cash transfers in households' welfare
use "${bright2425}\mod_r1_cash_long.dta", clear
ren hhcode hhid
keep hhid r1_04 //amount of cash transfers received
collapse(sum) r1_04, by(hhid) // in some of the households more than 1 member say yes
sort hhid
merge hhid using "${output}/health_humancap25_updt1"
drop if _m==1
ren r1_04 cash_received
keep hhid sector province quintile hhweight cash_received welfare_hh_real_ann
replace cash_received=0 if cash_received==.
gen cashtransfer_share= (cash_received/ welfare_hh_real_ann)*100
format cashtransfer_share %3.1f
label define province 1 "WP" 2 "CP" 3 "SP" 4 "NP" 5 "EP" 6 "NWP" 7 "NCP" 8 "UVA" 9 "SAB", modify
label values province province
*6a- Graphs
graph bar cashtransfer_share[fw=hhweight], over(sector) blab(bar, format(%3.2f) gap(0)) ///
title("Cash transfers as a share of households' annual welfare", size(4)) ///
	subtitle("By sector") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar cashtransfer_share[fw=hhweight], over(quintile) blab(bar, format(%3.2f) gap(0)) ///
title("Cash transfers as a share of households' annual welfare", size(4)) ///
	subtitle("By Quintiles") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")
	
graph bar cashtransfer_share[fw=hhweight], over(province, sort(cashtransfer_share)) blab(bar, format(%3.2f) gap(0)) ///
title("Cash transfers as a share of households' annual welfare", size(4)) ///
	subtitle("By provinces") ///
    ytit("Share(%)") note("Source-BRIGHT,2024-25")





