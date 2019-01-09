function errs = grabLLSfiles()
%GRABLLSFILES  simple file select add to process LLS data


%% Get settings file to pass to process function
[filename, pathname, ~] = uigetfile(...
    { '*.txt','Text files (*.txt)'},...
    'Select LLS settings text file to process...', 'S:\Scratch User Data',...
    'MultiSelect', 'on');

if (~iscell(filename))
    if (filename == 0)  % cancel or dialog kill
        return
    end
    % convert string to cell
    % uigetfile returns string on single file selction
    filename = cellstr(filename);
end

for i = 1:length(filename)
    errs(i) = processLLSimgs([pathname char(filename{1,i})]);
end

end

