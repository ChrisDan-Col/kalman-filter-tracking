% =============================================================================
% Author: Christian Danilo Arroyo Herrera
% Module: Computer Vision (CMP9135) — University of Lincoln, School of Computer Science
% Assessment: 2 | Academic Year 2025/2026
% This code is the author's own original work submitted as a university assessment.
% AUTHOR_FINGERPRINT: Q2hyaXN0aWFuIERhbmlsbyBBcnJveW8gSGVycmVyYXxjYXJyb3lvaGVycmVyYUBnbWFpbC5jb20=
% =============================================================================

clear; close all; clc;

mask_list = dir("parachute/GT/*.png");
num_images = length(mask_list);

if isempty(mask_list)
    error("Could not find images. Check your folder path.");
end

gt_cx = zeros(num_images, 1);
gt_cy = zeros(num_images, 1);
gt_theta = zeros(num_images, 1);

prev_angle = 0;
for i = 1:num_images
    mask = imread(fullfile("parachute/GT", mask_list(i).name));
    if size(mask, 3) == 3
        bw_mask = im2gray(mask) > 0;
    else
        bw_mask = mask > 0;
    end
    
    stats = regionprops(bw_mask, 'Centroid', 'Orientation');
    if ~isempty(stats)
        if length(stats) > 1, stats = stats(1); end
        
        gt_cx(i) = stats.Centroid(1);
        gt_cy(i) = stats.Centroid(2);
        
        current_angle = stats.Orientation;
        if i > 1
            delta = current_angle - prev_angle;
            if delta > 90
                current_angle = current_angle - 180;
            elseif delta < -90
                current_angle = current_angle + 180;
            end
        end
        gt_theta(i) = current_angle;
        prev_angle = current_angle;
    end
end

dt = 1; 

F_trans = [1 0 dt 0; 0 1 0 dt; 0 0 1 0; 0 0 0 1];
Q_trans = [0.1 0 0 0; 0 0.1 0 0; 0 0 2 0; 0 0 0 2]; 
H_trans = [1 0 0 0; 0 1 0 0];
R_trans = [5 0; 0 5];

x_trans = [gt_cx(1); gt_cy(1); 0; 0];
P_trans = Q_trans;

F_rot = [1 dt; 0 1];
Q_rot = [0.1 0; 0 0.5]; 
H_rot = [1 0];
R_rot = 2;              

x_rot = [gt_theta(1); 0];
P_rot = Q_rot;            

kf_cx = zeros(num_images, 1);
kf_cy = zeros(num_images, 1);
kf_theta = zeros(num_images, 1);

train_frames = 41;
test_frames = 10;

for i = 1:num_images
    [xp_trans, Pp_trans] = kalmanPredict(x_trans, P_trans, F_trans, Q_trans);
    [xp_rot, Pp_rot]     = kalmanPredict(x_rot, P_rot, F_rot, Q_rot);
    
    if i <= train_frames
        z_trans = [gt_cx(i); gt_cy(i)];
        z_rot = gt_theta(i);
        
        [x_trans, P_trans] = kalmanUpdate(xp_trans, Pp_trans, H_trans, R_trans, z_trans);
        [x_rot, P_rot]     = kalmanUpdate(xp_rot, Pp_rot, H_rot, R_rot, z_rot);
    else
        x_trans = xp_trans;
        P_trans = Pp_trans;
        x_rot = xp_rot;
        P_rot = Pp_rot;
    end
    
    kf_cx(i) = x_trans(1);
    kf_cy(i) = x_trans(2);
    kf_theta(i) = x_rot(1);
end

fprintf('\n Prediction Errors (Frames 41 to 50) \n');
fprintf('Frame | Trans Error (px) | Rot Error (deg)\n');

trans_errors = zeros(test_frames, 1);
rot_errors = zeros(test_frames, 1);
test_indices = (train_frames + 1):num_images;

for i = 1:test_frames
    idx = test_indices(i);
    
    e_pos = sqrt((kf_cx(idx) - gt_cx(idx))^2 + (kf_cy(idx) - gt_cy(idx))^2);
    
    dTheta = kf_theta(idx) - gt_theta(idx);
    e_theta = min(abs(dTheta), 180 - abs(dTheta));
    
    trans_errors(i) = e_pos;
    rot_errors(i) = e_theta;
    
    fprintf('  %02d  |      %7.2f     |     %7.2f\n', idx-1, e_pos, e_theta);
end

figure('Name', '2D translation tracking', 'Position', [100, 100, 700, 500]);
plot(gt_cx, gt_cy, 'b-', 'LineWidth', 2); hold on;
plot(kf_cx(1:train_frames), kf_cy(1:train_frames), 'g--', 'LineWidth', 2);
plot(kf_cx(test_indices), kf_cy(test_indices), 'r--', 'LineWidth', 2);
scatter(gt_cx(test_indices), gt_cy(test_indices), 40, 'b', 'filled');
set(gca, 'YDir','reverse');
title('Parachute translation trajectory');
xlabel('X Position (px)'); ylabel('Y Position (px)');
legend('Ground Truth', 'Kalman (training)', 'Kalman (prediction)', 'GT test points', 'Location', 'best');
grid on;

figure('Name', 'Rotation tracking', 'Position', [150, 150, 700, 400]);
plot(1:num_images, gt_theta, 'b-', 'LineWidth', 2); hold on;
plot(1:train_frames, kf_theta(1:train_frames), 'g--', 'LineWidth', 2);
plot(test_indices, kf_theta(test_indices), 'r--', 'LineWidth', 2);
title('Parachute orientation tracking');
xlabel('Frame Index'); ylabel('Angle (degrees)');
legend('Ground Truth', 'Kalman (training)', 'Kalman (prediction)', 'Location', 'best');
grid on;

figure('Name', 'Translation error', 'Position', [200, 200, 600, 350]);
bar(41:50, trans_errors, 'FaceColor', [0.8 0.2 0.2]);
title('Translation error for predicted frames'); 
xlabel('Frame index'); ylabel('Error (pixels)'); 
grid on;

figure('Name', 'Rotation error', 'Position', [250, 250, 600, 350]);
bar(41:50, rot_errors, 'FaceColor', [0.2 0.6 0.8]);
title('Rotation error for predicted frames'); 
xlabel('Frame index'); ylabel('Error (degrees)'); 
grid on;