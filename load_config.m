function config = load_config()
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

  SNR_start_dB      = 0;
  SNR_steps_dB      = 10;
  SNR_end_dB        = 20;
  
  config.type               = 'received';
  config.max_iterations_per_snr = 1e6;
  config.target_nr_errors   = 100; % stop simulation after target number
  config.nr_planes          = 2;
  config.scheduler          = 'round robin';
  config.timing_jitter      = 'on';
  config.max_delay          = 10;
  % Fixed configuration                                     
  config.channel_kind       = 'jakes';
  config.doppler_frequency  = 413; % Hz
  config.FFT_size           = 64;                                     
  config.CP_nr              = 11; %                                      
  config.subcarrier_nr      = 50;
  config.guard_lower        = 7;
  config.guard_higher       = 6;
  config.nr_tiles_dc        = 2;
  config.nr_tiles_rl        = 2;
  config.SNR_range_dB       = SNR_start_dB:...
      (SNR_end_dB-SNR_start_dB)/SNR_steps_dB:...
        SNR_end_dB;
  
  config.error_limit        = 20000;
  config.loop_threshold     = 20000;
  % misc
  config.CP_time            = 17.6e-6; % s
  config.t_sampling         = 1.6e-6; % s
  config.subcarrier_spacing = 9.765625e3; % Hz
  config.data_generation    = 'ofdm';
  config.data_length        = 1e5;
  base_pattern        = [1+1j; 1 - 1j;-1 + 1j; -1 - 1j];
  mapping.C4QAM       = base_pattern/sqrt(2);
  offset              = [2+2j];
  base_pattern_16     = base_pattern+offset;
  mapping.C16QAM      = [base_pattern_16;...
                        conj(base_pattern_16);...
                        -conj(base_pattern_16);...
                        -base_pattern_16;]/sqrt(10);
  mapping.CBPSK       = [-1; 1];
  mapping.chosen      = mapping.C4QAM;
            % mapping    00     01      10       11
    config.mapping = mapping;
  end
