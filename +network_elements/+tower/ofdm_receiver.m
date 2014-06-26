function [received_datastream, sliced_signal ] = ofdm_receiver( ...
    input_signal,...
    nr_tiles_per_dc,...
    nr_tiles_rl,...
    tower, plane,...
    side, noise_power)
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
%     along with  L-DACS simulator.  If not, see <http://www.gnu.org/licenses/>.
t = 1:length(input_signal);
sig_baseband = input_signal;
input_signal = input_signal.*exp(1j*pi.*t);
received_datastream = [];
sliced_signal       = [];
timing_recovery     = 4;
alphabet            = tower.mapping.chosen;
P_l                 = [2 40 10 2 56 4 2 40 10 2 56 4];
P_r                 = [4 56 2 10 40 2 4 56 2 10 40 2];
frame               = zeros(plane.FFT_size, 1);

% Timing recovery


% Upper and lower index information
if strcmp(side, 'upper')
    P               = P_r;
    P_ind           = plane.pilot_positions_upper;
    papr_position   = plane.papr_positions_upper;
else
    P               = P_l;
    P_ind           = plane.pilot_positions_lower;
    papr_position   = plane.papr_positions_lower;
end

for i_ = 1:nr_tiles_per_dc+nr_tiles_rl
    for j_ = 1:length(plane.nr_papr_in_data)
        % Where does the current frame start:
        switch plane.channel.channel_kind
            case {'full', 'pdp'}
                if strcmp(tower.jitter, 'on')
                    timing_recovery = network_elements.tower.recover_timing(input_signal)+2;
                else
                    timing_recovery = 0;
                end
                offset = ((i_)*6+(j_-1))*75+timing_recovery;
            otherwise
                if strcmp(tower.jitter, 'on')
                    timing_recovery = network_elements.tower.recover_timing(input_signal);
                else
                    timing_recovery = 0;
                end
                offset = ((i_)*6+(j_-1))*75+timing_recovery;
        end
        
        % Filter out current signal
        current_signal = input_signal(1+offset:75+offset);
        
        % Drop CP and do unitary FFT
        current_signal_no_cp = current_signal(12:75);
        current_signal_fft = fft(current_signal_no_cp, plane.FFT_size)/sqrt(plane.FFT_size);
        
        if j_ == 1
            % second_signal_fft = input_signal(1+offset
        end
        % Mask where to find Data
        mask = ones(1, 64);
        mask(1:7) = 0;
        mask(59:64) = 0;
        if j_ == 1 || j_ == 6
            mask(plane.pilot_positions_lower+33) = 0;
            mask(plane.pilot_positions_upper+33) = 0;
            
            % Use pilots to adapt the equalizer
            if j_==1
                second_signal_no_cp = input_signal(12+5*75+offset:6*75+offset);
                second_signal_fft = fft(second_signal_no_cp, plane.FFT_size)/sqrt(plane.FFT_size);
                network_elements.tower.adapt_equalizer(plane, tower, current_signal_fft, second_signal_fft, side);
                if tower.track_eq == 1 && plane.MSE.track==1
                    update_MSE(plane,tower,offset, sig_baseband);
                end
            end
        else
            mask(plane.papr_positions_lower+33) = 0;
            mask(plane.papr_positions_upper+33) = 0;
        end
        if strcmp(side, 'upper')
            mask(1:33) = 0;
        else
            mask(33:end) = 0;
        end
        
        % Equalize, slice and demap
        
            current_signal_fft                  = tower.equalizer(:, j_).'.*current_signal_fft;
            current_signal_fft_temp             = current_signal_fft;
            [data_current,...
                current_signal_fft_temp(logical(mask))] = tower.slicer(current_signal_fft(logical(mask)));
        
        received_datastream                 = [received_datastream data_current];
        sliced_signal                       = [sliced_signal current_signal_fft];
    end
end
end
function update_MSE(plane, tower, offset, signal)
for ii=1:6
    sig_no_fad = (signal./[plane.MSE.signal ones(1,10)]).*exp(1j*pi.*(1:length(signal)));
    sig_fad = signal.*exp(1j*pi.*(1:length(signal)));
    slice_fad = sig_fad(12+offset+(ii-1)*75:offset+ii*75);
    slice_no_fad = sig_no_fad(12+offset+(ii-1)*75:offset+ii*75);
    fft_fad(:, ii) = fft(slice_fad, 64);
    fft_no_fad(:, ii) = fft(slice_no_fad, 64);
end
grid = fft_no_fad./fft_fad;
squared_error = abs(tower.equalizer-grid).^2;
plane.update_mse(squared_error);
end
