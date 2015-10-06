function sample_data = SBE56Parse( filename, mode )
%SBE56PARSE Parses a .cnv data file from a Seabird SBE56
% CTD recorder.
%
% This function is able to read in a .cnv data file retrieved
% from a Seabird SBE56 Temperature Logger. It reads specific instrument header
% format and makes use of a lower level function readSBE37cnv to read the data.
% The files consist of up to three sections:
%
%   - instrument header - header information as retrieved from the instrument.
%                         These lines are prefixed with '*'.
%   - processed header  - header information generated by SBE Data Processing.
%                         These lines are prefixed with '#'.
%   - data              - Rows of data.
%
% This function reads in the header sections, and delegates to the two file
% specific sub functions to process the data.
%
% Inputs:
%   filename    - cell array of files to import (only one supported).
%   mode        - Toolbox data type mode ('profile' or 'timeSeries').
%
% Outputs:
%   sample_data - Struct containing sample data.
%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
% Contributor:  Guillaume Galibert <guillaume.galibert@utas.edu.au>
%

%
% Copyright (c) 2009, eMarine Information Infrastructure (eMII) and Integrated
% Marine Observing System (IMOS).
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
%     * Redistributions of source code must retain the above copyright notice,
%       this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of the eMII/IMOS nor the names of its contributors
%       may be used to endorse or promote products derived from this software
%       without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%
error(nargchk(1,2,nargin));

if ~iscellstr(filename)
    error('filename must be a cell array of strings');
end

% only one file supported currently
filename = filename{1};

[~, ~, ext] = fileparts(filename);
if strcmpi(ext, '.CNV')
    % read in every line in the file, separating
    % them out into each of the three sections
    instHeaderLines = {};
    procHeaderLines = {};
    dataLines       = {};
    try
        
        fid = fopen(filename, 'rt');
        line = fgetl(fid);
        while ischar(line)
            
            line = deblank(line);
            if isempty(line)
                line = fgetl(fid);
                continue;
            end
            
            if     line(1) == '*', instHeaderLines{end+1} = line;
            elseif line(1) == '#', procHeaderLines{end+1} = line;
            else                   dataLines{      end+1} = line;
            end
            
            line = fgetl(fid);
        end
        
        fclose(fid);
        
    catch e
        if fid ~= -1, fclose(fid); end
        rethrow(e);
    end
    
    % cnv file
    % read in the raw instrument header
    instHeader = parseInstrumentHeader(instHeaderLines);
    procHeader = parseProcessedHeader( procHeaderLines);
    
    % use SBE37 specific cnv reader function
    [data, comment] = readSBE37cnv(dataLines, instHeader, procHeader, mode);
else
    % have csv file
    % use SBE56 specific csv data reader function
    [data, comment, csvHeaderLines] = readSBE56csv(filename, mode);
    instHeader = parseInstrumentHeader(csvHeaderLines);
    procHeader = struct;
end

% create sample data struct,
% and copy all the data in
sample_data = struct;

sample_data.toolbox_input_file  = filename;
sample_data.meta.instHeader     = instHeader;
sample_data.meta.procHeader     = procHeader;

sample_data.meta.instrument_make = 'Seabird';
if isfield(instHeader, 'instrument_model')
    sample_data.meta.instrument_model = instHeader.instrument_model;
else
    sample_data.meta.instrument_model = 'SBE56';
end

if isfield(instHeader, 'instrument_firmware')
    sample_data.meta.instrument_firmware = instHeader.instrument_firmware;
else
    sample_data.meta.instrument_firmware = '';
end

if isfield(instHeader, 'instrument_serial_no')
    sample_data.meta.instrument_serial_no = instHeader.instrument_serial_no;
else
    sample_data.meta.instrument_serial_no = '';
end

time = genTimestamps(instHeader, data);

if isfield(instHeader, 'sampleInterval')
    sample_data.meta.instrument_sample_interval = instHeader.sampleInterval;
else
    sample_data.meta.instrument_sample_interval = median(diff(time*24*3600));
end

sample_data.dimensions = {};
sample_data.variables  = {};

% generate time data from header information
sample_data.dimensions{1}.name                  = 'TIME';
sample_data.dimensions{1}.typeCastFunc          = str2func(netcdf3ToMatlabType(imosParameters(sample_data.dimensions{1}.name, 'type')));
sample_data.dimensions{1}.data                  = sample_data.dimensions{1}.typeCastFunc(time);

sample_data.variables{end+1}.name           = 'TIMESERIES';
sample_data.variables{end}.typeCastFunc     = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.data             = sample_data.variables{end}.typeCastFunc(1);
sample_data.variables{end}.dimensions       = [];
sample_data.variables{end+1}.name           = 'LATITUDE';
sample_data.variables{end}.typeCastFunc     = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.data             = sample_data.variables{end}.typeCastFunc(NaN);
sample_data.variables{end}.dimensions       = [];
sample_data.variables{end+1}.name           = 'LONGITUDE';
sample_data.variables{end}.typeCastFunc     = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.data             = sample_data.variables{end}.typeCastFunc(NaN);
sample_data.variables{end}.dimensions       = [];
sample_data.variables{end+1}.name           = 'NOMINAL_DEPTH';
sample_data.variables{end}.typeCastFunc     = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.data             = sample_data.variables{end}.typeCastFunc(NaN);
sample_data.variables{end}.dimensions       = [];

% scan through the list of parameters that were read
% from the file, and create a variable for each
vars = fieldnames(data);
coordinates = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';
for k = 1:length(vars)
    
    if strncmp('TIME', vars{k}, 4), continue; end
    
    % dimensions definition must stay in this order : T, Z, Y, X, others;
    % to be CF compliant
    sample_data.variables{end+1}.dimensions     = 1;
    sample_data.variables{end  }.name           = vars{k};
    sample_data.variables{end  }.typeCastFunc   = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
    sample_data.variables{end  }.data           = sample_data.variables{end}.typeCastFunc(data.(vars{k}));
    sample_data.variables{end  }.coordinates    = coordinates;
    sample_data.variables{end  }.comment        = comment.(vars{k});
    
    if strncmp('PRES_REL', vars{k}, 8)
        % let's document the constant pressure atmosphere offset previously
        % applied by SeaBird software on the absolute presure measurement
        sample_data.variables{end}.applied_offset = sample_data.variables{end}.typeCastFunc(-14.7*0.689476);
    end
end

end

function header = parseInstrumentHeader(headerLines)
%PARSEINSTRUMENTHEADER Parses the header lines from a SBE19/37/56 .cnv file.
% Returns the header information in a struct.
%
% Inputs:
%   headerLines - cell array of strings, the lines of the header section.
%
% Outputs:
%   header      - struct containing information that was in the header
%                 section.
%
header = struct;

% there's no real structure to the header information, which
% is annoying. my approach is to use various regexes to search
% for info we want, and to ignore everything else. inefficient,
% but it's the nicest way i can think of
headerExpr   = '<HardwareData DeviceType=''(\S+)'' SerialNumber=''(\S+)''>';
memExpr      = '<MemorySummary>';
sampleExpr   = 'samplePeriod=''(\d+)''';
firmExpr     = '<FirmwareVersion>([\w .]+)</FirmwareVersion>';
modelCsvExpr  = '% Instrument type = (\S+)';
serialCsvExpr = '% Serial Number = (\d+)';
firmCsvExpr   = '% Firmware Version = ([\w .]+)';

exprs = {...
    headerExpr     ...
    memExpr      sampleExpr   ...
    firmExpr ...
    modelCsvExpr serialCsvExpr firmCsvExpr};

for k = 1:length(headerLines)
    
    % try each of the expressions
    for m = 1:length(exprs)
        
        % until one of them matches
        tkns = regexp(headerLines{k}, exprs{m}, 'tokens');
        if ~isempty(tkns)
            
            % yes, ugly, but easiest way to figure out which regex we're on
            switch m
                
                % header
                case 1
                    header.instrument_model     = tkns{1}{1};
                    header.instrument_serial_no = tkns{1}{2};
                    
                    % mem
                case 2
                    tkns = regexp(headerLines{k+1}, '<Samples>(\d+)</Samples>', 'tokens');
                    if ~isempty(tkns)
                        header.numSamples = str2double(tkns{1}{1});
                    end
                    tkns = regexp(headerLines{k+3}, '<BytesFree>(\d+)</BytesFree>', 'tokens');
                    if ~isempty(tkns)
                        header.freeMem    = str2double(tkns{1}{1});
                    end
                    
                    % sample
                case 3
                    header.sampleInterval        = str2double(tkns{1}{1});
                    
                    %firmware version
                case 4
                    header.instrument_firmware  = tkns{1}{1};
                    
                    % csv model
                case 5
                    header.instrument_model     = tkns{1}{1};
                    
                    % csv serial
                case 6
                    header.instrument_serial_no = tkns{1}{1};
                    
                    % csv firmware
                case 7
                    header.instrument_firmware  = tkns{1}{1};
                    
            end
            break;
        end
    end
end
end

function header = parseProcessedHeader(headerLines)
%PARSEPROCESSEDHEADER Parses the data contained in the header added by SBE
% Data Processing. This includes the column layout of the data in the .cnv
% file.
%
% Inputs:
%   headerLines - Cell array of strings, the lines in the processed header
%                 section.
%
% Outputs:
%   header      - struct containing information that was contained in the
%                 processed header section.
%

header = struct;
header.columns = {};

nameExpr = 'name \d+ = (.+):';
nvalExpr = 'nvalues = (\d+)';
badExpr  = 'bad_flag = (.*)$';
startExpr = 'start_time = (.+)';

for k = 1:length(headerLines)
    
    % try name expr
    tkns = regexp(headerLines{k}, nameExpr, 'tokens');
    if ~isempty(tkns)
        header.columns{end+1} = tkns{1}{1};
        continue;
    end
    
    % then try nvalues expr
    tkns = regexp(headerLines{k}, nvalExpr, 'tokens');
    if ~isempty(tkns)
        header.nValues = str2double(tkns{1}{1});
        continue;
    end
    
    % then try bad flag expr
    tkns = regexp(headerLines{k}, badExpr, 'tokens');
    if ~isempty(tkns)
        header.badFlag = str2double(tkns{1}{1});
        continue;
    end
    
    %BDM (18/02/2011) - added to get start time
    % then try startTime expr
    tkns = regexp(headerLines{k}, startExpr, 'tokens');
    if ~isempty(tkns)
        header.startTime = datenum(tkns{1}{1});
        continue;
    end
end
end

function time = genTimestamps(instHeader, data)
%GENTIMESTAMPS Generates timestamps for the data. Horribly ugly. I shouldn't
% have to have a function like this, but the .cnv files do not necessarily
% provide timestamps for each sample.
%

% time may have been present in the sample
% data - if so, we don't have to do any work
if isfield(data, 'TIME'), time = data.TIME; return; end

% To generate timestamps for the CTD data, we need to know:
%   - start time
%   - sample interval
%   - number of samples
%
% The SBE19 header information does not necessarily provide all, or any
% of this information. .
%
start    = 0;
interval = 0.25;

% figure out number of samples by peeking at the
% number of values in the first column of 'data'
f = fieldnames(data);
nSamples = length(data.(f{1}));

% try and find a start date - use castDate if present
if isfield(instHeader, 'castDate')
    start = instHeader.castDate;
end

% if scanAvg field is present, use it to determine the interval
if isfield(instHeader, 'scanAvg')
    
    interval = (0.25 * instHeader.scanAvg) / 86400;
end

% if one of the columns is 'Scan Count', use the
% scan count number as the basis for the timestamps
if isfield(data, 'ScanCount')
    
    time = ((data.ScanCount - 1) ./ 345600) + cStart;
    
    % if scan count is not present, calculate the
    % timestamps from start, end and interval
else
    
    time = (start:interval:start + (nSamples - 1) * interval)';
end
end

%%
function [data, comment, csvHeaderLines] = readSBE56csv(filename, mode)
%READSBE56CSV

% So far a typical SBE56 csv file has a number of header lines with '%' as
% first character, the a column label line (in double quotes), then data
% (also in double quotes). Sample number is an optional output, and there
% are several date formats but this function currently only support
% 'yyyy-mm-dd'
% An short example csv is
% % Instrument type = SBE56
% % Serial Number = 05600674
% % Firmware Version = SBE56 V0.96
% % Conversion Date = 2015-08-14
% % Source file = D:\Data\SBE56\SBE05600674_2015-04-27.xml
% % Calibration Date = 2014-09-09
% % Coefficients: 
% %       A0 = -1.118136E-3
% %       A1 = 3.269029E-4
% %       A2 = -5.503897E-6
% %       A3 = 1.792613E-7
% "Sample Number","Date","Time","Temperature"
% "1","2015-04-10","14:00:00","23.3373"
% "2","2015-04-10","14:00:00.5","23.3341"
% "3","2015-04-10","14:00:01","23.3281"
% "4","2015-04-10","14:00:01.5","23.3229"
% "5","2015-04-10","14:00:02","23.3197"
% "6","2015-04-10","14:00:02.5","23.3193"
% "7","2015-04-10","14:00:03","23.3206"
% "8","2015-04-10","14:00:03.5","23.3239"
% "9","2015-04-10","14:00:04","23.3268"
% "10","2015-04-10","14:00:04.5","23.3280"

csvHeaderLines = {};
try
    fid = fopen(filename, 'rt');
    line = strtrim(fgetl(fid));
    while strcmp(line(1),'%')
        csvHeaderLines{end+1} = line;
        line = fgetl(fid);
    end
    %fclose(fid);
    
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

% process first line of dataLines which is a columnn header labels
% typically "Sample Number","Date","Time","Temperature"
% grab all text within double quotes,uppercase and genvarname them for safety
expr='"(.*?)"'; %
tokens = regexp(line, expr, 'tokens');
tokens = upper(cellfun(@genvarname, tokens));
nCols = numel(tokens);

% possible labels are 'SAMPLENUMBER', 'DATE', 'TIME' and 'TEMPERATURE' but
% we should only need to handle 'DATE', 'TIME' and 'TEMPERATURE'
% find index column number of a label in original file (LOCB)
labels = {'DATE' 'TIME' 'TEMPERATURE'};

% so when read data ignoring unknown labels what are the labels column
% index,  note LHS deal statement the indices same order and number as labels
[LIA,LOCB] = ismember(tokens, labels);
LOCB(LOCB==0) = [];
iTokens = num2cell(LOCB);
[iDate, iTime, iTemp]=deal(iTokens{:});


% make up format string ignoring everything but labels
format = cell(nCols,1);
for ii=1:nCols
    format{ii}='%*q';
end
format(ismember(tokens, labels)) = {'%q'};
format=[format{:}];

dataCells = textscan(fid, format, 'Delimiter', ',');
fclose(fid);

data = struct;
comment = struct;

% can't imagine what conditions you would have a csv file without
% date,time and temperature
haveDateTime = false;
if ~isempty(iDate) && ~isempty(iTime)
    % datenum('2015-04-10T14:00:00.5', 'yyyy-mm-ddTHH:MM:SS.FFF') will work
    % datenum('2015-04-10T14:00:01', 'yyyy-mm-ddTHH:MM:SS.FFF') will fail
    % so split time and rewrite seconds as SS.FFF
    timeFFF = cellfun(@(x) sprintf('%2.2d:%2.2d:%06.3f',str2double(x)), regexp(dataCells{iTime},':','split'), 'UniformOutput', false);
    data.TIME = datenum(strcat(dataCells{iDate},'T',timeFFF),'yyyy-mm-ddTHH:MM:SS.FFF');
    comment.TIME = '';
    haveDateTime = true;
end


haveTemp = false;
if ~isempty(iTemp)
    data.TEMP = str2double(dataCells{iTemp});
    comment.TEMP = '';
    haveTemp = true;
end


if ~haveDateTime & ~haveTemp
    error('readSBE56csv could not convert data');
end

end
