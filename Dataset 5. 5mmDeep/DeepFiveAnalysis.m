% Clears old workspace
clear all

% Loads rosbags
files = dir('*.bag')    ; %%get all bag files on the current folder

frames = 7200;
pixelheight = 160;
depths = zeros(numel(files),frames,pixelheight);

for c=1:numel(files) % for loop for each file
    bag = files(c).name;
    bagdata = rosbag(bag); % Reads messages from rosbag
    bagselect = select(bagdata, 'Topic', '/depth_data') % Selects depth data
    msgs = readMessages(bagselect); % Stores data to msgs
    
    % Organises relevant data on matrix depths
    for d=1:frames
        for e=1:pixelheight
        depths(c,d,e) = msgs{d,1}.Data(e,1);
        end
    end
end

% Find height position of the tube at each frame for all series
i = zeros(numel(files),frames);
h = zeros(numel(files),frames);
for c=1:numel(files)
    for d=1:frames
        a = find(depths(c,d,90:110) < 1200 & depths(c,d,90:110) > 900);
        i(c,d) = round(median(a))+89;
        if isnan(i(c,d))
           i(c,d)=i(c,d-1);
        end
        h(c,d) = (i(c,d)-102)*(-1.8);
    end
end

% Find depth of the tube at each frame for all series
z1 = zeros(numel(files),frames);
z2 = zeros(numel(files),frames);
r = zeros(numel(files),frames);
for c=1:numel(files) 
    for d=1:frames
        z1(c,d) = depths(c,d,i(c,d));
        z2(c,d) = depths(c,d,i(c,d)-25);
        r(c,d) = z2(c,d)-z1(c,d);
    end
end

% Counter of correct/incorrect detections for confusion matrix
deep_counter = 0;
ok_counter = 0;
shallow_counter = 0;
for c=1:numel(files) 
    for d=1:frames
        if r(c,d)>203
            shallow_counter = shallow_counter+1;
        elseif r(c,d)<197
            deep_counter = deep_counter+1;
        else
            ok_counter = ok_counter+1;
        end
    end
end

% Plot depth values
depth_plot = cat(1,r(1,:),r(2,:),r(3,:),r(4,:),r(5,:),r(6,:),r(7,:),r(8,:),r(9,:),r(10,:),r(11,:));
M_depth = mean(depth_plot);
STD_depth = std(depth_plot);

total_mean_depth = mean(M_depth);
total_std_depth = std(M_depth);

plot_areaerrorbar(depth_plot);
hold on
xticks([0 450 900 1350 1800 2250 2700 3150 3600 4050 4500 4950 5400 5850 6300 6750 7200])
xticklabels({'0','15','30','45','60','75','90','105','120','135','150','165','180','195','210','225','240'})
hold on
plot([0 7200],[197 197],'r')
hold on
plot([0 7200],[203 203],'r')
hold on

legend({'Standard deviation','Mean depth measurements','Tolerance limits'},'Location','southeast','FontSize', 14)
xlabel('Time (s)','FontSize', 18), ylabel('Measured depth (mm)','FontSize', 18)
title('5mm depth error - Inspection results','FontSize', 24)
hold off
grid

% Function 'Shaded area error bar plot' version 1.3.1 developed by Víctor Martínez-Cagigal
% Extracted from https://www.mathworks.com/matlabcentral/fileexchange/58262-shaded-area-error-bar-plot
function plot_areaerrorbar(data, options)

    % Default options
    if(nargin<2)
        options.handle     = figure(1);
        options.color_area = [128 193 219]./255;    % Blue theme
        options.color_line = [ 52 148 186]./255;
        %options.color_area = [243 169 114]./255;    % Orange theme
        %options.color_line = [236 112  22]./255;
        options.alpha      = 0.5;
        options.line_width = 2;
        options.error      = 'std';
    end
    if(isfield(options,'x_axis')==0), options.x_axis = 1:size(data,2); end
    options.x_axis = options.x_axis(:);
    
    % Computing the mean and standard deviation of the data matrix
    data_mean = mean(data,1);
    data_std  = std(data,0,1);
    
    % Type of error plot
    switch(options.error)
        case 'std', error = data_std;
        case 'sem', error = (data_std./sqrt(size(data,1)));
        case 'var', error = (data_std.^2);
        case 'c95', error = (data_std./sqrt(size(data,1))).*1.96;
    end
    
    % Plotting the result
    figure(options.handle);
    x_vector = [options.x_axis', fliplr(options.x_axis')];
    patch = fill(x_vector, [data_mean+error,fliplr(data_mean-error)], options.color_area);
    set(patch, 'edgecolor', 'none');
    set(patch, 'FaceAlpha', options.alpha);
    hold on;
    plot(options.x_axis, data_mean, 'color', options.color_line, ...
        'LineWidth', options.line_width);
    hold off;
    
end