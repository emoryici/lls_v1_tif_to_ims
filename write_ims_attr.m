function [ outp ] = write_ims_attr( attr_name, attr_value, group_id, format_str )
%WRITE_IMS_ATTR writes HDF5 attribute to group in .ims file indicated by
%the group id
%   Uses c S1 str char formatting to match Imaris ims file char based
%   attributes

attr_dtype = H5T.copy('H5T_C_S1');
attr_plist = H5P.create('H5P_ATTRIBUTE_CREATE');

% if it's not a string and an array, 
if ( ~isa(attr_value, 'char') & (length(attr_value>1) ) )
    attr_str = '';
    for i=1:length(attr_value)
        % space separate with defined format string
        tmpstr = sprintf(format_str,attr_value(i));
        if i==length(attr_value) % don't add space to end
            attr_str = [attr_str tmpstr];
        else
            attr_str = [attr_str tmpstr ' '];
        end
    end
else
    attr_str = sprintf(format_str, attr_value);
end


attr_dspace = H5S.create_simple(1, size(attr_str,2), []);

attr = H5A.create(group_id, attr_name, attr_dtype, attr_dspace, attr_plist);
H5A.write(attr, 'H5ML_DEFAULT', attr_str);


% close everything
H5P.close(attr_plist);
H5S.close(attr_dspace);
H5T.close(attr_dtype);
H5A.close(attr);
end

