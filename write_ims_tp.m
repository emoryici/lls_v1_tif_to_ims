function write_ims_tp(data, data_res_levels, root_str, tp, dtn, chns_used, bytesize, um_per_px_z, chunk_dims, deflate)
%WRITE_IMS_DATA  Write data to .ims file
%   data:               4D array of data to write to file, dims (x;y;z;chn)
%   data_res_levels:    array of sizes for downsampling, starting with the
%                       original: (res_level, x;y;z)
%   root_str:           root name of file
%   tp:                 time point index, or series index
%   dtn:                data time number, called datenum elsewhere
%   chns_used:          boolean array for [405nm 488nm 560nm 642nm],
%                       e.g. [0 1 0 0] for 488nm only
%   bytesize:           data size in bytes, mostly 2 for uint16
%   um_per_px_z:        z step size in microns
%   chunk_dims:         array of [x y z] chunk sizes, try [64 64 4] for now
%   deflate:            gzip deflate value, 0-9 where 0 is no compression


%%  open, write, ...
% requires data to be available in workspace ........

%H5.open;
%err = 0;
file_str = [root_str sprintf('_tp%04d.ims',(tp-1))];
plist = 'H5P_DEFAULT'; % default property list

fcpl = H5P.create('H5P_FILE_CREATE');
fapl = H5P.create('H5P_FILE_ACCESS');

% % check valid file ID
% if H5I.is_valid(fid)
%     H5F.close(fid);
% end

%fid = H5F.create(file_str, 'H5F_ACC_TRUNC', plist, plist);
fid = H5F.create(file_str, 'H5F_ACC_TRUNC', fcpl, fapl);

% write root atributes
%write_root_attr(fid);
% if err
%     % write to log here
%     H5F.close(fid);
%     err = 1;
%     %H5.close;
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


%% write channel group structure and data

% pass concatenated channel data in 4th dim. i.e data(:,:,:,chns)
% if single channel below = 1
num_chns = size(data,4);

% create base dataset group
ds_gid = H5G.create(fid, '/DataSet', plist, plist, plist);

% write resolution level 0
% note, "/" starts from root, and without assumes current group
rl_gid = H5G.create(ds_gid, 'ResolutionLevel 0', plist, plist, plist);
tp_gid = H5G.create(rl_gid, 'TimePoint 0', plist, plist, plist);
% Note: each individual file is tp0 only, the header will have all tps
for chn = 1:num_chns
    ch_gid = write_chn(data(:,:,:,chn), chunk_dims, deflate,...
                       tp_gid, (chn-1), bytesize); 
end

% downsample and write resolution levels
num_levels = size(data_res_levels,1);

if num_levels > 1
    % data_res_levels contains the original in row 1, and the first
    % reduction in row 2, hence the varied n and n+1 or n-1 indicies
    for level = 1:(num_levels-1)  
        % write resolution levels and time point 0
        % note, "/" starts from root, and without assumes current group
        rl_gid = H5G.create(ds_gid, sprintf('ResolutionLevel %i',level),...
                            plist, plist, plist);
        tp_gid = H5G.create(rl_gid, 'TimePoint 0', plist, plist, plist);
        % reset, and then create temp downsampled data set
        data_out = [];
        data_out = uint16(downsample_data(data, data_res_levels(level+1,:)));
        for chn = 1:num_chns
            ch_gid = write_chn(data_out(:,:,:,chn), chunk_dims, deflate,...
                               tp_gid, (chn-1), bytesize); 
        end
        
    end
           
end


%% write datasetinfo
ftitle_str = sprintf('%s_tp%04d',root_str,tp);
write_datasetinfo(size(data), fid, chns_used, um_per_px_z, bytesize,...
    dtn, ftitle_str);
% note, omitted .ims from title

%% close things
H5G.close(ds_gid);
H5G.close(rl_gid);
H5G.close(tp_gid);
H5G.close(ch_gid);
H5F.close(fid);

%H5.close;



end
