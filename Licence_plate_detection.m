clc
close all;

%%
% Step 1) Read and Display Original Image

a = imread('I00057.jpg');                %a= Original Image
figure(1)
imshow(a)
title('Original Image')

%%
% Step 2) Convert Original to Grayscale Image

bw = rgb2gray(a);                   %bw=black and white image
figure(2)
imshow(bw)
title('Grayscale Image')

%%
% Step 3) Convert Grayscale to Negative Image

neg_img = imcomplement(bw);           %neg_img=negative image
figure(3)
imshow(neg_img)
title('Negative Image')
 
%%
% Step 4) Apply Bilateral Filter on Negative Image for Image Smoothening

patch = imcrop(neg_img,[170,35,25 25]);
figure(4)
imshow(patch)

patchVar = std2(patch)^2;
Dos = 2*patchVar;                          %Dos= Degree of softness
bf_img = imbilatfilt(neg_img,Dos);         %bf_img= bilateral filtered image
figure(5)
imshow(bf_img)
title('Bilateral Filtered Image')

%%
% Step 5) Apply Adaptive Thresholding on bilateral filtered Image for the purpose of Image Segmentation 

Thresh_img = adaptthresh(bf_img,0.6,'ForegroundPolarity','Dark','Statistic','Gaussian');      %Thres_img= threshold image which performs binarization and displays local threshold image
figure(7)
imshow(Thresh_img)
 
neg_bin_thres = imbinarize(bf_img,Thresh_img);        %Binarize image using local threshold
figure(8)
imshow(neg_bin_thres)
title('Image After Adaptive Thresholding')

%%
% Step 6) Clean Binarized Image by removing objects whose pixel is less than 100

clean_bin_img = bwareaopen(neg_bin_thres,100);
figure(9)
imshow(clean_bin_img)
title('Clean Binary Image')

%%
% Step 7) Apply MSER for text Detection on clean binarised image

[mserRegions, mserConnComp] = detectMSERFeatures(clean_bin_img,'RegionAreaRange',[100 3000],'ThresholdDelta',2);
figure(10)
imshow(clean_bin_img)
hold on
plot(mserRegions,'showPixelList',true,'showEllipses',false)
title('MSER detected Regions')
hold off

%%
% Step 8) Removal of non text regions
Measures = regionprops(mserConnComp,'BoundingBox','Eccentricity','Solidity','Extent','Euler','Image');
bb = vertcat(Measures.BoundingBox);
w = bb(:,4);
h = bb(:,3);
Aspect_Ratio = w./h;
Img_attributes = Aspect_Ratio' > 4; 
Img_attributes = Img_attributes | [Measures.Eccentricity] > .995 ;
Img_attributes = Img_attributes | [Measures.Solidity] < .3;
Img_attributes = Img_attributes | [Measures.Extent] < 0.1 | [Measures.Extent] > 0.9;
Img_attributes = Img_attributes | [Measures.EulerNumber] < -4;
Measures(Img_attributes) = [];
mserRegions(Img_attributes) = [];
figure(11)
imshow(clean_bin_img)
hold on
plot(mserRegions, 'showPixelList', true,'showEllipses',false)
title('After Removing Non-Text Regions Based On Geometric Properties')
hold off

%%
% Step 9) Construction of Bounding Boxes for text extraction

[label,num] = bwlabel(clean_bin_img);
bb_stats = regionprops(label,{'Area','BoundingBox'});
img_area = [bb_stats.Area];

characters = find((100<=img_area) & (img_area<=3000));
char_img = ismember(label,characters);
figure(12)
imshow(char_img)
title('Bounding Boxes on Characters')
for i=1:num
    hold on
    img_area = bb_stats(i).Area;
    if ((100<=img_area) && (img_area<=3000))
    rectangle('Position',[bb_stats(i).BoundingBox(1),bb_stats(i).BoundingBox(2),bb_stats(i).BoundingBox(3),bb_stats(i).BoundingBox(4)],'EdgeColor','r','LineWidth',2)
    end
end

%%
% Step 10) Resize Image obtained after removing non text regions
resize=imresize(char_img,2);
figure()
imshow(resize)

%%
% Step 11) Display Characters from License Plate using OCR on MATLAB Command Window

Output = ocr(resize,'TextLayout','Block');
Output.Text

%%
% Step 11) Message Box Icon Alert

text_speech = Output.Text;
text_screen = a;
Prompt = msgbox(sprintf('License Plate :: %s',text_speech),'ALERT','custom',text_screen);

%%
% Step 12) TEXT TO SPEECH Conversion

Voice = char(text_speech);
NET.addAssembly('System.Speech');
Speaker = System.Speech.Synthesis.SpeechSynthesizer;
Speaker.Volume = 100;
Speak(Speaker, Voice);
