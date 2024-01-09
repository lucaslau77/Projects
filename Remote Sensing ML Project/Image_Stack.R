library(raster)
library(sp)
library(sf)
library(stringr)
startTime = Sys.time()

# Working directory
setwd("C:\\Users\\LauLu\\Desktop\\Working Folder\\WoodyBiomass_SemiAuto_Classification")

# Export Path
ExportPath = (".\\Outputs\\1_Stacked_Images")

# Path to image folder
ImagePath = (".\\Input\\Pleiades")

# Path to polygon
segmentPath = (".\\Input\\Data\\LU_POLY_2010_revised.shp")
segments = st_read(segmentPath)

## get all images in subdirectory that end in FCIR.tif
FCIRlist = list.files(path = ImagePath, pattern = "_FCIR.tif$", recursive = TRUE)
## get all images in subdirectory that end in Colr.tif
ColRlist = list.files(path = ImagePath, pattern = "_Colr.tif$", recursive = TRUE)

# Projection
CRS = crs("+proj=aea +lat_0=40 +lon_0=-96 +lat_1=50 +lat_2=70 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs")

#loop through
for (i in FCIRlist) {
  # i = FCIRlist[2]
	LoopStart = Sys.time()
	FCIRimage= raster(paste(ImagePath, "/", i, sep = "")) #this gets just the first band, which is NIR
	FCIRimageProj = projectRaster(FCIRimage, crs = CRS)

	# Identify whether the values are NA or not
	FCIRimageNaM <- is.na(FCIRimageProj)
	
	# Find the columns and rows that are not completely filled by NAs
	colNotNA <- which(colSums(FCIRimageNaM) != nrow(FCIRimageProj))
	rowNotNA <- which(rowSums(FCIRimageNaM) != ncol(FCIRimageProj))
	
	# Find the extent of the new raster by using the first and last columns and rows that are not completely filled by NAs.
	FCIRExtent <- extent(FCIRimageProj, rowNotNA[1], rowNotNA[length(rowNotNA)],
	                        colNotNA[1], colNotNA[length(colNotNA)])
	
	# now get the colR file that matches
	# get matching to FCIR
	FCIRname = substring(i, 1, 25)
	test =grep(FCIRname, ColRlist)
	ColRlist[test]

	ColRimage = stack(paste(ImagePath, "/", ColRlist[test], sep = ""))
	ColRimageProj = projectRaster(ColRimage, crs = CRS)
	
	# for all that end in ColR files, match to FCIR files
	# stack together, delete duplicate bands
	stacked = stack(ColRimageProj, FCIRimageProj)
	names(stacked)<- c("Red", "Green", "Blue", "NIR")
	
	# Crop the new raster
	stackedClip <- crop(stacked, FCIRExtent)
	
	# Reclassify pixels with NA value to 0
	finalRaster <- reclassify(stackedClip, cbind(NA, 0))
	
	# Get the coordinate for the center of the raster
	raster_center_coord <- extent(c(mean(FCIRExtent[c(1,2)]), (mean(FCIRExtent[c(1,2)])+1),
	                                mean(FCIRExtent[c(3,4)]), (mean(FCIRExtent[c(3,4)])+1)))
	raster_center <- as(raster_center_coord, 'SpatialPolygons')
	crs(raster_center) <- CRS
	raster_center <- st_as_sf(raster_center)
	
	# Intersect center with segments and get the PLOTID
	seg_intersect <- st_intersection(st_make_valid(raster_center),st_make_valid(segments))
	PLOTID = seg_intersect$PLOTID
	
	## clip to polygon -- to be stacked with colR and saved with plot ID number in filename
	# image1crop = intersect(stacked, singlePoly)
	outName = paste("\\", PLOTID, "_Clipped_", FCIRname, sep = "")

	writeRaster(finalRaster, filename = outName, format = "GTiff")
	LoopEnd = Sys.time()
	Loop = LoopEnd - LoopStart
	print(paste(i, " = ", Loop))
	rm(FCIRimageProj)
	rm(ColRimageProj)
}

EndTime = Sys.time()

FullTime = EndTime - startTime
