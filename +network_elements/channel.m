classdef channel < handle
    %CHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tower
        plane
        channel_kind
        small_scale_fading
        small_scale_pointer
        small_scale_counter
        small_scale_len
        plane_obj
    end
    
    methods
        function obj = channel(config, tower, plane_id)
            obj.tower = tower;
            obj.plane = plane_id;
            obj.channel_kind = config.channel_kind;
            obj.small_scale_pointer = 1;
            obj.small_scale_counter = 1;
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
                    output_stream = filter([1 0 0], 1, obj.dummy_channel_response(input_stream));

                case 'pdp'
                     output_stream = filter(obj.exponential_pdp,1, input_stream);
                case 'jakes'
                     output_stream = obj.jakes(input_stream);
                case 'full'
                    output_stream = conv(obj.jakes(input_stream), obj.exponential_pdp);
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
        
        function output_stream = jakes(obj, input_stream)
            stream_len = length(input_stream);
            
            pointer = obj.small_scale_pointer;
            if pointer+5000>obj.small_scale_len
                obj.small_scale_counter = obj.small_scale_counter + 1;
                fprintf('*')
                obj.calculate_small_scale_fading;
                obj.small_scale_pointer = 1;
                pointer = 1;
            end
            fading_coeff = obj.small_scale_fading(pointer:pointer+stream_len-1);
            obj.small_scale_pointer = pointer+stream_len;
            output_stream = input_stream.*fading_coeff;
             if obj.plane_obj.MSE.track ==1
                 obj.plane_obj.MSE.signal = fading_coeff;
             end
        end
        
        function calculate_small_scale_fading(obj)
            full_filename = fullfile('channel_traces', strcat('rayleigh_plane_', num2str(obj.plane), 'nr', num2str(obj.small_scale_counter), '.mat'));
            if exist(full_filename, 'file') == 2
                load(full_filename, 'trace');
            else
                trace = channel.jakes_2;
                save(full_filename, 'trace');
            end
            trace = trace*sqrt(length(trace))/norm(trace);
            obj.small_scale_fading = trace;
            obj.small_scale_len    = length(trace);
        end
            
    end
    
end

