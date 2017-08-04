##Introduction
This repository is concerned with getting and cleaning data related to accelerometer and gyroscopic information collected on 30 persons performing 6 physical activities. This document is meant to describe the contents of the repository and the algorithm used to generate a tidy data set as required in the Getting & Cleaning Data Project on Coursera. The raw data can be found at: <https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip>.

There are two other files in this repository:

* **CodeBook.md**  
    * Describes the raw data, its transformation process, the resulting tidy dataset, and a description of its contents.  

* **run_analysis.R**  
    * An R script that automates the getting and cleaning data process. The script is run in the working directory where the downloaded files are, and outputs the tidy data set titled, "tidydataset.txt". The code book describes the tidy dataset in detail.

The course project outlines 5 steps:  
 1. Merges the training and the test sets to create one data set.  
 2. Extracts only the measurements on the mean and standard deviation for each measurement.  
 3. Uses descriptive activity names to name the activities in the data set.  
 4. Appropriately labels the data set with descriptive variable names.  
 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.  **

The "run_analysis.R" script automates this process. Use the link above to import a zip file containing all of the required help files and data. Place file contents in your working directory. 

###Files Required
The required downloaded files for tidy dataset generation script are:

- 'features.txt': Class Labels of all measurements taken. Dimensions are 561x2. 

- 'activity_labels.txt': Links the class labels with their activity name. Dimensions are 6x2.

- 'train/X_train.txt': Training set of measurements taken. Dimensions are 7352x561

- 'train/y_train.txt': Training set of activity labels for each measurement taken. Dimensions are 7352x1

- 'test/X_test.txt': Test set of measurements taken. Dimensions are 2947x561

- 'test/y_test.txt': Test set of activity labels for each measurement taken. Dimensions are 2947x561  

In both "train" and "test" sets:  

- '../subject_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30.  Dimensions are 7352x1.  

###Script "run_analysis.R" Processing
The rest of this file will describe the procecssing performed in the "run_analysis.R" script.

###Step 1
The data is divided into two sets: "train" and "test" and should be visible as folders in your working directory. Within each of those folders, there are three files that need to be merged first. Let's begin with "train":
```{r}
features<-read.table("features.txt")                          #Want the column names of the measurements
setwd("./train")                                              
subtrain<-read.table("subject_train.txt",col.names="subject") #Read in subject data
xtrain<-read.table("X_train.txt")                             #Read in measurement data
colnames(xtrain)<-features[,2]                                #Assign names to measurements
ytrain<-read.table("y_train.txt", col.names="activity")       #Read in the activity data
mergetrain<-cbind(subtrain,ytrain,xtrain)       #Merge subject, activity, and measurement data together
```

Merging the "test" data together:
```{r}
setwd("../test")                                                
subtest<-read.table("subject_test.txt", col.names="subject")  #Read in subject data
xtest<-read.table("X_test.txt")                               #Read in measurement data
colnames(xtest)=features[,2]                                  #Assign names to measurements
ytest<-read.table("y_test.txt", col.names="activity")         #Read in activity data
mergetest<-cbind(subtest,ytest,xtest)           #Merge subject, activity, and measurement data together
```

Now, for the final merge of mergetrain and mergetest:
```{r}
dataset<-rbind(mergetrain,mergetest)      #Bind on rows since each row is an observation of features/measurements                                                    #with respect to the subject and activity
```

This completes Step 1. The dimensions of dataset are 10299x563. The first to columns are the "subject" and "activity" followed by 561 measurements.

###Step 2
Step two extracts the mean and standard deviation measurements for all subjects and activities performed. The "data.table"" and "dplyr"  package will be needed to cast the dataset as a data.table and to select the necessary columns. The measurement requirement is interpreted to mean that the average and standard deviation of the measurements are to be extracted. This does not include meanFreq variables, which capture the mean frequency sampling of the variable - not the variable itself. Must be careful to exclude the angle measurements as well:
```{r}
install.packages(c("data.table","dplyr"))
library(data.table);library(dplyr)
DT<-data.table(dataset)           
subset<-select(DT,contains("subject"),contains("mean"),contains("std"),-contains("angle"),-contains("Freq"))

```

This completes Step 2. The final subset data has dimensions 10299x68 - representing 10299 observations for 66 explicit mean and standard deviation measurements (the first two columns are the subject and activity).

###Step 3
Next we want to replace the numeric 1-6 values for the "activity" with its string description. This is done below by reading in the mapping table between the numeric and string descriptions, merging it with the subset data from Step 2, and then finally eliminating the numeric column and renaming the "description" column to "activity".
```{r}
setwd("../")
activity<-read.table("activity_labels.txt", col.names=c("activity","description"))
subset.merge<-merge(activity,subset,by="activity")  
subset.merge<-subset.merge[,2:69]
subset2<-rename(subset.merge, activity=description)
```

###Step 4
The names are pretty descriptive already. I will remove "()" characters and standardize the spelling of Mean. The "-" separates the variable from the measurement and the measurement form the direction. General variable name formatting is "variable-measurement-direction".
```{r}
names(subset2)<-gsub("mean()","Mean",names(subset2),fixed=TRUE)
names(subset2)<-gsub("mean","Mean",names(subset2),fixed=TRUE)
names(subset2)<-gsub("std()","StD",names(subset2),fixed=TRUE)
```

###Step 5
Cast subset2 as a data.table so that the data set can be grouped by the "activity" and "subject" while applying the lapply function to calculate the mean for the remaining columns. The column names are then reformatted to indicate the mean() has been taken for each variable:
```{r}
subset2<-data.table(subset2)
gsubset<-subset2[, lapply(.SD,mean), by=list(activity,subject)]
colnames(gsubset)[3:68] <- paste("Mean(", colnames(gsubset)[3:68],")", sep = "")
```

The data set is now tidy. Write the table to a " " separate text file:
```{r}
write.table(gsubset,file="tidydataset.txt",row.name=FALSE)
```

The variables and data in the tidy dataset are detailed in CodeBook.md
