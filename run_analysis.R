###Getting & Cleaning Data Course Project###

##Step 1
#Navigate to Working Directory where the Read.Me and related texts are stored
#Read in features.txt to get class labels for X_train.txt
features<-read.table("features.txt")
setwd("./train")

#Read tables into R and assign headers
subtrain<-read.table("subject_train.txt",col.names="subject")
xtrain<-read.table("X_train.txt")
colnames(xtrain)<-features[,2]
ytrain<-read.table("y_train.txt", col.names="activity")

#Merge Datasets by binding columns together. Put subject and activity first.
mergetrain<-cbind(subtrain,ytrain,xtrain)

#Want to merge the train data with test data. Navigate to test data:
setwd("../test")

#Read tables into R
subtest<-read.table("subject_test.txt", col.names="subject")
xtest<-read.table("X_test.txt")
colnames(xtest)=features[,2]
ytest<-read.table("y_test.txt", col.names="activity")

#Merge test files together in same order as train files
mergetest<-cbind(subtest,ytest,xtest)

#Merge train and test by binding rows together to get merged dataset:
dataset<-rbind(mergetrain,mergetest)

#Step2
#Cast class of dataset to a data.table for easier manipulation
#Need to have data.table and dplyr packages installed and loaded.
#dplyr package used to extract columns via select() for "mean" and "std"
install.packages(c("data.table","dplyr"))
library(data.table);library(dplyr)
DT<-data.table(dataset)
subset<-select(DT,contains("activity"), contains("subject"),contains("mean"),contains("std"),-contains("angle"),-contains("Freq"))

#Step3
#Replace "activity" column's numeric values with string description:
setwd("../")
activity<-read.table("activity_labels.txt", col.names=c("activity","description"))
subset.merge<-merge(activity,subset,by="activity")
subset.merge<-subset.merge[,2:69]
subset2<-rename(subset.merge, activity=description)

#Step4
#Rename variables with better description
#The names are pretty descriptive already. I will remove "()" characters and
#standardize the spelling of Mean. The "-" separates the variable from the
#measurement and the measurement form the direction. General variable name
#formatting is "variable-measurement-direction" except for angle variables
#which consist soley of the variable name.
names(subset2)<-gsub("mean()","Mean",names(subset2),fixed=TRUE)
names(subset2)<-gsub("mean","Mean",names(subset2),fixed=TRUE)
names(subset2)<-gsub("std()","StD",names(subset2),fixed=TRUE)

#Step5
#Need to group the subset by activity and subject
#then find the mean of each column in the dataset
#One way of doing it is: gsubset<-subset2%>%group_by(activity,subject)%>%summarize_each(funs(mean))
#The way I chose is:
subset2<-data.table(subset2)
gsubset<-subset2[, lapply(.SD,mean), by=list(activity,subject)]
colnames(gsubset)[3:68] <- paste("Mean(", colnames(gsubset)[3:68],")", sep = "")

#Write the tidy dataset to a text file in your working directory:
write.table(gsubset,file="tidydataset.txt",row.name=FALSE)

