function [ output_stream, reduction, min_papr ] = reduce_papr( input_stream, papr_position)
    symbol_alph = [0 exp(1j*2*pi/8*(0:7))];
    frame = zeros(64, length(symbol_alph));
    frame(papr_position+33, :) = symbol_alph;
    time_papr = sqrt(64)*ifft(frame,64).';
    candidates = repmat(input_stream, length(symbol_alph), 1)+time_papr;
    papr = get_papr(candidates);
    [min_papr, ind] = min(papr);
    reduction = papr(1)-min_papr;
    output_stream = candidates(ind, :);
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
end

function [papr] = get_papr(input_stream)
    average_power = sum(abs(input_stream).^2, 2)/size(input_stream, 2);
    peak_power = max(abs(input_stream).^2,[], 2);
    papr = 10*log10(peak_power./average_power);
end