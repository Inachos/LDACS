function timing_correction = recover_timing(input_stream)
% Schmidl Cox Algorithm

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
if 1
    search_offset       = 3+75*[1 2 3 4 5]; % where to start looking
    time_offset         = 32;
    window_length       = 32;
    search_length       = 20;
    aim_correction      = 75*[0 1 2 3 4]; 
end

% Do Schmidl-Cox on all Sync symbols, then agree on mean estimation
for jj = 1:length(search_offset)
    for ii = search_offset(jj):search_offset(jj)+search_length
        
        ind_off     = ii+time_offset;
        P(ii, jj)   = input_stream(ind_off:ind_off+window_length)*...
            input_stream(ii:ii+window_length)';
        R(ii, jj)   = input_stream(ind_off:ind_off+window_length)*...
            input_stream(ind_off:ind_off+window_length)';
        
        M(ii, jj)   = abs(P(ii, jj))^2 / R(ii, jj)^2;
        
    end
    [max_val(jj), max_ind(jj)] = max(M(:, jj));
end
offset_corrected_ind =max_ind(2:4)-aim_correction(2:4);
 W = sum(M.^2, 1);
 W_norm = W(2:4)/sum(W(2:4));
timing_correction =round(offset_corrected_ind*W_norm')-85;
end