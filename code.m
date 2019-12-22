clear; close all; clc;

load FacesAndEmotions;
windows_size = [0.3 0.1 0.4 0.9];

%% - Fix image sizes & subplot loop, add comments, verify magic numbers in case#

%% 1. Plot original images
% Create a figure titled 'Faces (original)' with the 80 faces
%   (look at the picture in the word document)
fig1=figure('Name','Faces (original)');
set(fig1, 'Color','w','MenuBar','none');
set(fig1, 'units', 'normalized', 'OuterPosition', windows_size)

% Plot all images
grid_dim = ceil(sqrt(P));
for i = 1 : P  
  subplot(grid_dim,grid_dim,i);
  imagesc(Images(:,:,i));
  title("#"+i);
  axis equal; axis off;
end
colormap(gray);



%% 2. Preform PCA

% Reshape the images matrix into vectors, calculate and substract the mean
images_vecs = reshape(Images,N,P);
avg_image_vec = mean(images_vecs,2);
variance_mat = images_vecs-avg_image_vec;
% Get covariance matrix
denom = P-1;
images_Cov = (variance_mat*variance_mat')./denom;
% Calculate eigenvalues and eigenvectors. The function retrives these in a
% descending order, so no need to sort it.
[eig_vecs, D] = eigs(images_Cov,P);
eig_vals = diag(D);

%% 3. Plot Average face & EigenFaces
% Create a figure titled 'EigenFaces'. see word document for details.
fig3=figure('Name','EigenFaces');
set(fig3, 'Color','w','MenuBar','none');
set(fig3, 'units', 'normalized', 'OuterPosition', windows_size);

% Plot the average image
subplot(grid_dim+1,grid_dim,(grid_dim+1)/2);
avg_image = reshape(avg_image_vec,[Height,Width]);
imagesc(avg_image);
title("Average Face");
axis equal; axis off;
% Plot the EFs
for i = 1 : P
    g=subplot(grid_dim+1,grid_dim,grid_dim+i);
    EF = reshape(eig_vecs(:,i),[Height,Width]);
    imagesc(EF);
    title(sprintf('%.2f',eig_vals(i)));
    axis equal; axis off;
end
colormap(gray);
    

%% 4. Filter the variance
% 4 cases:
%1.	Keep all energy and reconstruct.
%2.	Keep only the 1st PC and reconstruct (Notice how much energy is explained by the first PC).
%3.	Keep 95% of the energy and reconstruct (Notice how many components you were using).
%4.	Keep 80% of the energy and reconstruct (Notice how many components you were using).
fig3 = figure('Name','Compression');
set(fig3, 'Color','w','MenuBar','none');

% Constants:
illegal_input = "Illegal input.";
instructions = ['Choose the level of compression: (press the number)\n' ...
    '1. Keep all energy.\n' ...
    '2. Keep 1st PC.\n' ...
    '3. Keep 95%% energy.\n' ...
    '4. Keep 80%% energy.\n'];
% Maps relevant cases to the requested energy by the instructions
energy_cases = [3 0.95; 4 0.8];
% Text locations
text_x = 0;
inst_y = 0.7;
error_y = 0.9;

% Calculate the cumulative sum of the eigen vectors' energy
eigs_energy = cumsum(eig_vals);
% Get case from user
is_legal_input = false;
while ~is_legal_input
    axis off;
    is_legal_input = true;
    text(text_x, inst_y, sprintf(instructions));
    pause;
    key = get(fig3,'CurrentCharacter');
    % Calculate the number of components to use, according to the case
    switch key
        case '1'  % All energy
            mComps = P;
        case '2'  % 1 component
            mComps = 1;
        case {'3' '4'} % Energy precentage
            % Retrieve the wanted energy precentage
            energy_perc = energy_cases(energy_cases==str2num(key),2);
            needed_energy = sum(eig_vals)*energy_perc;
            % Find how many components to use for keeping the energy
            [d, mComps] = min(abs(eigs_energy - needed_energy));
        otherwise
            is_legal_input = false;
            clf;
            text(text_x, error_y, illegal_input, 'color', 'r');
    end
end
% Calculate the actual kept energy within the chosen components
kept_energy = eigs_energy(mComps)/eigs_energy(end) * 100;

%% 5. Calculate eigenFaces scores
%The scores are the representation (coeffs) of X in the principal component space

% Get only the mComps first components (with highest eigan values) and
% encode all images
filter_mat = eig_vecs(:,1:mComps);
encoded = filter_mat.'* variance_mat;

%% 6. Preform reconstruction
reconstructed = filter_mat*encoded + avg_image_vec;

%% 7. Show reconstructed faces
% Create the reconstructed figure/s, see word document for details.
fig3.Name="Reconstruction";
set(fig3, 'units', 'normalized', 'OuterPosition', windows_size);

% Plot the reconstructed images
for i = 1 : P
  subplot(grid_dim,grid_dim,i);
  imagesc(reshape(reconstructed(:,i),[Height,Width]));
  title("#"+i);
  axis equal; axis off;
end
colormap(gray);
suptitle(sprintf("Faces (reconstruction): %.2f%% (%dD->%dD)",kept_energy,N,mComps));

