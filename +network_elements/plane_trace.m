classdef plane_trace < handle
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

        last_generated_data
        last_generated_signal
        last_received_data
        last_received_signal
        plane_id
        bits_sent
        rec_errors
        rec_correct
        last_received_sliced_signal
        symbol_error_vector
        papr_reduction
        papr_vector

    end
    
    methods
        function obj = plane_trace(config, plane_id)
       
            obj.plane_id                = plane_id;
            obj.last_generated_data     = [];
            obj.last_generated_signal   = [];
            obj.last_received_data      = [];
            obj.last_received_signal    = [];
                    obj.last_received_sliced_signal = [];
                    obj.symbol_error_vector = zeros(length(config.SNR_range_dB), 2);
            obj.papr_reduction          = [];
            obj.papr_vector          = [];
        end
        
        function current_total_errors = update(obj, snr_idx)
            nr_symbols = sum(size(obj.last_received_data));
            nr_symbols_total = nr_symbols + obj.symbol_error_vector(snr_idx, 1);
            obj.symbol_error_vector(snr_idx, 1) = nr_symbols_total;
            nr_errors = sum((obj.last_received_data~=obj.last_generated_data));
            current_total_errors = nr_errors + obj.symbol_error_vector(snr_idx, 2);
            obj.symbol_error_vector(snr_idx, 2) = current_total_errors;
        end
        

    end
    
end

