function sample_data = AanderaaParse( filename, mode )
%AanderaaParse Parses either .raw data file (with associcated
% metafiles of .cal (calibration coeffs) and .inf (basic time info etc)
%
% This function is able to read in a .csv data file produced by conversion
% of raw .TXT file.
%
% Inputs:
%   filename    - cell array of files to import (only one supported).
%   mode        - Toolbox data type mode.
%
% Outputs:
%   sample_data - Struct containing sample data.
%

%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%
% Copyright (c) 2024, Australian Ocean Data Network (AODN) and Integrated
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
is_eng = ~isempty(regexp(filename, '\.eng$'));

% calibration file, either old or new style
cal_filename = regexprep(filename, '.raw$', '.dev', 'ignorecase');

% User supplied information file, not to be confused with possible inf file
% from old aanderaa s/w, this file has some basic instrument info required
% for parsing the calibration and data files.
inf_filename = regexprep(cal_filename, '\.(dev|asc)$', '.inf', 'ignorecase');

if is_eng
    error('Aanderaa .eng export format not handled yet.');
end

if ~is_eng && ~exist(cal_filename, 'file')
    error('Calibration file must have the same radical as the data file with .cal extension');
end

if ~is_eng && ~exist(inf_filename, 'file')
    error('Information file must have the same radical as the data file with .inf extension');
end

% read in calibration coefficients and some basic instrument info
deviceInfo = Aanderaa.readMetadata(cal_filename, inf_filename);
deviceInfo.toolbox_input_file = filename;

[data, xattrs] = Aanderaa.readData(filename, deviceInfo);

sample_data = Aanderaa.construct_sample_data( deviceInfo, data, xattrs, mode );

end




