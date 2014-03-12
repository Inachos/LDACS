% L_DACS_main
        clear all
close all
%kinds = {'awgn', 'pdp', 'jakes', 'full'};
kinds = {'jakes', 'full'}
jitter = {'on', 'off'};
%jitter = {'off'}
factor = {1/2, 1/4, 1/8};
for kin = 1:length(kinds)
    for jit = 1:length(jitter)
        for fac = 1:length(factor);
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
        LDACS_config.MSE            = 'on';
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
            sim.eq_MSE = planes(pl_).MSE.grid;
            sim.plane = pl_;
            sim.x = SNR_steps_dB;
            sim.y = BER;
            sim.jitter = LDACS_config.timing_jitter;
            sim.kind  = LDACS_config.channel_kind;
            name = strcat(LDACS_config.channel_kind, '_jitter_', LDACS_config.timing_jitter);
            filename = strcat(name, '_plane_', num2str(pl_), '.mat');
            
            doppler = num2str(floor(LDACS_config.doppler_frequency*...
                                LDACS_config.prefactor));
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
