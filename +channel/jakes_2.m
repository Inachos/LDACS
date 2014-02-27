function small_scale_fading_trace = jakes_2()
N = 10000;
f_d = 413.001;
% B1 = [0 32/64-414/625e3];
% A1 = [0 0];
% B2 = [32/64-413/625e3:1/625e3:32/64+413/625e3];
% nu = -413:413;
% A2 = sqrt(1/pi/f_d./sqrt(1-(nu/f_d).^2));
% B3 = [32/64+414/625e3 1];
% A3 = [0 0];
% F = [B1 B2 B3];
% A = [A1 A2 A3];
nu = 0:413;
B2 = [nu/625e3];
A2 = sqrt(1/pi/f_d./sqrt(1-(nu/f_d).^2));
B3 = [414/625e3 1];
A3 = [0 0];
A = [A2 A3];
F = [B2 B3];
d = fdesign.arbmag('N,F,A', N, F, A);
Hd = design(d, 'freqsamp', 'systemObject',true);
noise_white = normrnd(0, 1/sqrt(2), 1, 1000000)+1j*normrnd(0, 1/sqrt(2), 1, 1000000);
display('filter fading')
noise_colored = filtfilt(Hd.Numerator,1, noise_white);
%small_scale_fading_trace = noise_colored(2:2:end).*exp(-1j*pi.*(1:length(noise_colored(2:2:end))));
small_scale_fading_trace = noise_colored;
end