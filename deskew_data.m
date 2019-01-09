function [ deskewed, um_per_px_z ] = deskew_data( data, xpzt_step )
%DESKEW_DATA Shear transform for LLS X PZT scan data sets
% deskews input data according to parameters of x step size
% deskew_data:      resulting deskewed result
% data:             input data, can be 3 or 4D
% xpzt_step:        stage x step size in microns
% ...

% set the skew amount
um_per_px_z = cosd(58.2) * xpzt_step;
%skew = um_per_px_z / 0.104;
skew = ( sind(58.2) * xpzt_step ) / 0.104;
tform = affine3d([1 0 0 0; 0 1 0 0; skew 0 1 0; 0 0 0 1]);  %  skew in
%sh coord x movement z
%tform = affine3d([1 0 0 0; 0 1 skew 0; 0 0 1 0; 0 0 0 1]);  %  skew in
%sh coord z movement y

if ndims(data) > 3
    % deskew channel by channel
    num_chns = size(data,4);
    for chn = 1:num_chns
        deskewed(:,:,:,chn) = imwarp(data(:,:,:,chn),tform,'FillValues',0);
    end        
else
    % just deskew  %  TODO - add checks for wrong data 
    deskewed = imwarp(data,tform,'FillValues',0);
end

end

