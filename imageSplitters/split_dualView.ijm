// Get files to process
parentDir = getDirectory("Choose a Directory containing Folders of experiments or a single experiment Folder.");
dirList = getFileList(parentDir);
setBatchMode(true);

for (a=0; a<dirList.length; a++) { // Loop over experiment folders
	if (File.isDirectory(parentDir + dirList[a]) ) { 
		currentDir = parentDir + dirList[a];
		fileList = getFileList(currentDir);
		makeCompositeImages();
	} else {
		currentDir = parentDir;
		fileList = dirList;
		makeCompositeImages();
		break
	}
}

function makeCompositeImages() {
	
	// Make a file for new composite images
	targetDir = substring(currentDir,0,lengthOf(currentDir) - 1) + "_composite";
	if ( !File.exists(targetDir) ) {
		File.makeDirectory(targetDir)
	}
	
	// Loop over files in each folder
	for (b = 0; b<fileList.length; b++) {
		if ( endsWith(fileList[b],".ome.tif") ) {
	
		// Open and process images
		open(currentDir + "/" + fileList[b]);
	 	activeImg = getTitle();
		getDimensions(width,height,channels,slices,frames);

		// Crop 488 channel
		selectWindow(activeImg);
		makeRectangle(0,0,width/2,height);
		run("Duplicate...", "title=488 duplicate");
		c1str = "c1=488 ";
		
		// Crop 638 channel		
		selectWindow(activeImg);
		makeRectangle(width/2,0,width/2,height);
		run("Duplicate...", "title=638 duplicate");
		c2str = "c2=638 ";

		// Create composite image
		run("Merge Channels...", c1str + c2str + "create");

		// Save image
		suffixIndex = indexOf(fileList[b],"_MMStack");
		imgName = substring(fileList[b],0,suffixIndex) + "_" + b;
		saveAs("tiff", targetDir + "/" + imgName + ".tif");

		close("*");
	}
	}
}

