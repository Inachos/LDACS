classdef channel < handle
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

    properties
        tower
        plane
        channel_kind
        small_scale_fading
        small_scale_pointer
        small_scale_counter
        small_scale_len
        plane_obj
        prefactor
    end
    
    methods
        function obj = channel(config, tower, plane_id)
            obj.tower = tower;
            obj.plane = plane_id;
            obj.channel_kind = config.channel_kind;
            switch obj.channel_kind
                case {'full'}
                    obj.small_scale_pointer = ones(1,3);
                    obj.small_scale_len = zeros(1,3);
                otherwise
                    obj.small_scale_pointer = 1;
                    obj.small_scale_len = 0;
            end
            obj.small_scale_counter =0;
            obj.prefactor           = config.prefactor;
        end
        
        function output_stream = dummy_channel_response(obj, input_stream)
            output_stream = input_stream;
        end
        function output_stream = awgn_channel_response(obj, input_stream, noise)
            noise_signal = normrnd(0, sqrt(noise/2), size(input_stream))+1j*normrnd(0, sqrt(noise/2), size(input_stream));
            output_stream = input_stream+noise_signal;
        end
        function output_stream = response(obj, input_stream)
            switch obj.channel_kind;
                case {'dummy', 'awgn'}
                    output_stream = obj.dummy_channel_response(input_stream);
                    
                case 'pdp'
                    output_stream = filter(obj.exponential_pdp,1, input_stream);
                case 'jakes'
                    output_stream = obj.jakes(input_stream, 1);
                case 'full'
                    output_stream = obj.jakes(input_stream, obj.exponential_pdp);
                case 'timing jitter'
                    
                    output_stream = obj.dummy_channel_response(input_stream);
                otherwise
                    error('not implemented')
            end
        end
        
        function pdp  = exponential_pdp(obj)
            tau_max = 2;
            pdp = exp(-(0:tau_max));
            pdp = sqrt(pdp.^2/norm(pdp)^2);
            
        end
        
        function output_stream = jakes(obj, input_stream, channel_taps)
            stream_len = length(input_stream);
            nr_taps = length(channel_taps);
            pointer = obj.small_scale_pointer;
            output_stream =  [zeros(size(input_stream)) zeros(1, nr_taps-1)];
            for ii = 1:nr_taps
                
                if pointer(ii)+5000>obj.small_scale_len(ii)
                    obj.small_scale_counter = obj.small_scale_counter + 1;
                    fprintf('*')
                    obj.calculate_small_scale_fading(ii);
                    obj.small_scale_pointer(ii) = 1;
                    pointer(ii) = 1;
                end
                fading_coeff(ii, :) = obj.small_scale_fading(ii, pointer:pointer+stream_len-1);
                obj.small_scale_pointer(ii) = pointer(ii)+stream_len;
                output_stream = output_stream + [zeros(1, ii-1) channel_taps(ii)*input_stream.*fading_coeff(ii,:) zeros(1,nr_taps-ii)];
                
            end
            
            
            
            if obj.plane_obj.MSE.track ==1
                obj.plane_obj.MSE.signal = fading_coeff;
            end
        end
        
        function calculate_small_scale_fading(obj, trace_nr)
            doppler = num2str(round(413*obj.prefactor));
            dir =  fullfile('channel_traces', doppler);
            if~exist(dir, 'dir')
                mkdir(dir);
            end
            full_filename = fullfile('channel_traces', doppler, strcat('rayleigh_plane_', num2str(obj.plane), 'nr', num2str(obj.small_scale_counter), '.mat'));
            if exist(full_filename, 'file') == 2
                load(full_filename, 'trace');
            else
                trace = channel.jakes_2(obj.prefactor);
                save(full_filename, 'trace');
            end
            trace = trace*sqrt(length(trace))/norm(trace);
            obj.small_scale_fading(trace_nr, :) = trace;
            obj.small_scale_len(trace_nr)    = length(trace);
        end
        
    end
    
end

