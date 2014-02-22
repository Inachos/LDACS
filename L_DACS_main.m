% L_DACS_main
%clear all
close all

% Load the configuration
display('Loading configuration')
LDACS_config        = load_config()
target_nr_errors    = LDACS_config.target_nr_errors;
max_iterations      = LDACS_config.max_iterations_per_snr;
SNR_steps_dB        = LDACS_config.SNR_range_dB;

% Adaptions
LDACS_config.channel_kind   = 'full'; % 'pdp', 'jakes', 'full' (=jakes+pdp), 'awgn'
LDACS_config.timing_jitter  = 'on';
LDACS_config.error_limit    = 10000;
LDACS_config.loop_threshold = 10000;

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

% Plotting
for pl_ = 1:length(planes)
    clear cur_trace
    clear BER
    cur_trace = planes(pl_).trace;
    BER = cur_trace.symbol_error_vector(:,2)./cur_trace.symbol_error_vector(:,1);
    figure
    semilogy(SNR_steps_dB, BER);
    title(sprintf('Plane %ld', pl_))
    xlabel('SNR [dB]')
    ylabel('BER')
    grid on
    hold off
end