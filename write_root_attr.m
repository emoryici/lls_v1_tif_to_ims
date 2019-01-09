function [ err ] = write_root_attr( fid )
%WRITE_ROOT_ATTR writes the standard Imaris 5.5 attributes to the root
% group of the file

% check valid file ID
% if ~H5I.is_valid(fid)
%     err = 1;
%     return
% end
% err = 0;
% 
% %  write the root attributes
% try
%     gid = H5G.open(fid, '/');
% catch
%     err = 1;
%     return
%     %...
% end
% plist = 'H5P_DEFAULT'; % default property list
% gid = H5G.create(fid, '/', plist, plist, plist);
gid = H5G.open(fid, '/');
write_ims_attr('DataSetDirectoryName','DataSet',gid,'%s');
write_ims_attr('DataSetInfoDirectoryName','DataSetInfo',gid,'%s');
write_ims_attr('ImarisDataSet','ImarisDataSet',gid,'%s');
write_ims_attr('ImarisVersion','5.5.0',gid,'%s');
% TODO - rethink, recheck here for linked time series
write_ims_attr('NumberOfDataSets','1',gid,'%s');
write_ims_attr('ThumbnailDirectoryName','Thumbnail',gid,'%s');

end

