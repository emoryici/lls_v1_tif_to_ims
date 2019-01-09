function write_datasetinfo(dims, fid, chns_used, um_per_px_z, bytesize, dtn, ftitle_str) 
%WRITE_DATASETINFO  writes metadata to ims file
% dims:         array of dimensions of data [xsize ysize zsize] to be written
% fid:          file ID from HDF5 create
% chns_used:    boolean array for [405nm 488nm 560nm 642nm], e.g. [0 1 0 0] for 488nm only
% zstep_um:     z step size in microns
% dtn(s):       datetimenumber (array) that will formatted to 'yyyy-mm-dd HH:MM:SS.FFF'
% tp:           time point for Imaris title name
% ftitle_str:   pre formatted ims filename string for title shown in Imaris

% get number or channels and array of channel ids, e.g. chn_ids = [ 2 4 ] for 488 and 642
[num_chns, chn_ids] = chn_details( chns_used );

%  blue, green, red, magenta color codes
blu_col = [0.0 0.0 1.0];
grn_col = [0.0 1.0 0.0];
red_col = [1.0 0.0 0.0];
mgt_col = [1.0 0.0 1.0];
% into their own array rgbs -> 4x3 double
rgbs = vertcat(blu_col,grn_col,red_col,mgt_col);
% channel names becomes cell array
chn_names = {'405nm','488nm','560nm','642nm'};
% guessing on range for average experiment
col_range = [100 1500];

% setup xyz parameters
xsize = dims(1);
ysize = dims(2);
zsize = dims(3);
um_per_px_xy = 0.104;


%% DataSetInfo
plist = 'H5P_DEFAULT'; % default property list
gid = H5G.create(fid, '/DataSetInfo', plist, plist, plist);

% BytesInc notes:
% Channel (n) attribute -> bytesinc is n*x*y*bitsize
% where n is 0 -> N-1
% Dimension X attribute -> byteinc is bitsize
% Dimension Y attribute -> byteinc is x*bitsize
% Dimension Z attribute -> byteinc is x*y*bitsize*N

% ??? single channel time lapse v8.4 saved dataset has no Dim x,y,z and no
% byteinc in channel 0

% create channels
for c = 0:num_chns-1
    grpStr = sprintf('/DataSetInfo/Channel %i', c);
    gid = H5G.create(fid, grpStr, plist, plist, plist);
    write_ims_attr('ColorMode','BaseColor',gid,'%s');
    write_ims_attr('ColorOpacity',1.0,gid,'%.3f');
    write_ims_attr('ColorRange',col_range,gid,'%.3f');
    % write_ims_attr('Name','488nm',gid,'%s'); becomes:
    write_ims_attr('Name',char(chn_names(chn_ids(c+1))),gid,'%s');
    % write_ims_attr('Color',grn_col,gid,'%.3f'); becomes
    write_ims_attr('Color',rgbs(chn_ids(c+1),:),gid,'%.3f');
    write_ims_attr('Min',0.0,gid,'%.6e');
    % max for bytesize, e.g. 2 bytes -> 16 bit
    write_ims_attr('Max',((2.^(bytesize*8))-1),gid,'%.6e');
end

% create x,y,z dimensions
gid = H5G.create(fid, '/DataSetInfo/Dimension X', plist, plist, plist);
write_ims_attr('BytesInc',bytesize,gid,'%i');
write_ims_attr('DimID',1,gid,'%i');
write_ims_attr('NumbersOfElements',xsize,gid,'%i');
write_ims_attr('Origin',0,gid,'%.6e');
write_ims_attr('Length',(xsize.*um_per_px_xy),gid,'%.6e');
% TODO - check if um, or change to m required
write_ims_attr('Unit','um',gid,'%s');

gid = H5G.create(fid, '/DataSetInfo/Dimension Y', plist, plist, plist);
write_ims_attr('BytesInc',(bytesize.*xsize),gid,'%i');
write_ims_attr('DimID',2,gid,'%i');
write_ims_attr('NumbersOfElements',ysize,gid,'%i');
write_ims_attr('Origin',0,gid,'%.6e');
write_ims_attr('Length',(ysize.*um_per_px_xy),gid,'%.6e');
% TODO - check if um, or change to m required
write_ims_attr('Unit','um',gid,'%s');

gid = H5G.create(fid, '/DataSetInfo/Dimension Z', plist, plist, plist);
write_ims_attr('BytesInc',(bytesize.*xsize.*ysize.*num_chns),gid,'%i');
write_ims_attr('DimID',3,gid,'%i');
write_ims_attr('NumbersOfElements',zsize,gid,'%i');
write_ims_attr('Origin',0,gid,'%.6e');
write_ims_attr('Length',(zsize.*um_per_px_z),gid,'%.6e');
% TODO - check if um, or change to m required
write_ims_attr('Unit','um',gid,'%s');

% Image
gid = H5G.create(fid, '/DataSetInfo/Image', plist, plist, plist);
write_ims_attr('Noc',num_chns,gid,'%i');
write_ims_attr('Unit','micron',gid,'%s');
write_ims_attr('X',xsize,gid,'%i');
write_ims_attr('Y',ysize,gid,'%i');
write_ims_attr('Z',zsize,gid,'%i');

recdate = datestr(dtn(1), 'yyyy-mm-dd HH:MM:SS.FFF');
write_ims_attr('RecordingDate',recdate,gid,'%s');
write_ims_attr('ExtMin0',0,gid,'%0.3f');
write_ims_attr('ExtMin1',0,gid,'%0.3f');
write_ims_attr('ExtMin2',0,gid,'%0.3f');
write_ims_attr('ExtMax0',(xsize.*um_per_px_xy),gid,'%0.3f');
write_ims_attr('ExtMax1',(ysize.*um_per_px_xy),gid,'%0.3f');
write_ims_attr('ExtMax2',(zsize.*um_per_px_z),gid,'%0.3f');
write_ims_attr('Name',ftitle_str,gid,'%s');

% Imaris
gid = H5G.create(fid, '/DataSetInfo/Imaris', plist, plist, plist);
write_ims_attr('ThumbnailMode','thumbnailMIP',gid,'%s');
write_ims_attr('ThumbnailSize',256,gid,'%i');
write_ims_attr('Version',8.4,gid,'%0.1f');

% ImarisDataSet
gid = H5G.create(fid, '/DataSetInfo/ImarisDataSet', plist, plist, plist);
write_ims_attr('Creator','Imaris x64',gid,'%s');
% TODO - check num of images for time lapse
write_ims_attr('NumberOfImages',1,gid,'%i');
write_ims_attr('Version',8.4,gid,'%0.1f');

dtn_len = length(dtn);
if dtn_len > 1
    % ImarisDataSet
    gid = H5G.create(fid, '/DataSetInfo/TimeInfo', plist, plist, plist);
    write_ims_attr('DatasetTimePoints',dtn_len,gid,'%i');
    write_ims_attr('FileTimePoints',dtn_len,gid,'%i');
    for tp = 1:dtn_len
        dt_str = datestr(dtn(tp), 'yyyy-mm-dd HH:MM:SS.FFF');
        write_ims_attr(sprintf('TimePoint%i',tp),dt_str,gid,'%s');
    end
end

end



