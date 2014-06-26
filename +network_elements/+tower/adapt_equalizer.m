function adapt_equalizer(plane, tower, current_signal_fft, second_signal_fft, side)
%     This file is part of L-DACS simulator.
% 
%     L-DACS simulator is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     L-DACS simulator is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
P_l         = [2 40 10 2 56 4 2 40 10 2 56 4];
P_r         = [4 56 2 10 40 2 4 56 2 10 40 2];
frame       = zeros(plane.FFT_size, 1);

if strcmp(side, 'upper')
    P       = P_r;
    P_ind   = plane.pilot_positions_upper;
else
    P       = P_l;
    P_ind   = plane.pilot_positions_lower;
end
for ind = 1:2
    if ind == 1
        signal = current_signal_fft;
        k = 1:2:12;
    elseif ind == 2
        signal = second_signal_fft;
        k = 2:2:12;
    end
    
    S = exp(1j*2*pi/64*P(k));
    frame(P_ind+33) = S;
    frame(frame==0) = 0;
    %-------------------------------------------------------------
    % Now the pilots are divided by the received symbols, according to:
    % Y_k   = H_k*S_k+Z_k
    % S_hat = eq*Y_k
    % eq    = (Y_k/S_k)^-1 = (H_k +Z_k/S_k)^-1
    % Subcarriers without Pilots are set to zero
    eq_pilots_temp  = frame.'./signal;
    eq_pilots       = eq_pilots_temp(eq_pilots_temp~=0); % only use pilot symbols
    
    % Interpolate for other subcarriers:
    P_ind_zeroed    = P_ind-min(P_ind);              % Shift P_ind so 0 is the smallest
    interp_ind      = P_ind_zeroed/max(P_ind_zeroed);% Show original indices as points \in [0, 1]
    new_ind         = (P_ind_zeroed(1):P_ind_zeroed(end)) / ... % Indices of ALL data carrying subcarriers as
        max(P_ind_zeroed);  % scaled to [0,1]
    % Interpolate known equalizers accross subcarriers, using 'spline'
    % configuration:
    equalizer_interpolated_f(:, ind)   = interp1(interp_ind.', eq_pilots.', new_ind.', 'spline');
end
for jj = 1:size(equalizer_interpolated_f, 1)
    equalizer_interpolated(jj, :) = interp1((0:1)', equalizer_interpolated_f(jj, :).', (0:1/5:1)', 'linear');
    % Adapt the stored equalizers of the tower
    
    
end
tower.equalizer(P_ind(1)+33:P_ind(end)+33, :) = equalizer_interpolated;
end
