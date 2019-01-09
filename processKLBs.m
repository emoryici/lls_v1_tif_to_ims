function err = processKLBs( root )
%PROCESSKLBS pulls settings xml files from root folder from given experiment
% and process into Imaris .ims file.
%
% root:   root folder path string


%%  setup
err = 1;
bytesize = 2;
deflate = 2;

% get datetime string and number from settings file
% this is our t=0
[dt_str,dtn] = get_rec_date(sfile);
% get the parameters from settings file
[ xg_params, zg_params, zp_params, xp_params, roi_rect, nimgs, ...
    nstacks, chns_used, deskew] = getSettingsParams( sfile );
% get number of channels details
[ num_chns, chn_ids ] = chn_details( chns_used );
%  TODO - make checks for zgalvo zstacks instead of x pzt steps
%  - make function to compare which range params are zero
%  - assign to variable, nslices
nslices = xp_params(3); % xp_params(3) is number of steps using X PZT 
% check numbers match up
chk_imgs = nstacks * num_chns * nslices;  
if chk_imgs ~= nimgs
    disp(['Settings file dimensions mismatch: ' sfile]);
    return
end

%%roi_rect:  ROI boundaries left, top, right, bottom;  delta + 1 = px size
xdim = roi_rect(3) - roi_rect(1) + 1;
ydim = roi_rect(4) - roi_rect(2) + 1;  % note down positive image convention

chunk_dims = ones(1,3);
if deskew  %  deskew stretches the data in the y-direction
    um_per_px_z = cosd(58.2) * xp_params(2);  % xp_params(2) is x pzt step size
    skew = ( sind(58.2) * xp_params(2) ) / 0.104;
    ydim_ds = round(( skew * nslices ) + ydim);  % don't lose lines, set them to zero
    dims = [xdim ydim_ds nslices];  % x y z deskewed dimensions
    %chunk_dims = [xdim ydim_ds 2];
else
    dims = [xdim ydim nslices];  % x y z dimensions
    %chunk_dims = [xdim ydim 2];
end
% previously:
chunk_dims = [128 128 4];
for n=1:3
    if dims(n)<chunk_dims(n)
        chunk_dims(n) = dims(n);
    end
end

% get resolution levels dimensions
data_res_levels = downsample_sizes(dims);
for rls = 1:size(data_res_levels,1)
    for dim=1:3
        if data_res_levels(rls,dim)<chunk_dims(dim)
            data_res_levels(rls,dim) = chunk_dims(dim);
        end
    end
end

%  TODO - check here to allow for passing full path vs current path
[pathstr,name,ext] = fileparts(sfile);
if ~isempty(pathstr)
    cd(pathstr);
else
    pathstr = pwd;
end

% get root of all file names; this assumes it's always root_Settings.txt
root_str = replace(name,'_Settings','');

% create/open log file to record processes applied to data set
global logfid;
logfilestr = [root_str '_log.txt'];
logfid = fopen(logfilestr, 'a+');
now_dt = datetime('now','Format','MM/dd/yyyy HH:mm:ss');
fprintf(logfid,'processed=%s\n',now_dt);
fprintf(logfid,'deskew=%i\n',deskew);
fprintf(logfid,'chn_ids=%i %i %i %i\n',chns_used(1),chns_used(2),chns_used(3),chns_used(4));


% create cell array containing cell array of channel root names
% and ims filename, both for that timepoint
file_search_strs = cell(nstacks,2);
for tp = 1:nstacks
    % note, below are match strs for grabbing files
    ch405_str = '';
    ch488_str = '';
    ch560_str = '';
    ch642_str = '';
    chns_cell = {ch405_str,ch488_str,ch560_str,ch642_str};
    for chn =1:num_chns
        chns_cell{chn_ids(chn)} = [root_str sprintf('_ch%d_stack%04d',(chn-1),(tp-1))];
    end
    % ims file string is exact, as we create
    ims_str = [root_str sprintf('_tp%04d.ims',(tp-1))];
    file_search_strs{tp,1} = chns_cell;
    file_search_strs{tp,2} = ims_str;
end





%%  single program multiple data
%use spmd with something like below ; split time points up between workers
try
    spmd% also can use (n) or (m,n) for number n with minimum m
        tps_per_lab = ceil(nstacks / numlabs);
        for idx = 1:tps_per_lab
            tp_idx = labindex + ((idx-1) * numlabs); 
            if tp_idx < (nstacks+1)
                % load, process, etc. and save ims child timepoint
                %disp(tp_idx);
                % record datenum for tp_idx timepoint for header ims post
                % timepoint processing

                tifdata = zeros(xdim,ydim,nslices,num_chns,'uint16');
                for chn = 1:num_chns
                    fstr = file_search_strs{tp_idx,1}{1,chn_ids(chn)};
                    search_str = [pathstr '\' fstr '*'];
                    chnf_struct = dir(search_str);
                    if size(chnf_struct,1)>1 % if dir found more than one file
                        % TODO raise error here
                        disp([search_str ' returned more than one file.']);
                    end

                    fname_str = [pathstr '\' chnf_struct.name];
                    [img, tif_info] = Load_Tiff( fname_str, 'uint16' );
                    % if slices in tif do not match settings
                    if ( size(tif_info,1) ~= nslices ) 
                        %  TODO raise error here
                        disp([chnf_struct.name ' mismatch in slice number.']);
                    end
                    % tifdata(long, short, z, channel)
                    tifdata(:,:,:,chn) = img;
                    % set the first and last 2 columns to 0 to avoid camera issues
                    tifdata(:,1,:,chn) = 0;
                    tifdata(:,2,:,chn) = 0;
                    tifdata(:,ydim-1,:,chn) = 0;
                    tifdata(:,ydim,:,chn) = 0;
                    
                    disp([chnf_struct.name ' loaded.']);

                end
                disp('Deskewing');
                [dsdata, um_per_px_z] = deskew_data(tifdata, xp_params(2));
                disp(['Writing ims timepoint ' num2str(tp_idx)]);
                write_ims_tp(dsdata, data_res_levels, root_str, tp_idx, ...
                             dtn, chns_used, bytesize, um_per_px_z, ...
                             chunk_dims, deflate);
                tifdata = 0;
                dsdata = 0;

            end
        end

    end
catch
    fprintf(logfid,'error=spmd_fail\n');
    disp(['Error in spmd multi-threaded section. Processing ' root_str ' files aborted.']);
    fclose('all');
    return
end

fprintf(logfid,'nstacks_processed=%i\n',nstacks);

%%
% note this is repeat of section in spmd above, with different variables to
% avoid headache
msecs = zeros(nstacks,1);
for tp = 1:nstacks
    % just grab msec times from channel 1
    file_str = file_search_strs{tp,1}{1,chn_ids(1)};
    dir_str = [pathstr '\' file_str '*'];
    file_struct = dir(dir_str);
    if size(file_struct,1)>1 % if dir found more than one file
        % TODO raise error here
        disp([dir_str ' search returned more than one file; post spmd section.']);
    end
    msecs(tp) = getFilenameMsec(file_struct.name);
end

for tp = 1:(nstacks-1)
    msec_delta(tp) = msecs(tp+1) - msecs(tp);
end
msd_mean = mean(msec_delta);
msd_med = median(msec_delta);
if msd_mean ~= msd_med
    disp('Not all time steps the same.  Using median.');
end

dtns = zeros(nstacks,1);
for tp = 1:nstacks
    [ ~, out_dtn ] = add_msec_datetime( dtn, (msd_med.*(tp-1)) );
    dtns(tp) = out_dtn;
end

% TODO - calc um_per_px_z up the top
write_ims_header(root_str, data_res_levels, nstacks, dtns, chns_used, dims, bytesize, um_per_px_z{1});

fprintf(logfid,'header_written=1\n');

% close log file
fclose('all');
err = 0;


end



%%  write all time point .ims files

% below has been inserted into spmd in above function

% % grab data from all channels into dataset array
% tifdata = zeros(xdim,ydim,nslices,num_chns,'uint16');
% for chn = 1:num_chns
%     fstr = file_search_strs{tp,1}{1,chn_ids(chn)};
%     search_str = [pathstr '\' fstr '*'];
%     chnf_struct = dir(search_str);
%     %disp_str = [chnf_struct.name ' found.'];
%     %disp(disp_str);
%     if size(chnf_struct,1)>1 % if dir found more than one file
%         % TODO raise error here
%     end
%     fname_str = [pathstr '\' chnf_struct.name];
%     [img, tif_info] = Load_Tiff( fname_str, 'uint16' );
%     if ( size(tif_info,1) ~= nslices ) % if slices in tif do not match settings
%         %  TODO raise error here
%     end
%     tifdata(:,:,:,chn) = img;
%     disp_str = [chnf_struct.name ' loaded.'];
%     disp(disp_str);
% end
