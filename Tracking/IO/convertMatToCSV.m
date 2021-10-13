function convertMatToCSV(mat_file_path, output_path, input_Hz, output_Hz, beltBordersX, beltBordersY, NaN_value)
% @author Jakob Thumm jakob.thumm@student.kit.edu
% @date 2020
% 1) Read in mat file from mat_file_path
% 1.1) Replace out of bounds values with [NaN_value] if argument is given.
% 2) Downsample the data from input_Hz to output_Hz
% 3) Save the data to a csv file in output_path
% The output file name will be [mat_file_name]_[outputHz]Hz.csv
% output_Hz is an optional parameter. Leave it out to ignore
%   downsampling.
% replace_NaN_value is an optional parameter.
arguments
    mat_file_path char
    output_path char
    input_Hz int32
    output_Hz int32 = input_Hz
    beltBordersX (1, 2) double = [0.388, 0.788]
    beltBordersY (1, 2) double = [0, 0.18]
    NaN_value (1, 1) double = NaN
end

if ~exist(output_path, 'dir')
    mkdir(output_path);
end

assert(input_Hz >= output_Hz)
downSamplyBy = round(input_Hz/output_Hz);
output_Hz = input_Hz / downSamplyBy;

[~, filename, ~] = fileparts(mat_file_path);
% Load mat file
mat = load(mat_file_path);
gt_x_y_vx_vy = getfield(mat, string(fieldnames(mat)));

sz = size(gt_x_y_vx_vy);
% Downsample
gt_x_y_vx_vy = gt_x_y_vx_vy(:, 1:downSamplyBy:sz(2), :);
% Check for every particle position if it is on belt
on_belt = gt_x_y_vx_vy(1, :, :) > beltBordersX(1) ...
    & gt_x_y_vx_vy(1, :, :) < beltBordersX(2) ...
    & gt_x_y_vx_vy(2, :, :) > beltBordersY(1) ...
    & gt_x_y_vx_vy(2, :, :) < beltBordersY(2);
% Find first and last time step where there is a particle on the belt
one_on_belt = any(on_belt, 3);
first_valid = find(one_on_belt, 1);
last_valid = find(one_on_belt, 1, 'last');
% Replace the positions where the particle is not on the belt with NaN
gt_x_y_vx_vy(:, ~on_belt) = NaN_value;
% Reduce the data to first and last time step
gt_x_y_vx_vy = gt_x_y_vx_vy(:, first_valid:last_valid, :);
sz = size(gt_x_y_vx_vy);

% Transform to 2D table
x = gt_x_y_vx_vy(1, :, :);
y = gt_x_y_vx_vy(2, :, :);

output_table = zeros(sz(2), sz(3)*2);
x_indices = 1:2:(sz(3) * 2);
y_indices = 2:2:(sz(3) * 2);
output_table(:, x_indices) = x;
output_table(:, y_indices) = y;

filename = filename + "_" + num2str(output_Hz) + "Hz";
% Create header
header = "";
header_format_x = 'TrackID_%d_X';
header_format_y = 'TrackID_%d_Y';
for i = 1:sz(3)
    header = header + sprintf(header_format_x, i) + ", ";
    header = header + sprintf(header_format_y, i) + ", ";
end
header = char(header);
header = header(1:(end -1));
% Save file
filename = filename + ".csv";
output_file = output_path + filename;
% write header to file
fid = fopen(output_file, 'w');
fprintf(fid, '%s\n', header);
fclose(fid);
%write data to end of file
writematrix(output_table, output_file, 'WriteMode', 'append');
end
