

setwd("E:\\R\\project\\credit card customer\\BankChurners.csv")
getwd()

CC_Custch<- read.csv('project BankChurners.csv')



dim(CC_Custch)

str(CC_Custch)

head(CC_Custch)

tail(CC_Custch)

colnames(CC_Custch)

summary(CC_Custch)

CC_Custch_org<-CC_Custch

CC_Custch[CC_Custch=='Unknown']<- NA

duplicated(CC_Custch)

sum(duplicated(CC_Custch))

#1)  what is the distribution of customer Attrition(Attrition Flag- Target variable)?

Att_fl<- table(CC_Custch$Attrition_Flag)
Att_fl

pie(Att_fl , col = c("yellow","Green"),
                                       main = "Attrition Flag")

#2) what is the distribution of customer Attrition(Attrition Flag) grouped by Income category?

CardInc<- table(CC_Custch$Attrition_Flag,CC_Custch$Income_Category)
CardInc

chisq.test(CardInc)

#3) what is the distribution of customer Attrition(Attrition Flag)  grouped by card category?

Att_crd<- table(CC_Custch$Attrition_Flag,CC_Custch$Card_Category)
Att_crd

counts<-Att_crd
barplot(counts, main="Card Category Vs. Attrition Flag",
        xlab="Attrition Flag", col=c("darkblue","red"),
        legend = rownames(counts))



#4) what is the distribution of customer Attrition(Attrition Flag)  grouped by gender?

Att_Fl1<-table(CC_Custch$Attrition_Flag,CC_Custch$Gender)
Att_Fl1


# to know the dependency between the variable I used Chi Square test

chisq.test(Att_Fl1)


counts1<-Att_Fl1
barplot(counts1, main="Gender Vs. Attrition Flag",
        xlab="Attrition Flag", col=c("pink","red"),
        legend = rownames(counts1))

#5)Is there a relationship between customer Attrition(Attrition Flag) and Months_Inactive?


table(CC_Custch$Months_Inactive_12_mon)

MoInAtt<-aggregate(Months_Inactive_12_mon~Attrition_Flag,data=CC_Custch,'mean')
MoInAtt

boxplot(Months_Inactive_12_mon~Attrition_Flag ,data=CC_Custch , 
        Main = " Attrition by months inactive" ,col = "blue1" )


t.test(Months_Inactive_12_mon~Attrition_Flag ,data=CC_Custch )


#6)Is there a relationship between Attrition_Flag and Total Revolving Balance

table(CC_Custch$Total_Revolving_Bal)


Totrevol<- aggregate(Total_Revolving_Bal~Attrition_Flag ,data=CC_Custch,'mean')
Totrevol


t.test(Total_Revolving_Bal~Attrition_Flag ,data=CC_Custch)

#7)what is distribution of credit limit?

Crdlim<- CC_Custch$Credit_Limit
Crdlim

summary(CC_Custch$Credit_Limit)


library(ggplot2)

hist(Crdlim ,breaks= 8, col = "gray",border = "pink", labels = TRUE)



#8)Is there a relationship between Income and credit limit?

sum(is.na(CC_Custch$Income_Category))

rna <- which(is.na(CC_Custch$Income_Category))
rna

table(CC_Custch$Income_Category)

#summarization
IncrL <-aggregate(Credit_Limit~Income_Category,data=CC_Custch,'mean')
IncrL


boxplot(Credit_Limit~Income_Category,data=CC_Custch , 
        Main = " Income categorgy by credit limit" ,col = "pink" )



#9)Is there a relationship between Contacts_Count_12_mon and Attrition Flag ?



AvgUtl<- aggregate(Contacts_Count_12_mon ~Attrition_Flag, data=CC_Custch,'mean')
AvgUtl

t.test(Contacts_Count_12_mon ~Attrition_Flag, data=CC_Custch)


#10) Is there a relationship between Total Transaction Amount and Total Transaction Count?

cor(CC_Custch$Total_Trans_Amt,CC_Custch$Total_Trans_Ct)

plot(x = CC_Custch$Total_Trans_Ct, y = CC_Custch$Total_Trans_Amt,
     pch = 8, 
     xlab = "Total_Trans_Ct", ylab = "Total_Trans_Amt", col = "Blue")




