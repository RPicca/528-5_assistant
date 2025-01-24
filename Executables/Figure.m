% Figure.m
%
% Author:  William Kozma Jr
%          wkozma@ntia.gov
%          US Dept of Commerce, NTIA/ITS
%          May/June 2022 : Geneva Study Group 3 Meetings
% 
% Description: This function allows the user to generate a figure similar
%              to the figures shown in Rec P.528-3.
%
% Inputs:
%   f__mhz      - Frequency, in MHz
%   h_2__meter  - Height of the high terminal, in meters
%   p           - Time percentage
%   tpol        - Polarization (0 = Horizontal; 1 = Vertical) 
%
% Output: [Plot]
function Figure(f__mhz, h_2__meter, p, tpol)

exe = 'P528Drvr_x86.exe'; 
temp_file = 'temp.csv';

% List of possible h_1__meters
h1s = [1.5 15 30 60 1000 10000 20000];

% Generate distance array
d__km = zeros(1, 1800);
for i = 1:1800
    d__km(i) = i;
end

% 2D array to hold data for all the curves
data = zeros(8, 1800);

% Generate free space line
h_1__meter = 1.5;

% Call P.528 driver
cmd = [' -mode CURVE -h1 ' num2str(h_1__meter) ...
       ' -h2 ' num2str(h_2__meter) ...
       ' -f ' num2str(f__mhz)...
       ' -p ' num2str(p)...
       ' -tpol ' num2str(tpol) ...
       ' -o ' temp_file];
dos([exe cmd]);

% Read data
fileID = fopen(temp_file,'r');

% Skipping lines in output file...
for j = 1:13
    fgetl(fileID);
end

% Read the lines containing basic transmission loss
freeSpaceLine = fgetl(fileID);

% Parse loss values
freeSpace_Split = strsplit(freeSpaceLine, ',');
for j = 2:1801
    loss = char(strtrim(freeSpace_Split(j)));
    data(1,j - 1) = str2double(loss);
end

% Close and delete the temp file
fclose(fileID);
delete(temp_file);

cnt = 1;

% Generate basic transmission loss data
for i = 1:length(h1s)
    h_1__meter = h1s(i);
    
    % Make sure h_1__meter <= h_2__meter
    if (h_1__meter > h_2__meter)
        break;
    end
    
    cnt = cnt + 1;
    
    % Call P.528 driver
    cmd = [' -mode CURVE -h1 ' num2str(h_1__meter) ...
           ' -h2 ' num2str(h_2__meter) ...
           ' -f ' num2str(f__mhz)...
           ' -p ' num2str(p)...
           ' -tpol ' num2str(tpol) ...
           ' -o ' temp_file];
    dos([exe cmd]);
    
    % Read data
    fileID = fopen(temp_file,'r');
    
    % Skipping lines in output file...
    for j = 1:14
        fgetl(fileID);
    end
    
    % Read the lines containing basic transmission loss
    totalLossLine = fgetl(fileID);
    
    % Parse loss values
    total_Split = strsplit(totalLossLine, ',');
    for j = 2:1801
        loss = char(strtrim(total_Split(j)));
        data(i + 1,j - 1) = str2double(loss);
    end
    
    % Close and delete the temp file
    fclose(fileID);
    delete(temp_file);
end

% Plot the results
hFig = figure(1);
set(hFig, 'Position', [100 100 1000 350])

hold on

% Select the correct number of curves to plot
for i = 1 : cnt
    plot(d__km,data(i,:),'LineWidth',2)
end

% Format the plot
axis([0 1800 100 300])
yticks([100 120 140 160 180 200 220 240 260 280 300])
xticks([0 200 400 600 800 1000 1200 1400 1600 1800])
grid on
xlabel('Distance (km)')
ylabel('Basic transmission loss (dB)');
legend('Location','southwest');

% Select the correct number of labels
labels = {'Free space','h1 = 1.5 m','h1 = 15 m','h1 = 30 m','h1 = 60 m','h1 = 1 000 m','h1 = 10 000 m','h1 = 20 000 m'};
legend(labels(1:cnt))

set(gca,'Ydir','reverse')
end