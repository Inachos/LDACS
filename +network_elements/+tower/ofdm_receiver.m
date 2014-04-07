function [received_datastream, sliced_signal ] = ofdm_receiver( ...
    input_signal,...
    nr_tiles_per_dc,...
    nr_tiles_rl,...
    tower, plane,...
    side, noise_power)

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
        [data_current,...
            current_signal_fft(logical(mask))] = tower.slicer(current_signal_fft(logical(mask)));
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
%
%
% function adapt_equalizer(plane, tower, current_signal_fft, current_frame, side)
%
% % Construct the pilots as they should be
%
% P_l         = [2 40 10 2 56 4 2 40 10 2 56 4];
% P_r         = [4 56 2 10 40 2 4 56 2 10 40 2];
% frame       = zeros(plane.FFT_size, 1);
%
% if strcmp(side, 'upper')
%     P       = P_r;
%     P_ind   = plane.pilot_positions_upper;
% else
%     P       = P_l;
%     P_ind   = plane.pilot_positions_lower;
% end
%
% if current_frame == 1
%     k = 1:2:12;
% elseif current_frame == 6
%     k = 2:2:12;
% end
%
% S = exp(1j*2*pi/64*P(k));
% frame(P_ind+33) = S;
% frame(frame==0) = 0;
% %-------------------------------------------------------------
% % Now the pilots are divided by the received symbols, according to:
% % Y_k   = H_k*S_k+Z_k
% % S_hat = eq*Y_k
% % eq    = (Y_k/S_k)^-1 = (H_k +Z_k/S_k)^-1
% % Subcarriers without Pilots are set to zero
% eq_pilots_temp  = frame.'./current_signal_fft;
% eq_pilots       = eq_pilots_temp(eq_pilots_temp~=0); % only use pilot symbols
%
% % Interpolate for other subcarriers:
% P_ind_zeroed    = P_ind-min(P_ind);              % Shift P_ind so 0 is the smallest
% interp_ind      = P_ind_zeroed/max(P_ind_zeroed);% Show original indices as points \in [0, 1]
% new_ind         = (P_ind_zeroed(1):P_ind_zeroed(end)) / ... % Indices of ALL data carrying subcarriers as
%     max(P_ind_zeroed);  % scaled to [0,1]
%
% % Interpolate known equalizers accross subcarriers, using 'spline'
% % configuration:
% equalizer_interpolated   = interp1(interp_ind.', eq_pilots.', new_ind.', 'spline');
%
% % Adapt the stored equalizers of the tower
% tower.equalizer(P_ind(1)+33:P_ind(end)+33, :) = kron(ones(1,6), equalizer_interpolated);
% end
%
%
% function adapt_equalizer_v3(plane, tower, current_signal_fft, input_signal, frame_length, side,offset)
%
% % Construct the pilots as they should be
%
% P_l         = [2 40 10 2 56 4 2 40 10 2 56 4];
% P_r         = [4 56 2 10 40 2 4 56 2 10 40 2];
% frame       = zeros(plane.FFT_size, 1);
%
% if strcmp(side, 'upper')
%     P       = P_r;
%     P_ind   = plane.pilot_positions_upper;
% else
%     P       = P_l;
%     P_ind   = plane.pilot_positions_lower;
% end
% for i_ = 1:frame_length
%
%     for ind = 1:2
%         if ind == 1
%             signal_time = input_signal(12+(i_-1)*75*6+offset:75+(i_-1)*75*6+offset);
%             k = 1:2:12;
%         elseif ind == 2
%             signal_time = input_signal(12+(i_-1)*75*6+5*75+offset:75*6+(i_-1)*75*6+offset);
%             k = 2:2:12;
%         end
%         signal = fft(signal_time, 64)/sqrt(length(signal_time));
%         S = exp(1j*2*pi/64*P(k));
%         frame(P_ind+33) = S;
%         frame(frame==0) = 0;
%         %-------------------------------------------------------------
%         % Now the pilots are divided by the received symbols, according to:
%         % Y_k   = H_k*S_k+Z_k
%         % S_hat = eq*Y_k
%         % eq    = (Y_k/S_k)^-1 = (H_k +Z_k/S_k)^-1
%         % Subcarriers without Pilots are set to zero
%         eq_pilots_temp  = frame.'./signal;
%         eq_pilots       = eq_pilots_temp(eq_pilots_temp~=0); % only use pilot symbols
%
%         % Interpolate for other subcarriers:
%         P_ind_zeroed    = P_ind-min(P_ind);              % Shift P_ind so 0 is the smallest
%         interp_ind      = P_ind_zeroed/max(P_ind_zeroed);% Show original indices as points \in [0, 1]
%         new_ind         = (P_ind_zeroed(1):P_ind_zeroed(end)) / ... % Indices of ALL data carrying subcarriers as
%             max(P_ind_zeroed);  % scaled to [0,1]
%         % Interpolate known equalizers accross subcarriers, using 'spline'
%         % configuration:
%         equalizer_interpolated_f(:, 2*(i_-1)+ind)   = interp1(interp_ind.', eq_pilots.', new_ind.', 'spline');
%     end
% end
% for jj = 1:size(equalizer_interpolated_f, 1)
%     int_ind = kron((0:(frame_length-1))/(frame_length), [1 1]) + ...
%         kron(ones(1, frame_length), [0, 5/6/(frame_length)]);
%     ind_2 = 0:1/6/frame_length:int_ind(end);
%     equalizer_interpolated(jj, :) = interp1(int_ind.', equalizer_interpolated_f(jj, :).', ind_2.', 'spline');
%     % Adapt the stored equalizers of the tower
%
%
% end
% tower.equalizer(P_ind(1)+33:P_ind(end)+33, :) = equalizer_interpolated;
% end