parentDir = getDirectory("Choose a Directory containing Folders of experiments or a single experiment Folder.");
dirList = getFileList(parentDir);
setBatchMode(true);

for (a=0; a<dirList.length; a++) { // Loop over experiment folders
	if (File.isDirectory(parentDir + dirList[a]) ) { 
		currentDir = parentDir + dirList[a];
		fileList = getFileList(currentDir);
		resliceImages();
	} else {
		currentDir = parentDir;
		fileList = dirList;
		resliceImages();
		break
	}
}

function resliceImages() {
	// Loop over files in each folder
	b = 0;
	while (b<fileList.length-1) {
		if ( endsWith(fileList[b],".ome.tif") & endsWith(fileList[b+1],".ome.tif") ) {
			// Open and process images
			open(currentDir + "/" + fileList[b]);
			img1 = getTitle();
			lastSlice = nSlices;

 			// If there is an odd number of images in current file...
 			if (lastSlice%2 != 0){
				lastSlice = d2s(lastSlice,0);

				// remove the last image and save cropped file
				run("Make Substack...", "delete slices=" + lastSlice);
  				selectWindow(img1);
				saveAs("tiff", currentDir + "/" + img1);

				// open the next file and add the last image from the previous file to the begining of this subsequent file
				open(currentDir + "/" + fileList[b+1]);
				img2 = getTitle();
				run("Concatenate...", "  image1=[Substack (" + lastSlice +")] image2=" + img2 + " image3=[-- None --]");
				saveAs("tiff", currentDir + "/" +img2);		
				close("*");
				b = b + 2;
  			}
 			else{
 				 b = b + 1;
  			}
		}
		else{
			b = b + 1;
		}
	}
		
}