function sample_data = odysseyParse( filename, mode )
% ODYSSEYPARSE Parses a .csv data file created from Odyssey export
% of instrument file. Requires "verbose output" and rename
%
%
%   - header - header information generated by Odyssey software.
%              Typically first 9 lines. Limited information.
%   - data   - Rows of comma seperated data.
%
% This function reads in the header sections, and delegates to the two file
% specific sub functions to process the data.
%
% Inputs:
%   filename    - cell array of files to import (only one supported).
%   mode        - Toolbox data type mode. Ignored and assumed to by
%           'timeSeries'
%
% Outputs:
%   sample_data - Struct containing sample data.
%
% Code based on ECOTripletParse.m
%

%
% Until I understand how to use the GenericParser framework, just write a
% custom parser.
%
% Each data file appears to start with 10 header lines, with an apparently 
% stable format.
%
% Example start of data file below.
%
%Site Name ,ODY13009
%Site Number ,1
%Logger ,Integrating Light Sensor
%Logger Serial Number ,13009
%
%
%Scan No ,Date and Time,       Integrating Light,        ,
%        ,        ,RAW VALUE ,CALIBRATED VALUE,
%
%1,24/02/2021 , 05:05:00,1,1
%2,24/02/2021 , 05:10:00,2,2
%3,24/02/2021 , 05:15:00,2,2
%4,24/02/2021 , 05:20:00,1,1
%5,24/02/2021 , 05:25:00,2,2
%6,24/02/2021 , 05:30:00,2,2
%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%
% Copyright (c) 2022, Australian Ocean Data Network (AODN) and Integrated
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
%     * Neither the name of the AODN/IMOS nor the names of its contributors
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

narginchk(1,2);

if ~iscellstr(filename)
    error('filename must be a cell array of strings');
end

% only one file supported currently
filename = filename{1};
[~, ~, ext] = fileparts(filename);
if ~strcmpi(ext, '.CSV')
    error('odysseyParse : parser can only handle CSV files.');
end

metadata_filename = strrep(filename, '.csv', '.dev');

sample_data = [];

[header, data, xattrs] = Odyssey.readCSV(filename);

% will need something to convert CALIBRATED_VALUE to PAR

% create sample data struct,
% and copy all the data in
sample_data = struct;
sample_data.toolbox_input_file  = filename;

%%
meta = struct;
meta.featureType    = mode;
meta.procHeader     = header;

meta.instrument_make = header.instrument_make;
if isfield(header, 'instrument_model')
    meta.instrument_model = header.instrument_model;
else
    meta.instrument_model = 'Odyssey Unknown';
end

if isfield(header, 'instrument_firmware')
    meta.instrument_firmware = header.instrument_firmware;
else
    meta.instrument_firmware = '';
end

if isfield(header, 'instrument_serial_no')
    meta.instrument_serial_no = header.instrument_serial_no;
elseif isfield(header, 'instrument_serial_number')
    meta.instrument_serial_no = header.instrument_serial_number;
else
    meta.instrument_serial_no = '';
end

time = data.TIME;

if isfield(header, 'instrument_sample_interval')
    meta.instrument_sample_interval = header.instrument_sample_interval;
else
    meta.instrument_sample_interval = mean(diff(time*24*3600));
end

%%
vNames = fieldnames(data);
exclude_var_names = 'TIME';
idx = ~ismember(vNames, exclude_var_names);
vNames = vNames(idx);
ts_vars = vNames;

dimensions = IMOS.gen_dimensions('timeSeries', 1, {'TIME'}, {@double}, time);
idx = getVar(dimensions, 'TIME');
dimensions{idx}.data = time;
% not sure if what smoothing window does
%dimensions{idx}.comment = ['Time stamp corresponds to the start of the measurement which lasts ' num2str(meta.instrument_average_interval) ' seconds.'];

% define toolbox struct.
vars0d = IMOS.featuretype_variables('timeSeries'); %basic vars from timeSeries

coords1d = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';
vars1d = IMOS.gen_variables(dimensions,ts_vars,{},fields2cell(data,ts_vars),'coordinates',coords1d);

sample_data.meta = meta;
sample_data.dimensions = dimensions;
sample_data.variables = [vars0d, vars1d];

indexes = IMOS.find(sample_data.variables,xattrs.keys);
for vind = indexes
    iname = sample_data.variables{vind}.name;
    sample_data.variables{vind} = combineStructFields(sample_data.variables{vind},xattrs(iname));
end

end



