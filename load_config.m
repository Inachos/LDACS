function config = load_config()
  % Set variable data

  SNR_start_dB      = 0;
  SNR_steps_dB      = 15;
  SNR_end_dB        = 30;
  
  config.max_iterations_per_snr = 1e6;
  config.target_nr_errors   = 100; % stop simulation after target number
  config.nr_planes          = 2;
  config.scheduler          = 'round robin';
  config.timing_jitter     = 'on';
  % Fixed configuration                                     
  config.channel_kind       = 'jakes';
  config.FFT_size           = 64;                                     
  config.CP_nr              = 11; %                                      
  config.subcarrier_nr      = 50;
  config.guard_lower        = 7;
  config.guard_higher       = 6;
  config.nr_tiles_dc        = 2;
  config.nr_tiles_rl        = 2;
  config.SNR_range_dB      = SNR_start_dB:...
      (SNR_end_dB-SNR_start_dB)/SNR_steps_dB:...
        SNR_end_dB;
  
  % misc
  config.CP_time            = 17.6e-6; % s
  config.t_sampling         = 1.6e-6; % s
  config.subcarrier_spacing = 9.765625e3; % Hz
  config.data_generation    = 'ofdm';
  config.data_length        = 1e5;

  mapping.C4QAM       = [1+1j; 1 - 1j;-1 + 1j; -1 - 1j]/sqrt(2);
  mapping.CBPSK       = [-1; 1];
  mapping.chosen      = mapping.C4QAM;
            % mapping    00     01      10       11
    config.mapping = mapping;
  end
