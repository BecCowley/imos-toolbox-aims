function waveData = readWorkhorseWaveAscii( filename )
%READWORKHORSEWAVEASCII Reads RDI Workhorse wave data from processed wave text files
% (_LOG9.txt, DSpec*.txt, PSpec*.txt, SSpec*.txt and VSpec*.txt).
%
% Inspired from read_adcpWvs.m and read_adcpWvs_spec.m by Charlene Sullivan
% csullivan@usgs.gov USGS Woods Hole Science Center.
%
% This function takes the name of a binnary RDI wave data file (.WVS) and
% from that name locates the log9 and spectra files (_LOG9.txt, DSpec*.txt,
% PSpec*.txt, SSpec*.txt and VSpec*.txt). Those files can be obtained using
% WavesMon RDI softwares (see http://pubs.usgs.gov/of/2005/1211/images/pdf/report.pdf).
% It is assumed that these files are located in the same directory as the
% binary file and that the log9 file is named '*_LOG9.TXT'.
%
% This function currently assumes a number of things:
%
%   - That the ASCII files exist in the same directory as the binary file.
%   - That the spectra files are named DSpec*.txt, PSpec*.txt, SSpec*.txt
%   and VSpec*.txt with * being a date of format yyyymmddHHMM.
%   - That the log file is of format 9 and with a name such as
%   '*_LOG9.TXT'. See this URL below for more details on the format :
% https://raw.githubusercontent.com/wiki/aodn/imos-toolbox/documents/Instruments/RDI/WavesMon_Users_Guide.pdf
%
% Inputs:
%   filename - The name of a binary RDI wave file (.WVS).
%
% Outputs:
%   waveData - struct containing data read in from the wave data text files.
%
% Author:       Guillaume Galibert <guillaume.galibert@utas.edu.au>
%

%
% Copyright (C) 2017, Australian Ocean Data Network (AODN) and Integrated 
% Marine Observing System (IMOS).
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation version 3 of the License.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with this program.
% If not, see <https://www.gnu.org/licenses/gpl-3.0.en.html>.
%
narginchk(1, 1);

if ~ischar(filename), error('filename must be a string'); end

waveData = struct;

% transform the filename into a path
[filePath, name, ext] = fileparts(filename);

% read the summary file
summaryFile = fullfile(filePath, [name '.txt']);

if exist(summaryFile, 'file')
    summaryFileID = fopen(summaryFile);
    summary = textscan(summaryFileID, '%s', 'Delimiter', '');
    waveData.summary = summary{1};
    fclose(summaryFileID);
end

% Load the *_LOG9.TXT file
logFile = dir(fullfile(filePath, '*_LOG9.TXT'));

if isempty(logFile), error(['file ' filePath filesep '*_LOG9.TXT not found!']); end

data = csvread(fullfile(filePath, logFile.name));

% Extract time
time.YY = data(:,2) + 2000;
time.MM = data(:,3);
time.DD = data(:,4);
time.hh = data(:,5);
time.mm = data(:,6);
time.ss = data(:,7);
time.cc = data(:,8);

waveData.param.time = datenum(time.YY, time.MM, time.DD, time.hh, time.mm, time.ss + time.cc/100);
clear time;

% Extract wave parameters
param = {...
    'Hs',   'Tp',   'Dp', ...
    'Tp_W', 'Dp_W', 'Hs_W', ...
    'Tp_S', 'Dp_S', 'Hs_S', ...
    'ht', ...
    'Hmax', 'Tmax', ...
    'Hth',  'Tth', ...
    'Hmn',  'Tmn', ...
    'Hte',  'Tte', ...
    'Dmn'};
nParam = length(param);
for i = 1:nParam
    waveData.param.(param{i}) = data(:, i+8);
    
    % Replace all values of -1 and -32768 (WavesMon bad data indicator
    % for data in the *LOG9.TXT file) with NaN
    waveData.param.(param{i})(waveData.param.(param{i}) == -1) = NaN;
    waveData.param.(param{i})(waveData.param.(param{i}) == -32768) = NaN;
end
clear data;

% Spectra types
specType = {'D', 'P', 'S', 'V'};
for s = 1:length(specType)
    % get list of files for the spectra type
    specFile = dir(fullfile(filePath, [specType{s} 'Spec*.txt']));
    
    if isempty(specFile), error(['file ' filePath filesep specType{s} 'Spec*.txt not found!']); end
    
    % loop through the files and load the data.  Also replace
    % all values of 0 (WavesMon bad data indicator for spectra
    % data) with NaN
    nFiles = length(specFile);
    for n = 1:nFiles
        filename = specFile(n).name;
        
        filetime = str2double(filename(6:end-4)) + 200000000000;
        filetime = [num2str(filetime) '0'];
        filetime = datenum(filetime, 'yyyymmddHHMM');
        
        switch specType{s}
            case 'D'
                if n == 1
                    % get some metadata that are the same through the
                    % deployment
                    fid = fopen(fullfile(filePath, filename), 'r');
                    for i=1:2
                        fgetl(fid);
                    end
                    
                    infoDim = fgetl(fid);
                    
                    fgetl(fid);
                    
                    infoFreq = fgetl(fid);
                    fclose(fid);
                    
                    infoDim = sscanf(infoDim', '%*s %d %*s %*s %d %*s');
                    waveData.Dspec.nDir  = infoDim(1);
                    waveData.Dspec.nFreq = infoDim(2);
                    
                    infoFreq = sscanf(infoFreq', '%*s %*s %*s %*s %f %*s %*s %*s %*s %*s %*s %*s %f');
                    freqStep  = infoFreq(1);
                    firstFreq = infoFreq(2);
                    
                    waveData.Dspec.freq = (firstFreq : freqStep : firstFreq + (waveData.Dspec.nFreq-1)*freqStep)';
                    waveData.Dspec.dir = (0 : 360/waveData.Dspec.nDir : 360 - 360/waveData.Dspec.nDir)';
                end
                
                % get the direction at which the first direction slice
                % begins. It is determined by WavesMon and can vary between
                % individual deployments
                fid = fopen(fullfile(filePath, filename), 'r');
                for i=1:5
                    fgetl(fid);
                end
                infoDir = fgetl(fid);
                fclose(fid);
                
                firstDirSlice = ...
                    sscanf(infoDir', '%*s %*s %*s %*s %*s %*s %*s %d %*s');
                
                direction = (firstDirSlice : 360/waveData.Dspec.nDir : firstDirSlice + 360 - 360/waveData.Dspec.nDir)';
                direction(direction >= 360) = direction(direction >= 360) - 360;
                
                % we add a negative value so that interpolation is possible
                % for 0
                iLastDir = direction == max(direction);
                direction(end+1) = min(direction) - 360/waveData.Dspec.nDir;
                
                data = load(fullfile(filePath, filename), '-ascii');
                data( data == 0 ) = nan;
                data(:, end+1) = data(:, iLastDir);
                
                % let's interpolate the data at fixed directions
                interpData = nan(waveData.Dspec.nFreq, waveData.Dspec.nDir);
                for i=1:waveData.Dspec.nFreq
                    interpData(i, :) = interp1(direction, data(i, :), waveData.Dspec.dir);
                end
                waveData.Dspec.time(n) = filetime;
                waveData.Dspec.data(n, :, :) = interpData;
                clear data interpData;
                
            otherwise
                data = load(fullfile(filePath, filename), '-ascii');
                data( data == 0 ) = nan;
                waveData.([specType{s} 'spec']).time(n) = filetime;
                waveData.([specType{s} 'spec']).data(n, :)= data;
        end
    end
end

% Test time lengths for spectra types, have cases where times from spectra
% are different (currently always shorter) than LOG9.txt wave data times.
nTimes = numel(waveData.param.time);
specType = {'D', 'P', 'S', 'V'};
for s = 1:length(specType)
    specName = [specType{s} 'spec'];
    nSpecTime = numel(waveData.(specName).time);
    if nSpecTime ~= nTimes
        if nSpecTime < nTimes
        % spectra time shorter than LOG9.txt wave data times
        % typically missing the last record
        disp(['Fixing short ' specName ' time.']);
        [~, loc]=ismember(waveData.(specName).time, waveData.param.time);
        else
        % spectra time longer than LOG9.txt wave data times
        disp(['Fixing long ' specName ' time.']);
        [~, loc]=ismember(waveData.param.time, waveData.(specName).time);
        end
        % copy data from spectra times to matched LOG9 time.
        
        % index locations for real numbers with tolerance
        %[~, loc]=ismember(waveData.(specName).time, waveData.param.time, 'tol',1e-4);
        oldData = waveData.(specName).data;
        sizeOldData = size(oldData);
        waveData.(specName).time = waveData.param.time;
        waveData.(specName).data = NaN([nTimes sizeOldData(2:end)]);
        newdataLoc = repmat(loc, [1 sizeOldData(2:end)]);
        if nSpecTime < nTimes
        waveData.(specName).data(newdataLoc) = oldData;
        else
        waveData.(specName).data = oldData(newdataLoc);            
        end
        clear('oldData');
        clear('oldTime');
        clear('newdataLoc');
    end
end

end