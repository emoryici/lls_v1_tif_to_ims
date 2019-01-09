function [ msec ] = getFilenameMsec ( filename_str )
% grab msec time from filename_str

% get first msec time values, any number of digits before 'msec'
msec_strs = regexp(filename_str, '[0-9]+(?=msec)','match');
msec = str2double(msec_strs(1,1));

end