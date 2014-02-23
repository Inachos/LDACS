function [ data_stream, ofdm_signal ] = ofdm_data_and_signal( nr_tiles__dc, nr_tiles_rl, plane, side)
data_stream             = [];
ofdm_signal             = [];
alphabet                = plane.mapping.chosen;
P_l                     = [2 40 10 2 56 4 2 40 10 2 56 4];
P_r                     = [4 56 2 10 40 2 4 56 2 10 40 2];
frame                   = zeros(plane.FFT_size, 1);

% Side dependent stuff
if strcmp(side, 'upper')
    P = P_r;
    P_ind = plane.pilot_positions_upper;
    papr_position = plane.papr_positions_upper;
else
    P = P_l;
    P_ind = plane.pilot_positions_lower;
    papr_position = plane.papr_positions_lower;
end

for i_ = 0:nr_tiles__dc+nr_tiles_rl
    % the implementation does not respect the mapping order of the
    % data, but it is all random anyway
    if i_ == 0
        % Preamble is fixed, calculate once, then always load
       if isempty(plane.preamble)
           plane.preamble       = generate_preamble(plane);
           plane.tower.preamble = plane.preamble;
       end
       
       ofdm_signal = plane.preamble;
       
    else
        
        for j_ = 1:length(plane.nr_papr_in_data)
            frame       = zeros(64, 1);
            nr_control  = plane.nr_papr_in_data(j_)+...
                             plane.nr_pilot_in_data(j_);
                         
            [symb_par, data] = generate_parallel(plane.subcarrier_nr-...
                                                    nr_control,...
                                                    alphabet, plane);
            % Generate symbols in the frequency grid
            switch side
                case 'lower'
                    symb_par = [zeros(7, 1); symb_par];
                    symb_par = [symb_par; zeros(64-nr_control-length(symb_par), 1)];
                case 'upper'
                    symb_par = [symb_par; zeros(6, 1)];
                    symb_par = [zeros(64-nr_control-length(symb_par), 1); symb_par];
            end
            
            % Generate pilots if necessary
            if plane.nr_pilot_in_data(j_) > 0
                if j_ == 1
                    k = 1:2:12;
                elseif j_ == 6
                    k = 2:2:12;
                end
                S               = exp(1j*2*pi/64*P(k));
                frame(P_ind+33) = S;
                frame(frame==0) = symb_par;
            else
                frame(1:plane.FFT_size ~= (papr_position+33)) = symb_par;
            end
            
            % Apply unitary FFT and concatenate to one stream, including
            % overlap
            ofdm_signal_temp    = sqrt(plane.FFT_size)*ifft(frame, plane.FFT_size).';
            ofdm_signal         = append_symbol(ofdm_signal, ofdm_signal_temp);
            
            % Move DC frame to DC
            t = 1:length(ofdm_signal);
            ofdm_signal = ofdm_signal.*exp(-1j*33*2*pi);
            
            
            data_stream = [data_stream data];
        end
    end
end


end

function ofdm_symbol = add_pre_and_postfix_and_windowing(ofdm_signal_temp)
ofdm_symbol = [ofdm_signal_temp(end-10:end) ofdm_signal_temp ofdm_signal_temp(1:8)];
windowing = window();
ofdm_signal_temp = windowing.*ofdm_symbol;
end

function ofdm_signal = append_symbol(ofdm_signal, ofdm_symbol)
ofdm_symbol_new = add_pre_and_postfix_and_windowing(ofdm_symbol);
if isempty(ofdm_signal)
    ofdm_signal = ofdm_symbol_new;
else
    ofdm_signal(end+1:end+75) = zeros(1,75);
    ofdm_signal(end-82:end) = ofdm_signal(end-82:end) + ...
        ofdm_symbol_new;
end

end

function window = window()
% Return the window for the symbol
window              = ones(1, 83);
t                   = 1:8;
window(1:8)         =  1/2+1/2*cos(pi*(1+((t-1)/8)));
window(end-7:end)   =  1/2-1/2*cos(pi*(1+(t/8)));

end

function [symb_par, data] = generate_parallel(nr_symbols, alphabet, plane)
% Parallel data generation, irrespective of Modulation order (Gray mapping
% is achieved in the correct index to symbol assignment in the config
data            = randi([0 1], 1,nr_symbols*log2(length(alphabet)));
data_par        = reshape(data, log2(length(alphabet)), nr_symbols, []);
mapping_vector  = (2.^(0:log2(length(alphabet))-1));
symb_par        = squeeze(mapping_vector(end:-1:1)*data_par)+1;
symb_par        = alphabet(symb_par);
end

function preamble = generate_preamble(plane)
preamble = [];
 P_AGC = [29 8 35 53 30 17 21 16 7 37 23 35 40 41 8 46 32 47 8 36 26 53 12 26 33 4 31 42 0 6 48 18 60 24 2 15 16 58 48 37 61 22 38 52 23 3 63 36 49 42];
        S_AGC = exp(1j*2*pi/64.*P_AGC);
        mask = [zeros(1, 7), ones(1,25), 0, ones(1,25), zeros(1, 6)];
        frame = mask;
        frame(logical(mask)) = S_AGC;
        AGC_symbol = sqrt(plane.FFT_size)*ifft(frame, 64);
        preamble = append_symbol(preamble, AGC_symbol);
        
        for j_ = 2:6
            P_sync =[-24, -22, -20, -18, -16, -14, -12, -10, -8, -6, -4, -2, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24];
            k = 0:length(P_sync)-1;
            S_sync = sqrt(2)*exp(1j*pi.*k.^2/length(P_sync));
            frame = zeros(1, 64);
            frame(P_sync+33) = S_sync;
            
            sync_symbol = sqrt(plane.FFT_size)*ifft(frame, plane.FFT_size);
            %sync_symbol = sqrt(length(sync_symbol))/norm(sync_symbol)*sync_symbol;
            preamble = append_symbol(preamble, sync_symbol);
            
        end
end
        