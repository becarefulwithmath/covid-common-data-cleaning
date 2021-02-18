clear all
// install package to import spss file
// net from http://radyakin.org/transfer/usespss/beta
//usespss "data.sav"
//saveold "G:\Shared drives\Koronawirus\studies\5 data analysis (Ariadna data)\data_stata_format.dta", version(13)
capture use "G:\Shared drives\Koronawirus\studies\5 data analysis (Ariadna data)\data_stata_format.dta", clear
capture use "G:\Dyski współdzielone\Koronawirus\studies\5 data analysis (Ariadna data)\data_stata_format.dta", clear




//XXX to remove too fast and too slow participants, e.g. fastest (5%) slowest (1%)
// define variable that slows percentile, by time
sort time
gen time_perc = _n/_N
//use it later during the robustness check, when results will be ready (add/remove 5% fastest participants)

gen male=sex==2

//VACCINE PART DATA CLEANING
rename (p37_1_r1	p37_1_r2	p37_1_r3	p37_1_r4	p37_1_r5	p37_1_r6	p37_1_r7	p37_8_r1	p37_8_r2	p37_8_r3	p37_8_r4	p37) (v_producer_reputation	v_efficency	v_safety	v_scarsity	v_other_want_it	v_scientific_authority	v_ease_personal_restrictions	v_price0	v_priceplus70	v_priceminus10	v_priceminus70	v_decision) 
global vaccine_vars "v_producer_reputation	v_efficency	v_safety	v_scarsity	v_other_want_it	v_scientific_authority	v_ease_personal_restrictions	v_price0	v_priceplus70	v_priceminus10	v_priceminus70"
global vaccine_short "v_producer_reputation	v_efficency	v_safety	v_scarsity	v_other_want_it	v_scientific_authority	v_ease_personal_restrictions"

//info in wrong columns, pls check for more such cases!
replace v_decision=P390 if v_decision==""

//DEMOGRAPHICS DATA CLEANING
//wojewodstwo is ommited, because of no theoretical reason to include it
rename (age year) (age_category age)
rename (miasta wyksztalcenie) (city_population edu)

capture drop elementary_edu
gen elementary_edu=edu==1|edu==2
gen secondary_edu=edu==3|edu==4
gen higher_edu=edu==5|edu==6|edu==7

rename m8 income
rename m9 health_state

gen health_poor=health_state==1|health_state==2
gen health_good=health_state==4|health_state==5

gen religious=m10==2|m10==3
//add frequent relig activity
 
global demogr "male age i.city_population secondary_edu higher_edu i.income health_poor health_good religious"
global dem_int "male age higher_edu"

//OTHER DATA CLEANING
rename warunek treatment //Asia, is it really treatment? which is which? which one is corona and cold?
global omg_pls_do_not_be_significant "i.treatment"

// correlations
//pwcorr $demogr v_*, star(.01)
//asdoc pwcorr $demogr v_*, star(.01) fs(6) dec(2) bonferroni save(Asdoc command results.doc) append

//goole about first order interactions check in stata ologit, two way interactions
/*
v_producer_reputation##age
v_safety##age

sex, age, higher_edu interactions
*/


dis "$int_manips"

global int_manips ""
foreach manipulation in $vaccine_short {
	foreach man2 in $vaccine_vars {
	local abb=substr("`manipulation'",1,8)
	local abb2=substr("`man2'",1,14)
	 gen vi_`abb'_`abb2'=`abb'*`abb2'	
	global int_manips "$int_manips vi_`abb'_`abb2'" 	

}
}

dis "$int_manips"

global interactions ""
foreach manipulation in $vaccine_vars {
	foreach demogr in $dem_int {
	local abb=substr("`manipulation'",1,14)
	gen i_`abb'_`demogr'=`abb'*`demogr'	
	global interactions "$interactions i_`abb'_`demogr'" 	

}
}
 



quietly ologit v_decision $vaccine_vars $demogr 
est store m_1
quietly ologit v_decision $vaccine_vars $demogr $omg_pls_do_not_be_significant
est store m_2
test $vaccine_vars

ologit v_decision $vaccine_vars $demogr $omg_pls_do_not_be_significant i_*
est store m_3
test $interactions
ologit v_decision $vaccine_vars $demogr $omg_pls_do_not_be_significant vi_*
est store m_4
test $int_manips

est table m_1 m_2, b(%12.3f) var(20) star(.01 .05 .10) stats(N)

tab v_decision
