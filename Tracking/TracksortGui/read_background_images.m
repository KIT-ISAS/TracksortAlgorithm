function [background_images,imageInfos] = read_background_images(imagePath)
dirContent=dir(fullfile(imagePath,'*.bmp'));
if length(dirContent)<2
    dirContent=dir(fullfile(imagePath,'*.BMP'));
end
if length(dirContent)<2
    dirContent=dir(fullfile(imagePath,'*.jpg'));
end
if length(dirContent)<2
    dirContent=dir(fullfile(imagePath,'*.png'));
end
if length(dirContent)<2
    errordlg('Background images must have one of the following formats: bmp, jpg or png ');
    return
end
imageInfos=imfinfo(fullfile(imagePath,dirContent(1).name));
background_images = sort_nat({(dirContent.name)});

end

