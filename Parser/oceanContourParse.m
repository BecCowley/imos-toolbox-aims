function [sample_data] = oceanContourParser(filename_in_cell, toolbox_mode)
% function [data] = oceanContourParser(filename_in_cell, toolbox_mode)
%
% The OceanContour Parser for netcdf or mat files.
%
% Inputs:
%
% filename [cell[str]] - A cell containing one filename string.
% toolbox_mode [str] - the processing mode string.
%                    Default: 'timeSeries'
%
% Outputs:
%
% sample_data - toolbox struct containing the data.
%
% Example:
%
% % this is a wrapper,
% % check the `OceanContour.readOceanContourFile`
% % docstring for tests.
%
% author: hugo.oliveira@utas.edu.au
%
narginchk(1, 2)

invalid_file_arg = ~iscellstr(filename_in_cell) && length(filename_in_cell) ~= 1;

if invalid_file_arg
    errormsg('First argument file isn''t a singleton cell of strings')
end

filename = filename_in_cell{1};
inexistent_file = isempty(dir(filename));

if inexistent_file
    errormsg('file %s doesn''t exist', filename)
end

% returns cell array
sample_data = OceanContour.readOceanContourFile(filename);

[filePath, fileRadName, ~] = fileparts(filename);
waveFile = fullfile(filePath, [fileRadName '_waves.nc']);
isWaveData = exist(filename, 'file') && exist(waveFile, 'file');

if isWaveData
%       % turn sample data into a cell array
%       temp{1} = sample_data;
%       sample_data = temp;
%       clear temp;
      
      sample_data = [sample_data, OceanContourWaves.readOceanContourFile(waveFile)];
end

end
