libname Athiproj "E:\mine\SAS - Adv\project";
PROC OPTIONS OPTION = MACRO;
RUN;

data Athiproj. My_project;
Infile "E:\mine\SAS - Adv\project\New_Wireless_Fixed.txt" obs = 10000 ;


Input Acct_no 1-13
@ 15 Acc_dt mmddyy10.
@26 Deact_dt mmddyy10.
Deact_Reason $ 41-44
Good_Credit 53
Rate_Plan $ 62
Dealer_Type $ 65-66
Age 74-75
Province $ 80-81
@ 85 Sales dollar6.2
;
format  Acc_dt date9. Deact_dt date9. Acct_no 13.0 ;
format Sales dollar6.2;
;
run;

proc print data = Athiproj. My_project ; run;


proc contents data = Athiproj. My_project;
run;


PROC SORT DATA= Athiproj. My_project
 DUPOUT= Athiproj. MyProNdup
 NODUPRECS ;
 BY Acct_no ;
RUN ;

/*1.1  Explore and describe the dataset briefly. For example, is the acctno unique? What
is the number of accounts activated and deactivated? When is the earliest and
latest activation/deactivation dates available? 
*/

/*PROC SQL;
CREATE TABLE projtab AS
SELECT * ,
		COALESCE(Age,mean(Age)) as N_Age, 
		COALESCE(Sales,median(Sales)) AS N_Sales
FROM Athiproj. My_project
;
ALTER TABLE projtab 
DROP Age,Sales
;
QUIT;
PROC PRINT DATA = projtab;RUN;*/

/*1a*/

PROC SQL;
CREATE TABLE Athiproj. Uni_Acctno AS
SELECT DISTINCT Acct_no
FROM Athiproj. My_project
;
QUIT;
proc print data = Athiproj. Uni_Acctno;run;

PROC SQL;
 SELECT COUNT(DISTINCT Acct_no) AS UNI_ID_COUNT
 FROM Athiproj. My_project
 ;
 QUIT;

/*1b*/

DATA Athiproj. Decdate_miss; 
SET Athiproj. My_project;
IF Deact_Reason EQ " " THEN Deact_Reason1 ="Active   ";
else  Deact_Reason1="Deactive";
RUN;

 proc print data = Athiproj. Decdate_miss; run;

PROC SQL;
SELECT COUNT(*) AS TOTAL_COUNT, 
	   COUNT(DISTINCT Deact_Reason1) AS UNIQUE_COUNT LABEL= "Active"
FROM Athiproj. Decdate_miss
WHERE Deact_Reason1 ='Active'

;
QUIT;

PROC SQL;
SELECT COUNT(*) AS TOTAL_COUNT, 
	   COUNT(DISTINCT Deact_Reason1) AS UNIQUE_COUNT LABEL= "Deactive"
FROM Athiproj. Decdate_miss
WHERE Deact_Reason1 ='Deactive'

;
QUIT;



/*1c*/

proc sql outobs=1;
         select*from Athiproj. My_project
	  where Acc_dt is not null
	  order by Acc_dt;
Quit;

proc sql outobs=1;
         select*from Athiproj. My_project
	  where Acc_dt is not null
	  order by Acc_dt Desc;
Quit;


proc sql outobs=1;
         select*from Athiproj. My_project
	  where Deact_dt is not null
	  order by Deact_dt;
Quit;

proc sql outobs=1;
         select*from Athiproj. My_project
	  where Deact_dt is not null
	  order by Deact_dt Desc;
Quit;

/*1.2  What is the age and province distributions of active and deactivated customers?*/



proc sgplot data=Athiproj. Decdate_miss;
vbox Age / category=Deact_Reason1;
TITLE 'Distribution of Age to Account status';
 run;

PROC SGPLOT DATA = Athiproj. Decdate_miss;
VBAR Province / GROUP = Deact_Reason1;
TITLE 'Distribution of Province to Account status';
RUN;




/*1.3 Segment the customers based on age, province and sales amount:
Sales segment: < $100, $100---500, $500-$800, $800 and above.
Age segments: < 20, 21-40, 41-60, 60 and above.
Create analysis report 
*/

DATA Athiproj. Seg;
 SET Athiproj. My_project;
   length   agegroup $15;
   length   salesgroup $15;
   if       Age   le 20	then  agegroup = 'less than 20';
   else if  Age   le 41	then  agegroup = 'between 21-40 ';
   else if  Age   le 61	then  agegroup = 'between 41-60 ';
   else if  Age   gt 61	then  agegroup = 'more than 60';
		
   if       Sales le 100  then  salesgroup = 'less than 100';
   else if  Sales le 500  then  salesgroup = 'between 100-500';	 
   else if  Sales le 800  then  salesgroup = 'between 500-800';	 
   else if  Sales gt 800  then  salesgroup = 'more than 800';	
run;

proc print data =Athiproj. Seg; run; 

proc means data=Athiproj. Seg  n NMISS  mean max min range median;
run;



/*1.4 .Statistical Analysis:

1) Calculate the tenure in days for each account and give its simple statistics.*/


data Athiproj. tenure;
set Athiproj. My_project;
where Acc_dt is not null;
TENURE_days = INTCK("days",Acc_dt,"23Apr2021"D);
run;
proc print data =Athiproj. tenure ; run;

proc means data=Athiproj. tenure  n NMISS  mean max min range median;
run;



/*2) Calculate the number of accounts deactivated for each month.*/




data Athiproj. Yr_Mon;
set Athiproj. Decdate_miss;
where Deact_dt is not null;
Dec_dt_mon = put(Deact_dt,MONYY7.);
run;
proc print data =Athiproj. Yr_Mon ; run;

proc sql;
select Dec_dt_mon, count ( Deact_Reason1) as total_dec_mon
from Athiproj. Yr_Mon
where Deact_Reason1 = "Deactive"
group by Dec_dt_mon
;
quit;


/*3) Segment the account, first by account status “Active” and “Deactivated”, then by
Tenure: < 30 days, 31---60 days, 61 days--- one year, over one year. Report the
number of accounts of percent of all for each segment.*/



data Athiproj. tenure1;
set Athiproj. My_project;
where Acc_dt is not null;
TENURE_days = INTCK("days",Acc_dt,"23Apr2021"D);
IF Deact_Reason EQ " " THEN Deact_Reason1 ="Active   ";
else  Deact_Reason1="Deactive";
run;

proc sql;
create table Athiproj. tenure2 as
select * ,
     min(Acc_dt) as Accountstartdate,
     max(Deact_dt) as Deactivated_Date,
     max(Deact_dt) - min(Acc_dt) as Tenure_of_stay
from Athiproj. My_project
group by Acct_no
;
quit;

proc print data =Athiproj. tenure2; run;


PROC FORMAT;
 VALUE TEN 
           LOW - 30 ="LESS THAN 30 days"
 			31-60   = "BETWEEN 31 AND 60 days"
			61-365 = "BETWEEN 61 days AND 1year"
		  366- HIGH = "1 YEARS AND ABOVE";
RUN;

data tenure_fin;
MERGE Athiproj. tenure1 (IN=A)    Athiproj. tenure2  (IN=B);
 BY Acct_no;
 IF B ;
RUN;

proc print data =tenure_fin; run;



proc print data =tenure_fin ;
format TENURE_days ten.;
format Tenure_of_stay ten.;
run;


proc freq data =Athiproj. tenure1 ;
table TENURE_days Deact_Reason1 ;
format TENURE_days ten.;
run;



/*4) Test the general association between the tenure segments and “Good Credit”
“RatePlan ” and “DealerType.”*/



DATA Athiproj. ten_Seg;
 SET tenure_fin;
   length   Tenuregroup $15;
	    if      TENURE_days   le 30	then  Tenuregroup = 'less than 30 days';
   else if  TENURE_days   le 60	then  Tenuregroup = 'btw 31-60days';
   else if  TENURE_days   le 365	then  Tenuregroup = 'btw 61days-1 yr ';
   else if  TENURE_days   gt 366	then  Tenuregroup = 'more than 1 yr';
	
   if      Tenure_of_stay   le 30	then  Tenuregroup = 'less than 30 days';
   else if  Tenure_of_stay   le 60	then  Tenuregroup = 'btw 31-60days';
   else if  Tenure_of_stay   le 365	then  Tenuregroup = 'btw 61days-1 yr ';
   else if  Tenure_of_stay   gt 366	then  Tenuregroup = 'more than 1 yr';

run;


/*step 1*/
PROC FREQ DATA = Athiproj. ten_Seg;
TITLE "Relationship between Tenure segment and Dealer Type";
TABLE Tenuregroup * Dealer_Type/CHISQ OUT=OUT_Dealer_Type;
RUN;

/*step 2 */
%LET DSN =Athiproj. ten_Seg ;
%LET VAR1 = Tenuregroup;
%LET VAR2 = Dealer_Type;

PROC FREQ DATA = &DSN;
TITLE "Relationship between Tenure segment and Dealer Type";
 TABLE &VAR1. * &VAR2 /CHISQ OUT=OUT_&VAR1._&VAR2 ;
RUN;

/*step 3*/

%MACRO CHSQUARE (DSN = ,VAR1= , VAR2= );
ods graphics on;
proc freq data=&DSN;
tables (&VAR1.)*(&VAR2) / chisq
 plots=(freqplot(twoway=grouphorizontal
 scale=percent));
run;
ods graphics off
%MEND CHSQUARE;


%CHSQUARE(DSN = Athiproj. ten_Seg , VAR1= Tenuregroup , VAR2 =Dealer_Type);

%CHSQUARE(DSN = Athiproj. ten_Seg , VAR1= Tenuregroup , VAR2 =Good_Credit);

%CHSQUARE(DSN = Athiproj. ten_Seg , VAR1= Tenuregroup , VAR2 =Rate_Plan);



/*5) Is there any association between the account status and the tenure segments?
Could you find out a better tenure segmentation strategy that is more associated
with the account status?*/

%CHSQUARE(DSN = Athiproj. ten_Seg , VAR1= Tenuregroup , VAR2 =Deact_Reason1);




/*6) Does Sales amount differ among different account status, GoodCredit, and
customer age segments?
*/

proc means data=Athiproj. Decdate_miss mean clm;
var Sales;
run;


ods graphics on;
proc ttest data=Athiproj. Decdate_miss;
class Deact_Reason1;
var Sales;
run;
ods graphics off;


ods graphics on;
proc ttest data=Athiproj. Decdate_miss;
class Good_Credit;
var Sales;
run;
ods graphics off;


ods graphics on;
PROC ANOVA DATA = Athiproj. Seg;
 CLASS agegroup;
 MODEL Sales = agegroup;
 MEANS agegroup/Scheffe;
 RUN;
QUIT;

ods graphics off;


