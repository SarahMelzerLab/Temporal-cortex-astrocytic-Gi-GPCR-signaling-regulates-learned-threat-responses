%Created by Sarah 20221012. Opens a 640x512 pixel video of any length with
%buttons for forward, backward, jump to specific frame, save number of
%selected frames to mat file in folder of video
clear all


box = input('Enter in which box the animal was placed . Type r for the right box. Type l for the left box. ','s');
    if box== 'l'
        dimX=22.7;%x dimension in cm
        dimY=29.7;%y dimension in cm
    elseif box== 'r' 
        dimX=23;%x dimension in cm
        dimY=30;%y dimension in cm
    end
    
soundduration=30;%[sec]
Noshocks=15;
inverted=0;
shocklength=1; %change to 2 sec based on the fear conditioning test (duration of the shock)

version='20221229';

close all
global i
global m
global hFig
global a
global c
global xdata
global ydata
global framelist
global filename
global frame
global threshold

thresholdfreezing=0.1;
framerate=30;
freezetime=60;%[no of frames that the mouse needs to freeze, usually 60 frames for 2 min]
stepsize=0.1;
framelist=[];
[filename,directory]=uigetfile('.avi');%select video to be analyzed
cd(directory)

vid1=VideoReader(filename);
m=vid1.NumberOfFrames;
i=double(1);

behavior=input('type 1 if you want to analyze freezing; type 0 if you want to analyze only photometry')

%% show video to define beginning and end
        % Create new figure
        hFig = figure('position',[100 178 960 768],...
               'HandleVisibility','callback'); % hide the handle to prevent unintended modifications of our custom UI
        
%         Create panel for figure
        hPanel = uipanel('parent',hFig,'Position',[0.02 0.18 0.8 0.8],'Units','Normalized');%define how much of figure should be covered with video

%         Create axis for figure
        hAxis = axes('position',[0 0 1 1],'Parent',hPanel);%1 for whole image, 2 for half of it
        hAxis.XTick = [];
        hAxis.YTick = [];
        hAxis.XColor = [1 1 1];
        hAxis.YColor = [1 1 1];
        
% Play buttons with text Start/Pause/Continue, forward, backward
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Play at normal speed',...
                'position',[315 10 150 25], 'tag','PBButton123','callback',...
                {@playCallback,vid1,hAxis});
        
       uicontrol(hFig,'unit','pixel','style','pushbutton','string','1 frame forward',...
                'position',[10 10 100 25],'callback',...
                {@forwardCallback,vid1,hAxis});        
            
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','1 frame backward',...
                'position',[115 10 100 25],'callback',...
                {@backwardCallback,vid1,hAxis});

        uicontrol(hFig,'unit','pixel','style','text','string','Determine first and last frame in light',...
                'position',[200 730 400 20],'BackgroundColor',[1 1 1]);

  % Exit button with text Exit
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                'BackgroundColor',[1 0.2 0.2],'position',[830 10 50 25],'callback', ...
                {@exitCallback,vid1,hFig});
            
  %Text field and button to type frame number and jump to frame number
         a=uicontrol(hFig,'unit','pixel','style','edit',...
                'position',[830 250 100 25]);
         uicontrol(hFig,'unit','pixel','style','pushbutton','string','Jump To Frame',...
                'position',[830 220 100 25],'callback', ...
                {@FrameCallback,vid1,hAxis});
            
   %slider for fast forward and backward      
         c = uicontrol(hFig,'Style','slider','SliderStep',[0.0001 0.1],...
             'BackgroundColor',[0.7 1 0.7],'Position',[10 50 800 20],'callback', ...
                {@SliderCallback,vid1,hAxis});
         c.Value = 1/m;
         
   %field with frame number and button to save frame number     
         uicontrol(hFig,'unit','pixel','style','text','string',i,...
                'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
         uicontrol(hFig,'unit','pixel','style','pushbutton','string','Save 1st light frame',...
             'position',[830 370 120 25],'callback', ...
                {@FrameGrabCallback1,vid1,hAxis});
          uicontrol(hFig,'unit','pixel','style','pushbutton','string','Save last light frame',...
             'position',[830 340 120 25],'callback', ...
                {@FrameGrabCallback2,vid1,hAxis});
          uicontrol(hFig,'unit','pixel','style','pushbutton','string','Estimate 1st frame',...
             'position',[830 300 120 25],'callback', ...
                {@FrameGrabCallback3,vid1,hAxis});

         %add title     
         uicontrol(hFig,'unit','pixel','style','text','string','Move slider for fast forward and backward; arrows to jump 10-11 frames',...
                'position',[10 75 400 20],'BackgroundColor',[1 1 1]);
             
            
% Initialize the display with the first frame of the video
 frame = read(vid1,i);
 [xdata,ydata]=size(frame);
 
 % Display input video frame on axis
image(xdata,ydata,frame,'Parent', hAxis);

%% set start/end, initialize video
waitfor(hFig);
trackingstart=framelist(1);
endvideo=framelist(end);
lengthtracking=endvideo-trackingstart+1;
frame = read(vid1, trackingstart);
[m,n]=size(frame(:,:,1));

%% Opens thresholded image to adjust brightness
close all
frame = read(vid1, trackingstart);
frame1=imcomplement(frame);%
thresholdcutoff=292000;
thresholdlist=sort(reshape(im2double(frame(:,:,1)),[1,m*n])); 
thresholdstart=0.5;


i=double(1);

        % Create new figure
        hFig = figure('position',[100 178 960 768],...
               'HandleVisibility','callback'); % hide the handle to prevent unintended modifications of our custom UI

%         Create panel for figure
        hPanel = uipanel('parent',hFig,'Position',[0.02 0.18 0.8 0.8],'Units','Normalized');%define how much of figure should be covered with video

%         Create axis for figure
        hAxis = axes('position',[0 0 1 1],'Parent',hPanel);%1 for whole image, 2 for half of it
        hAxis.XTick = [];
        hAxis.YTick = [];
        hAxis.XColor = [1 1 1];
        hAxis.YColor = [1 1 1];
        
% Play buttons with text Start/Pause/Continue, forward, backward
       
  % Exit button with text Exit
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                'BackgroundColor',[1 0.2 0.2],'position',[830 10 50 25],'callback', ...
                {@exitCallback,vid1,hFig});
            
            
   %slider for fast forward and backward      
         c = uicontrol(hFig,'Style','slider','SliderStep',[0.0001 0.1],...
             'BackgroundColor',[0.7 1 0.7],'Position',[10 50 850 20],'string','adjust threshold','callback', ...
                {@SliderCallback2,vid1,hAxis});
         c.Value = thresholdstart;
         
    %add title     
         uicontrol(hFig,'unit','pixel','style','text','string','Move slider to adjust threshold',...
                'position',[200 730 400 20],'BackgroundColor',[1 1 1]);

% Initialize the display with the first frame to be tracked of the video
  %frame = read(vid1, trackingstart);
   frameth=uint8(im2bw(frame1,0.5)*255);
 [xdata,ydata]=size(frame);
 image(xdata,ydata,frameth,'Parent', hAxis);

%% calibrate box
waitfor(hFig);
% frame = read(vid1, trackingstart);
% image(frame);
% title('mark borders of floor and click create mask');hold on
% object1=roipoly(frame);
% objectloc1=find(object1);
% [y,x]=ind2sub([512,640],objectloc1);
% location(1)=mean(x);
% location(2)=mean(y);
% plot(location(1),location(2),'.r')
% dim=zeros(1,length(x));
% for i=1:length(x)
%     dim(i)=sqrt(((x(i)-location(1))^2)+((y(i)-location(2))^2));%list of area distances from centre
% end
% centerx=location(1);
% centery=location(2);
% [~,cornerloc]=max(dim);%find most distal part of tracked body
% dim=zeros(1,length(x));
% for i=1:length(x)
%     dim(i)=sqrt(((x(i)-x(cornerloc))^2)+((y(i)-y(cornerloc))^2));%
% end
% [~,cornerloc2]=max(dim);%find most distant 2 area
% plot(x(cornerloc),y(cornerloc),'.r')
% plot(x(cornerloc2),y(cornerloc2),'.r')
% diagonal=sqrt(((x(cornerloc)-x(cornerloc2))^2)+((y(cornerloc)-y(cornerloc2))^2));
% cornerlocx=min(x(cornerloc),x(cornerloc2));
% cornerlocy=min(y(cornerloc),y(cornerloc2));
% %pause(0.5)
% calibratespace=diagonal/(sqrt((dimX^2)+(dimY^2)));
if box=='l'
    calibratespace=14.7064; %this corresponds to the pixels per cm
end

if box=='r'
    calibratespace= 14.6521;
end

 %% initiate data matrices for tracking
global threshold
frame = read(vid1, trackingstart);
frame1=imcomplement(frame);
frameth=im2bw(frame1,threshold);
biggestold = bwareafilt(frameth,[30,20000]);
[m,n]=size(frame(:,:,1));
[y,x]=ind2sub([m,n],find(biggestold));
location=[mean(x),mean(y)];
bodypixelchange=zeros(1,lengthtracking);
centroid=zeros(lengthtracking,2);
stretchedatend=zeros(lengthtracking,1);
stretchedopposite=zeros(lengthtracking,1);

%% Start tracking
%the video is thresholded (black and white), it looks for the biggest blob, which is
%the mouse, excluding the poo of the mouse, and uses the center of the
%biggest blob to track.
%searches for mouse only in the area that that I defined and in the frames that I defined in the first figure (the first GUI).
%It calculates the movement of the animal in pixels: calculates how many pixels change from one frame
%to another (only taking into account the biggest blob that is the mouse).
wrongframes=[];
for iFrame = trackingstart:endvideo
    frame2 = read(vid1, iFrame);
    frame1=imcomplement(frame2);%-imcomplement(intensitysumobject);
     frame=uint8(im2bw(frame1,threshold)*255);frame=imfill(frame,'holes');

     biggest = bwareafilt(im2bw(frame,0.5),[500,20000]);
     if isempty(find(biggest))
         bodypixelchange(iFrame-trackingstart+1)=0;
         stretchedopposite(iFrame-trackingstart+1)=0;
         wrongframes=[wrongframes,iFrame];
         iFrame
     else
         [y,x]=ind2sub([m,n],find(biggest));
         location=[mean(x),mean(y)]; %location corresponds to centroid of mouse
         
         framebw=imabsdiff(biggest(:,:,1),biggestold(:,:,1));% calculates absolute differences of thresholded image
         bodypixelchange(iFrame-trackingstart+1)=sum(sum(framebw));%calculates how many pixels are different from one frame to the next
         biggestold=biggest;
         stretched=zeros(1,length(x));
         for i=1:length(x)
             stretched(i)=sqrt(((x(i)-location(1))^2)+((y(i)-location(2))^2));%list of all bodypixels'distances from centroid
         end
         [stretchedatend(iFrame-trackingstart+1),stretchedloc]=max(stretched);%find most distal part of tracked body
         % roisize(i)=sum(sum(biggest));
         stretched=zeros(1,length(x));
         for i=1:length(x)
             stretched(i)=sqrt(((x(i)-x(stretchedloc))^2)+((y(i)-y(stretchedloc))^2));%list of all bodypixels'distances from most distal part of tracked body
         end
         [stretchedopposite(iFrame-trackingstart+1),stretchedoppositeloc]=max(stretched);%find most distant 2 body points
     end
     
     centroid(iFrame-trackingstart+1,:)=location;
     %define body longitudinal axis
    
     
     if mod(iFrame,500)==0 %it shows the thresholded image with the centroid as a red dot every 500 frames
         close all
         imshow(frame);hold on;
         if isempty(find(biggest))==0
             plot(x,y,'r.');plot(location(1),location(2),'b.');title('')
             plot([x(stretchedloc),x(stretchedoppositeloc)],[y(stretchedloc),y(stretchedoppositeloc)],'y');
         end
         pause(0.2)
         iFrame
     end
    %
end
bodylength=stretchedopposite;
%stretchedopposite=bodylength-stretchedatend;
distancetraveled=sqrt(((centroid(2:end,1)-centroid(1:length(centroid)-1,1)).^2)+((centroid(2:end,2)-centroid(1:length(centroid)-1,2)).^2));
distancetraveled=movmean(distancetraveled,2); %sliding approach that takes the average of 2 frames with window size of 1
close all; figure; plot(distancetraveled,'.');hold on; title('distance traveled in pixel per frame')
%% calibrate centroid
close all
centroidcalibrated=centroid/calibratespace;

%% calculate speed
speed=distancetraveled*30/calibratespace;%in cm per sec, multiplied by 30 because we have 30 frames/s

%% save figure and data
cd(directory)
filename=find(directory=='\');
if filename(end)==length(directory)
    filename=directory(filename(length(filename)-1)+1:length(directory)-1)
else    
filename=directory(filename(end)+1:end)
end
%filename=filename(1:(length(filename)-19));
save(strcat(filename,'_behavior'),'distancetraveled','bodypixelchange','shocklength','trackingstart','endvideo','centroid','speed','centroidcalibrated','calibratespace','version','box','lengthtracking');%,'intensitysum');

%% define freezing 'threshold
% plays chunks of videos to ask whether mouse is freezing or not;
% continuous until 15 chunks defined as non-freezing -->use as upper
% threshold (distancetraveled from one frame to next)
framediff=bodypixelchange/50;
framediffsmooth=framediff;
for i=2:length(framediff)-1
    z=sort(framediff(i-1:i+1));
    framediffsmooth(i)=mean([z(1),z(2)]);
end

if behavior==1
threshold=thresholdfreezing;
correct=1;
framediffthreshtested=framediffsmooth;
framediffthreshtested_b=framediffthreshtested;
figure('Position', [100 150 1000 700]) 
ypeak=[200:210,201:211,202:212,203:213,204:214];
ypeak=[ypeak,ypeak+5,ypeak+10,ypeak+15,ypeak+20,ypeak+25,ypeak+30];
xpeak=[300:310,300:310,300:310,300:310,300:310];
xpeak=[xpeak,xpeak,xpeak,xpeak,xpeak,xpeak,xpeak];

while correct==1%run while loop continuously until it gets broken because of 'break'
framediffthresholded=framediffthreshtested;%framediffthreshtested: all freezing timepoints will be 0; all identified movements will be 10000;
framediffthresholded(framediffthresholded<threshold)=0;
  
% find freezing behavior based on new threshold, make new freezing variable
freezing=[];
for i=1:length(framediffthresholded)-freezetime
    if framediffthresholded(i)==0
        if sum(framediffthresholded(i:i+(freezetime-1)))==0%freezing defined as movement below threshold for at least 2 sec
            freezing=[freezing;i];
            if framediffthresholded(i+freezetime)>0%freezing defined as movement below threshold for at least 2 sec
               freezing=[freezing;[(i+1):(i+(freezetime-1))]'];
            end
        end
    end
end

%if last data point in tracking list is freezing, check whether last 2sec bout is freezing.
if framediffthresholded(end)==0 
    if sum(framediffthresholded((length(framediffthresholded)-(freezetime-1)):end))==0
        freezing=[freezing;((length(framediffthresholded)-(freezetime-1)):length(framediffthresholded))'];
    end
end
if length(freezing)>0
ratinglist=[];
while length(ratinglist)<15
    [~,maxloc]=max(framediffthreshtested_b(freezing));%,'MinPeakHeight',lowerthreshold,'MinPeakDistance',60);
    maxloc=maxloc(1);
    freezing(maxloc)
    if framediffthreshtested_b(freezing(maxloc))==0
        threshold=threshold+stepsize;
        break
    end
    start=0;
    while freezing(maxloc)-freezing(maxloc-start)==start
        start=start+1;
        if maxloc-start<1;
            break
        end
        if start>10
            break
        end
    end
    start=start-1;
    terminate=0;
    while freezing(maxloc+terminate)-freezing(maxloc)==terminate%determin end of freezing bout
        terminate=terminate+1;%+1 to increase for next round 
        if maxloc+terminate>size(freezing)
            break
        end
        if terminate>10;
            break
        end
    end
    terminate=terminate-1;
    
    rating=3;
    while rating==3
        image(read(vid1,(freezing(maxloc-start)+trackingstart-1)));
        pause(0.5)
        for j=maxloc-start:maxloc+terminate
            image(read(vid1,(freezing(j)+trackingstart-1)));
            title(threshold);
            if j==maxloc
                hold on; plot(xpeak,ypeak,'.g')
            end
            pause(0.0333) 
        end
        image(read(vid1,(freezing(j)+trackingstart)));
        hold on; plot([200,300],[200,200],'-r')
        hold off
        rating=input('0=freeze; 1=move; 3=repeat; 4=RepeatPrevious step1')
        
        if rating==0
            framediffthreshtested(freezing(maxloc-start:maxloc+terminate))=0;%framediffthreshtested: all freezing timepoints will be 0; all identified movements will be 10000;
            framediffthreshtested_b(freezing(maxloc-start:maxloc+terminate))=0;%framediffthreshtested_b; all freezing timepoints will be 0; all identified movements will be 0;
            old=freezing(maxloc-start:maxloc+terminate);
            ratingold=rating;
        elseif rating==1
            framediffthreshtested(freezing(maxloc)-2:freezing(maxloc)+2)=10000;
            framediffthreshtested_b(freezing(maxloc)-2:freezing(maxloc)+2)=0;
            old=(freezing(maxloc)-2:freezing(maxloc)+2);
            ratingold=rating;
%         elseif rating==2
%             framediffthreshtested(freezing(maxloc-start:maxloc+terminate))=10000;
%             framediffthreshtested_b(freezing(maxloc-start:maxloc+terminate))=0;
        elseif rating==4
            framediffthreshtested(old)=framediffsmooth(old);
            framediffthreshtested_b(old)=framediffsmooth(old);
        elseif isempty(rating)==1
            rating=3;
        elseif rating==2
            rating=3;
        elseif rating>4
            rating=3;
        end
    end

    if rating==0
        threshold=threshold+stepsize;
        correct=1;
        break
    elseif rating==4
        if ratingold==0
            threshold=threshold-stepsize;
        elseif ratingold==1
        end
        correct=1;
        break
    end
    ratinglist=[ratinglist,rating];

 end
if length(ratinglist)==15
    disp('rating complete')
    break
end
else
    threshold=threshold+stepsize;
    correct=1;
end
end
upperthreshold=threshold;
lowerthreshold=upperthreshold;
end 

%% save intermediate behavior data
if behavior==1
    save(strcat(filename,'_behavior'),'filename','centroid','shocklength','bodypixelchange','distancetraveled','upperthreshold','lowerthreshold','trackingstart','endvideo','soundduration','framediffthreshtested','Noshocks','version','calibratespace','box');
else
    save(strcat(filename,'_behavior'),'filename','centroid','shocklength','bodypixelchange','distancetraveled','trackingstart','endvideo','soundduration','Noshocks','version','calibratespace','box');
end

%% go through all chunks below freezing threshold
% find values between lower and upper threshold and play videos to define as moving or freezing

if behavior==1
close all
plot(framediff)
hold on
plot(framediffsmooth)
freezingtrace=zeros(length(framediffthresholded),1);
freezingtrace(freezing)=1;
plot(freezingtrace*upperthreshold)

ypeak=[200:210,201:211,202:212,203:213,204:214];
ypeak=[ypeak,ypeak+5,ypeak+10,ypeak+15,ypeak+20,ypeak+25,ypeak+30];
xpeak=[300:310,300:310,300:310,300:310,300:310];
xpeak=[xpeak,xpeak,xpeak,xpeak,xpeak,xpeak,xpeak];
figure('Position', [100 150 1000 700]) 
framediffthresholded=framediffthreshtested;
framediffthresholded(framediffthresholded<upperthreshold)=0;
freezing=[];
for i=1:length(framediffthresholded)-freezetime
    if framediffthresholded(i)==0
        if sum(framediffthresholded(i:i+(freezetime-1)))==0%freezing defined as movement below threshold for at least 2 min
            freezing=[freezing;i];
            if sum(framediffthresholded((i+1):i+freezetime))==0%freezing defined as movement below threshold for at least 2 min
            else
                freezing=[freezing;((i+1):(i+(freezetime-1)))'];
            end
        end
    end
end
if framediffthresholded(end)==0
    if sum(framediffthresholded((length(framediffthresholded)-(freezetime-1)):end))==0
        freezing=[freezing;[(length(framediffthresholded)-(freezetime-1)):length(framediffthresholded)]'];
    end
end

ratinglist=zeros(1,15)+1;
framediffthreshtested_b=framediffthreshtested;

while sum(ratinglist(length(ratinglist)-14:end))>0
    if mod(length(ratinglist),100)==0;
        framediffthresholded=framediffthreshtested;
        framediffthresholded(framediffthresholded<lowerthreshold)=0;
        freezing=[];
        for i=1:length(framediffthresholded)-freezetime
            if framediffthresholded(i)==0
                if sum(framediffthresholded(i:i+(freezetime-1)))==0%freezing defined as movement below threshold for at least 2 min
                    freezing=[freezing;i];
                    if sum(framediffthresholded((i+1):i+freezetime))==0%freezing defined as movement below threshold for at least 2 min
                    else
                        freezing=[freezing;((i+1):(i+(freezetime-1)))'];
                    end
                end
            end
        end
        if framediffthresholded(end)==0
            if sum(framediffthresholded((length(framediffthresholded)-(freezetime-1)):end))==0
                freezing=[freezing;[(length(framediffthresholded)-(freezetime-1)):length(framediffthreshtested)]'];
            end
        end
    end
    [~,maxloc]=max(framediffthreshtested_b(freezing));%,'MinPeakHeight',lowerthreshold,'MinPeakDistance',60);
    maxloc=maxloc(1)
    lowerthreshold=framediffthreshtested_b(freezing(maxloc));
    if framediffthreshtested_b(freezing(maxloc))==0
        break
    end
       start=0;
    while freezing(maxloc)-freezing(maxloc-start)==start
        start=start+1;
        if maxloc-start<1;
            break
        end
        if start>10
            break
        end
    end
    start=start-1;
    terminate=0;
    while freezing(maxloc+terminate)-freezing(maxloc)==terminate%determin end of freezing bout
        terminate=terminate+1;%+1 to increase for next round 
        if maxloc+terminate>size(freezing)
            break
        end
        if terminate>10;
            break
        end
    end
    terminate=terminate-1;
    
    rating=3;
    while rating==3
        image(read(vid1,(freezing(maxloc-start)+trackingstart-1)));
        pause(0.5)
        for j=maxloc-start:maxloc+terminate
            image(read(vid1,(freezing(j)+trackingstart-1)));
            title(framediffthreshtested_b(freezing(maxloc)));
            if j==maxloc
                hold on; plot(xpeak,ypeak,'.g')
            end
            pause(0.05)                   
        end
        image(read(vid1,(freezing(j)+trackingstart)));
        hold on; plot([200,300],[200,200],'-r')
        

        rating=input('0=freeze; 1=move; 3=repeat; 4=RepeatPrevious step3')
        hold off
        if rating==0
            framediffthreshtested(freezing(maxloc-start:maxloc+terminate))=0;
            framediffthreshtested_b(freezing(maxloc-start:maxloc+terminate))=0;
            old=freezing(maxloc-start:maxloc+terminate);
            maxlocold=maxloc;
        startold=start;
        terminateold=terminate;
        elseif rating==1
            framediffthreshtested(freezing(maxloc)-2:freezing(maxloc)+2)=upperthreshold+1000;
            framediffthreshtested_b(freezing(maxloc)-2:freezing(maxloc)+2)=0;
            old=freezing(maxloc)-2:freezing(maxloc)+2;
            maxlocold=maxloc;
        startold=start;
        terminateold=terminate;
%         elseif rating==2
%             framediffthreshtested(freezing(maxloc-start:maxloc+terminate))=upperthreshold+1000;
%             framediffthreshtested_b(freezing(maxloc-start:maxloc+terminate))=0;
        elseif rating==4
            framediffthreshtested(old)=framediffsmooth(old);
            framediffthreshtested_b(old)=framediffsmooth(old);
            rating=3;
            ratinglist=ratinglist(1:length(ratinglist)-1);
            maxloc=maxlocold;
            start=startold;
            terminate=terminateold;
        elseif isempty(rating)==1;
            rating=3;
        end
        if rating==2;
            rating=3;
        end
        if rating>4;
            rating=3;
        end
    end
    ratinglist=[ratinglist,rating];
    
end
 
% end


%quantify freezing
framediffthresholded=framediffthreshtested;
framediffthresholded(framediffthresholded<lowerthreshold)=0;
%find freezing behavior
freezing=[];
for i=1:length(framediffthresholded)-freezetime
    if framediffthresholded(i)==0
        if sum(framediffthresholded(i:i+(freezetime-1)))==0%freezing defined as movement below threshold for at least 2 min
            freezing=[freezing;i];
            if sum(framediffthresholded((i+1):i+freezetime))==0%freezing defined as movement below threshold for at least 2 min
            else
                freezing=[freezing;((i+1):(i+(freezetime-1)))'];
            end
        end
    end
end

if framediffthresholded(end)==0
    if sum(framediffthresholded((length(framediffthresholded)-(freezetime-1)):end))==0
        freezing=[freezing;((length(framediffthresholded)-(freezetime-1)):length(framediffthresholded))'];
    end
end
freezingtrace=zeros(length(framediffthresholded),1);
freezingtrace(freezing)=1;
end

%% load photometry data 
close all
load('allData.mat')

%% correct light trace if necessary
%it should have only 1 "ON" period!!!
pause on
lightok=0;
while lightok==0;
close all
figure; plot(light)
axis([1,length(light),-0.1 1.1])
pause(1);
lightok=input('light ok?Press ENTER if ok!Press 0 if not!')
if lightok==0
    lightstart=input('what is the FIRST data point with light ON?')
    lightend=input('what is the LAST data point with light ON?')
    light(1:lightstart-1)=1;
    light(lightend+1:end)=1;
    light(lightstart:lightend)=0;
end
end

%% calibrate video and photometry
lengthtracking=endvideo-trackingstart+1;
calibrate=((max(find(light==0))-min(find(light==0))+1))/(lengthtracking+1);%calculates time from first time light is on to last time light is on and divides by number of frames with light on;
shocks=shock(min(find(light==0)):max(find(light==0)));
shocks=shocks(calibrate:calibrate:end);
shocks=find((shocks(2:end)-shocks(1:length(shocks)-1))==-1)+1;
shocks=[shocks;shocks+((shocklength*30)-1)];%matrix with 2 rows, first row is start, second row is end of each shock
Noshocks=length(shocks);

sound_paired=paired(min(find(light==0)):max(find(light==0)));
sound_paired=sound_paired(calibrate:calibrate:end);
sound_paired=find((sound_paired(2:end)-sound_paired(1:length(sound_paired)-1))==-1)+1;
sound_paired=[sound_paired;sound_paired+((soundduration*30)-1)];%matrix with 2 rows, first row is start, second row is end of each paired sound

sound_unpaired=unpaired(min(find(light==0)):max(find(light==0)));
sound_unpaired=sound_unpaired(calibrate:calibrate:end);
sound_unpaired=find((sound_unpaired(2:end)-sound_unpaired(1:length(sound_unpaired)-1))==-1)+1;
sound_unpaired=[sound_unpaired;sound_unpaired+((soundduration*30)-1)];%matrix with 2 rows, first row is start, second row is end of each unpaired sound

%% analyze freezing during baseline, sounds

conditioning=input('type 1 if this is the conditioning day, type anything else if this is the retrieval day')

if behavior==1
freezingbaseline=freezing;
if inverted==0;
    freezingbaseline(freezingbaseline>=sound_paired(1,1))=0;
    freezingbaseline=length(find(freezingbaseline))/((sound_paired(1,1)-1))*100;%percent time freezing
else
    freezingbaseline(freezingbaseline>=sound_unpaired(1,1))=0;
    freezingbaseline=length(find(freezingbaseline))/((sound_unpaired(1,1)-1))*100;%percent time freezing
end

%analyze freezing during paired sounds
freezingsoundlist=zeros(1,Noshocks);
for i=1:Noshocks
    freezingsound=freezing;
    if conditioning==1
        freezingsound(freezingsound<sound_paired(1,i))=0;freezingsound(freezingsound>sound_paired(2,i)-30)=0;
        freezingsoundlist(i)=length(find(freezingsound))/((soundduration-1)*30)*100;
    else
    freezingsound(freezingsound<sound_paired(1,i))=0;freezingsound(freezingsound>sound_paired(2,i))=0;
    freezingsoundlist(i)=length(find(freezingsound))/((soundduration)*30)*100;
    end
    
end

%analyze freezing 30s after shock/paired sound
freezingaftershocklist=zeros(1,Noshocks);
for i=1:Noshocks
    freezingshock=freezing;
    freezingshock(freezingshock<shocks(2,i)+1)=0;freezingshock(freezingshock>shocks(2,i)+900)=0;
    freezingaftershocklist(i)=length(find(freezingshock))/900*100;
end

%analyze freezing during unpaired sounds
freezingunpairedsoundlist=zeros(1,Noshocks);
for i=1:Noshocks
    freezingunpairedsound=freezing;
    freezingunpairedsound(freezingunpairedsound<sound_unpaired(1,i))=0;freezingunpairedsound(freezingunpairedsound>sound_unpaired(2,i))=0;
    freezingunpairedsoundlist(i)=length(find(freezingunpairedsound))/((soundduration)*30)*100;
end

%analyze freezing after unpaired sounds
freezingafterunpairedsoundlist=zeros(1,Noshocks);
for i=1:Noshocks
    freezingafterunpairedsound=freezing;
    freezingafterunpairedsound(freezingafterunpairedsound<(sound_unpaired(2,i)+1))=0;freezingafterunpairedsound(freezingafterunpairedsound>(sound_unpaired(2,i)+900))=0;
    freezingafterunpairedsoundlist(i)=(length(find(freezingafterunpairedsound))/900)*100;
end
end

%analyze MotionIndex during baseline
MotionIndexBaselineTimecourse=[sum(framediff(1:900)),sum(framediff(901:1800)),sum(framediff(1801:2700)),sum(framediff(2701:3600))]/900;

%analyze MotionIndex during baseline
MotionIndexBaseline=sum(framediff(1:3600))/3600;



%analyze MotionIndex during paired sounds
MotionIndexSound=zeros(1,Noshocks);
for i=1:Noshocks
    if conditioning==1
        MotionIndexSound(i)=sum(framediff(round(sound_paired(1,i)):round(sound_paired(2,i)-30)))/((soundduration*30)-30);
    else
        MotionIndexSound(i)=sum(framediff(round(sound_paired(1,i)):round(sound_paired(2,i))))/((soundduration*30));
    end
end

%analyze MotionIndex during unpaired sounds
MotionIndexSoundUP=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndexSoundUP(i)=sum(framediff(round(sound_unpaired(1,i)):round(sound_unpaired(2,i))))/((soundduration*30));
end

%analyze MotionIndex during shock
MotionIndexShock=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndexShock(i)=sum(framediff(round(shocks(1,i)):round(shocks(1,i)+29)))/30;
end

%analyze MotionIndex 30s before paired sound
MotionIndexBeforeSound=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndexBeforeSound(i)=sum(framediff(round(sound_paired(1,i))-900:(round(sound_paired(1,i))-1)))/900;
end

%analyze MotionIndex 30s before unpaired sound
MotionIndexBeforeSoundUP=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndexBeforeSoundUP(i)=sum(framediff(round(sound_paired(1,i))-900:(round(sound_paired(1,i))-1)))/900;
end

%analyze MotionIndex 1s before shock
MotionIndex1sBeforeShock=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndex1sBeforeShock(i)=sum(framediff(round((shocks(1,i))-30):(round(shocks(1,i))-1)))/30;
end
%analyze MotionIndex 1s after shock
MotionIndex1sAfterShock=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndex1sAfterShock(i)=sum(framediff((round(shocks(2,i))+1):(round(shocks(2,i))+30)))/30;
end
%analyze MotionIndex 2s after shock
MotionIndex2sAfterShock=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndex2sAfterShock(i)=sum(framediff((round(shocks(2,i))+31):(round(shocks(2,i))+60)))/30;
end
%analyze MotionIndex 3s after shock
MotionIndex3sAfterShock=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndex3sAfterShock(i)=sum(framediff((round(shocks(2,i))+61):(round(shocks(2,i))+90)))/30;
end
%analyze MotionIndex 4s after shock
MotionIndex4sAfterShock=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndex4sAfterShock(i)=sum(framediff((round(shocks(2,i))+91):(round(shocks(2,i))+120)))/30;
end
%analyze MotionIndex 4s after shock
MotionIndex5sAfterShock=zeros(1,Noshocks);
for i=1:Noshocks
    MotionIndex5sAfterShock(i)=sum(framediff((round(shocks(2,i))+121):(round(shocks(2,i))+150)))/30;
end

%plot trial averaged Motion Index for Shock
TA_MotionIndexShock=zeros(Noshocks,1801);
for i=1:Noshocks
    TA_MotionIndexShock(i,:)=framediff(round(shocks(1,i)-900):round(shocks(1,i)+900));
end
%plot trial averaged Motion Index paired sound
TA_MotionIndexPaired=zeros(Noshocks,2701);
for i=1:Noshocks
    TA_MotionIndexPaired(i,:)=framediff(round(sound_paired(1,i)-900):round(sound_paired(1,i)+1800));
end
%plot trial averaged Motion Index unpaired sound
TA_MotionIndexUnpaired=zeros(Noshocks,2701);
for i=1:Noshocks
    TA_MotionIndexUnpaired(i,:)=framediff(round(sound_unpaired(1,i)-900):round(sound_unpaired(1,i)+1800));
end

%plot trial averaged Motion Index for Shock, only first 5 stimuli
TA_MotionIndexShock5=zeros(5,1801);
for i=1:5
    TA_MotionIndexShock5(i,:)=framediff(round(shocks(1,i)-900):round(shocks(1,i)+900));
end
%plot trial averaged Motion Index paired sound, only first 5 stimuli
TA_MotionIndexPaired5=zeros(5,2701);
for i=1:5
    TA_MotionIndexPaired5(i,:)=framediff(round(sound_paired(1,i)-900):round(sound_paired(1,i)+1800));
end
%plot trial averaged Motion Index unpaired sound, only first 5 stimuli
TA_MotionIndexUnpaired5=zeros(5,2701);
for i=1:5
    TA_MotionIndexUnpaired5(i,:)=framediff(round(sound_unpaired(1,i)-900):round(sound_unpaired(1,i)+1800));
end


%% save behavior data
if behavior==1
    save(strcat(filename,'_behavior'),'filename','framerate','framediff','framediffsmooth','conditioning','centroid','shocklength','light','calibrate','bodypixelchange','framediffthresholded','freezingaftershocklist','freezing','freezingtrace','freezingshock','freezingsoundlist','freezingunpairedsoundlist','MotionIndexBaseline','MotionIndexBaselineTimecourse','MotionIndex1sBeforeShock','MotionIndexShock','MotionIndex1sAfterShock','lowerthreshold','calibrate','trackingstart','shocks','sound_paired','sound_unpaired','Noshocks','MotionIndexBeforeSound','MotionIndexSound','MotionIndex2sAfterShock','MotionIndex3sAfterShock','MotionIndex4sAfterShock','MotionIndex5sAfterShock','MotionIndexBeforeSoundUP','MotionIndexSoundUP','freezingbaseline','freezingaftershocklist','freezingafterunpairedsoundlist','TA_MotionIndexShock5','TA_MotionIndexPaired5','TA_MotionIndexUnpaired5','MotionIndexBeforeSound','upperthreshold','framediffthreshtested','centroidcalibrated','distancetraveled','speed','calibratespace','inverted','TA_MotionIndexShock','trackingstart','endvideo','soundduration','framediffthreshtested','Noshocks','version','calibratespace','box');
else
    save(strcat(filename,'_behavior'),'filename','framediff','framerate','framediffsmooth','conditioning','centroid','shocklength','light','calibrate','bodypixelchange','stretchedatend','calibrate','MotionIndexBaseline','MotionIndexBaselineTimecourse', 'MotionIndex1sBeforeShock','MotionIndexShock','MotionIndex1sAfterShock','trackingstart','shocks','sound_paired','sound_unpaired','Noshocks','MotionIndexBeforeSound','MotionIndexSound','MotionIndex2sAfterShock','MotionIndex3sAfterShock','MotionIndex4sAfterShock','MotionIndex5sAfterShock','TA_MotionIndexShock5','TA_MotionIndexPaired5', 'MotionIndexBeforeSound','TA_MotionIndexUnpaired5','centroidcalibrated','distancetraveled','speed','calibratespace','inverted','TA_MotionIndexShock','trackingstart','endvideo','soundduration','Noshocks','version','calibratespace','box');
end

%% Figure for behavior

if behavior==1
close all
figure('Position',[100,100,600,700]);

subplot(4,3,1:2,'XTick',18000:18000:length(speed),'XTickLabel',10:10:60);hold on;plot(speed(2:end),'-k')
plot(freezing,zeros(length(freezing),1)-2,'g.');
%plot(shocks,(zeros(2,Noshocks)-4),'r-','LineWidth',4)
plot(sound_paired,(zeros(2,Noshocks)-4),'Color',[0.7,0,0],'LineWidth',2)
plot(sound_unpaired,(zeros(2,Noshocks)-4),'k','LineWidth',2)
ylabel('speed [cm/sec]');xlabel('time [min]');axis tight
title('speed, freezing, sounds')

subplot(4,3,3);hold on
%plot(centroidcalibrated(:,1)-(cornerlocx/calibratespace),centroidcalibrated(:,2)-(cornerlocy/calibratespace),'.k')
plot(centroidcalibrated(:,1),centroidcalibrated(:,2),'.k')
axis('tight');xlabel('cm');ylabel('cm');title('centroid locations')

subplot(4,3,9,'XTick',[-900,1,901,1801],'XTickLabel',[-30,0,30,60]); hold on
title('Average Motion Index trial 1-5');
ylabel('Motion Index [AU]')
stdUnpaired=std(TA_MotionIndexUnpaired5)/sqrt(5);
plot(-900:1800,movmean(mean(TA_MotionIndexUnpaired5),30),'k','LineWidth',1)
plot(-900:1800,movmean(mean(TA_MotionIndexPaired5),30),'Color',[0.7,0,0],'LineWidth',1)
xlabel('[sec]')

%plot freezing scores over time
subplot(4,1,2);b=bar(0:Noshocks,[freezingbaseline,zeros(1,Noshocks);0,freezingsoundlist;0,freezingunpairedsoundlist;0,freezingaftershocklist;0,freezingafterunpairedsoundlist]');ylabel('time freezing [%]');
b(1).FaceColor=[0.7,0.7,0.7];b(1).EdgeColor=[0.7,0.7,0.7];
b(2).FaceColor=[0.7,0,0];b(2).EdgeColor=[0.7,0,0];
b(3).FaceColor=[0,0,0];b(3).EdgeColor=[0,0,0];
b(4).FaceColor=[0.2,0.2,0.5];b(4).EdgeColor=[0.2,0.2,0.5];
b(5).FaceColor=[0,0.7,0.7];b(5).EdgeColor=[0,0.7,0.7];
legend('baseline','CS','US','after CS (30s)','after US (30s)','Location','bestoutside'); 
ylabel('time freezing [%]');
ylim([0 100])
title('Freezing')
xlabel('trial No.')

%plot average Freezing
subplot(4,3,8);b=bar([[freezingbaseline;0],[mean(freezingsoundlist);0],[mean(freezingunpairedsoundlist);0],[mean(freezingaftershocklist);0],[mean(freezingafterunpairedsoundlist);0]]);
b(1).FaceColor=[0.7,0.7,0.7];b(1).EdgeColor=[0.7,0.7,0.7];
b(2).FaceColor=[0.7,0,0];b(2).EdgeColor=[0.7,0,0];
b(3).FaceColor=[0,0,0];b(3).EdgeColor=[0,0,0];
b(4).FaceColor=[0.2,0.2,0.5];b(4).EdgeColor=[0.2,0.2,0.5];
b(5).FaceColor=[0,0.7,0.7];b(5).EdgeColor=[0,0.7,0.7];
%legend('baseline','paired sound','unpaired sound','after shock/paired sound (30s)','after unpaired sound (30s)'); % add legend
axis([0.6 1.5 0 100])
title('Freezing trial 1-15')
xticks([])

%plot average Freezing for 1st 5 stimuli only
subplot(4,3,7);b=bar([[freezingbaseline;0],[mean(freezingsoundlist(1:5));0],[mean(freezingunpairedsoundlist(1:5));0],[mean(freezingaftershocklist(1:5));0],[mean(freezingafterunpairedsoundlist(1:5));0]]);
b(1).FaceColor=[0.7,0.7,0.7];b(1).EdgeColor=[0.7,0.7,0.7];
b(2).FaceColor=[0.7,0,0];b(2).EdgeColor=[0.7,0,0];
b(3).FaceColor=[0,0,0];b(3).EdgeColor=[0,0,0];
b(4).FaceColor=[0.2,0.2,0.5];b(4).EdgeColor=[0.2,0.2,0.5];
b(5).FaceColor=[0,0.7,0.7];b(5).EdgeColor=[0,0.7,0.7];
%legend('baseline','paired sound','unpaired sound','after shock/paired sound (30s)','after unpaired sound (30s)','Location','bestoutside'); % add legend
ylabel('time freezing [%]');
axis([0.6 1.5 0 100])
title('Freezing trial 1-5')
xticks([])

subplot(4,2,7,'XTick',[1:900:3000],'XTickLabel',[-30:30:90]);hold on
TAfreezing=zeros(15,2700);
for i=1:15
    TAfreezing(i,:)=freezingtrace(sound_paired(1,i)-900:sound_paired(1,i)+1799);
end
plot(mean(TAfreezing(1:5,:)),'r')
title('freezing prob trials 1-5'); axis tight
subplot(4,2,8,'XTick',[1:900:3000],'XTickLabel',[-30:30:90]);hold on
plot(mean(TAfreezing(11:15,:)),'r')

TAfreezing=zeros(15,2700);
for i=1:15
    TAfreezing(i,:)=freezingtrace(sound_unpaired(1,i)-900:sound_unpaired(1,i)+1799);
end
plot(mean(TAfreezing(11:15,:)),'k')    
title('freezing prob trials 11-15'); axis tight

subplot(4,2,7);hold on
plot(mean(TAfreezing(1:5,:)),'k')
axis tight

saveas(gcf,strcat(filename,'_behavior'),'png')

%Figure
xvector=-900:900;
xvector=[xvector;xvector;xvector;xvector;xvector];
figure; subplot(4,1,1); hold on
plot(xvector',TA_MotionIndexShock5','Color',[0.8 0.8 0.8]);hold on;
plot(-900:900,mean(TA_MotionIndexShock5),'k')
axis tight
title('trial averaged shock response first 5 stimuli');ylabel('Motion Index')
subplot(4,1,2); hold on
plot(TA_MotionIndexShock','Color',[0.8 0.8 0.8]);hold on;
plot(mean(TA_MotionIndexShock),'k')
axis tight
title('trial averaged shock response first 15 stimuli');ylabel('Motion Index')
xvector=(-900:1800);xvector=[xvector;xvector;xvector;xvector;xvector];
subplot(4,1,3); plot(xvector',TA_MotionIndexPaired5','Color',[0.8 0.8 0.8]);hold on;
plot(-900:1800,mean(TA_MotionIndexPaired5),'k')
title('trial averaged paired sound response first 5 stimuli');ylabel('Motion Index')
subplot(4,1,4); plot(xvector',TA_MotionIndexUnpaired5','Color',[0.8 0.8 0.8]);hold on;
plot(-900:1800,mean(TA_MotionIndexUnpaired5),'k')
title('trial averaged unpaired sound response first 5 stimuli');ylabel('Motion Index')

figure
b=bar([[MotionIndexBaseline;0],[MotionIndexSound(1);0],[MotionIndexSoundUP(1);0],[MotionIndexShock(1);0],[MotionIndex1sAfterShock(1);0],[MotionIndex2sAfterShock(1);0],[MotionIndex3sAfterShock(1);0],[MotionIndex4sAfterShock(1);0],[MotionIndex5sAfterShock(1);0]]);
b(1).FaceColor=[0.7,0.7,0.7];b(1).EdgeColor=[0.7,0.7,0.7];
b(2).FaceColor=[0.2,0,0.6];b(2).EdgeColor=[0.2,0,0.6];
b(3).FaceColor=[0.0,0.5,0.5];b(3).EdgeColor=[0.0,0.5,0.5];
b(4).FaceColor=[0.7,0,0];b(4).EdgeColor=[0.7,0,0];
b(5).FaceColor=[0.7,0,0];b(5).EdgeColor=[0.7,0,0];
b(6).FaceColor=[0.7,0,0];b(6).EdgeColor=[0.7,0,0];
b(7).FaceColor=[0.7,0,0];b(7).EdgeColor=[0.7,0,0];
b(8).FaceColor=[0.7,0,0];b(8).EdgeColor=[0.7,0,0];
b(9).FaceColor=[0.7,0,0];b(8).EdgeColor=[0.7,0,0];

input('images ok?')
close all
end

%% add photometry data?
photometry=input('Run photometry analysis? 1=YES; 0=NO')
if photometry==1
    GCaMP=input('type 1 if you are analyzing GCaMP')
end

if photometry==1
    pinkycamp=input('type 1 if you want to analyze the pinky camp (rawSig2')
end

%% define autofluorescence
if photometry==1
    if pinkycamp == 1
    figure; plot(rawSig2); hold on; title('check autofluorescence in green channel and type into command window')
    else
        figure; plot(rawSig1); hold on; title('check autofluorescence in green channel and type into command window')
    end
    pause(1);
    autofluorescence=input('check autofluorescence in green channel and type into command window')
end


%% calibrate photometry to video
if photometry==1
    calibrate=((max(find(light==0))-min(find(light==0))+1))/20/(length(distancetraveled)+1);%calculates time from first time light is on to last time light is on and divides by number of frames with light on;
end

%% downsample rawSig1 to match framerate
if photometry==1
    Sig1calibrated=[];
    if pinkycamp==1
    for i=min(find(light==0))/20:calibrate:max(find(light==0))/20
        Sig1calibrated=[Sig1calibrated,mean(rawSig2(round(i):round(i+calibrate)))];
        Sig3calibrated=[];
    end
    else
    for i=min(find(light==0))/20:calibrate:max(find(light==0))/20 %divide by 20 since rawSig1 is downsampled 20x compared to light
        Sig1calibrated=[Sig1calibrated,mean(rawSig1(round(i):round(i+calibrate)))];
         Sig3calibrated=[];
    end
    end
    if GCaMP==1
    for i=min(find(light==0))/20:calibrate:max(find(light==0))/20
        Sig3calibrated=[Sig3calibrated,mean(rawSig3(round(i):round(i+calibrate)))];
    end
    end
      
end

%% calculate exponential fit to correct for bleaching
if photometry==1
    time=zeros(1,length(10:2000:length(Sig1calibrated)-4999));
    for i=1:length(time)
        [~,b]=min(Sig1calibrated(((i*2000)-2000+10):((i*2000)+9)));
        b=b+((i*2000)-2000+10)-1;
        time(i)=b;
    end
     if GCaMP==1
        meanSig1calibrated=[];
        for i=1:length(Sig1calibrated)-1999
            meanSig1calibrated=[meanSig1calibrated,min(Sig1calibrated(round(i):round(i+1999)))];
        end
    else
    meanSig1calibrated=movmean(Sig1calibrated,2000);%smoothen even more to improve the exponential fit
    end
    filtSig1fit = fit(time',(meanSig1calibrated(time)-autofluorescence)','exp1'); 
    figure('Position',[400 400 1200 600]);subplot(1,2,1);plot(Sig1calibrated-autofluorescence);hold on;plot(filtSig1fit(1:length(Sig1calibrated)));title('exp1')
    filtSig1fit2 = fit(time',(meanSig1calibrated(time)-autofluorescence)','exp2'); 
    subplot(1,2,2);plot(Sig1calibrated-autofluorescence);hold on;plot(filtSig1fit2(1:length(Sig1calibrated)));title('exp2')
    pause(1);
    fitok=input('Select better fit!!! Hit 1 for left, 2 for right, or Ctrl+C to terminate script')
    
    if fitok==2
        filtSig1fit=filtSig1fit2;
    end


    filtSig1fitted=Sig1calibrated-autofluorescence;
    for i=1:2000:length(Sig1calibrated)-1999
        filtSig1fitted(i:i+1999)=filtSig1fitted(i:i+1999)./filtSig1fit(i:i+1999)';
    end
    filtSig1fitted(i+2000:end)=filtSig1fitted(i+2000:end)./filtSig1fit(i+2000:length(filtSig1fitted))';
     Sig1=(filtSig1fitted*filtSig1fit(1));%Sig1 is rawSig1 downsampled to framerate and corrected for bleaching
end

%% calculate delta F/F and a normalized trace for color encoding 
if photometry==1
    DeltaFF=Sig1-mean(Sig1(1:3600));%calculates deltaF, uses mean of first 2 min as baseline (30*60*2 frames=3600)
    DeltaFF=DeltaFF/mean(Sig1(1:3600))*100; %calculate delta F/F as percentage, normalized to minimum fluorescence in Sig1calibrated. might need to use mean of baseline instead.
    C=DeltaFF-min(DeltaFF); C=C/max(C);%C=photometry trace going from 0 to 1 for automatic color coding in figures below
    DeltaFF3=[]; 
    if GCaMP==1 %to calculate mBeRFP
    DeltaFF3=Sig3calibrated-mean(Sig3calibrated(1:3600));%calculates deltaF, uses mean of first 2 min as baseline (30*60*2 frames=3600)
    DeltaFF3=DeltaFF3/mean(Sig3calibrated(1:3600))*100; %calculate delta F/F as percentage, normalized to minimum fluorescence in Sig1calibrated. might need to use mean of baseline instead.
    %C=DeltaFF3-min(DeltaFF3); C=C/max(C);%C=photometry trace going from 0 to 1 for automatic color coding in figures below
     end
end

%% analyze fluorescence at beginning of freezing
if behavior==1 
    if photometry==1
         freezingstart=find((freezingtrace(2:end)-freezingtrace(1:length(freezingtrace)-1))==1)+1; %finds end of low movement periods (defined as movement of <0.3 for at least 1 sec)
         freezingstart(freezingstart>length(freezingtrace)-180)=[];
         TAfreezingstart=zeros(length(freezingstart),360);
         for i=1:length(freezingstart)
             TAfreezingstart(i,:)=DeltaFF(freezingstart(i)-180:freezingstart(i)+179);
         end
     end
end

%% analyze fluorescence at end of freezing
 if behavior==1
     if photometry==1
       freezingend=find((freezingtrace(2:end)-freezingtrace(1:length(freezingtrace)-1))==-1); %finds end of low movement periods (defined as movement of <0.3 for at least 1 sec)
       freezingend(freezingend>length(freezingtrace)-180)=[];
       TAfreezingend=zeros(length(freezingend),360);
       for i=1:length(freezingend)
           TAfreezingend(i,:)=DeltaFF(freezingend(i)-180:freezingend(i)+179);
       end
     end
 end

%% analyze fluorescence at start of paired sounds
 if photometry==1
   TAsound1start=zeros(length(sound_paired),2700);%30sec before, 30sec for sound, 30 sec after =2700 frames
   for i=1:length(sound_paired)
       TAsound1start(i,:)=DeltaFF(sound_paired(1,i)-900:sound_paired(1,i)+1799);
   end
 end

%% analyze fluorescence at start of unpaired sounds
 if photometry==1
   TAsound2start=zeros(length(sound_unpaired),2700);%30sec before, 30sec for sound, 30 sec after =2700 frames
   for i=1:length(sound_unpaired)
       TAsound2start(i,:)=DeltaFF(sound_unpaired(1,i)-900:sound_unpaired(1,i)+1799);
   end
 end

%% make figures
 if photometry == 1
    close all
    figure('Position', [50, 80, 1300, 1100])

    % First subplot for DeltaFF (top row)
    subplot(8, 1, 1, 'XTick', 3600:3600:length(C), 'XTickLabel', 2:2:length(C)); 
    hold on; 
    plot(DeltaFF, 'Color', [0 0.8 0]);
    if behavior == 1
        plot(freezing, zeros(length(freezing), 1) - 8, 'k.');
    end
    plot(sound_paired, (zeros(2, Noshocks) - 10), 'Color', [0.7, 0, 0], 'LineWidth', 2);
    plot(sound_unpaired, (zeros(2, Noshocks) - 10), 'b', 'LineWidth', 2);
    ylabel('DF/F');
    xlabel('time [min]');
    axis tight;
    title('fluorescence, freezing, sounds');

    % Second subplot for DeltaFF3 directly below DeltaFF
     if GCaMP==1
    subplot(8, 1, 2, 'XTick', 3600:3600:length(C), 'XTickLabel', 2:2:length(C)); 
    hold on; 
    plot(DeltaFF3, 'Color', 'r'); % Plot DeltaFF3 in red
    if behavior == 1
        plot(freezing, zeros(length(freezing), 1) - 8, 'k.');
    end
    plot(sound_paired, (zeros(2, Noshocks) - 10), 'Color', [0.7, 0, 0], 'LineWidth', 2);
    plot(sound_unpaired, (zeros(2, Noshocks) - 10), 'b', 'LineWidth', 2);
    ylabel('DF/F');
    xlabel('time [min]');
    axis tight;
    title('mCherry');
     end

    % Adjust subsequent plots up one row
    subplot(8, 3, [13, 16]); % Moved up from [16, 19]
    hold on;
    plot(speed, DeltaFF(1:length(speed)), 'k.');
    xlabel('speed [cm/sec]'); 
    ylabel('DF/F');
    axis tight;
    regress = fit(speed, DeltaFF(1:length(speed))', 'poly1'); 
    plot(regress(0:40));

    if behavior == 1
        subplot(8, 3, [8, 11], 'XTick', 1:90:360, 'XTickLabel', -6:3:6); % Moved up from [11, 14]
        hold on;
        plot(TAfreezingstart', 'Color', [0.6 0.6 0.6]);
        plot(mean(TAfreezingstart), 'b', 'LineWidth', 1);
        plot([181, 181], [min(DeltaFF), max(DeltaFF)], '--r');
        axis('tight');
        xlabel('time after freezing start [sec]');
        ylabel('DF/F [%]');
        title('freezing start');

        subplot(8, 3, [9, 12], 'XTick', 1:90:360, 'XTickLabel', -6:3:6); % Moved up from [12, 15]
        hold on;
        plot(TAfreezingend', 'Color', [0.6 0.6 0.6]);
        plot(mean(TAfreezingend), 'b', 'LineWidth', 1);
        plot([181, 181], [min(DeltaFF), max(DeltaFF)], '--r');
        axis('tight');
        xlabel('time after freezing end [sec]');
        ylabel('DF/F [%]');
        title('freezing end');
    end

    subplot(8, 3, [7, 10]); % Moved up from [10, 13]
    hold on;
    for i = 1:length(centroidcalibrated)
        plot(centroidcalibrated(i, 1), centroidcalibrated(i, 2), '.', 'Color', [min(C(i) * 2, 1), min(2 - (C(i) * 2), 1), max(1 - (C(i) * 2), 0)]);
        hold on;
    end
    axis('tight');
    xlabel('cm'); 
    ylabel('cm'); 
    title('DF/F');

    subplot(8, 3, [19, 22], 'XTick', -1200:600:1200, 'XTickLabel', -40:20:40); % Moved up from [22, 25]
    hold on;
    [crosscorr, lags] = xcorr((DeltaFF(2:end) - mean(DeltaFF))', speed, 1200, 'coeff');
    plot(lags, crosscorr); 
    hold on;
    plot([-1200, 1200], [0, 0], 'k--');
    axis([-1200 1200 -0.4 0.8]);
    xlabel('lag [sec]');
    ylabel('cross-correlation DFF and speed');
    
    subplot(4, 6, 9, 'XTick', -1200:600:1200, 'XTickLabel', -40:20:40); % 
    hold on;title('correlation wo sounds/shocks')
    DeltaFF_exCSshock=DeltaFF;
    speed_exCSshock=speed;
    Sounds=[sound_paired(1,:),sound_unpaired(1,:)];
    Sounds=sort(Sounds);
    for i=size(Sounds,2):-1:1
    DeltaFF_exCSshock(Sounds(i):Sounds(i)+(60*30))=[];
    speed_exCSshock(Sounds(i):Sounds(i)+(60*30))=[];
    end
    [crosscorr2, lags2] = xcorr((DeltaFF_exCSshock(2:end) - mean(DeltaFF_exCSshock))', speed_exCSshock, 1200, 'coeff');
    plot(lags2, crosscorr2); 
    hold on;
    plot([-1200, 1200], [0, 0], 'k--');
    axis([-1200 1200 -0.4 0.8]);
    xlabel('lag [sec]');
    ylabel('cross-correlation');

    subplot(4, 6, 10, 'XTick', -1200:600:1200, 'XTickLabel', -40:20:40); % 
    hold on;title('correlation shocks')
    DeltaFF_OnlyShock=DeltaFF;
    speed_OnlyShock=speed;
    for i=size(shocks,2)-1:-1:1
    DeltaFF_OnlyShock(shocks(1,i)+(60*30):shocks(1,i+1))=[];
    speed_OnlyShock(shocks(1,i)+(60*30):shocks(1,i+1))=[];
    end
    speed_OnlyShock(shocks(end)+(30*60):end)=[];
    DeltaFF_OnlyShock(shocks(end)+(30*60):end)=[];
    speed_OnlyShock(1:shocks(1))=[];
    DeltaFF_OnlyShock(1:shocks(1))=[];
    [crosscorr3, lags3] = xcorr((DeltaFF_OnlyShock(2:end) - mean(DeltaFF_OnlyShock))', speed_OnlyShock, 1200, 'coeff');
    plot(lags3, crosscorr3); 
    hold on;
    plot([-1200, 1200], [0, 0], 'k--');
    axis([-1200 1200 -0.4 0.8]);
    xlabel('lag [sec]');
    ylabel('cross-correlation');
    
    subplot(4, 6, 11, 'XTick', -1200:600:1200, 'XTickLabel', -40:20:40); % 
    hold on;title('correlation sounds')
    DeltaFF_OnlySound=DeltaFF;
    speed_OnlySound=speed;
    for i=size(Sounds,2)-1:-1:1
    DeltaFF_OnlySound(Sounds(i)+(29*30):Sounds(i+1)-(29*30))=[];
    speed_OnlySound(Sounds(i)+(29*30):Sounds(i+1)-(29*30))=[];
    end
    speed_OnlySound(Sounds(end)+(29*60):end)=[];
    DeltaFF_OnlySound(Sounds(end)+(29*60):end)=[];
    speed_OnlySound(1:Sounds(1)-(29*30))=[];
    DeltaFF_OnlySound(1:Sounds(1)-(29*30))=[];
    [crosscorr4, lags4] = xcorr((DeltaFF_OnlySound(2:end) - mean(DeltaFF_OnlySound))', speed_OnlySound, 1200, 'coeff');
    plot(lags4, crosscorr4); 
    hold on;
    plot([-870, 870], [0, 0], 'k--');
    axis([-870 870 -0.4 0.8]);
    xlabel('lag [sec]');
    ylabel('cross-correlation');


    subplot(8, 3, [14, 17], 'XTick', 1:300:2700, 'XTickLabel', -30:10:60); % Moved up from [17, 20]
    hold on;
    fill([901, 901, 900 + (soundduration * 30), 900 + (soundduration * 30)], [min(DeltaFF), max(DeltaFF), max(DeltaFF), min(DeltaFF)], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(TAsound1start(1:5, :)', 'Color', [0.6 0.6 0.6]);
    plot(mean(TAsound1start(1:5, :)), 'b', 'LineWidth', 1);
    axis('tight');
    xlabel('time after paired sound start [sec]');
    ylabel('DF/F [%]');
    title('trials 1-5');

    subplot(8, 3, [15, 18], 'XTick', 1:300:2700, 'XTickLabel', -30:10:60); % Moved up from [18, 21]
    hold on;
    fill([901, 901, 900 + (soundduration * 30), 900 + (soundduration * 30)], [min(DeltaFF), max(DeltaFF), max(DeltaFF), min(DeltaFF)], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(TAsound2start(1:5, :)', 'Color', [0.6 0.6 0.6]);
    plot(mean(TAsound2start(1:5, :)), 'b', 'LineWidth', 1);
    axis('tight');
    xlabel('time after unpaired sound start [sec]');
    ylabel('DF/F [%]');
    title('trials 1-5');

    subplot(8, 3, [21, 24], 'XTick', 1:300:2700, 'XTickLabel', -30:10:60); % Moved up from [25, 28]
    hold on;
    fill([901, 901, 900 + (soundduration * 30), 900 + (soundduration * 30)], [min(DeltaFF), max(DeltaFF), max(DeltaFF), min(DeltaFF)], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(TAsound2start(11:15, :)', 'Color', [0.6 0.6 0.6]);
    plot(mean(TAsound2start(11:15, :)), 'b', 'LineWidth', 1);
    axis('tight');
    xlabel('time after unpaired sound start [sec]');
    ylabel('DF/F [%]');
    title('trials 11-15');

    subplot(8, 3, [20, 23], 'XTick', 1:300:2700, 'XTickLabel', -30:10:60); % Moved up from [24, 27]
    hold on;
    fill([901, 901, 900 + (soundduration * 30), 900 + (soundduration * 30)], [min(DeltaFF), max(DeltaFF), max(DeltaFF), min(DeltaFF)], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(TAsound1start(11:15, :)', 'Color', [0.6 0.6 0.6]);
    plot(mean(TAsound1start(11:15, :)), 'b', 'LineWidth', 1);
    axis('tight');
    xlabel('time after paired sound start [sec]');
    ylabel('DF/F [%]');
    title('trials 11-15');
end
%% %% save photometry data
  if photometry==1
      saveas(gcf,strcat(filename,'_photometryAnalysis'),'png');
      if behavior==1
          save(strcat(filename,'_photometryAnalysis'),'DeltaFF','DeltaFF3','C','Sig1calibrated','Sig3calibrated','autofluorescence','TAfreezingstart','TAfreezingend','TAsound1start','TAsound2start','calibrate','lags','crosscorr','lags2','crosscorr2','lags3','crosscorr3','lags4','crosscorr4','freezing','sound_paired','sound_unpaired','speed','light','version');
      else
          save(strcat(filename,'_photometryAnalysis'),'DeltaFF','DeltaFF3','C','Sig1calibrated','Sig3calibrated','autofluorescence','TAsound1start','TAsound2start','calibrate','lags','crosscorr','lags2','crosscorr2','lags3','crosscorr3','lags4','crosscorr4','sound_paired','sound_unpaired','speed','light','version');
      end
  end


%% function definitions used in this script
%Execute pushbutton for exit from GUI
 function exitCallback(~,~,~,hFig)
 global framelist
global filename
        close(hFig);
        %save(strcat([pwd,'\',filename(1:length(filename)-4)]),'framelist')
 end
    
 %Execute pushbutton to play video at 30Hz
 function playCallback(hObject,~,vid1,hAxis)
 global i
 global m
 global c
 global hFig
 global xdata
 global ydata
 
       try
            % Check the status of play button
            isTextStart = strcmp(hObject.String,'Play at normal speed');
            isTextCont  = strcmp(hObject.String,'Continue');

            if (isTextStart || isTextCont);
                hObject.String = 'Pause';
            else
                hObject.String = 'Continue';
            end

            % play video at 30Hz
            while strcmp(hObject.String, 'Pause') && double(i)~m;
                % Read input video frame
                i=double(i)+1;
                frame = read(vid1,double(i));
                % Display input video frame on axis
                image(xdata,ydata,frame,'Parent', hAxis);
                 c.Value=i/m;
                uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
                'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
                pause(0.03333);
               

            end


       catch ME
           % Re-throw error message if it is not related to invalid handle
           if ~strcmp(ME.identifier, 'MATLAB:class:InvalidHandle');
               rethrow(ME);
           end
       end
       
 
 end
 
 
 %Execute pushbutton for frame by frame backward play
 function backwardCallback(~,~,vid1,hAxis)
 global i
 global m
 global c
 global hFig
 global xdata
 global ydata
       i=double(i)-1;
       if i<1;
          i=1;
       end
           c.Value=i/m;
           uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
                    'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
        pause(0.2)
        for o=1:2
            frame1=read(vid1,i);
            image(xdata,ydata,frame1,'Parent', hAxis);
        end

 end

 %Execute pushbutton for frame by frame forward play   
 function forwardCallback(~,~,vid1,hAxis)
 global i
 global m
 global c
 global hFig
 global xdata
 global ydata
       i=double(i)+1;
      if i>m;
          i=m;
      end
       c.Value=i/m;
       uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
                'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
pause(0.2)
for o=1:2
      frame2=read(vid1,i);
       image(xdata,ydata,frame2,'Parent', hAxis);
end
 end


 %Execute pushbutton to jump to first frame with light estimated from last frame   
 function FrameGrabCallback3(~,~,vid1,hAxis)
 global i
 global m
 global c
 global hFig
 global xdata
 global ydata
 global framelist
       i=double(framelist(2))-104516;
       if i<0
           i=1;
       end
       c.Value=i/m;
       uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
                'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
pause(0.2)
for o=1:2
      frame2=read(vid1,i);
       image(xdata,ydata,frame2,'Parent', hAxis);
end
end
 


 %Execute slider 
  function SliderCallback(~,~,vid1,hAxis)
 global i
 global m
 global c
 global hFig
 global xdata
 global ydata
 if c.Value>0
     i=round(c.Value*m);
 else
     i=1;
 end
       frame=read(vid1,double(i));
       image(xdata,ydata,frame,'Parent', hAxis);
       uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
                'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
   
 end
 
 %Execute pushbutton to Jump to indicated Frame
 function FrameCallback(~,~,vid1,hAxis)
 global i
 global m
 global c
 global hFig
 global a
 global xdata
 global ydata
       i=str2double(a.String);
       frame=read(vid1,i);
       %showFrameOnAxis(hAxis,frame1);
       image(xdata,ydata,frame,'Parent', hAxis);
       c.Value=i/m;
       uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
                'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
 end

 %Execute pushbutton to save current Frame number as start in workspace
 function FrameGrabCallback1(~,~,vid1,hAxis)
 global i
 global framelist
 global xdata
 global ydata
 global m
 global c
 global hFig
framelist(1)=i
i=i+104516;
if i>m
    i=m;
end
frame=read(vid1,i);
image(xdata,ydata,frame,'Parent', hAxis);
c.Value=i/m;
uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
        'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
 end

  %Execute pushbutton to save current Frame number as last frame in workspace
 function FrameGrabCallback2(~,~,vid1,hAxis)
 global i
 global framelist
framelist(2)=i
 end


  %Execute slider button
  function SliderCallback2(~,~,vid1,hAxis)
 global i
 global m
 global c
 global hFig
 global xdata
 global ydata
 global thresholdmax
 global frame
 global threshold
 global frameth

%  i=round(c.Value*m)
threshold=c.Value;
frame1=imcomplement(frame);
    frameth=uint8(im2bw(frame1,threshold)*255);
       image(xdata,ydata,frameth,'Parent', hAxis);
       uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
                'BackgroundColor',[0.5 0.5 1],'position',[830 400 120 25]);
   
 end
 