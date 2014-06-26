function small_scale_fading_trace = jakes_2(prefactor)
N = 20000;
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
f_d = 2*413.001*prefactor;
% B1 = [0 33/64-floor(f_d+1)/625e3];
% A1 = [0 0];
% B2 = [33/64-floor(f_d)/625e3:1/625e4:33/64+floor(f_d)/625e3];
% nu = -floor(f_d):.1:floor(f_d);
% A2 = sqrt(1/pi/f_d./sqrt(1-(nu/f_d).^2));
% B3 = [33/64+floor(f_d+1)/625e3 1];
% A3 = [0 0];
% F = [B1 B2 B3];
% A = [A1 A2 A3];
nu = 0:1:f_d;
B2 = [nu/625e3];
A2 = sqrt(1/pi/f_d./sqrt(1-(nu/f_d).^2));
B3 = [(floor(f_d)+1)/625e3 1];
A3 = [0 0];
A = [A2 A3];
F = [B2 B3];
d = fdesign.arbmag('N,F,A', N, F, A);
Hd = design(d, 'freqsamp', 'systemObject',true);
noise_white = normrnd(0, 1/sqrt(2), 1, 1000000)+1j*normrnd(0, 1/sqrt(2), 1, 1000000);
fprintf('|')
noise_colored = filter(Hd.Numerator,1, noise_white);
%small_scale_fading_trace = noise_colored(2:2:end).*exp(-1j*pi.*(1:length(noise_colored(2:2:end))));
small_scale_fading_trace = noise_colored(1:end-length(Hd.Numerator));
end