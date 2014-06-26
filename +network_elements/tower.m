classdef tower < handle
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
    properties
        planes
        preamble
        mapping
        jitter
        equalizer
        nr_tiles_dc
        nr_tiles_rl
        max_delay
        type
        MSE_indicator
        track_eq
    end
    
    methods
        function obj = tower(config)
            obj.mapping                 = config.mapping;
            obj.jitter                  = config.timing_jitter;
            obj.equalizer               = ones(config.FFT_size, 6);
            obj.nr_tiles_dc             = config.nr_tiles_dc;
            obj.nr_tiles_rl             = config.nr_tiles_rl;
            obj.max_delay               = config.max_delay;
            obj.type                    = config.type;
            obj.MSE_indicator           = config.MSE_indicator;
            obj.track_eq                = 0;
        end
        
        function [nr_attached] =  attach_plane(obj, plane_id)
            found_idx = obj.planes == plane_id;
            if sum(found_idx) > 0
                nr_attached = 0; % was already attached
            else
                obj.planes = [obj.planes plane_id];
                nr_attached = 1;
            end
        end
        
        function [nr_dropped] = drop_plane(obj, plane_id)
            drop_idx = obj.planes == plane_id;
            nr_dropped = sum(drop_idx);
            obj.planes = obj.planes(~nr_dropped);
        end
        
        function [received_datastream, sliced_signal] = receiver(obj, planes, snr_dB)
            % Calculate the sum signal as seen by the tower
            if snr_dB == obj.MSE_indicator
                obj.track_eq = 1;
            else 
                obj.track_eq = 0;
            end
            traces = [planes.trace];
            if(strcmp(obj.type, 'received'))
            input_signal = sum(vertcat(traces.last_received_signal), 1);
            
            % Add additive white gaussian noise
            [input_signal, noise_power] = obj.awgn_channel_response(input_signal, snr_dB, obj.type);
            else
                input_signal_temp = vertcat(traces.last_received_signal);
                for ii = 1:size(input_signal_temp, 1)
                 [input_signal_temp(ii, :), noise_power]=   obj.awgn_channel_response(input_signal_temp(ii, :), snr_dB, obj.type);
                end
                input_signal = sum(input_signal_temp, 1);
            end
            input_signal = obj.add_timing_jitter(input_signal);
                 
            for i_ = 1:length(planes)
                
                [planes(i_).trace.last_received_data,...
                    planes(i_).trace.last_received_sliced_signal]...
                    = network_elements.tower.ofdm_receiver(input_signal,...
                    obj.nr_tiles_dc,...
                    obj.nr_tiles_rl,...
                    obj, planes(i_),...
                    planes(i_).side,...
                    noise_power);
            end
        end
        function [data_stream, sliced_signal] = slicer(obj, input_signal)
            if obj.mapping.chosen == obj.mapping.C4QAM
                [data_stream, sliced_signal] = obj.slicer_4QAM(input_signal);
            else
                error('not implemented at the moment')
                
            end
            
            
        end
        function [data_stream, sliced_signal] = slicer_4QAM(obj, input_signal)
            sliced_signal = 1/sqrt(2)*...
                (sign(real(input_signal))+1j*sign(imag(input_signal)));
            alphabet_ind = [0 1 2 3]*bsxfun(@eq, obj.mapping.C4QAM, reshape(sliced_signal, 1, []));
            data_mat = [floor(alphabet_ind./2);mod(alphabet_ind, 2) ];
            data_stream = reshape(data_mat, 1, []);
        end
        function [data_stream, sliced_signal] = slicer_16QAM(obj, input_signal)
            
            
            
            
        end
        
        function [output_stream, noise] = awgn_channel_response(obj, input_stream, snr_dB, type)
            % Since the SNR is defined over the bit energy, we need the
            % fraction of the signal that actually carries bits.
            information_symbol_ratio = (38*2+48*4) * ... Nr data symbols per 2 tiles
                obj.nr_tiles_dc * ... Nr data tiles in dc frame
                obj.nr_tiles_rl / ... Nr tiles in one data frame
                length(input_stream);
            
            % Right now, this is calculated as receive SNR. Therefore, The
            % received power is calculated:
            if strcmp('received', type)
            av_power_input = norm(input_stream).^2/length(input_stream);
            else
                av_power_input = 1;
            end
            bits_per_symbol = log2(length(obj.mapping.chosen));
            
            noise = 10.^(-snr_dB./10) *... Noise power for 1 bit per symbol and unit transmit power
                information_symbol_ratio * ... Correction for information ratio
                av_power_input/bits_per_symbol; % Correction for receive ratio and Power per Symbol vs Power per Bit
            
            noise_signal = normrnd(0, sqrt(noise/2), size(input_stream))+1j*normrnd(0, sqrt(noise/2), size(input_stream));
            output_stream = input_stream+noise_signal;
        end
        
        function output_stream = add_timing_jitter(obj, input_stream)
            max_delay = obj.max_delay; % Maximum allowed jitter
            
            % Expand vector by random noise of appropriate power, so the
            % circular shift does not wrap the signal around 
            s_power = norm(input_stream)^2/length(input_stream);
            deviation = sqrt(s_power/2);
            input_stream = [input_stream, normrnd(0, deviation, 1, max_delay)+ ... 
                                       1j*normrnd(0, deviation, 1, max_delay) ];
            % Generate jitter and shift. Note, it is not necessary to
            % simulate twosided jitter, as this only amounts to a shift of
            % the reference plane
            if strcmp(obj.jitter, 'on')
                timing_shift = randi([0 max_delay], 1, 1);
            else
                timing_shift = 0;
            end
            output_stream = circshift(input_stream, [0, timing_shift]);
            
        end
    end
    
end

