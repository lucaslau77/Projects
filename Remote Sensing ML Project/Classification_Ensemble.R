#import all required libraries
library(sf)
library(sp)
library(raster)
library(spatialEco)
library(maptools)
library(randomForest)
library(rgdal)
library(caret)
library(caretEnsemble)
library(stringr)
library(rgeos)
library(dplyr)

#######################################################################################################################################
#1) set up paths to required data
setwd("C:/Users/LauLu/Desktop/Working Folder/WoodyBiomass_SemiAuto_Classification")

segmentPath = ("./Outputs/2_eCognition_Segments")

trainingPath = ("./Outputs/3_Training_Data")

#2) set up parameters for classification
Selection = c(1:22)   #here i am setting up a subset of the columns- change as required.
#make sure to only include "valid layers" (e.g. not ClassID etc)
Train.Selection = c(1:23)
perc = 0.75		#percentage of points used in training (vs testing)
set.seed(100)

#######################################################################################################################################
#3) cycle through each of the segmented polygons (from imagery) and training data
list.of.training = list.files(path = trainingPath, pattern = "*.shp$")
list.of.segmentedImages = list.files(path = segmentPath,  pattern = "*.shp$")

training = NULL
testing = NULL

#4) Split training data to 75% training, 25% testing. Combine data.
for (i in list.of.training) {
  # i=list.of.training[5]
  
  trainPolys = shapefile(paste(trainingPath, "/", i, sep = ""))
  
  trainPolys_NotNull = sp.na.omit(trainPolys) #null segments are one where no training data intersects, so we remove those.
  
  # Split to 75% training, 25% testing
  smp_size75 = floor(perc * nrow((trainPolys_NotNull)))
  train_ind = sample(seq_len(nrow(trainPolys_NotNull)), size = smp_size75)
  
  training <- rbind(training, data.frame(trainPolys_NotNull[train_ind,][,Train.Selection]))
  # training_bc <- undersample_ds(training, "Training", nsamples_class)
  testing <- rbind(testing, data.frame(trainPolys_NotNull[-train_ind,][,Train.Selection]))
}

# Create function to balance data sets (If required)
# nsamples_class <- 10
# undersample_ds <- function(x, classCol, nsamples_class){
#   for (i in 1:length(unique(x[, classCol]))){
#     class.i <- unique(x[, classCol])[i]
#     if((sum(x[, classCol] == class.i) - nsamples_class) != 0){
#       x <- x[-sample(which(x[, classCol] == class.i), 
#                      sum(x[, classCol] == class.i) - nsamples_class), ]
#     }
#   }
#   return(x)
# }

#5) Create and compare ML models
# Create random forest model
mod.rf <- train(Training~., data=training, method = "rf")
pred.rf <- as.factor(predict(mod.rf, testing))

# Create SVM model
mod.svm <- train(Training~., data=training, method = "svmRadial")
pred.svm <- as.factor(predict(mod.svm, testing))

# Combine models
predDF <- data.frame(pred.rf, pred.svm, Training = testing$Training)
# predDF_bc <- undersample_ds(predDF, "class", nsamples_class)

combModFit.gbm <- train(Training~., data=predDF, method = "gbm")
combPred.gbm <- predict(combModFit.gbm, predDF)

# Calculate model correlation
results <- resamples(list(rf = mod.rf, svm = mod.svm))
modelCor(results)

# Accuracy results
print(c(confusionMatrix(pred.rf, as.factor(testing$Training))$overall[1],
        confusionMatrix(pred.svm, as.factor(testing$Training))$overall[1],
        confusionMatrix(combPred.gbm, as.factor(testing$Training))$overall[1]))

for (k in list.of.segmentedImages) {
  # k=list.of.segmentedImages[3]
  
  segPolys = shapefile(paste(segmentPath, "/", k, sep = ""))
  
	All_Predictor_Data = data.frame(segPolys[,Selection])
	colnames(All_Predictor_Data) <- names(training[,Selection])

	for(j in 1:ncol(All_Predictor_Data )){
 	 	All_Predictor_Data [is.na(All_Predictor_Data [,j]), j] = mean(All_Predictor_Data [,j], na.rm = TRUE)
	}
  
	All_Predictor_Data[is.na(All_Predictor_Data)] <- 0
	All_Predictor_Data[All_Predictor_Data == "Inf"] <- 0
	
	pred.rf = as.factor(predict(mod.rf, All_Predictor_Data))
	pred.svm = as.factor(predict(mod.svm, All_Predictor_Data))
	
	predDF <- data.frame(pred.rf, pred.svm)
	
	predicted = predict(combModFit.gbm, predDF)
	
	outColNames=c(names(All_Predictor_Data), "Predicted")
	output = cbind(segPolys, All_Predictor_Data[20:22], predicted)
	names(output)=outColNames
	
	for (n in 1:nrow(output)) {
	  if ((sum(All_Predictor_Data[n,][,11:14])) == 0)
	    {output$Predicted[n] = "NA"}
	}
	
	# Merge polygons with same class
	output_merged <- unionSpatialPolygons(output, predicted)
	
	# Convert output to data frame and aggregate data attributes.
	output.df <- as(output, "data.frame")
	output.agg <- aggregate(output.df$Area_exclu, list(predicted), sum)
	row.names(output.agg) <- as.character(output.agg$Group.1)
	
	# Change column names
	colnames(output.agg) <- c("predicted", "area")
	
	# Combine output_merged with aggregated attributes
	output_merged_shp <- SpatialPolygonsDataFrame(output_merged, output.agg)
	
	# Convert to sf
	output_sf <- st_as_sf(output_merged_shp)
	
	# Separate polygons
	output_cast <- st_cast(output_sf, "POLYGON")
	
	# Calculate polygon area and change factor column to character
	output_cast$area = as.integer(st_area(output_cast))
	output_cast <- output_cast %>% mutate_if(is.factor, as.character)
	
	# If polygon is tree and area > 1 hector, become forest
	for (h in 1:nrow(output_cast)) {
	  if ((output_cast$area[h] > 10000)&(output_cast$predicted[h] == "Tree")) {
	    output_cast$predicted[h] = as.character("Forest")
	  }
	}
	
	# Convert sf back to spatial polygon
	output_final <- as(output_cast, 'Spatial')
	
	outFile = paste("NDVI_Test_eCognition_", sub(".shp", "", k), sep = "")

	writeOGR(output_final, "./Outputs/4_Classification_Predicted_Results", outFile, driver="ESRI Shapefile")
	}
