% =============================================================================
% Author: Christian Danilo Arroyo Herrera
% Module: Computer Vision (CMP9135) — University of Lincoln, School of Computer Science
% Assessment: 2 | Academic Year 2025/2026
% This code is the author's own original work submitted as a university assessment.
% AUTHOR_FINGERPRINT: Q2hyaXN0aWFuIERhbmlsbyBBcnJveW8gSGVycmVyYXxjYXJyb3lvaGVycmVyYUBnbWFpbC5jb20=
% =============================================================================

clear; close all; clc;

image_list = dir("parachute/images/*.png");
mask_list  = dir("parachute/GT/*.png");

if isempty(image_list)
    error("Could not find images. Check your folder path.");
end

num_images = length(image_list);

shape_features = zeros(num_images, 4);
hog_features = zeros(num_images, 4);

for i = 1:num_images
    img = imread(fullfile("parachute/images", image_list(i).name));
    mask = imread(fullfile("parachute/GT",  mask_list(i).name));
    
    if size(mask, 3) == 3
        bw_mask = im2gray(mask) > 0;
    else
        bw_mask = mask > 0;
    end
    
    stats = regionprops(bw_mask, 'Area', 'Perimeter', 'ConvexArea', 'Eccentricity');
    
    if length(stats) > 1
        [~, max_idx] = max([stats.Area]);
        stats = stats(max_idx);
    end
    
    Area = stats.Area;
    Perimeter = stats.Perimeter;
    ConvexArea = stats.ConvexArea;
    
    solidity = Area / ConvexArea;
    non_compactness = (Perimeter^2) / Area;
    circularity = (4 * pi * Area) / (Perimeter^2);
    eccentricity = stats.Eccentricity;
    
    shape_features(i, :) = [solidity, non_compactness, circularity, eccentricity];
    
    gray_img = im2double(rgb2gray(img));
    parachute_pixels = gray_img .* bw_mask;
    
    [Gmag, Gdir] = imgradient(parachute_pixels);
    
    Gdir(Gdir < 0) = Gdir(Gdir < 0) + 180;
    
    bin_0   = sum(Gmag((Gdir >= 0 & Gdir < 22.5) | Gdir >= 157.5));
    bin_45  = sum(Gmag(Gdir >= 22.5 & Gdir < 67.5));
    bin_90  = sum(Gmag(Gdir >= 67.5 & Gdir < 112.5));
    bin_135 = sum(Gmag(Gdir >= 112.5 & Gdir < 157.5));
    
    h = [bin_0, bin_45, bin_90, bin_135];
    hog_features(i, :) = h / (norm(h) + eps); 
end

frames = 1:num_images;

figure('Name', 'Shape Features Over Time', 'Position', [100, 100, 900, 600]);
subplot(2,2,1); plot(frames, shape_features(:,1), '-o', 'LineWidth', 1.5); 
title('Solidity'); xlabel('Frame'); ylabel('Value'); grid on;

subplot(2,2,2); plot(frames, shape_features(:,2), '-x', 'LineWidth', 1.5, 'Color', 'r'); 
title('Non-compactness'); xlabel('Frame'); ylabel('P^2 / A'); grid on;

subplot(2,2,3); plot(frames, shape_features(:,3), '-s', 'LineWidth', 1.5, 'Color', 'g'); 
title('Circularity'); xlabel('Frame'); ylabel('4\pi A / P^2'); grid on;

subplot(2,2,4); plot(frames, shape_features(:,4), '-d', 'LineWidth', 1.5, 'Color', 'm'); 
title('Eccentricity'); xlabel('Frame'); ylabel('Value'); grid on;

figure('Name', 'HoG Features Over Time', 'Position', [150, 150, 900, 600]);
subplot(2,2,1); plot(frames, hog_features(:,1), '-o', 'LineWidth', 1.5); 
title('HoG: 0^{\circ} (Horizontal)'); xlabel('Frame'); ylabel('Normalized Magnitude'); grid on;

subplot(2,2,2); plot(frames, hog_features(:,2), '-x', 'LineWidth', 1.5, 'Color', 'r'); 
title('HoG: 45^{\circ}'); xlabel('Frame'); ylabel('Normalized Magnitude'); grid on;

subplot(2,2,3); plot(frames, hog_features(:,3), '-s', 'LineWidth', 1.5, 'Color', 'g'); 
title('HoG: 90^{\circ} (Vertical)'); xlabel('Frame'); ylabel('Normalized Magnitude'); grid on;

subplot(2,2,4); plot(frames, hog_features(:,4), '-d', 'LineWidth', 1.5, 'Color', 'm'); 
title('HoG: 135^{\circ}'); xlabel('Frame'); ylabel('Normalized Magnitude'); grid on;