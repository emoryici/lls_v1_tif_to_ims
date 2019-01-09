function [ dt_str, dtn ] = get_rec_date( filenamepath )
%GET_REC_DATE pulls the creation date from filenamepath
%   filenamepath is full filename and path to file
%   
%   outstr formatted yyyy-mm-dd HH:MM:SS.FFF
%   dtn is datetime number

% get file create details
% use first file create date - assuming 0 seconds into minute
% add msec from filename to this starting point

% get file create date time from Win DOS command
[status, cmdout] = dos(['dir "' filenamepath '"']);
monthday = regexp(cmdout,'[0-9]{2}(?=/)','match');
year = regexp(cmdout,'(?<=/)[0-9]{4}','match');
hour = regexp(cmdout,'[0-9]{2}(?=:)','match');
min = regexp(cmdout,'(?<=:)[0-9]{2}','match');
ampm = regexp(cmdout,'(?<=\s)(A|P)M','match');
% "YYYY-MM-DD HH:MM:SS”, note: 24hr
hr = str2num(char(hour));
if strcmp(cellstr(ampm),'PM')
    if hr ~= 12
        hr = hr + 12;
    end
else
    if hr == 12
        hr = 0;
    end
end
hour = sprintf('%02d',round(hr));
dt_str = [char(year) '-' char(monthday(1)) '-' char(monthday(2)) ' ' ...
char(hour) ':' char(min) ':00.000'];
dtn = datenum(dt_str);

end

