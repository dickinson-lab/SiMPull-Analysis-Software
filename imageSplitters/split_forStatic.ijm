// Get files to process
parentDir = getDirectory("Choose a Directory containing Folders of experiments");
dirList = getFileList(parentDir);

//setBatchMode(true);
// Loop over files in each folder
for (a=0; a<dirList.length; a++) {  

	if ( File.isDirectory(parentDir + dirList[a]) ) { 
	currentDir = parentDir + dirList[a];
	fileList = getFileList(currentDir);

	
	for (b = 0; b<fileList.length; b++) { // Loop over files in each folder
	
		// Make a file to save dual view images
		targetDir = substring(currentDir,0,lengthOf(currentDir)-1) +"_dualView";
		if ( !File.exists(targetDir) ) {
			File.makeDirectory(targetDir)
		}

		// Open and process images
		open(currentDir + "/" + fileList[b]);
	 	activeImg = getTitle();
		getDimensions(width,height,channels,slices,frames);
		
		// Crop 488 channel
		makeRectangle(0,height/2,width/2,height/2);
		run("Duplicate...", "title=488 duplicate");
		
		// Crop 561 channel 
		selectWindow(activeImg);
		makeRectangle(width/2,0,width/2,height/2);
		run("Duplicate...", "title=561 duplicate");

		// Combine images side by side and save as dual view
		run("Combine...", "stack1=488 stack2=561");
		saveAs("tiff", targetDir + "/" + fileList[b] + "_dual");

		close("*");
		}
	}
}

