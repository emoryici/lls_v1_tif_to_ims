function write_ims_header(root_str, data_res_levels, tps, dtns, chns_used, dims, bytesize, um_per_px_z)
%WRITE_IMS_HEADER  Write ims file with full group structure with links

%   root_str:           root name of file
%   data_res_levels:    original and reduced dims for resolution levels
%   tps:                total number of timepoints
%   dtns:               data time number array
%   chns_used:          boolean array for [405nm 488nm 560nm 642nm], e.g. [0 1 0 0] for 488nm only
%   dims:               array of dimensions of data [xsize ysize zsize]
%   bytesize:           data size in bytes, mostly 2 for uint16
%   um_per_px_z:        z step size in microns



%%  open, write, ...
% requires data to be available in workspace ........

%H5.open;

filename = [root_str '_hdr.ims'];
plist = 'H5P_DEFAULT'; % default property list
fcpl = H5P.create('H5P_FILE_CREATE');
fapl = H5P.create('H5P_FILE_ACCESS');

%fid = H5F.create(filename, 'H5F_ACC_TRUNC', plist, plist);
fid = H5F.create(filename, 'H5F_ACC_TRUNC', fcpl, fapl);

path_str = [pwd '\'];

% % write root atributes  %  TODO - check # of images in root attributes
% err = write_root_attr(fid);
% if err
%     % write to log here
%     H5.close;
%     return;
% end

gid = H5G.open(fid, '/');
write_ims_attr('DataSetDirectoryName','DataSet',gid,'%s');
write_ims_attr('DataSetInfoDirectoryName','DataSetInfo',gid,'%s');
write_ims_attr('ImarisDataSet','ImarisDataSet',gid,'%s');
write_ims_attr('ImarisVersion','5.5.0',gid,'%s');
% TODO - rethink, recheck here for linked time series
write_ims_attr('NumberOfDataSets','1',gid,'%s');
write_ims_attr('ThumbnailDirectoryName','Thumbnail',gid,'%s');
H5G.close(gid);

%%  write linked header

% create DataSet
% create all ResolutionLevels
% create all TimePoints
% create all Channels


% write dataset info
write_datasetinfo(dims, fid, chns_used, um_per_px_z, bytesize, dtns, sprintf('%s_hdr', root_str)) ;

%%

% create base dataset group
ds_gid = H5G.create(fid, '/DataSet', plist, plist, plist);

[ num_chns, ~ ] = chn_details( chns_used );

%%

res_levels = size(data_res_levels,1);
for res = 1:res_levels
    
    rl_gid = H5G.create(ds_gid, sprintf('ResolutionLevel %i',(res-1)), plist, plist, plist);
    
    for tp = 1:tps
        
        tp_gid = H5G.create(rl_gid, sprintf('TimePoint %i',(tp-1)), plist, plist, plist);
        
        for chn = 1:num_chns
            
            write_chn_linked(root_str, path_str, tp_gid, (res-1), (tp-1), (chn-1));  %  create Channels as linked
            
        end
        
    end
    
end


%% close things
H5G.close(ds_gid);
H5G.close(rl_gid);
H5G.close(tp_gid);
H5F.close(fid);

%H5.close;



end
