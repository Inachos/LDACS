function small_scale_fading_trace = jakes()
% This function creates a fading trace of fixed length, according to the
% jakes psd.

% First, white noise of unit power is calculated
noise_white = normrnd(0, 1/sqrt(2), 1, 10000)+1j*normrnd(0, 1/sqrt(2), 1, 10000);


f_d         = 413; % [Hz] cutoff of the jakes spectrum
f_s         = 625e3; %[Hz] Bandwidth of OFDM signal
delta       = 1; % Steps in Hz of the jakes filter
fft_size    = 2^nextpow2(f_d*2); % Minimum FFT size to cover the jakes spectrum
nu          = -f_d+1:delta:f_d-1; % Frequency used (avoid singularities by going to f_d-1
H           = zeros(fft_size, 1); % Fill up H with zeros outside of jakes band
%H((fft_size/2)-floor(412/delta):fft_size/2+floor(412/delta)) =...
 %                                   sqrt(1/pi/f_d./sqrt(1-(nu/f_d).^2));
                                %sqrt because PSD(h) = N_0*|H|^2, therefore
                                % |H|^2 has to show jakes form
H(1:825)   = sqrt(1/pi/f_d./sqrt(1-(nu/f_d).^2));   
h = sqrt(fft_size)*ifft(H, fft_size); %unitary FFT
%h(end/2:end) = 0; %Avoid periodic behaviour
noise_colored = conv(noise_white, h);
noise_colored_unity = noise_colored*sqrt(length(noise_colored))./...
    norm(noise_colored);

% At this point, the time base is 1/(fft_size*delta*1Hz) per sample. This has to
% be resampled to achieve 1/(625e3Hz) s per sample. 
display('start resampling')
noise_resampled = resample(noise_colored, f_s, floor(f_d*delta*2));
t=1:length(noise_colored_unity);
small_scale_fading_trace =noise_resampled;%noise_colored_unity.'.*exp(1j*pi.*t);% noise_resampled;
end