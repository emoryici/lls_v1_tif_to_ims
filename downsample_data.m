function resample_data = downsample_data(data, new_dims)
%DOWNSAMPLE  downsample data into resample_data for all chns
%   resample_data:      Array of downsized data (new_dims,chns)
% input:
%   data:               input raw data (x,y,z,chns)
%   new_dims:           x,y,z dimensions to resample to


num_chns = size(data,4);
nx = new_dims(1); % desired output dimensions
ny = new_dims(2);
nz = new_dims(3);
[y, x, z] = ndgrid(linspace(1,size(data,1),nx),...
                 linspace(1,size(data,2),ny),...
                 linspace(1,size(data,3),nz));

resample_data = zeros(nx,ny,nz,num_chns);

for chn = 1:num_chns
    resample_data(:,:,:,chn) = interp3(double(data(:,:,:,chn)),x,y,z);
end

end