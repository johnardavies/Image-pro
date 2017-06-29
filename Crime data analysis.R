library(rgdal)
library(geojsonio)
library(ggplot2)

#Processes the monthly crime data into two geojsons 1) a geojson of geocoded crime events and 2) a geojson of crimes by ward
#The code then plots monthly crime rates

#Filepath for the monthly crime data from the 2016 folder
path="filepath\London2016crimedata\\2016\\"

#Reads in the data files month by month and sticks it together in a dataframe called all
all <- data.frame() #creates a data frame called all
i <- 1 #creates a counter variable called i sets it to 1
files <- list.files(path, pattern = '*.csv')   # list.files produces a character vector of the names of files or directories in the named directory. 
for (f in files) {    #loops through the files in the list
  print(paste('Reading file',i,'of',length(files)))
  d <- read.table(paste(path, f, sep=''),sep=",", header=T)
  names(d)<-tolower(names(d))  #sets all the file names to lower case
  print(names(d))
  all <- rbind(all, d)  #sticks the new variables to those that have already been collected from the previous files looked at
  i <- i+1
}

#############################################################################################################################################
#Creates a gesojson from the crime points data

crime<-all
rm(all)

#Remove the crimes with no coordinates
crime<-subset(crime, crime$longitude!="NA" & crime$latitude!="NA")

#Creates speatial points
points<-SpatialPoints(cbind(crime$longitude, crime$latitude))

#sets up the projection for the photos as the same
proj4string(points) <- CRS("+proj=longlat +datum=WGS84")
              

#Creates a spatial points data frame
crimespdf = SpatialPointsDataFrame(points, crime)

############################################################################################################################
#Removes all crimes that are geocoded outside London

#Reads in the EU NUTS file
Lward<-readOGR("filepath\shape\\data","NUTS_RG_03M_2006")

#Selects the London boundary
Lward<-subset(Lward, Lward@data$NUTS_ID=='UKI')

#Sets the projection
Lward<-spTransform(Lward, CRS("+proj=longlat +datum=WGS84"))

#sees which ward the crime was in and binds it to the data frame
inLon<-over(crimespdf, Lward)

crimespdf@data<-cbind(crimespdf@data, inLon)

#Removes the crimes that fall outside London
crimespdf<-subset(crimespdf, crimespdf@data$OBJECTID!='NA') 
########################################################################################################################################

#Write out the crime point data as a geojson
geojson_write(crimespdf, file = "filepath\\crime.geojson")

##########################################################################################################################################
#Calculates the crimes by Londonwards and write out as a geojson

#Reads in the Londonwards data
Lwards<-readOGR("filepath\\Londonwardsinfo.geojson" , "OGRGeoJSON") 

#Sets up the projection
Lwards<-spTransform(Lwards, CRS("+proj=longlat +datum=WGS84"))

#Matches each crime to a Londonward
inLonward<-over(crimespdf, Lwards)

#Recodes crimetype so there are no javascript problemslater with the .

names(crimespdf@data)[names(crimespdf@data)=="Crime.type"] <- "Crimetype"

crimespdf@data<-cbind(crimespdf@data, inLonward[, c("NAME", "GSS_CODE", "HECTARES", "NONLD_AREA", "LB_GSS_CD","BOROUGH", "POLY_ID","osward")])

library(plyr)
#Creates acrosstab of ward by crimetype in long form
Crimebywards<-count(crimespdf@data, c('NAME','crime.type' ))

#Reshape it from long form to wide form
library(reshape2)

#Calculates number of crimes bt tyoe by london ward
Crimebywards<-dcast(Crimebywards, NAME ~ crime.type, value.var = "freq", fun = sum)

#Calculates the row totals
Crimebywards$total<-apply(Crimebywards[,-1],1,sum)

#Matches the crime by ward data to the Local authority wards data.
Lwards@data<-cbind(Lwards@data, Crimebywards[match(Lwards@data[,c("NAME")], Crimebywards[,c("NAME")]) ,])

#Removes the first column to prevent duplication of the name variable
Lwards@data<-Lwards@data[, -1]

#Write out the crime by local authority data as a geojson
geojson_write(Lwards, file = "filepath\\crimela.geojson")


##########################################################################################################################################
#Plots the number of crimes over time
Closurecount<-count(crimespdf@data, c('month','crime.type' ))

#Plots the number of crimes over time, in this case for anti-social behaviour
ggplot(data=subset(Closurecount, Closurecount$crime.type=='Anti-social behaviour'),aes(x=month,y=freq, group=crime.type, color=crime.type))+geom_line()+ xlab("Month in 2016") + ylab("Number of crimes")

