function [data flags log] = inWaterQC( sample_data, data, k )
%INWATERQC Flags samples which were taken before the instrument was placed
% in the water.
%
% Flags all samples from the data set which have a time that is before the 
% in water time. Assumes that these samples will be at the beginning of the
% data set.
%
% Inputs:
%   sample_data - struct containing the entire data set and dimension data.
%
%   data        - the vector of data to check.
%
%   k           - Index into the sample_data.variables vector.
%
% Outputs:
%   data        - Same as input.
%
%   flags       - Vector the same size as data, with before in-water samples 
%                 flagged. Empty if no values were flagged.
%
%   log         - Empty cell array..
%
% Author: Paul McCarthy <paul.mccarthy@csiro.au>
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

error(nargchk(3, 3, nargin));
if ~isstruct(sample_data),        error('sample_data must be a struct'); end
if ~isvector(data),               error('data must be a vector');        end
if ~isscalar(k) || ~isnumeric(k), error('k must be a numeric scalar');   end

flags = char;
log   = {};

% end index of samples which were taken before in water
sEnd = 0;

dateFmt = readToolboxProperty('exportNetCDF.dateFormat');
time_coverage_start = datenum(sample_data.time_coverage_start, dateFmt);

qc_set  = str2num(readToolboxProperty('toolbox.qc_set'));
flagVal = imosQCFlag('bad', qc_set, 'flag');

origLength = length(data);

% step through the start of the data set until we find a sample 
% which has a time greater than or equal to the in water time
time = sample_data.dimensions{1}.data;

startTime = time(1);

for k = 1:length(time)
  
  if time(k) >= time_coverage_start
    
    sEnd    = k;
    endTime = time(k);
    break;
    
  end
end

% the entire data set is before the in water time
if sEnd == 0, sEnd = length(data)+1;
  
% the entire data set is after the in water time
elseif sEnd == 1, return;
end

% flag the samples that are before the in water time
flags(1:sEnd-1) = flagVal;
  
end
