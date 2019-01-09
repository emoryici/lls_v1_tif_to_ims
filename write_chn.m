function [ ch_gid ] = write_chn(data, chunk_dims, deflate, gid, chn, bytesize) 
%WRITE_CHN creates groups, writes attributes and data
% data:         3D data array to be written
% chunk_dims:   dimensions, [cx cy cz] of each chunk to be written
% deflate:      sets the gzip compression amount, higher is more
% gid:          group ID to create channel in
% chn:          channel number
% bytesize:     8 or 16 bit option


plist = 'H5P_DEFAULT'; % default property list
dims = size(data); % array of dimensions of data [xsize ysize zsize]

%% create channel group
% was from root, changed to relative from passed gid param
%grp_str = ['/DataSet/ResolutionLevel ' sprintf('%i',res) ...
%    '/TimePoint ' sprintf('%i',tp) '/Channel ' sprintf('%i',chn)];
grp_str = ['Channel ' sprintf('%i',chn)];
ch_gid = H5G.create(gid, grp_str, plist, plist, plist);


%% write attributes
% histogram min and max
write_ims_attr('HistogramMin',0.0,ch_gid,'%0.3f');
% max for bytesize, e.g. 2 bytes -> 16 bit
write_ims_attr('HistogramMax',((2.^(bytesize*8))-1),ch_gid,'%0.3f');
% image dimensions
write_ims_attr('ImageSizeX',dims(1),ch_gid,'%i');
write_ims_attr('ImageSizeY',dims(2),ch_gid,'%i');
write_ims_attr('ImageSizeZ',dims(3),ch_gid,'%i');


%%  write data
dtype = H5T.copy('H5T_NATIVE_USHORT');
dspace = H5S.create_simple(3, fliplr(dims), []);
dplist = H5P.create('H5P_DATASET_CREATE');
h5_chunk_dims = fliplr(chunk_dims);
H5P.set_chunk(dplist,h5_chunk_dims);
H5P.set_deflate(dplist,deflate);
dsetname = 'Data';
%dset = H5D.create(ch_gid, dsetname, dtype, dspace, plist);
dset = H5D.create(ch_gid, dsetname, dtype, dspace, dplist);
H5D.write(dset, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', plist, data);


%%  create and write histogram
[hst,~] = histcounts(data,2.^(bytesize*8),'BinMethod','integers');
dathst = uint64(hst.');
dtype = H5T.copy('H5T_NATIVE_ULLONG');
dspace = H5S.create_simple(1, length(dathst), []);
dsetname = 'Histogram';
dset = H5D.create(ch_gid, dsetname, dtype, dspace, plist);
H5D.write(dset, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', plist, dathst);


%% close everything
H5T.close(dtype);
H5S.close(dspace);
H5P.close(dplist);
H5D.close(dset);

end



