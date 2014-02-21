classdef plane < handle
    %PLANE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tower
        id
        channel
        trace
        data_length
        data_generation
        mapping
        subcarrier_nr
        tile_size
        tile_size_data
        nr_pilot_in_data
        nr_papr_in_data
        pilot_positions_lower
        pilot_positions_upper
        papr_positions_lower
        papr_positions_upper
        FFT_size
        guard_higher
        guard_lower
        side
        preamble
        nr_tiles_dc
        nr_tiles_rl
    end
    
    methods
        function obj = plane(config, tower, plane_id, side)
            obj.tower   = tower;
            obj.id      = plane_id;
            tower.attach_plane(plane_id);
            obj.channel = network_elements.channel(config, tower, plane_id);
            obj.trace = network_elements.plane_trace(config, plane_id);
            obj.data_generation         = config.data_generation;
            obj.data_length             = config.data_length;
            obj.mapping                 = config.mapping;
            obj.subcarrier_nr           = config.subcarrier_nr/2;
            obj.nr_pilot_in_data        = [6 0 0 0 0 6];
            obj.nr_papr_in_data         = [0 1 1 1 1 0];
            obj.pilot_positions_lower   = [-25 -21 -16 -11 -6 -1];
            obj.pilot_positions_upper   = [ 1 6 11 16 21 25];
            obj.papr_positions_lower    = -24;
            obj.papr_positions_upper    = 23;
            obj.FFT_size                = config.FFT_size;
            obj.guard_higher            = config.guard_higher;
            obj.guard_lower             = config.guard_lower;
            obj.side                    = side;
            obj.preamble                = [];
            obj.channel.calculate_small_scale_fading;
            obj.nr_tiles_dc             = config.nr_tiles_dc;
            obj.nr_tiles_rl             = config.nr_tiles_rl;
          
        end
        
        function generate_data_and_signal(obj)
            
            switch obj.data_generation
                case 'dummy'
                    obj.trace.last_generated_data = obj.generate_dummy_data;
                    obj.trace.last_generated_signal = obj.generate_dummy_signal(obj.trace.last_generated_data);
                case 'ofdm'
                    [obj.trace.last_generated_data, obj.trace.last_generated_signal] = ...
                        network_elements.plane.ofdm_data_and_signal(obj.nr_tiles_dc,...
                                                                    obj.nr_tiles_rl,...
                                                                    obj, obj.side);
                otherwise
                    error('OFDM data generation not implemented');
            end
        end
        
        function [data] = generate_dummy_data(obj)
           data = randi([0 1], 1, obj.data_length); 
        end
        function [signal] = generate_dummy_signal(obj, data)
            % dummy mapping: 4QAM, unit power:
            alphabet = obj.mapping.C4QAM;
            %symb_par = obj.serial_to_parallel(data, alphabet);

            
            data_reordered = reshape(data, 2, [])';
            alphabet_idxs = data_reordered*[2; 1] + 1;
            signal = alphabet(alphabet_idxs);
        end
            
        
        function receive_signal(obj)
            [obj.trace.last_received_data, obj.trace.last_received_sliced_signal] = obj.tower.receiver(obj.trace.last_received_signal);
        end
        function calculate_channel(obj)
           obj.trace.last_received_signal = obj.channel.response(obj.trace.last_generated_signal); 
        end

    end
    
end