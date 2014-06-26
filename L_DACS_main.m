% L_DACS_main
%     This file is part of L-DACS simulator.
% 
%     Foobar is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     Foobar is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
        clear all
close all


kinds = {'awgn', 'pdp','jakes', 'full'};
%kinds = {'full'}
jitter = {'on', 'off'};
%jitter = {'off'}
factor = {1, 2^-1, 2^-2, 2^-3, 2^-4};
%factor = {2^-3};
for kin = 1:length(kinds)
    for jit = 1:length(jitter)
       	switch kinds{kin}
            case {'awgn', 'pdp'}
            len = 1;
            otherwise
            len = length(factor);
        end
        for fac = 1:len
        clear planes
        clear tower
        % Load the configuration
        display('Loading configuration')
        LDACS_config        = load_config();
        LDACS_config.prefactor = factor{fac};
        target_nr_errors    = LDACS_config.target_nr_errors;
        max_iterations      = LDACS_config.max_iterations_per_snr;
        SNR_steps_dB        = LDACS_config.SNR_range_dB;
        
        % Adaptions
        LDACS_config.channel_kind   = kinds{kin}; % 'pdp', 'jakes', 'full' (=jakes+pdp), 'awgn'
        LDACS_config.timing_jitter  = jitter{jit};
        LDACS_config.error_limit    = 20000;
        LDACS_config.loop_threshold = 5000;
        LDACS_config.MSE            = 'off';
        LDACS_config.MSE_indicator  = 20;
        % Instance the elements of the network
        display('Instancing tower and scheduler...')
        tower               = network_elements.tower(LDACS_config);
        
        display('Instancing planes and channels...')
        planes              = network_elements.planes_factory(LDACS_config, tower);
        
        
        %----------------------------------------------------------
        %                    Main Loop
        %----------------------------------------------------------
        display('Entering main loop now')
        total = 0;
        
        for snr_ = 1:length(SNR_steps_dB)
            % Visual output
            fprintf('%s',strcat('SNR:   ',num2str(SNR_steps_dB(snr_)), 'dB'))
            
            current_errors  = 0;
            loop_count      = 0;
            
            % Simulate while at least one plane hasn't seen enough errors and the
            % loop count is below the threshold
            while sum(current_errors < LDACS_config.error_limit) > 0 &&...
                    loop_count     < LDACS_config.loop_threshold
                
                loop_count = loop_count +1;
                if mod(loop_count, 5) == 0
                    fprintf('.');
                end
                
                % Calculate signal for all Planes
                for planes_idx = 1:LDACS_config.nr_planes;
                    
                    total = total + 1;
                    
                    planes(planes_idx).generate_data_and_signal;
                    % Calculate fading channel
                    planes(planes_idx).calculate_channel();
                    
                end
                
                % Add awgn and receive signal
                tower.receiver(planes, SNR_steps_dB(snr_));
                
                % Calculate made errors
                for planes_idx = 1:LDACS_config.nr_planes;
                    current_errors(planes_idx) = planes(planes_idx).trace.update(snr_);
                end
                
            end
            fprintf('\n')
        end
        % display(num2str(total))
        figure
        % Plotting
        for pl_ = 1:length(planes)
            clear cur_trace
            clear BER
            cur_trace = planes(pl_).trace;
            BER = cur_trace.symbol_error_vector(:,2)./cur_trace.symbol_error_vector(:,1);
            semilogy(SNR_steps_dB, BER);

            xlabel('SNR [dB]')
            ylabel('BER')
            grid on
            hold on
            %sim.eq_MSE = planes(pl_).MSE.grid;
            sim.plane = pl_;
            sim.x = SNR_steps_dB;
            sim.y = BER;
            sim.papr_vector = cur_trace.papr_vector;
            sim.papr_mean   =10*log10(mean(10.^(sim.papr_vector/10)));
            sim.papr_reduction_vector = cur_trace.papr_reduction;
            sim.papr_reduction_mean   = 10*log10(mean(10.^(sim.papr_reduction_vector/10)));
            sim.jitter = LDACS_config.timing_jitter;
            sim.kind  = LDACS_config.channel_kind;
            name = strcat(LDACS_config.channel_kind, '_jitter_', LDACS_config.timing_jitter);
            filename = strcat(name, '_plane_', num2str(pl_), '.mat');
                   	switch kinds{kin}
            case {'awgn', 'pdp'}
              doppler = 'no_fading';
                        otherwise
            doppler = num2str(floor(LDACS_config.doppler_frequency*...
                                LDACS_config.prefactor));
            end
            if ~exist(fullfile('results', doppler), 'dir')
                mkdir(fullfile('results', doppler));
            end
            full_filename = fullfile('results', doppler, filename);
            save(full_filename, 'sim');
                        title(full_filename)
        end
        hold off
        end
    end
end
