
% This function calculates the principal angles between two subspaces
%
% Inputs:
%   A - A matrix whose columns form an orthonormal basis for the first subspace.
%   B - A matrix whose columns form an orthonormal basis for the second subspace.
%       (Note: Inputs are assumed to be orthonormal. If not, consider using
%       `orth(A)` and `orth(B)` before passing them to this function.)
%
% Output:
%   angles_rad - A vector of principal angles between the two subspaces,
%                in radians, sorted in non-decreasing order.


function angles_rad = subspace_angles(A, B)

% Ensure inputs are double for numerical precision in SVD and acos.
% `eig` outputs are typically double, but explicit casting is safer.
A = double(A);
B = double(B);

% The number of principal angles is the minimum of the number of columns
% (dimensions) of the two subspace bases.
% The inputs A and B are assumed to already represent orthonormal bases
% from eigenvectors (as per the GEDAI context).

% Compute the SVD of A' * B. The singular values (S) are the cosines
% of the principal angles.
% We only need the singular values, so U and V are not captured.
[~, S, ~] = svd(A' * B);

% Extract the singular values, which are on the diagonal of S.
cos_theta = diag(S);

% Due to floating-point arithmetic, cos_theta might be slightly outside
% the valid range of [-1, 1] for acos. Clip values to prevent complex outputs.
cos_theta(cos_theta > 1) = 1;
cos_theta(cos_theta < -1) = -1;

% Calculate the principal angles using arccosine.
angles_rad = acos(cos_theta);

% Sort the angles in non-decreasing (ascending) order,
% as is standard for principal angles (and typically done by subspacea).
angles_rad = sort(angles_rad);

end