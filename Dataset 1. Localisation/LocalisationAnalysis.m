% Clears old workspace
clear all

% Loads rosbags
files = dir('*.bag'); % Get all bag files on the current folder

pose_frequency = 2400; % The robot publishes its pose at 10 Hz, for 4 minutes (240s) there are 2400 readings
xpose = zeros(numel(files), pose_frequency);

for c=1:numel(files) % for loop for each bag file
    bag = files(c).name;
    bagdata = rosbag(bag); % Reads messages from rosbag
    bagselect = select(bagdata, 'Topic', '/robot_pose') % Selects pose data
    msgs = readMessages(bagselect); % Stores data to msgs
    
    % Organises relevant data on xpose array
    for d=1:pose_frequency
        xpose(c,d) = msgs{d,1}.Position.X-2.52; % 2.52 is a calibrated value, depending on the robot's map
    end
end

% Concatenates all arrays, measures mean and standard deviation 30 tests
xt = cat(1,xpose(1,:),xpose(2,:),xpose(3,:),xpose(4,:),xpose(5,:),xpose(6,:),xpose(7,:),xpose(8,:),xpose(9,:),xpose(10,:),xpose(11,:),xpose(12,:),xpose(13,:),xpose(14,:),xpose(15,:),xpose(16,:),xpose(17,:),xpose(18,:),xpose(19,:),xpose(20,:),xpose(21,:),xpose(22,:),xpose(23,:),xpose(24,:),xpose(25,:),xpose(26,:),xpose(27,:),xpose(28,:),xpose(29,:),xpose(30,:));
M = mean(xt);
STD = std(xt);

% Quanitfy static error of the robot's localisation algorithm
static_position_mean = zeros(1,16);
error_static_position = zeros(1,16);
for position=1:16
    static_position_mean(1,position) = mean(M(1, ((position-1)*150+50):((position-1)*150+150)));
    error_static_position(1,position) = static_position_mean(position)-position*0.252;
end
total_localisation_error = mean(error_static_position); % in metres
total_localisation_std = std(error_static_position);

plot_areaerrorbar(xt);
hold on
xticks([0 150 300 450 600 750 900 1050 1200 1350 1500 1650 1800 1950 2100 2250 2400]) % Plots time in seconds
xticklabels({'0','15','30','45','60','75,','90','105','120','135','150','165','180','195','210','225','240'})
hold on
plot([0 150],[0.25 0.25],'r') % Displays ground truth
plot([150 300],[0.5 0.5],'r')
plot([300 450],[0.75 0.75],'r')
plot([450 600],[1 1],'r')
plot([600 750],[1.25 1.25],'r')
plot([750 900],[1.5 1.5],'r')
plot([900 1050],[1.75 1.75],'r')
plot([1050 1200],[2 2],'r')
plot([1200 1350],[2.25 2.25],'r')
plot([1350 1500],[2.5 2.5],'r')
plot([1500 1650],[2.75 2.75],'r')
plot([1650 1800],[3 3],'r')
plot([1800 1950],[3.25 3.25],'r')
plot([1950 2100],[3.5 3.5],'r')
plot([2100 2250],[3.75 3.75],'r')
plot([2250 2400],[4 4],'r')
hold off

legend({'Localisation standard deviation','Localisation mean','Ground truth'},'Location','northwest','FontSize', 14)
xlabel('Time (s)','FontSize', 18), ylabel('Measured length position (m)','FontSize', 18)
title('Localisation results','FontSize', 24)

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