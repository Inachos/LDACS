function timing_correction = recover_timing(input_stream)
% Schmidl Cox Algorithm

if 1
    search_offset       = 3+75*[1 2 3 4 5]; % where to start looking
    time_offset         = 32;
    window_length       = 31;
    search_length       = 20;
    aim_correction      = 11+75*[1 2 3 4 5]; % empirically found
else
    search_offset = 76;
    window_length = 83;
    time_offset = 76;
    search_length = 15;
    aim_correction = 76;
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
offset_corrected_ind =max_ind-aim_correction;
 W = sum(M.^2, 1);
 W_norm = W/sum(W);
timing_correction = min(max(round(offset_corrected_ind*W_norm'), 0), 15);
end