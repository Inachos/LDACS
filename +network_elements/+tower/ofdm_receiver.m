function [received_datastream, sliced_signal ] = ofdm_receiver( ...
    input_signal,  nr_tiles_per_dc, nr_tiles_rl,...
    tower, plane, side, noise_power)

received_datastream = [];
sliced_signal       = [];
timing_recovery     = 4;
alphabet = tower.mapping.C4QAM;
P_l = [2 40 10 2 56 4 2 40 10 2 56 4];
P_r = [4 56 2 10 40 2 4 56 2 10 40 2];
frame = zeros(plane.FFT_size, 1);
if strcmp(tower.jitter, 'on')
    timing_recovery = recover_timing(input_signal);
else
    timing_recovery = 0;
end
if strcmp(side, 'upper')
    P = P_r;
    P_ind = plane.pilot_positions_upper;
    papr_position = plane.papr_positions_upper;
else
    P = P_l;
    P_ind = plane.pilot_positions_lower;
    papr_position = plane.papr_positions_lower;
end
for i_ = 1:nr_tiles_per_dc+nr_tiles_rl
    for j_ = 1:length(plane.nr_papr_in_data)
        offset = ((i_)*6+(j_-1))*75-2+timing_recovery;
        current_signal = input_signal(1+offset:75+offset);
        current_signal_no_cp = current_signal(12:75);
        current_signal_fft = fft(current_signal_no_cp, plane.FFT_size)/sqrt(plane.FFT_size);
        mask = ones(1, 64);
        mask(1:7) = 0;
        mask(59:64) = 0;
        if j_ == 1 || j_ == 6
            mask(plane.pilot_positions_lower+33) = 0;
            mask(plane.pilot_positions_upper+33) = 0;
            adapt_equalizer(plane, tower, current_signal_fft, j_, side)
        else
            mask(plane.papr_positions_lower+33) = 0;
            mask(plane.papr_positions_upper+33) = 0;
        end
        if strcmp(side, 'upper')
            mask(1:33) = 0;
        else
            mask(33:end) = 0;
        end
        
        current_signal_fft = tower.equalizer.'.*current_signal_fft;
        [data_current, current_signal_fft(logical(mask))] = tower.slicer_4QAM(current_signal_fft(logical(mask)));
        received_datastream = [received_datastream data_current];
        sliced_signal = [sliced_signal current_signal_fft];
    end
end
end

function timing_correction = recover_timing(input_stream)
% Schmidl Cox Algorithm
% The start of the 32 slot pattern induced by Schmidl-Cox is at
% The 87 Slot:
% | 11 slots AGC CP | 64 slots AGC | 11 slots Sync CP | 64 slots Sync |...
%                                                 here ^

if 1
    search_offset = -6+76*[1 2 3 4 5]; % where to start looking
    time_offset = 32;
    window_length = 31;
    search_length = 50;
    aim_correction = 5+76*[1 2 3 4 5];
else
    search_offset = 76;
    window_length = 83;
    time_offset = 76;
    search_length = 15;
    aim_correction = 76;
end
for jj = 1:length(search_offset)
for ii = search_offset(jj):search_offset(jj)+search_length
    ind_off = ii+time_offset;
    P(ii, jj) =  input_stream(ind_off:ind_off+window_length)*input_stream(ii:ii+window_length)';
    R(ii, jj) = input_stream(ind_off:ind_off+window_length)*input_stream(ind_off:ind_off+window_length)';
    M(ii, jj) = abs(P(ii, jj))^2/R(ii, jj)^2;
    
end
[max_val(jj), max_ind(jj)] = max(M(:, jj));
end
timing_correction = min(max(round(mean(max_ind-aim_correction)), 0), 10);
end

function adapt_equalizer(plane, tower, current_signal_fft, current_frame, side)
P_l = [2 40 10 2 56 4 2 40 10 2 56 4];
P_r = [4 56 2 10 40 2 4 56 2 10 40 2];
frame = zeros(plane.FFT_size, 1);
if strcmp(side, 'upper')
    P = P_r;
    P_ind = plane.pilot_positions_upper;
else
    P = P_l;
    P_ind = plane.pilot_positions_lower;
end
if current_frame == 1
    k = 1:2:12;
elseif current_frame == 6
    k = 2:2:12;
end
S = exp(1j*2*pi/64*P(k));
frame(P_ind+33) = S;
frame(frame==0) = 0;
eq_pilots_temp = frame.'./current_signal_fft;
eq_pilots = eq_pilots_temp(eq_pilots_temp~=0);
index_zeroed =(P_ind-min(P_ind));
interp_ind = index_zeroed/max(index_zeroed);
new_ind = (index_zeroed(1):index_zeroed(end))/max(index_zeroed);
%linear_interp = interp1q(interp_ind.', eq_pilots.', new_ind.');
linear_interp = interp1(interp_ind.', eq_pilots.', new_ind.', 'spline');
tower.equalizer(P_ind(1)+33:P_ind(end)+33) = linear_interp;
end
