function data_res_levels = downsample_sizes(data_dims)
%DOWNSAMPLE  Create (x,y,z) sizes for different resolution levels needed
% output:
%   data_res_levels:    Array of downsized data (res_level,dims) sizes,
%   starting with array index of res_level 1 that corresponds to Resolution
%   Level 0 in the HDF5 file structure
% input:
%   data_dims:          Size array of data (xsize, ysize, zsize)

resize_index = 1;

% fill first res level xyz values
data_res_levels(1,:) = data_dims;
cur_res_x = data_res_levels(resize_index,1);
cur_res_y = data_res_levels(resize_index,2);
cur_res_z = data_res_levels(resize_index,3);

keep_resizing = (cur_res_x*cur_res_y*cur_res_z > 4*1024*1024);
%while ((vLargeImage->GetSizeX())*vLargeImage->GetSizeY()*vLargeImage->GetSizeZ() > 4*1024*1024) 

while keep_resizing
    % get current res level array dimensions
    cur_res_x = data_res_levels(resize_index,1);
    cur_res_y = data_res_levels(resize_index,2);
    cur_res_z = data_res_levels(resize_index,3);
    
    % create booleans for resize needed in each dimension
    
    reduceX = ( 100 * cur_res_x * cur_res_x ) > ( cur_res_y * cur_res_z );
    reduceY = ( 100 * cur_res_y * cur_res_x ) > ( cur_res_x * cur_res_z );
    reduceZ = ( 100 * cur_res_z * cur_res_z ) > ( cur_res_x * cur_res_y );
    
    % create next res level array dimensions
    if reduceX
        data_res_levels(resize_index+1,1) = round(cur_res_x/2);
    else
        data_res_levels(resize_index+1,1) = cur_res_x;
    end
    
    if reduceY
        data_res_levels(resize_index+1,2) = round(cur_res_y/2);
    else
        data_res_levels(resize_index+1,2) = cur_res_y;
    end
    
    if reduceZ
        data_res_levels(resize_index+1,3) = round(cur_res_z/2);
    else
        data_res_levels(resize_index+1,3) = cur_res_z;
    end    

    keep_resizing = (data_res_levels(resize_index+1,1)...
                    *data_res_levels(resize_index+1,2)...
                    *data_res_levels(resize_index+1,3)...
                    > 4*1024*1024);
    resize_index = resize_index + 1;
    
end

%  result = (condition) ? true : false
%  if (condition)
%    result = true;
%  else
%    result = false;
%  endif

%  From Peter Majer @ Bitplane
% 
% while ((vLargeImage->GetSizeX())*vLargeImage->GetSizeY()*vLargeImage->GetSizeZ() > 4*1024*1024) {
% 
%   ++vResolutionIndex;
%   UInt64 vLargeSizeX = vLargeImage->GetSizeX();
%   UInt64 vLargeSizeY = vLargeImage->GetSizeY();
%   UInt64 vLargeSizeZ = vLargeImage->GetSizeZ();
%   bool vReduceZ = (10*vLargeSizeZ)*(10*vLargeSizeZ) > vLargeSizeX*vLargeSizeY;
%   bool vReduceY = (10*vLargeSizeY)*(10*vLargeSizeY) > vLargeSizeX*vLargeSizeZ;
%   bool vReduceX = (10*vLargeSizeX)*(10*vLargeSizeX) > vLargeSizeY*vLargeSizeZ;
%   UInt64 vSmallSizeZ = vReduceZ ? vLargeImage->GetSizeZ()/2 : vLargeImage->GetSizeZ();
%   UInt64 vSmallSizeY = vReduceY ? vLargeImage->GetSizeY()/2 : vLargeImage->GetSizeY();
%   UInt64 vSmallSizeX = vReduceX ? vLargeImage->GetSizeX()/2 : vLargeImage->GetSizeX();
% }
% 
% LargeSize refers to the resolution at the higher resolution level and the Booleans determine whether the next lower level has the same size or is reduced by a factor of 2.
% 
% To give a pyramid example:
% Level 0:  7643x5246x1552
% Level 1: 3821x2632x776
% Level 2: 1910x1316x388
% Level 3: 955x658x194
% Level 4: 477x329x97
% Level 5: 238x164x48