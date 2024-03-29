// Get files to process
parentDir = getDirectory("Choose a Directory containing Folders of experiments or a single experiment Folder.");
dirList = getFileList(parentDir);

// Dialog box with options
Dialog.create("Options");
Dialog.addMessage("Which channels do you want to keep?");
Dialog.addCheckbox("375",true);
Dialog.addCheckbox("488",true);
Dialog.addCheckbox("561",true);
Dialog.addCheckbox("638",true);
Dialog.show();
keep375 = Dialog.getCheckbox();
keep488 = Dialog.getCheckbox();
keep561 = Dialog.getCheckbox();
keep638 = Dialog.getCheckbox();

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
	
	// Loop over files in each folder
	for (b = 0; b<fileList.length; b++) {
		if ( endsWith(fileList[b],".ome.tif") ) {
	
		// Make a file for new composite images
		targetDir = substring(currentDir,0,lengthOf(currentDir) - 1) + "_composite";
		if ( !File.exists(targetDir) ) {
			File.makeDirectory(targetDir)
		}

		// Open and process images
		open(currentDir + "/" + fileList[b]);
		activeImg = getTitle();
		getDimensions(width,height,channels,slices,frames);

		if (keep375) {
			makeRectangle(0,0,width/2,height/2);
			run("Duplicate...", "title=375 duplicate");
			c1str = "c1=375 ";
		} else {
			c1str = "";
		}

		if (keep488) {
			selectWindow(activeImg);
			makeRectangle(0,height/2,width/2,height/2);
			run("Duplicate...", "title=488 duplicate");
			c2str = "c2=488 ";
		} else {
			c2str = "";
		}	

		if (keep561) {
			selectWindow(activeImg);
			makeRectangle(width/2,0,width/2,height/2);
			run("Duplicate...", "title=561 duplicate");
			c3str = "c3=561 ";
		} else {
			c3str = "";
		}

		if (keep638) {
			selectWindow(activeImg);
			makeRectangle(width/2,height/2,width/2,height/2);
			run("Duplicate...", "title=638 duplicate");
			c4str = "c4=638 ";
		} else { 
			c4str = "";
		}
				
		// Make composite
		run("Merge Channels...", c1str + c2str + c3str + c4str + "create");

		// Save new image
		suffixIndex = indexOf(fileList[b],"_MMStack");
		imgName = substring(fileList[b],0,suffixIndex) + "_" + b;				
		saveAs("tiff", targetDir + "/" + imgName + ".tif");
		close("*");
		showProgress(a*dirList.length+b, dirList.length * fileList.length);
		}
	}
}
