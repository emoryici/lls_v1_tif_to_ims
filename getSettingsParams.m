function [ xg_params, zg_params, zp_params, xp_params, roi_rect, nimgs, ...
    nstacks, chns_used, deskew] = getSettingsParams( filestr )
%GETSETTINGSPARAMS pulls Offset, Interval (step size), and number
% of pixels (number of steps) from lattice light sheet settings file.
% Returned Variables:
%   xg_params, zg_params, zp_params, xp_params:  array of 3 doubles
%    
%   roi_rect:  ROI boundaries left, top, right, bottom;  delta + 1 = px size
%   nimgs, nstacks: single values
%   chns_used: see function [ num_chns, chn_ids ] = chn_details( chns_used )
%   deskew:  boolean for deskew needed


%% open file and scan to end of Waveform section
sfile = fopen(filestr);

% boolean for while loop
working = 1;
% count for line number
count = 0;
% x & z galvo, z & s piezo, and # of stacks line number
% Note, file uses s for stage, I'm using x
% TODO - revisit if different scan options are available for different
% chns; currently it will grab the last of the group of 1,2,3 or 4 lines
xgal = 0;zgal =0;zpzt = 0;xpzt = 0;ns = 0;
% blank channels used array
chns_used = [0 0 0 0];
% check if deskew is needed
deskew = 0;

while working
    slines = textscan(sfile,'%s',1,'delimiter','\n');
    count = count + 1;
    str = string(slines{1,1});
    
    if contains(str,'X Galvo')
        xgal = count;
        xgal_lstr = str;
    end
    if contains(str,'Z Galvo')
        zgal = count;
        zgal_lstr = str;
    end
    if contains(str,'Z PZT')
        zpzt = count;
        zpzt_lstr = str;
    end
    if contains(str,'S PZT')
        xpzt = count;
        xpzt_lstr = str;
    end
    % TODO - review if interleaved channel acq is used
    if contains(str,'# of stacks')
        ns = count;
        ns_lstr = str;
    end
    if contains(str,'Excitation Filter')
         if contains(str,'405')
             chns_used(1) = 1;
         elseif contains(str,'488')
             chns_used(2) = 1;
         elseif contains(str,'560')
             chns_used(3) = 1;
         elseif contains(str,'642')
             chns_used(4) = 1;
         end
    end
    if contains(str,'Z motion')
        if contains(str,'Sample piezo')
            deskew = 1;
        end
    end
    
    
    
    if contains(str,'FOV ROI')
        roi_lstr = str;
    end
    if contains(str,'# of Imgs')
        nimgs_lstr = str;
    end
    
    
    if contains(str,'Advanced Timing')
        working = 0;
    end
    if count > 1000
        break
    end
end

%textscan(fid, '%s', 1, 'delimiter', '\n', 'headerlines', linenum-1);

% parse lines 9,11, 13, & 15
% x galvo, z galvo, z pzt, & x pzt rspfly
% for offset, range, and steps

% xgal_lstr = string(slines{1,1}(9,1));
% zgal_lstr = string(slines{1,1}(11,1));
% zpzt_lstr = string(slines{1,1}(13,1));
% xpzt_lstr = string(slines{1,1}(15,1));

%  (?<=\t)(\d+(\.\d+)?) matches one or more digits after a tab, with one or
%  more digits of decimal places after that optional
xg_strs = regexp(xgal_lstr, '(?<=\t)(\d+(\.\d+)?)','match');
zg_strs = regexp(zgal_lstr, '(?<=\t)(\d+(\.\d+)?)','match');
zp_strs = regexp(zpzt_lstr, '(?<=\t)(\d+(\.\d+)?)','match');
xp_strs = regexp(xpzt_lstr, '(?<=\t)(\d+(\.\d+)?)','match');
%  (?<=\t)(\d+) matches one or more digits after a tab
nstacks = str2double(regexp(ns_lstr, '(?<=\t)(\d+)','match'));
nimgs = str2double(regexp(nimgs_lstr, '(?<=\t)(\d+)','match'));
%  (?<==)(\d+) matches one of more digits after an equals
% ROIs left, top, right, bottom;  delta + 1 = px size
roi_strs = regexp(roi_lstr, '(?<==)(\d+)','match');

roi_rect = str2double(roi_strs);
xg_params = str2double(xg_strs);
zg_params = str2double(zg_strs);
zp_params = str2double(zp_strs);
xp_params = str2double(xp_strs);


% close file id
fclose(sfile);


end