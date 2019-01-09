function [ dt_str, out_dtn ] = add_msec_datetime( in_dtn, msec )
% FORMAT_TOPDOWN_DATETIME
% format string as yyyy-mm-dd hh:mm:ss.msec 24hr clock
% input:
%   datetime number, msec value to be added
% output:
%   new datetime string and datetime number

out_dtn = in_dtn + (double(msec)/(86400*1e3)); % daily fractional; 60x60x24 = 86400
dt_str = datestr(out_dtn, 'yyyy-mm-dd HH:MM:SS.FFF');

end

