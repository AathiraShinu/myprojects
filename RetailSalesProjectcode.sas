/*Setting Directory and Enabling Macros*/


PROC OPTIONS OPTION = MACRO;
RUN;
libname AATHI "E:\mine\data for project\Project Data Files\Proje
ct Data Files\6.Retail Sales Analysis";

/* Importing Files*/
PROC IMPORT OUT= AATHI.transactionhistory
            DATAFILE= "E:\mine\data for project\Project Data Files\Proje
ct Data Files\6.Retail Sales Analysis\transactionhistoryforcurrentcustom
erss.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="transactionhistoryforcurrentcus$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;



proc print data = AATHI.transactionhistory(obs = 200) ; run;



PROC IMPORT OUT= AATHI.ec90 
            DATAFILE= "E:\mine\data for project\Project Data Files\Proje
ct Data Files\6.Retail Sales Analysis\ec90 data.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

proc print data = AATHI.ec90(obs=200) ; run;

*GETTING COLUMN NAMES FOR BOTH FILES ;

PROC CONTENTS DATA = AATHI.transactionhistory VARNUM SHORT;
RUN;

*Customer_ID Item_Code Source Order_Date Item_Description Category price Quantity ;

PROC CONTENTS DATA = AATHI.ec90 VARNUM SHORT;
RUN;


*Order_Number Customer_Number City Prov Postal_Code Order_First_Time Source
Sales_amount Item_Num Item_Description Category_code Quantity;


*EXPLORING THE DATA COLUMNS OF BOTH FILES;
PROC CONTENTS DATA = AATHI.transactionhistory ;
RUN;


PROC CONTENTS DATA = AATHI.ec90 ;
RUN;


PROC MEANS DATA= AATHI.transactionhistory N NMISS MIN MEAN MEDIAN STD MAX MAXDEC=2;
RUN;

PROC MEANS DATA= AATHI.ec90 N NMISS MIN MEAN MEDIAN STD MAX MAXDEC=2;
RUN;

*DATA CLEANING - of Transactionhistory ;

*From the Proc Means Procedure we can find out that Price and Quantity ;
*has '0'  as Mininum so we are further drilling down on this ;

Proc SQl;
Select Count (*) 
from AATHI.transactionhistory
where Quantity = 0;
quit;* we have 9 Rows so we are deleting them ;

data AATHI.transactionhistory;
set AATHI.transactionhistory;
if Quantity = 0 then delete;
run;

Proc SQl;
Select Count (*) 
from AATHI.transactionhistory
where price = 0;
quit; * we have 385 Rows so we are deleting them ;

data AATHI.transactionhistory;
set AATHI.transactionhistory;
if price = 0 then delete;
run;

*Checking for missing values in Categorical Columns;

Proc freq data = AATHI.transactionhistory;
table Category / missing;
run; *we have a category as blank so we drop that blank category;

data AATHI.transactionhistory;
set AATHI.transactionhistory;
if Category = ' ' then delete;
run; 

Proc freq data = AATHI.transactionhistory;
table Category Source;
run;

*Creating Sales Column in Transactionhistory ; 

Proc SQL;
Create Table AATHI.transactionhistory as
Select *, price * Quantity as Sales
from AATHI.transactionhistory;
quit;

Proc Print data = AATHI.transactionhistory (obs = 20) ; run;


PROC MEANS DATA= AATHI.transactionhistory N NMISS MIN MEAN MEDIAN STD MAX MAXDEC=2;
RUN;

*DATA CLEANING - of EC90 ;

*RENAMING COLUMNS IN EC90;


*renaming Sales_amount = sales,Customer_Number = Customer_ID, Category_code =Category ,
Order_Number = Item_Code columns to ,;


data AATHI.ec90
(rename = ( Customer_Number = Customer_ID 
Category_code = Category
Order_Number = Item_Code));
set AATHI.ec90;
run;

data AATHI.ec90
(rename = (Sales_amount = Sales));
set AATHI.ec90;
run;

Proc freq data = AATHI.ec90;
table City Prov Category Source;
run;



*create price columns in EC90 ;

data AATHI.ec90 ;
set AATHI.ec90;
Price = Sales / Quantity;
run;

proc print data = AATHI.ec90 (obs = 20) ; run;


*Checking for Unique Customer, Item Count AND Total Sales for both dataset ;

Proc SQL;
Select Count (Customer_ID )  as Total_Count,
	   Count (Distinct Customer_ID ) as Unique_Cust_ID,
	   Count (Distinct Item_Code ) as Unique_Item,
	   sum (price ) as Total_amt
from AATHI.transactionhistory
;
quit;

Proc SQL;
Select Count (Customer_ID )  as Total_Count,
	   Count (Distinct Customer_ID ) as Unique_Cust_ID,
	   Count (Distinct Item_Code ) as Unique_Item,
	   sum (price ) as Total_amt
from AATHI.ec90
;
quit;


PROC CONTENTS DATA = AATHI.transactionhistory VARNUM SHORT;
RUN;


PROC CONTENTS DATA = AATHI.ec90 VARNUM SHORT;
RUN;


*JOINING TWO DATASETS;

*Extracting only required columns from both dataset;

proc SQL;
create table AATHI.transaction as
select A.Customer_ID,A.Item_Code,A.Source,A.Category,A.Item_Description,A.price,
A.Quantity,A.Sales
from AATHI.transactionhistory as A
;
quit;

Proc Print data = AATHI.transaction (obs = 20); run;

proc SQL;
create table AATHI.NewEc90 as
select B.Customer_ID,B.Item_Code,B.Source,B.Category,B.Item_Description,B.price,
B.Quantity,B.Sales
from AATHI.ec90 as B
;
quit;

Proc Print data = AATHI.NewEc90 (obs = 20); run;



*Combining both the dataset ; 

Proc sort data = AATHI.transaction ;
by Customer_ID;
run;


Proc sort data = AATHI.NewEc90 ;
by Customer_ID;
run;




PROC SQL;
 CREATE TABLE AATHI.TotalTransact AS
 SELECT * 
 FROM AATHI.transaction
 Outer Union Corr /*corr=Corresponding*/
 SELECT *
 FROM AATHI.NewEc90
 ;
 QUIT;


Proc sort data = AATHI.TotalTransact;
by Customer_ID;
run;


Proc SQL;
create table AATHI.City as
select B.City,B.Prov,B.Customer_ID
from AATHI.Ec90 as B;
quit;

Proc sort data = AATHI.City;
by Customer_ID;
run;

data AATHI.TotalSales;
merge AATHI.TotalTransact AATHI.City ;
by Customer_ID;
run;



proc sort DATA = AATHI.TotalSales nodup ;
by Customer_ID Item_Code Source Category Item_Description price Quantity Sales Prov City;
run;

PROC PRINT DATA = AATHI.TotalSales ;RUN;

PROC CONTENTS DATA = AATHI.TotalSales ;
RUN;
 

*Customer_ID Item_Code Source Category Item_Description price Quantity Sales Prov City;


PROC MEANS DATA= AATHI.TotalSales  N NMISS MIN MEAN MEDIAN STD MAX MAXDEC=2;
RUN;


Proc freq data = AATHI.TotalSales;
table Item_Code Source Category Item_Description Prov City/ missing;
run;
 
/*UNIVARIATE ANALYSIS*/

/*For Categorical Columns*/


proc gchart DATA = AATHI.TotalSales;
   
   pie Source / coutline=white
   				percent=arrow;
 TITLE 'Distribution of Source';               	
run;
quit;

proc gchart DATA = AATHI.TotalSales;
   
   pie Category / coutline=black
   					percent=arrow;
 TITLE 'Distribution of Category';               	
run;
quit;

 
proc gchart DATA = AATHI.TotalSales;
   
   pie Prov / coutline=Yellow
   					percent=arrow;
 TITLE 'Distribution of Province';               	
run;
quit;





/*For Numerical Columns*/


title 'Price Distribution';
proc sgplot DATA = AATHI.TotalSales;
  histogram price;
  density price  / type=normal  lineattrs=(pattern=solid);
    run;


	
title 'Distribution price';
proc sgplot DATA = AATHI.TotalSales;
 vbox price;
 run;

 Proc Univariate DATA = AATHI.TotalSales;
 var price;
 run;


 title 'Distribution Quantity';
proc sgplot DATA = AATHI.TotalSales;
 vbox Quantity;
 run;

Proc Univariate DATA = AATHI.TotalSales;
 var Quantity;
 run;

 title 'Distribution Sales';
proc sgplot DATA = AATHI.TotalSales;
 vbox Sales;
 run;



 Proc Univariate DATA = AATHI.TotalSales;
 var Sales;
 run;



/*BIVARIATE ANALYSIS*/


 PROC SGPLOT  DATA = AATHI.TotalSales ;
 VBAR Source/GROUP =  Category ;
 TITLE "Relationship between Source and Category";
RUN;
QUIT;

 PROC SGPLOT  DATA = AATHI.TotalSales ;
 VBAR Source/GROUP =  Category ;
 TITLE "Relationship between Source and Category";
RUN;
QUIT;



title ' Sales by Source';
proc sgplot DATA = AATHI.TotalSales;
  vbar Source / response=Sales stat=sum nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;
 

title ' Sales by Category';
proc sgplot DATA = AATHI.TotalSales;
  vbar Category / response=Sales stat=sum nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;


  title ' Sales by Province';
proc sgplot DATA = AATHI.TotalSales;
  vbar Prov / response=Sales stat=sum nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;


ods html style=statistical;

proc sgplot DATA = AATHI.TotalSales;
   scatter y=Sales x=Quantity ;
   title ' Sales by Quantity';
run;

ods html close;



/*MULTIVARIATE ANALYSIS*/
ods html style=statistical;
title 'Actual Sales by Source and Category';
proc sgplot DATA = AATHI.TotalSales;
  vbar Source / response= Sales stat=Sum group=Category nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;
ods html close;



ods html style=statistical;
title 'Actual Sales by Province and Source';
proc sgplot DATA = AATHI.TotalSales;
  vbar Prov / response= Sales stat=Sum group=Source nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;
ods html close;




ods html style=statistical;
title 'Actual Sales by Province and Category';
proc sgplot DATA = AATHI.TotalSales;
  vbar Prov / response= Sales stat=Sum group=Category nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;
ods html close;


ods html style=statistical;
title 'Actual Quantity sold by Province and Source';
proc sgplot DATA = AATHI.TotalSales;
  vbar Prov / response= Quantity stat=Sum group=Source nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;
ods html close;



ods html style=statistical;
title 'Actual Quantity sold  by Province and Category';
proc sgplot DATA = AATHI.TotalSales;
  vbar Prov / response= Quantity stat=Sum group=Category nostatlabel;
  xaxis display=(nolabel);
  yaxis grid;
  run;
ods html close;


proc Tabulate DATA = AATHI.TotalSales;
class  Source Prov Category;
var Sales ;
table Prov * Category , Source * Sales/
rts = 20;
run; 


proc Tabulate DATA = AATHI.TotalSales;
class  Source Prov Category;
var Quantity ;
table Prov * Category , Source * Quantity/
rts = 20;
run; 








*orders per customer by Province;
proc sql ;
create table AATHI.totalorder_Province as
select count(customer_ID) AS TOTAL_ORDERS_PER_CUSTOMER, Prov
FROM AATHI.TotalSales
group by Prov
order by TOTAL_ORDERS_PER_CUSTOMER DESC;
quit;

Proc Print data = AATHI.totalcount_Province (Obs = 10  ); run;


*sales per province;
proc sql ;
create table AATHI.totalsales_PROV as
select sum(Sales) format dollar13.2 AS TOTAL_SALES_PER_PROV, Prov
FROM AATHI.TotalSales
group by Prov 
order by TOTAL_SALES_PER_PROV DESC;
quit;

Proc Print data = AATHI.totalsales_PROV (Obs = 10  ); run;


/*Top 10 Customer ID , Item Code */

proc sql;
 create table AATHI.Top_Customers as
select Customer_ID as Customers,
sum(Sales) as total_Sales
from AATHI.TotalSales
group by Customer_ID order by total_Sales desc;
title 'Top 10 Customers with total Sales';
quit;  

Proc print data = AATHI.Top_Customers (obs = 10); run;



proc sql;
 create table AATHI.Top_Items as
select Item_Code as Items,
sum(Sales) as total_Sales
from AATHI.TotalSales
group by Item_Code order by total_Sales desc;
title 'Top 10 Items with total Sales ';
quit;  

Proc print data = AATHI.Top_Items (obs = 10); run;




/*Customer_ID Item_Code*/




/*HYPOTHESIS TESTING*/


 /*Creating Macro for doing Chi square testing*/
PROC FREQ DATA = AATHI.TotalSales;
TITLE "Relationship between Source and Category";
TABLE Source*Category/CHISQ OUT=OUT_Source_Category;
RUN;

/*step 2 */
%LET DSN =AATHI.TotalSales ;
%LET VAR1 = Source;
%LET VAR2 = Category;

PROC FREQ DATA = &DSN;
TITLE "Relationship between Source and Category";
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



%CHSQUARE(DSN = AATHI.TotalSales , VAR1= Source , VAR2 =Category);

%CHSQUARE(DSN = AATHI.TotalSales , VAR1= Prov  , VAR2 =City);

%CHSQUARE(DSN = AATHI.TotalSales , VAR1= Source , VAR2 =Prov);

%CHSQUARE(DSN = AATHI.TotalSales , VAR1= Source , VAR2 =City);

%CHSQUARE(DSN = AATHI.TotalSales , VAR1= Category , VAR2 =Prov);

%CHSQUARE(DSN = AATHI.TotalSales , VAR1= Category , VAR2 =City);



ods graphics on;
PROC ANOVA DATA = AATHI.TotalSales;
 CLASS Source ;
 MODEL Sales = Source;
 MEANS Source/Scheffe;
 RUN;
QUIT;

ods graphics off;

ods graphics on;
PROC ANOVA DATA = AATHI.TotalSales;
 CLASS Source ;
 MODEL Sales = Source;
 MEANS Source/Scheffe;
 RUN;
QUIT;

ods graphics off;

/*Category Item_Description price Quantity Sales Prov City*/

PROC CORR DATA = AATHI.TotalSales;
  VAR price Quantity ;
  WITH Sales;
RUN;


/*Model Building*/

proc standard DATA = AATHI.TotalSales mean = 0 std = 1 out = AATHI.N_TotalSales;
var Sales Quantity price;
run;





ods graphics on;
proc glmselect DATA = AATHI.N_TotalSales plots =All;
class Prov Source Category City;
model Sales = Source Category  price Quantity Prov City/Selection = Forward select= SL showpvalues stats=all STB;

run;

ods graphics off;





/*Clustering*/


PROC CLUSTER DATA = AATHI.TotalSales METHOD=ward print = 10 ccc pseudo;
VAR Quantity  price;
copy sales;

RUN;



ods graphics on;
PROC TREE noprint ncl =5 out = out;
copy sales :Quantity : price ;
RUN;
ods graphics off;


%macro show;
	Proc freq;
		tables cluster * Sales/ nopercent norow nocol plot = none;
	run;


	Proc candisc noprint out=can;
		class cluster ;
		var  Quantity : price: ;
	run;

	proc sgplot data = can ;
		scatter y= can2 x= can1 / group = cluster;
	run;
%mend;

PROC TREE noprint ncl =5 out = out;
copy sales :Quantity : price ;
RUN;

%show;



/*End*/
