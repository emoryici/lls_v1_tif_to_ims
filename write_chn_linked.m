function write_chn_linked(root_str, path_str, gid, res, tp, chn) 
%WRITE_CHN_LINKED creates an empty group with contents / atrributes linked
%from a given timepoint
%
% root_str:     root string of filename
% path_str:     path string of filename
% gid:          group ID to create channel in
% res:          resolution level
% tp:           timepoint
% chn:          channel number

plist = 'H5P_DEFAULT'; % default property list

%% create channel group
grp_str = ['Channel ' sprintf('%i',chn)];

%lnkd_grp_str = sprintf('DataSet/ResolutionLevel %i/TimePoint %i/Channel %i',res, tp, chn);
lnkd_grp_str = sprintf('DataSet/ResolutionLevel %i/TimePoint 0/Channel %i',res, chn);
disp(['Grp: ' grp_str ' linked to ' lnkd_grp_str]);
%file_str = [path_str root_str sprintf('_tp%04d.ims',tp)]; 
file_str = ['/' root_str sprintf('_tp%04d.ims',tp)];
disp(['File location: ' file_str]);
H5L.create_external(file_str, lnkd_grp_str, gid, grp_str, plist, plist);


end



